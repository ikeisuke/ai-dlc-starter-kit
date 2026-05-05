# 論理設計: Unit 002 retrospective Issue 一本化 + spool + mirror_state ラベル化

## 概要

Unit 002 のドメインモデル（`design-artifacts/domain-models/unit_002_retrospective_issue_only_domain_model.md`）に基づき、シェルスクリプト実装に展開する論理構造を定義する。具体的なコードは実装フェーズで生成する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

---

## アーキテクチャパターン

**3 層責務分離（domain pure / I/O wrap / orchestration）+ adapter 互換層**:

| 層 | 役割 | 対応ファイル |
|----|------|-------------|
| ドメイン純粋関数層 | 値変換・検証・正規化（副作用なし、決定論的） | `lib/retrospective-issue.sh` 内の `_compose_*` / `_normalize_*` / `_validate_*` 関数群 |
| I/O ラップ層 | gh CLI / ファイル書込み / SHA256 計算等の副作用境界 | `lib/retrospective-issue.sh` 内の `_gh_*` / `_spool_*` 関数群 |
| オーケストレーション層 | 公開関数 `retrospective_issue_create()` / `retrospective_body_compose()` および `retrospective-resend.sh` | `lib/retrospective-issue.sh` 公開関数 + `retrospective-resend.sh` |
| 互換アダプタ層 | 旧 `retrospective-generate.sh` / `retrospective-mirror.sh` の旧 stdout 契約を保持しつつ新フローに委譲 | `retrospective-generate.sh` / `retrospective-mirror.sh`（既存ファイル改修） |

Unit 001 と同じ 3 層構造（純粋 / I/O / orchestration）を踏襲し、新フロー（共有関数）と旧 I/F（CLI スクリプト）の境界を 1 ファイルに集約することで責務分離と再利用性を両立する。

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/
├── lib/
│   ├── feedback-mode.sh             (Unit 001 / 既存 / 本 Unit から source 利用)
│   ├── feedback-mode-wizard.sh      (Unit 001 / 既存 / 本 Unit から source 利用)
│   └── retrospective-issue.sh       【新規】共有関数 + 命名規約定数 + 純粋関数群
├── retrospective-resend.sh          【新規】CLI: スプール → 起票 → 削除
├── retrospective-generate.sh        【改修】互換アダプタ層化
├── retrospective-mirror.sh          【改修】互換アダプタ層化
├── retrospective-validate.sh        【改修】Issue 本文文字列対応化
├── read-config.sh                   (既存 / source 利用)
├── write-config.sh                  (既存 / source 利用)
└── env-info.sh                      (既存 / gh_status 取得)

skills/aidlc/templates/
└── retrospective_template.md        【改修】Issue 本文用テンプレに転換

skills/aidlc/steps/operations/
└── 04-completion.md                 【改修】§1.5 全面書き換え

tests/
├── retrospective-issue-create.bats  【新規】
├── retrospective-body-compose.bats  【新規】
├── retrospective-spool.bats         【新規】
├── retrospective-resend.bats        【新規】
└── operations-04-completion-section1-5.bats  【新規】統合テスト
```

### コンポーネント詳細

#### `lib/retrospective-issue.sh`

- **責務**: 共有関数 / 命名規約定数 / mirror_state 正規化 / 重複検出 / 本文構築 / Issue 起票 / スプール書込 のすべてを 1 ファイルに集約。3 層責務分離は内部関数 prefix で表現（`_pure_*` / `_io_*` / `_orch_*`）。
- **依存**: `lib/feedback-mode.sh`（Unit 001）、`gh` CLI（I/O 層内のみ）、`base64` / `sha256sum`（macOS は `shasum -a 256` fallback）、`jq`（NDJSON 構築・パース）
- **公開インターフェース**: 後述「インターフェース設計 / 公開関数」を参照
- **多重 source ガード**: `__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED=1` を立て、Unit 001 同様に冪等 source を保証

#### `retrospective-resend.sh`

- **責務**: スプールファイル読取 → 各エントリの `retrospective_issue_create()` 再呼び出し → 起票成功エントリの spool 削除
- **依存**: `lib/retrospective-issue.sh`、`env-info.sh`（gh_status 取得）
- **公開インターフェース**: CLI（後述スクリプトインターフェース設計）

#### `retrospective-generate.sh`（互換アダプタ層化）

- **責務**: 旧 stdout プレフィックス契約（`retrospective\tcreated\t<path>` 等）を維持しつつ、内部処理を `retrospective_issue_create()` に委譲
- **依存**: `lib/retrospective-issue.sh`
- **公開インターフェース**: 旧 CLI 引数（`<CYCLE>`）と stdout プレフィックスは Plan §「互換アダプタ層 保証範囲」表に従う

#### `retrospective-mirror.sh`（互換アダプタ層化）

- **責務**: 旧 `detect` / `send` / `record` サブコマンドの stdout プレフィックス契約を維持しつつ、内部処理を `retrospective_issue_create()` + `LegacyAdapterTranslator` に委譲
- **依存**: `lib/retrospective-issue.sh`
- **公開インターフェース**: 旧サブコマンド + 引数は Plan §「互換アダプタ層 保証範囲」表に従う

#### `retrospective-validate.sh`（Issue 本文対応化）

- **責務**: 既存の YAML 検証（q*_answer / q*_quote の整合性 / forbidden words / 長さ）を、ローカルファイルではなく **本文文字列**に対して実行する。`--apply` モード時は本文中の YAML ブロックの `q*_answer: yes → no` をダウングレードした **本文文字列を常に stdout 返却**（実ファイル書き換えは絶対に行わない）。呼出側が一時ファイルへリダイレクト + `mv` で適用する責務を持つ
- **依存**: なし（独立スクリプト）
- **公開インターフェース**: 既存サブコマンド `validate <body_or_path>` を維持。`--apply` フラグの動作を「ファイル書き換え」から「ダウングレード適用後の本文を **常に stdout 返却**（再パース不要）」に変更

---

## インターフェース設計

### 公開関数（`lib/retrospective-issue.sh` を source した呼出側が利用）

> **I/F 正本**: Plan §「I/F 正本の統一規則」を参照。本セクションは Plan の正本を具体化する詳細仕様であり、シグネチャ・引数・戻り値・exit code は Plan と完全一致する。

#### `retrospective_body_compose(draft_yaml_path, kpt_md_path, cycle)`（Orchestration / 公開）

- **引数**:
  - `draft_yaml_path: string`（必須 / Unit 003 から渡される LlmDraftYaml ファイルパス、空ファイル可）
  - `kpt_md_path: string`（必須 / KptSections ファイルパス）
  - `cycle: string`（必須 / `<CYCLE>`）
- **戻り値**:
  - 標準出力: 共有契約 6.2 構造に整合した本文 Markdown
  - 終了コード: 0=成功（部分欠損フォールバック含む） / 1=ランタイム異常（ファイル読取失敗等） / 2=YAML パース失敗 or 引数エラー
- **副作用**: ファイル読取のみ（書込みなし）。新規ファイルは生成しない（指摘 #3 純粋/IO 境界）
- **stderr**: `<level>\t<code>\t<detail>` フォーマット（Unit 001 と整合）
- **アルゴリズム概要**:
  1. `draft_yaml_path` 読取 → `_pure_compose_body(yaml_string, kpt_string, cycle)` を呼ぶ
  2. パース失敗（ファイル不正） → exit 2
  3. 純粋関数の戻り値をそのまま stdout に出力

#### `_pure_compose_body(draft_yaml_string, kpt_md_string, cycle)`（純粋関数 / 内部公開）

- **引数**: すべて文字列（path ではなく内容そのもの）
- **戻り値**: 共有契約 6.2 構造の Markdown 文字列
- **終了コード**: 0=成功（部分欠損フォールバック含む） / 2=YAML パース失敗
- **副作用**: なし（純粋関数。**ファイルアクセスなし** / 標準入出力なし）
- **アルゴリズム概要**:
  1. `draft_yaml_string` 空 → 空 problem_drafts として扱い、共有契約 6.2 §「問題なし」セクションを構築
  2. `draft_yaml_string` 非空 → 段階的 awk パース（実装フェーズで yq fallback を判断）
  3. パース失敗 → exit 2
  4. パース成功 → 各 problem_draft を共有契約 6.2 §「問題項目（Problem）」テンプレに展開
  5. 必須フィールド欠損 → 警告 + 空文字列フォールバック（文字列構築のみ）
  6. KPT セクションを `kpt_md_string` から末尾連結
  7. 末尾に `mirror_state` + `human_reviewed: false` の YAML ブロックを付与
- **BATS 直接呼出**: 純粋性検証のため、関数を export して BATS テストから直接呼び出す

#### `retrospective_issue_create(body_path, feedback_mode, cycle)`

- **引数**:
  - `body_path: string`（必須 / `retrospective_body_compose()` 出力をファイルに書いたパス）
  - `feedback_mode: string`（必須 / Unit 001 で正規化済の 5 値文字列）
  - `cycle: string`（必須 / `<CYCLE>` / `^[A-Za-z0-9._-]+$` 以外は exit 2 / path traversal 防御）
- **拡張環境変数**（オプショナル / 主に `retrospective-resend.sh` および §1.5 から使用）:
  - `AIDLC_RETRO_FORCE_TARGET`: `local` / `mirror` / `both` / `none` で target 解決を上書き（resend で `retry_target` を尊重するため）
  - `AIDLC_RETRO_CURRENT_COUNT` + `AIDLC_RETRO_LIMIT`: 両方が非空整数で指定された時のみ cap 判定を実施。これらが未指定の場合、本関数は cap 判定をスキップする（cap 判定は呼出元責務）
  - `AIDLC_RETRO_SKIP_LOCAL`: `1` の時、target に `local` / `both` が含まれていても local 起票をスキップ（resend の `partial_state.local_created` 非 null 時用）
- **戻り値**:
  - 標準出力: `<key>=<value>` 形式の複数行（Plan §「retrospective_issue_create() 出力契約」準拠）
  - 終了コード:
    - 0: `result ∈ {created, skipped, spooled}`
    - 1: `result=failed`（gh 起票失敗 / spool 書込失敗 / relabel 失敗）
    - 2: 引数エラー（`feedback_mode` 未知 / `cycle` 不正 / `force_target` 不正等）
- **副作用**: GitHub Issue 作成 / ラベル付与 / Milestone 紐付け / spool ファイル追記
- **アルゴリズム概要**:
  1. `cycle` バリデーション → 不正なら exit 2
  2. `AIDLC_RETRO_FORCE_TARGET` が指定されていればそれを target、なければ `feedback_mode_resolve` で `RetrospectiveTarget` に翻訳
  3. `target=none` → `result=skipped reason=mode-disabled` で即時 return（exit 0）
  4. cap 判定（`AIDLC_RETRO_CURRENT_COUNT` / `AIDLC_RETRO_LIMIT` が両方指定されている場合のみ実施）→ 超過時 `result=skipped reason=cap-exceeded mirror_state=skipped:max_exceeded` で return
  5. `gh_status` 取得 → `available` 以外なら spool 経路へ分岐: `_spool_append()` でエントリ追記 → `result=spooled` で return（exit 0）
  6. 重複検出（`_gh_find_duplicate()` で `gh issue list --label retrospective --milestone <CYCLE>`）→ 重複時 `result=skipped reason=duplicate existing_issue_url=<URL>` で return
  7. ラベル `retrospective,mirror-state:pending` を付けて起票試行（`_gh_create_issue()`）
     - `AIDLC_RETRO_SKIP_LOCAL=1` 時は local 起票をスキップ
     - `target=both` の場合は local → mirror の順で 2 回起票
     - 部分起票失敗（local 成功 / mirror 失敗）時は `result=failed reason=mirror-failed-after-local-created local_issue_url=<URL>` + spool 退避（`retry_target=mirror`, `partial_state.local_created=<URL>`）で return（exit 1）
  8. 起票成功 → `gh issue edit --add-label mirror-state:created --remove-label mirror-state:pending` で状態確定（最大 3 回リトライ / 指数バックオフ）
     - relabel 最終失敗時は `result=failed reason=relabel-failed-<local|mirror> mirror_state=pending` + spool 退避（`partial_state.<side>_created=<URL>`）で return（exit 1 / 次回 resend で再試行可能）
     - 全成功時は `result=created mirror_state=created` で return（exit 0）

#### 命名規約定数

```text
readonly RETROSPECTIVE_LABEL="retrospective"
readonly MIRROR_STATE_LABEL_PREFIX="mirror-state:"
readonly RETROSPECTIVE_ISSUE_TITLE_TEMPLATE="Retrospective: %s"
readonly RETROSPECTIVE_SPOOL_HEADER="<!-- retrospective-spool v1 -->"
readonly RETROSPECTIVE_SPOOL_VERSION="1"
```

`source` した呼出側（特に Unit 004 / 互換アダプタ）から参照する。

#### `_normalize_mirror_state(...)`（内部公開、互換アダプタから呼び出し可）

- **責務**: 旧 `LegacyMirrorStateSignal` ⇄ canonical `MirrorStateValue` ⇄ ラベル文字列の双方向変換を 1 関数に集約
- **シグネチャ群**:
  - `_normalize_legacy_to_canonical(prefix, state_arg, error_reason) → canonical`
  - `_normalize_canonical_to_label(canonical) → label_or_empty`
  - `_normalize_label_to_canonical(label) → canonical`
  - `_normalize_reconcile(label_canonical, yaml_canonical) → canonical`（不整合時はラベル優先 + stderr 警告）
- **写像表**: ドメインモデル §`MirrorStateNormalizer` / Plan §「旧語彙正規化規則」を参照

### スクリプトインターフェース設計

#### `retrospective-resend.sh`

##### 概要

スプールファイルから起票待ちエントリを読み取り、各エントリを Issue として再起票する。起票成功したエントリは spool から削除する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <CYCLE>` | 任意 | 対象サイクル。未指定時は最新 cycle を `.aidlc/cycles/` から自動決定 |
| `--dry-run` | 任意 | 起票・spool 書込みを行わず、対象エントリと予想結果を表示のみ |
| `--strict` | 任意 | SHA256 不一致時に skip ではなく停止する（既定: skip + 警告） |

##### 成功時出力

```text
resend	cycle	<CYCLE>
resend	loaded	<entry_count>
resend	processed	<idx>	result=created	issue_url=<URL>
resend	processed	<idx>	result=failed	reason=<gh-error-code>
resend	processed	<idx>	result=skipped	reason=duplicate	existing_issue_url=<URL>
resend	summary	created=<n>	failed=<n>	skipped=<n>	remaining=<n>
```

- 終了コード:
  - `0`: 全エントリが `created` または `skipped` で完結（**failed が 0 件のみ**）
  - `1`: `failed` が 1 件以上含まれる（部分失敗 / 上位はエラー扱いで再送リトライ案内） / 中断 / 致命的失敗
  - `2`: 引数エラー / spool 不正 / cycle 不在
- 出力先: stdout

##### エラー時出力

```text
error	spool-not-found	cycle=<CYCLE>
error	spool-header-missing	path=<spool_path>
error	gh-not-available
```

- 終了コード: `1`（ランタイム異常） / `2`（引数 / spool 構造不正）
- 出力先: stderr

##### 使用コマンド例

```bash
# 最新 cycle を自動決定して再送
bash skills/aidlc/scripts/retrospective-resend.sh

# 特定 cycle を指定
bash skills/aidlc/scripts/retrospective-resend.sh --cycle v2.5.1

# dry-run
bash skills/aidlc/scripts/retrospective-resend.sh --cycle v2.5.1 --dry-run
```

#### `retrospective-generate.sh`（互換アダプタ）

##### 引数

旧 I/F: `<CYCLE>`（位置引数 1）

##### 成功時出力（旧プレフィックス互換）

```text
retrospective	created	<issue_url_or_legacy_path>
retrospective	skip	<reason>
```

- 旧 `<path>` には起票成功時の Issue URL を流す（旧呼出元の awk パターン `retrospective\tcreated\t.+` には影響しない）
- `skip` の reason は `disabled` / `already-exists`（重複検出時は新フローの canonical `skipped:duplicate` を `already-exists` に翻訳）

#### `retrospective-mirror.sh`（互換アダプタ）

##### サブコマンドと引数

旧 I/F: `detect <body_path>` / `send <body_path> <idx> <title> <draft_path>` / `record <body_path> <idx> <state>`

##### 成功時出力（旧プレフィックス互換）

```text
mirror	skip	not-mirror-mode
mirror	skip	no-skill-caused
mirror	skip	all-processed
mirror	candidate	<idx>	<title>	<draft_path>
mirror	sent	<idx>	<url>
mirror	send-failed	<idx>	<reason>
mirror	recorded	<idx>	<state>
```

新フローの `RetrospectiveCreationOutcome` を `LegacyAdapterTranslator` で旧語彙に変換する。

##### 旧→新 意味マッピング（指摘 #4 反映 / Plan §「互換アダプタ層 旧→新 意味マッピング」整合）

| 旧プレフィックス語彙 | canonical 値 | 一致度 | 取扱 |
|----------------------|--------------|--------|------|
| `mirror\tsent` | `created` | 完全一致 | 保証 |
| `mirror\tsend-failed` | `error` | 完全一致 | 保証 |
| `mirror\trecorded\tskipped` | `skipped:max_exceeded` または `skipped:duplicate` | 部分一致 | 非保証（warn + 保守的選択 `skipped:max_exceeded`） |
| `mirror\trecorded\tpending` | `created` 互換扱い | 一致しない | 非保証（warn + 意味差を stderr 明示） |

**設計判断**: 旧 `recorded:pending` は新 canonical `pending`（spool 待機）とは意味が異なる。旧呼出元が `pending` 受領時に何を期待しているかは「ユーザーが後で判断」であり、新フローでは「Issue 起票 + ラベル `mirror-state:created` 付与」で完結するため、互換アダプタ層では `created` 互換扱いとして warn を出す。canonical 中間語彙 `legacy-deferred` は導入しない（v2.7.x で旧フロー削除予定のため）。

### Unit 003 フック契約（指摘 #5 反映 / Plan §「Unit 003 フック契約」整合）

`04-completion.md §1.5` で source 経由で呼び出すフック関数:

| フック関数名 | 必須/任意 | 引数 | 戻り値 | exit code | 未定義時の挙動 |
|--------------|----------|------|--------|-----------|----------------|
| `retrospective_prefill_hook(cycle, kpt_md_path)` | 任意 | 文字列 2 つ | stdout に Intent §6.3 スキーマの YAML | 0=成功 / 非0=失敗 | no-op（stdout 空 + exit 0） |
| `retrospective_update_hook(issue_url, cycle)` | 任意 | 文字列 2 つ | （任意） | 0=成功 / 非0=失敗 | no-op（exit 0） |

**未定義時の検出**: `command -v retrospective_prefill_hook` で関数の存在を確認し、不在時は内部 fallback 関数（no-op）を呼ぶ。

**失敗時のフォールバック**:

- prefill 失敗（exit 非 0）: 空 YAML として扱い、`_pure_compose_body` の空 YAML フォールバックパスで本文構築を継続
- update 失敗（exit 非 0）: 警告ログ「Unit 003 update フック失敗: <issue_url>」+ §1.5 を継続終了（Unit 002 は exit 0 を維持）

**依存逆転回避**:

- Unit 002 は Unit 003 の実装ファイルを直接参照しない（`source` も `lib/retrospective-issue.sh` のみ / Unit 003 の `lib/retrospective-llm.sh` は §1.5 の呼出元責任で source される想定）
- BATS テストではモック関数を `setup` で定義し、Unit 003 実装ファイルに依存しない

---

## データモデル概要

### スプールファイル形式（NDJSON in fenced block）

#### ファイル: `cycles/<CYCLE>/history/retrospective-spool.md`

- **形式**: Markdown 内に閉じ込めた NDJSON fenced block
- **ヘッダ（必須・1 行目）**: `<!-- retrospective-spool v1 -->`
- **機械可読部分**: 単一の ` ```ndjson ... ``` ` fenced block
- **各行 1 エントリの JSON フィールド**（Plan §「スプールファイル形式」の最新スキーマ準拠 / 指摘 #2 / #6 反映）:

  | フィールド | 型 | 説明 |
  |------------|-----|------|
  | `id` | string（UUID v4） | エントリ一意識別子。再送時の ID ベース削除に使用 |
  | `version` | string | スプールスキーマバージョン（現在 `"1"`） |
  | `cycle` | string | サイクル識別子 |
  | `feedback_mode` | string | 試行時の `feedback_mode`（5 値正規化後） |
  | `attempted_at` | string | ISO8601 タイムスタンプ |
  | `target` | string | `local` / `mirror` / `both` |
  | `retry_target` | string | 再送時の対象（partial 起票時は `mirror` のみ） |
  | `partial_state` | object | `{"local_created":"<URL or null>","mirror_created":"<URL or null>"}` |
  | `attempt_reason` | string | 失敗コード |
  | `body_b64` | string | 本文 Markdown の base64 |
  | `body_sha256` | string | デコード後 body の SHA256 hex |

**注**: 実際の JSON 構築は `jq` で行う。改行・タブ・特殊文字は base64 で保護されるため fenced block 内のテキスト解釈に依存しない。

**排他制御（指摘 #6）**:

- spool 書込み（追記 / 削除 / 圧縮）は `flock(1)` 相当のロックで保護
- 一時ファイル + `mv` の原子的置換と組み合わせ、部分書込み時の整合を保つ
- ロック取得不能（5 秒タイムアウト）時は exit 1
- ID ベース削除は行番号や位置に依存しないため、複数エントリの同時操作で誤削除リスクを低減

**partial 起票時の再送ルール（指摘 #2）**:

- partial 起票（`target=both` で local 成功 / mirror 失敗）時、spool エントリの `retry_target=mirror` + `partial_state.local_created=<URL>` を記録
- 再送 (`retrospective-resend.sh`) は `retry_target` を見て対象 target のみ再起票
- `partial_state.local_created` が非 null の場合、再送結果の `local_issue_url` には partial_state の URL を採用（再起票しない）

### Issue 本文構造（共有契約 6.2 整合）

```text
# Retrospective: <CYCLE>

## Keep / Try / Problem
（KptSections 展開）

## 問題項目（Problem）

### 問題 N: <タイトル>

**何が起きたか**: ...
**なぜ起きたか**: ...
**損失と影響**: ...

**主因切り分け**:
| 主因分類 | 該当 | 反映先 |
|----------|------|-------|
| プロダクト固有 | yes/no | ... |
| AI-DLC Starter Kit 固有 | yes/no | ... |
| 両方に責任 | yes/no | ... |

**skill 起因判定**:
```yaml
skill_caused_judgment:
  q1_answer: "yes" | "no"
  q1_quote: "..."
  ...
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
human_reviewed: false
```
```

---

## 処理フロー概要

### ユースケース 1: §1.5 で retrospective Issue を起票（gh available / `local-and-mirror` / 重複なし）

**ステップ**:

1. `04-completion.md §1.5 Step 2`: `feedback_mode_normalize` + `feedback_mode_resolve` で `target=both` に解決。wizard 起動条件外。
2. `Step 3`: `feedback_cap_check(local-and-mirror, current_count, limit)` → `over=false`。Unit 003 prefill フック呼び出し → draft YAML 取得（成功 / 失敗どちらも続行）
3. `Step 4`: `retrospective_body_compose(draft_yaml, kpt_md, cycle)` → 本文 Markdown を一時ファイルに書込み。`retrospective-validate.sh validate <body_path> --apply` で違反項目をダウングレードしたい場合は本文を上書き
4. `Step 5`: `retrospective_issue_create(body_path, feedback_mode, cycle)` → exit 0 + `result=created target=both local_issue_url=... mirror_issue_url=... mirror_state=created`
5. `Step 6`: Unit 003 update フック呼び出し（`local_issue_url` を引き渡し / 本 Unit 範囲外の動作）

**関与するコンポーネント**: `feedback-mode.sh`（Unit 001）/ `retrospective-issue.sh`（本 Unit）/ `gh` CLI

### ユースケース 2: §1.5 で retrospective Issue を起票（gh 不可 → spool）

**ステップ**:

1. Step 2-4 同上
2. Step 5: `retrospective_issue_create()` 内で `_gh_status_check` が `unavailable` を返す → spool 経路へ分岐
3. `_spool_append()` でヘッダ + fenced block + entry 追記 → `result=spooled spool_path=... mirror_state=pending` で return（exit 0）
4. 上位サマリ: `gh が利用不可のため retrospective をスプールしました。次回 gh 利用可能時に scripts/retrospective-resend.sh を実行してください。` と案内（指摘 #4 対応の必須分岐）

**関与するコンポーネント**: `retrospective-issue.sh`（本 Unit）/ `env-info.sh`

### ユースケース 3: スプール再送（`retrospective-resend.sh` 起動）

**ステップ**:

1. `--cycle` 引数 or 最新 cycle 自動決定
2. `_spool_load()` でヘッダ確認 + fenced block 抽出
3. 各エントリで:
   - `body_b64` を base64 デコード → SHA256 検証
   - 一時ファイルに書込み → `retrospective_issue_create()` を呼ぶ
   - 成功時 → spool から当該行を削除、失敗時 → 残置
4. サマリ表示

**関与するコンポーネント**: `retrospective-resend.sh` / `retrospective-issue.sh` / `gh` CLI

### ユースケース 4: 互換アダプタ呼び出し（旧呼出元から `retrospective-generate.sh v2.5.1`）

**ステップ**:

1. `retrospective-generate.sh` が引数を受け取る
2. 内部で `retrospective_body_compose()` + `retrospective_issue_create()` を **mock 引数で呼ぶ**（draft_yaml=空、KPT=`templates/retrospective_template.md`）
3. 結果を `LegacyAdapterTranslator.to_generate_legacy()` で旧プレフィックス出力 `retrospective\tcreated\t<issue_url>` に変換
4. 旧呼出元の awk パターンが従来通り動作

**関与するコンポーネント**: `retrospective-generate.sh`（薄いラッパー）/ `retrospective-issue.sh`

---

## 非機能要件（NFR）への対応

### 冪等性

- **要件**: 同一サイクル + 同一タイトルの retrospective Issue が二重起票されない
- **対応策**: `_gh_find_duplicate()` を起票前に必ず実行。重複検出時は `result=skipped reason=duplicate` で `existing_issue_url` を返す。BATS テストで「同サイクルでの 2 回目呼び出し」を verify

### 可用性

- **要件**: `gh_status != available` でも振り返り内容が消失しない
- **対応策**: spool 書込 + `body_sha256` integrity チェック + `retrospective-resend.sh` 再送。`feedback_mode=disabled` のみ spool 不要（明示的なスキップ意思）

### 後方互換

- **要件**: 旧 `retrospective.md` ファイルが残存しても新フローが正常動作 / 旧 `retrospective-generate.sh` / `retrospective-mirror.sh` 呼出元が壊れない
- **対応策**:
  - `RetrospectiveLegacyFileRepository` で読み取りのみ提供
  - 互換アダプタ層が旧 stdout プレフィックス契約を保持（Plan §「互換アダプタ層 保証範囲」表）
  - `mirror-state:sent` ラベルの読取は canonical `created` と等価扱い

---

## 技術選定

- **言語**: Bash 4+（既存 Unit 001 と同様）。macOS デフォルト Bash 3.2 でも動作するよう `[[ ... ]]` / `printf '%s\n'` 等の互換構文を使用
- **依存ツール**:
  - `gh` CLI（Issue 起票・編集・検索）
  - `jq`（NDJSON 構築・パース / spool エントリ操作）
  - `base64`（macOS / Linux 両対応 / `base64 -w 0` は GNU 限定のため `tr -d '\n'` で改行除去する設計）
  - `sha256sum`（Linux）/ `shasum -a 256`（macOS）— `command -v` で fallback 解決
- **テストフレームワーク**: BATS（既存と整合）
- **YAML パーサ**: 設計フェーズで `python -c "import yaml; ..."` / `yq` / awk のいずれかを確定（Unit 001 では awk ベースのため、整合性のため awk 案を第一候補）

---

## 04-completion.md §1.5 改修案（最終形）

現行 §1.5 の Step 2-5 を以下に置き換える。ステップ数は 5 → 6（Unit 003 起票後 update フック追加）。

> **本ブロックは「処理フローの擬似的記述」であり、実装コードではない**。プロジェクト規約「コマンド置換 `$(...)` 禁止」に従い、実装時はリダイレクト + `read` 等で書き直す。本擬似フローでも `$(...)` を使わない記述に統一した（指摘 #7 反映）。

```text
##### Step 1: feedback_mode 解決 + wizard 判定

source skills/aidlc/scripts/lib/feedback-mode.sh

scripts/read-config.sh rules.retrospective.feedback_mode > /tmp/raw.txt
read raw < /tmp/raw.txt

feedback_mode_normalize "$raw" > /tmp/mode.txt
read mode < /tmp/mode.txt

is_interactive_env > /tmp/env.txt
read env_interactive < /tmp/env.txt

feedback_mode_requires_wizard "$mode" "$env_interactive" > /tmp/wizard.txt
read needs_wizard < /tmp/wizard.txt

if [[ "$needs_wizard" == "true" ]]; then
    source skills/aidlc/scripts/lib/feedback-mode-wizard.sh
    feedback_mode_wizard > /tmp/wizard_result.txt
    read mode < /tmp/wizard_result.txt
fi

##### Step 2: cap 判定 + Unit 003 prefill フック

# current_count は §1.5 の前ステップで計算済み変数（既存ロジック維持）
scripts/read-config.sh rules.retrospective.feedback_max_per_cycle > /tmp/limit.txt
read limit < /tmp/limit.txt

feedback_cap_check "$mode" "$current_count" "$limit" > /tmp/cap.txt
# over=true なら §1.5 終了（cap.txt の over=... 行を grep して判定）

# Unit 003 prefill フック呼び出し（未定義時は内部 no-op）
draft_yaml_path=/tmp/retro-draft.yml
if command -v retrospective_prefill_hook >/dev/null 2>&1; then
    retrospective_prefill_hook "$cycle" "$kpt_md_path" > "$draft_yaml_path" || : > "$draft_yaml_path"
else
    : > "$draft_yaml_path"  # 空ファイル fallback
fi

##### Step 3: 本文構築 + validate

source skills/aidlc/scripts/lib/retrospective-issue.sh

kpt_md_path=/tmp/retro-kpt.md
# KPT セクションのテンプレ展開を書込（テンプレ展開ロジックは既存）
sed "s/{{CYCLE}}/$cycle/g" skills/aidlc/templates/retrospective_template.md > "$kpt_md_path"

body_path=/tmp/retro-body.md
retrospective_body_compose "$draft_yaml_path" "$kpt_md_path" "$cycle" > "$body_path"

bash skills/aidlc/scripts/retrospective-validate.sh validate "$body_path" --apply > "${body_path}.applied"
mv "${body_path}.applied" "$body_path"

##### Step 4: Issue 起票

set +e
retrospective_issue_create "$body_path" "$mode" "$cycle" > /tmp/retro-result.txt
rc=$?
set -e

case "$rc" in
    0)
        if grep -q '^result=created' /tmp/retro-result.txt; then
            grep -E '^(local|mirror)_issue_url=' /tmp/retro-result.txt > /tmp/retro-url.txt
            head -n 1 /tmp/retro-url.txt > /tmp/retro-url-first.txt
            cut -d= -f2 /tmp/retro-url-first.txt > /tmp/retro-issue-url.txt
            read issue_url < /tmp/retro-issue-url.txt
            echo "起票成功: $issue_url"
        elif grep -q '^result=spooled' /tmp/retro-result.txt; then
            echo "gh が利用不可のためスプールしました。次回 gh 利用可能時に bash skills/aidlc/scripts/retrospective-resend.sh を実行してください。"
        else
            grep '^reason=' /tmp/retro-result.txt > /tmp/retro-reason.txt
            read reason_line < /tmp/retro-reason.txt
            echo "起票スキップ: $reason_line"
        fi
        ;;
    1)
        grep '^reason=' /tmp/retro-result.txt > /tmp/retro-reason.txt
        read reason_line < /tmp/retro-reason.txt
        echo "[警告] 起票失敗（再送可能）: $reason_line"
        ;;
    2)
        echo "[エラー] 引数エラー" >&2
        exit 2
        ;;
esac

##### Step 5: Unit 003 update フック（起票成功時のみ）

if [[ -n "${issue_url:-}" ]]; then
    if command -v retrospective_update_hook >/dev/null 2>&1; then
        retrospective_update_hook "$issue_url" "$cycle" || \
            printf 'warn\tunit003_update_hook_failed\t%s\n' "$issue_url" >&2
    fi
fi
```

> 上記は処理フローの擬似的記述。実装フェーズで `04-completion.md` 内のステップ記述として展開する。プロジェクト規約 `$(...)` 禁止に準拠した書式（リダイレクト + `read`）で記述している。

---

## BATS テストケース一覧

### `tests/retrospective-body-compose.bats`

- `compose: 共有契約 6.2 構造の章立てが順序通り出力される`
- `compose: Intent §6.3 スキーマ準拠の draft_yaml を受理し本文に prefilled する`
- `compose: human_reviewed: false が初期値で埋め込まれる`
- `compose: 空 YAML 入力時は全フィールド空 + primary_cause=product 仮置きフォールバック`
- `compose: 必須フィールド欠損時は警告 + 空文字列フォールバックで exit 0`
- `compose: YAML パース失敗時は exit 2`
- `compose: 値域違反（primary_cause=invalid）時は警告 + 既定値 product 仮置き exit 0`

### `tests/retrospective-issue-create.bats`

- `create: feedback_mode=local-issue-only で local リポに 1 件起票 + retrospective + mirror-state:created ラベル付与`
- `create: feedback_mode=mirror-only で mirror リポに 1 件起票`
- `create: feedback_mode=local-and-mirror で local→mirror の順で 2 件起票`
- `create: feedback_mode=disabled で起票せず result=skipped reason=mode-disabled exit 0`
- `create: 重複検出（既存 Issue あり）で result=skipped reason=duplicate existing_issue_url=<URL> exit 0`
- `create: cap 超過で result=skipped reason=cap-exceeded exit 0`
- `create: gh_status=unavailable で result=spooled spool_path=<path> mirror_state=pending exit 0`
- `create: gh 起票失敗で result=failed reason=gh-rate-limit mirror_state=error exit 1`
- `create: target=both で local 成功 / mirror 失敗時 result=failed reason=mirror-failed-after-local-created local_issue_url=... exit 1`
- `create: target=both で local リポと mirror リポが同一の場合 local のみ起票（OWNER/REPO 一致縮退）`
- `create: 引数 feedback_mode 未知で exit 2`

### `tests/retrospective-spool.bats`

- `spool: ファイル不存在時はヘッダ + 空 fenced block を生成して追記`
- `spool: ヘッダ存在時は fenced block 末尾に新エントリ 1 行追記`
- `spool: NDJSON フィールド全件（id / version / cycle / feedback_mode / attempted_at / target / retry_target / partial_state / attempt_reason / body_b64 / body_sha256）が揃う`
- `spool: id が UUID 形式 + エントリ間で一意`
- `spool: body_b64 のデコードと SHA256 検証が一致`
- `spool: 複数エントリ追記の順序が保たれる`
- `spool: ヘッダ不在時のロード失敗で exit 2`
- `spool: SHA256 不一致エントリは skip + 警告（既定）`
- `spool: SHA256 不一致エントリは --strict で停止 exit 1`
- `spool: id ベース削除で対象エントリのみが消える（行番号変動の影響なし）`
- `spool: partial 起票時に retry_target=mirror + partial_state.local_created=<URL> が記録される`
- `spool: 排他ロック取得不能時 5 秒タイムアウトで exit 1 + 警告`

### `tests/retrospective-resend.bats`

- `resend: 1 エントリ正常再送（spool から id ベース削除）`
- `resend: 複数エントリ全件再送（全件成功 → spool 空）`
- `resend: 部分失敗時（1/3 成功）→ 成功エントリの id のみ削除、失敗エントリは残置`
- `resend: --dry-run で spool 変更なし + 予想結果のみ出力`
- `resend: --cycle 未指定で最新 cycle 自動決定`
- `resend: spool 不在 / cycle 不在で exit 2`
- `resend: gh_status=unavailable で exit 1（再送中の gh 不可は警告 + 中断）`
- `resend: retry_target=mirror エントリは mirror のみ起票し partial_state.local_created の URL を採用（local 二重起票しない）`
- `resend: retry_target=both エントリは local + mirror 両方起票`

### `tests/operations-04-completion-section1-5.bats`（統合テスト）

- `§1.5: feedback_mode=disabled で全ステップスキップ`
- `§1.5: feedback_mode=interactive + 対話環境で wizard 起動 → 確定値で再評価`
- `§1.5: feedback_mode=local-and-mirror で local + mirror に起票（モック gh）`
- `§1.5: gh_status=unavailable で spool 経路 + 案内メッセージ表示`
- `§1.5: Unit 003 prefill フック未定義時に no-op + 空 YAML フォールバックで起票継続`
- `§1.5: Unit 003 prefill フック失敗（exit 非 0）時に空 YAML フォールバックで起票継続`
- `§1.5: 起票成功後、Unit 003 update フック未定義時は no-op（§1.5 は exit 0 で終了）`
- `§1.5: 起票成功後、Unit 003 update フック呼び出し（モック関数で issue_url 引き渡しを assert）`
- `§1.5: Unit 003 update フック失敗（exit 非 0）時に警告 + §1.5 は exit 0 を維持`
- `§1.5: 起票失敗（exit 1）時に警告サマリを表示し、後続の §1.6 に進む`

---

## 実装上の注意事項

- **base64 改行処理**: macOS の `base64` は既定で 76 文字ごとに改行を入れる。NDJSON 内に改行を含めないため `tr -d '\n'` で除去するか、`base64 | tr -d '\n'` のパイプで対応
- **SHA256 コマンド**: `command -v sha256sum >/dev/null 2>&1 && sha256sum || shasum -a 256` で fallback。Unit 001 と同様の互換性確保
- **jq 利用**: NDJSON 構築は `jq -nc --arg version "1" --arg cycle "$cycle" ...` で安全。手書きの JSON 文字列連結は禁止（クォート崩壊リスク）
- **コマンド置換禁止（指摘 #7 反映 / 実装規約）**: プロジェクト CLAUDE.md により `$(...)` および `$(< ...)` は禁止。代替パターンを以下に固定:

  | 用途 | 禁止 | 採用 |
  |------|------|------|
  | コマンド出力を変数へ | `var=$(cmd)` | `cmd > /tmp/x; read var < /tmp/x` |
  | ファイル内容を変数へ | `var=$(< /tmp/x)` | `read var < /tmp/x`（単一行）/ `mapfile var < /tmp/x`（複数行） |
  | 一時ファイル生成 | `path=$(mktemp ...)` | 固定パス（`/tmp/aidlc-retro-<purpose>-$$`）または `mktemp ... > /tmp/path.txt; read path < /tmp/path.txt` |

- **mktemp 代替パターン（実装フェーズで詳細確定）**: 並行実行を考慮した PID + nanoseconds 付与パスを実装時に決定する。BATS テストは `BATS_TEST_TMPDIR` を利用
- **set -euo pipefail**: 既存スクリプトと整合。spool 書込・gh 起票は明示的に `set +e` で失敗ハンドリング
- **shellcheck**: `# shellcheck disable=...` の例外指定を最小限に保つ
- **テスト hermetic性**: BATS テストは `gh` 実バイナリではなく PATH 先頭に置いた stub を使い、ネットワーク非依存で動作する

---

## 不明点と質問（設計中に記録）

[Question] YAML パーサ実装の選定（awk / yq / python -c "import yaml")
[Answer] Unit 001 が awk ベースで feedback-mode.sh を実装しているため、Unit 002 でも awk による段階的パースを第一候補とする。複雑なネスト（problem_drafts[]）が awk で扱いにくい場合は yq へ切り替える判断を実装フェーズで行う（依存追加は最小限に）。

[Question] retrospective-validate.sh の `--apply` モードの新仕様で、本文文字列に対するダウングレードを行った後、`retrospective_issue_create()` に渡す前に再パースする必要があるか
[Answer] 不要。`--apply` は **常に stdout 返却**（実ファイル書き換えは行わない / 呼出側がリダイレクトで適用）するだけで、構造は変わらない。`retrospective_body_compose` の出力 → validate `--apply` → `retrospective_issue_create` の直列パイプラインで完結。

[Question] `target=both` で local リポ / mirror リポを区別する仕組み（OWNER/REPO の解決元）
[Answer] local リポは `git remote get-url origin` から OWNER/REPO を抽出。mirror リポは固定値 `ikeisuke/ai-dlc-starter-kit`（upstream）を `lib/retrospective-issue.sh` 内の定数 `MIRROR_REPO="ikeisuke/ai-dlc-starter-kit"` で保持。設計判断: 動的設定（config.toml 経由）は本サイクルでは導入しない（Intent §「OUT_OF_SCOPE」で簡素化を選択）。

[Question] スプールエントリのインプレース上書き（特定行削除）の安全性。`sed -i` は macOS / Linux で挙動差があり、エラー時に元ファイルが消失するリスク
[Answer] `mktemp` で一時ファイルに新内容を書き、`mv` で原子的に置き換える方式を採用（`sed -i` は使わない）。Unit 001 の `write-config.sh` と同等の安全パターンを踏襲。

[Question] Unit 003 prefill / update フックは関数なのか別スクリプトなのか
[Answer] 関数（`retrospective_prefill_hook` / `retrospective_update_hook`）。Unit 003 が `lib/retrospective-llm.sh` 等で提供する想定。Unit 002 は §1.5 ステップ記述に **関数名のみ**を埋め込み、実装は Unit 003 が `source` 経由で差し替える。Unit 002 BATS テストではモック関数で代替する。
