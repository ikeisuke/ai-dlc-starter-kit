# Unit 004 ドメインモデル: predecessor handoff の Issue 検索化

## 1. ユビキタス言語

| 用語 | 説明 |
|------|------|
| PredecessorCycle | 前サイクル（直前にリリースしたサイクルのバージョン）。例: 本サイクルが v2.6.0 なら v2.5.0 |
| PredecessorIssue | 前サイクル振り返り Issue（closed Milestone + `retrospective` ラベル AND 検索でヒットする Issue） |
| PredecessorReference | predecessor handoff の解決結果（Issue URL / spool 内 URL / v2.5.0 retrospective.md パス / 不在 のいずれか） |
| ResolutionPath | 解決経路（Milestone+label / label fallback / spool / v2.5.0 互換 / warn-continue の 5 種） |
| MilestoneEnabled | `[project].milestone_enabled` 設定（true: Milestone 検索 canonical / false: label のみ fallback） |
| GhStatus | `gh` CLI の利用可能性（`available` / `unavailable` / `not-installed`）。Unit 002 の `__retro_gh_status` 戻り値と完全一致 |
| SpoolEntry | Unit 002 が定義する NDJSON v1 形式のエントリ。`issue_url` フィールドを持つ（partial_state 等は Unit 002 内部実装） |

## 2. 集約 / 値オブジェクト / エンティティ

### 2.1 PredecessorReference（集約）

predecessor handoff 解決結果を表す不変オブジェクト。

```text
PredecessorReference {
  resolution_path: ResolutionPath
  issue_url: Option<URL>      # Some when path ∈ {Milestone+label, label-fallback, spool}
  file_path: Option<Path>     # Some when path = v2.5.0-compat
  source_milestone: Option<MilestoneTitle>  # Some when path ∈ {Milestone+label}
  warn_messages: List<String>  # warn 表示すべきメッセージ
}
```

### 2.2 ResolutionPath（値オブジェクト）

```text
enum ResolutionPath {
  MILESTONE_AND_LABEL,   # 経路 1: gh + milestone_enabled=true
  LABEL_FALLBACK,        # 経路 1': gh + milestone_enabled=false
  SPOOL_FALLBACK,        # 経路 2: 経路 1/1' で 0 件 or gh 不可
  V2_5_0_COMPAT,         # 経路 3: 1/1'/2 すべて 0 件
  WARN_CONTINUE,         # 経路 4: 1/1'/2/3 すべて 0 件
}
```

### 2.3 IssueQueryResult（値オブジェクト）

```text
IssueQueryResult {
  issues: List<{ url: URL, title: String, closedAt: DateTime }>
}
```

### 2.4 SpoolEntry（外部ライブラリ参照）

Unit 002 の NDJSON v1 形式（読み取り専用）。Unit 004 から見えるのは `issue_url` のみ。

## 3. 純粋関数（Pure Function）

### 3.1 `_pure_classify_resolution_path(gh_status, milestone_enabled, query_count, spool_exists, compat_file_exists) -> ResolutionPath`

判定順（経路 1 → 1' → 2 → 3 → 4）に従って解決経路を分類する純粋関数。副作用なし、テスト容易性最大化。

**入力**:
- `gh_status`: `"available" | "unavailable" | "not-installed"`（Unit 002 `__retro_gh_status` 戻り値と完全一致）
- `milestone_enabled`: `true | false`
- `query_count`: Issue 検索ヒット数（経路 1/1' 実行時のみ意味あり / `gh` 不可時は -1 で渡す）
- `spool_exists`: spool ファイルの存在 + `_spool_extract_entries` 取得行数 ≥ 1
- `compat_file_exists`: v2.5.0 retrospective.md 存在

**出力**:
- 経路 1: `gh_status=available × milestone_enabled=true × query_count ≥ 1`
- 経路 1': `gh_status=available × milestone_enabled=false × query_count ≥ 1`
- 経路 2: 経路 1/1' で 0 件 OR `gh_status != available`、AND `spool_exists=true`
- 経路 3: 1/1'/2 すべて 0 件 AND `compat_file_exists=true`
- 経路 4: 上記すべて不成立

### 3.2 `_pure_format_query_args(prev_cycle, milestone_enabled) -> List<String>`

`gh issue list` の引数列を生成する純粋関数。

- `milestone_enabled=true`: `["--milestone", prev_cycle, "--label", "retrospective", "--state", "all", "--limit", "50"]`
- `milestone_enabled=false`: `["--label", "retrospective", "--state", "all", "--limit", "50"]`

### 3.3 `_pure_sort_by_closed_at_desc(issues) -> List<Issue>`

複数件ヒット時の `closedAt` 降順並び替えのみを担当する純粋関数（並び替え結果をそのまま返す / 自動採用や「最新を選ぶ」決定は行わない）。経路 1' で複数件ヒット時に「`closedAt` 降順でデフォルト候補を提示し AI エージェント側で必ず確認を通す」ためのソート実装に使う。

## 4. ドメインサービス

### 4.1 PredecessorIssueResolver（公開 / 純ロジック）

```text
predecessor_resolve_issue(prev_cycle: String) -> PredecessorReference
```

判定順に従って解決経路を実行し `PredecessorReference` を返す。`prev_cycle` のバリデーションは `__retro_validate_cycle`（Unit 002 既存）を借用。

**責務分離（重要）**: `predecessor_resolve_issue` は「候補集合 + 推奨候補（経路 1 / 1' で複数件時の `closedAt` 降順ソート結果）+ 解決経路の確定 / 1 件採用 / 0 件 → 次経路移行」までを純ロジックとして担当する。
**AskUserQuestion 起動は本関数の責務外**: 複数件ヒット時の対話確認 / ユーザー選択は `01-setup.md §4a` の AI エージェント側で実行する（Unit 003 で確立した「hook 関数本体 vs AI エージェント前段手順」の責務分離パターン踏襲）。
本関数は複数件時には NDJSON で候補リスト全体（`candidates: [...]` 配列）を出力し、AI エージェント側がそれを解釈して `AskUserQuestion` を起動する。1 件確定時のみ `issue_url` 単一値を出力する。

**副作用**: `gh issue list` 呼び出し / spool ファイル読み取り（Unit 002 `_spool_extract_entries` 経由）/ ファイル存在確認 / stderr `<level>\t<code>\t<detail>` ログ。**対話 I/O は一切行わない**。

### 4.2 GhStatusProvider（参照: Unit 002 既存）

`__retro_gh_status` を Unit 004 でも source して使う。

### 4.3 SpoolReader（参照: Unit 002 既存 + 薄いラッパー / 内部関数）

```text
__pred_read_spool_issue_url(spool_path: Path) -> Option<URL>
```

Unit 002 の `_spool_extract_entries` を呼び出し、NDJSON 各行から `jq -r .issue_url` で URL を抽出。複数件ある場合は最後の有効 URL を採用（spool 末尾優先 / Unit 002 の append 順 invariant に依存）。

## 5. 状態遷移

```text
[start]
  ↓
{prev_cycle 検証}
  ↓ 失敗 → exit 2 (引数エラー)
  ↓ 成功
{gh_status 取得}
  ↓
{milestone_enabled 取得}
  ↓
[判定順（_pure_classify_resolution_path）]
  ├─ 経路 1: Issue 検索（Milestone + label）→ 1 件 OR ≥ 2 件 (AskUserQuestion) → PredecessorReference 確定
  ├─ 経路 1': Issue 検索（label fallback）→ 同上
  ├─ 経路 2: spool fallback → URL 取得成功で確定
  ├─ 経路 3: v2.5.0 互換 → file_path 設定
  └─ 経路 4: warn/continue → 全フィールド空
  ↓
[出力 / コンテキスト変数設定]
  - 経路 1/1'/2: `predecessor_retrospective_issue_url` 設定
  - 経路 3: `predecessor_retrospective_file_path` 設定
  - 経路 4: 未設定 + warn 表示
```

## 6. 不変条件 (Invariant)

- I1: 経路の優先順位は厳密に 1 → 1' → 2 → 3 → 4。上位経路で確定すれば下位は実行しない
- I2: `predecessor_retrospective_issue_url` は経路 1/1'/2 採用時のみ設定。経路 3 / 4 では未設定
- I3: `predecessor_retrospective_file_path` は経路 3 採用時のみ設定。経路 1/1'/2/4 では未設定
- I4: spool 読み取りは Unit 002 の `_spool_extract_entries` を必ず経由。`partial_state.*` 等の内部構造を Unit 004 で直接解釈しない
- I5: `prev_cycle` のバリデーションは Unit 002 の `__retro_validate_cycle` を借用（独自実装しない）
- I6: 命名規約（`retrospective` ラベル / Milestone title format）は Intent §6.1 を canonical source として参照

## 7. 例外と境界

| 状態 | 分類 | 動作 | exit code |
|------|------|------|-----------|
| prev_cycle 不正 | 引数エラー | stderr `error\tpredecessor_invalid_cycle\t...` | 2 |
| gh CLI 一時エラー（ネットワーク不通 / レート制限 / auth 失効） | 継続可能エラー | stderr `warn\tpredecessor_gh_error\t...` + spool fallback へ移行 | 0（fallback 経路で完了） |
| gh CLI 致命的エラー（ライブラリ系の例外的失敗 / `gh` バイナリ起動不能で `__retro_gh_status` も呼べない等） | 継続不能エラー | stderr `error\tpredecessor_gh_fatal\t...` + 即終了 | 1 |
| spool ファイル形式不正（Unit 002 ヘッダ欠落等） | 継続可能エラー | Unit 002 `_spool_extract_entries` が exit 2 → Unit 004 では spool 取得失敗扱い + stderr `warn\tpredecessor_spool_invalid\t...` + v2.5.0 互換へ移行 | 0（fallback 経路で完了） |
| spool 読み取り I/O エラー（ファイル読取権限なし等） | 継続不能エラー | stderr `error\tpredecessor_io_error\t...` | 1 |
| 全経路で 0 件 | 警告完了 | 経路 4（warn + continue / `warn\tpredecessor_no_reference\t...`） | 0 |

## 8. テスト容易性

- 純粋関数 `_pure_classify_resolution_path` / `_pure_format_query_args` / `_pure_sort_by_closed_at_desc` は副作用なし → BATS で単体検証（並び替えのみ / 自動採用しない）
- ドメインサービス `predecessor_resolve_issue` は gh CLI / spool ファイル / 互換ファイルをモック化（bats stub + 環境変数）
- 命名規約は Intent §6.1 から定数として抽出（テストで参照可能）
