# Unit 004 論理設計: helper の zsh source 互換性保証

## 概要

`predecessor-issue.sh` の `__PRED_SCRIPT_DIR` 解決を **shell 判定分岐方式（案 B）** で zsh / bash 両対応にし、helper 6 ファイル全体の bash / zsh 両 source 動作を bats テスト（新規 `tests/aidlc-helpers-zsh-source.bats`）で保証する論理設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコードは Phase 2（実装）で作成する。

## 採用案の確定

### 案 A（1 行併記方式）— **不採用**

```bash
__PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%N}}")" >/dev/null 2>&1 && pwd)
```

**不採用理由**: bash 3.2 / 5.3 の両方で `${(%):-%N}` がパースエラーになる（`bad substitution` / `誤った代入です`）。bash パーサが `${ParameterName}` 構文の `(%)` をパラメータ名として解釈できないため、bash 経路が常に壊れる。

**実機検証結果**:

| Shell | バージョン | 結果 |
|-------|----------|------|
| bash | 3.2.57 (macOS デフォルト) | `${(%):-%N}: bad substitution` |
| bash | 5.3.9 (Homebrew) | `${(%):-%N}: 誤った代入です` |
| zsh | 5.9 (macOS デフォルト) | OK（`zsh` を返す） |

### 案 B（shell 判定分岐方式）— **採用**

```bash
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # zsh 経由: ${(%):-%N} で source されたファイル名を取得
    __PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${(%):-%N}")" >/dev/null 2>&1 && pwd)
else
    # bash 経由: BASH_SOURCE[0] で解決（既存ロジック維持）
    __PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
fi
```

**採用理由**:

- bash と zsh の構文が完全に独立し、互いの構文がパースエラーを引き起こさない
- bash 経路は **既存ロジックそのまま維持** で後方互換完全保証（exit code / stdout / stderr すべて変化なし）
- zsh 経路は新規追加され、`${(%):-%N}` がスクリプトファイルのパスを返す
- 実機検証で macOS の bash 3.2 / bash 5.3 / zsh 5.9 全てで正常動作（cwd 任意、source 元 cwd 任意）

**実機検証結果（案 B）**: SCRIPT_DIR が helper ファイル自身の絶対パスとして解決される（cwd 依存なし）

## アーキテクチャパターン

**Strategy Pattern（最小適用）**: ShellRuntime 別の SCRIPT_DIR 解決戦略を if-else 分岐で切替。本 Unit の規模では Strategy class を導入する複雑性は不要で、最小の if-else 分岐に留める。

設計指針:

- **YAGNI 原則**: shell 判定ロジックは helper ファイル内のたった 1 箇所（SCRIPT_DIR 初期化）にのみ存在する。共通関数化（`detect_shell_runtime()` 等）はしない
- **DR-001 不変条件**: 修正対象を `predecessor-issue.sh` の 1 ファイルに限定するため、shell 判定ロジックの helper 化（共通ライブラリ化）は本 Unit のスコープ外

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/lib/
├── predecessor-issue.sh  # 修正対象（SCRIPT_DIR 初期化 + 既存ロジック）
├── retrospective-issue.sh  # 修正対象外（zsh source は OUT_OF_SCOPE）
├── aidlc-paths.sh        # leaf helper（SCRIPT_DIR 不使用）
├── aidlc-validate.sh     # leaf helper（SCRIPT_DIR 不使用）
├── aidlc-gh.sh           # leaf helper（SCRIPT_DIR 不使用）
└── aidlc-spool.sh        # leaf helper（SCRIPT_DIR 不使用）

tests/
├── aidlc-helpers-zsh-source.bats   # 新規（zsh 互換性テスト 6 件以上）
└── aidlc-helpers-migration.bats    # 既存（移管契約テスト、本 Unit では変更なし）
```

### コンポーネント詳細

#### `predecessor-issue.sh`（修正対象）

- **責務**: zsh / bash 両対応の `__PRED_SCRIPT_DIR` 解決ロジックを提供（既存責務に追加なし、初期化ロジックのみ修正）
- **依存**: `aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` を `__PRED_SCRIPT_DIR` 経由で source
- **修正範囲**: ファイル 30 行目（`__PRED_SCRIPT_DIR=$(cd -- ...)`）の **1 行を 5〜7 行の if-else ブロックに置換**するのみ。他の責務（`predecessor_resolve_issue` 公開関数、診断出力ヘルパ、純粋関数群、内部関数群）は完全に変更なし

#### `tests/aidlc-helpers-zsh-source.bats`（新規）

- **責務**: helper 6 ファイル全体の bash / zsh 両 source 動作確認
- **依存**:
  - **テスト実行要件**: bats-core（bash で動作）/ helper ファイル群
  - **被テスト shell（fixture 経由起動）**: bash（**3.2+**、macOS デフォルト互換）+ zsh（5.0+、macOS / Linux 両対応。`command -v zsh` で利用可否を fail-safe チェック）
- **テスト構造**: helper 1 ファイルあたり 1 ケース、計 6 ケース（最低）。各ケース内で bash / zsh 両 source + SCRIPT_DIR 検証を実施

## インターフェース設計

### スクリプトインターフェース設計

#### `predecessor-issue.sh`（既存契約維持）

- **公開関数**: `predecessor_resolve_issue <prev_cycle>`（**変更なし**、API 契約そのまま）
  - **引数**: `prev_cycle: string` - 前サイクル名（例: `v2.5.3`）
  - **戻り値**: exit 0=成功（warn 含む）/ 1=バリデーションエラー（cycle 検証失敗等）/ 2=システムエラー（外部コマンド失敗等）— ガイド `exit-code-convention.md` 規約準拠（既存実装挙動との部分不整合は本 Unit のスコープ外、OUT_OF_SCOPE 候補）
  - **stdout**: NDJSON 1 行（`resolution_path` / `issue_url` / `file_path` / `source_milestone` / `candidates`）（**変更なし**）
  - **stderr**: `<level>\t<code>\t<detail>` フォーマット（**変更なし**）
- **内部変数**: `__PRED_SCRIPT_DIR`（**初期化ロジックのみ変更**、解決後の値域は変化なし = helper ファイル自身のディレクトリの絶対パス）

#### `tests/aidlc-helpers-zsh-source.bats`（新規）

- **テストケース命名**: `@test "zsh-source: <helper-name> source 動作確認（bash / zsh 両対応）"`
- **fixture 構造**: bats `setup` で `REPO_ROOT` / `HELPER_LIB_DIR` を解決、`teardown` で TMP cleanup
- **assertion パターン**:

  ```text
  CASE 1 (bash assertion):
    run bash -c "source '$HELPER_LIB_DIR/<helper>'"
    [ "$status" -eq 0 ]

  CASE 2 (zsh assertion):
    run zsh -c "source '$HELPER_LIB_DIR/<helper>'"
    [ "$status" -eq 0 ]   # OUT_OF_SCOPE の場合は skip

  CASE 3 (SCRIPT_DIR assertion, predecessor-issue.sh / retrospective-issue.sh のみ):
    run bash -c "source '$HELPER_LIB_DIR/<helper>' && printf '%s' \"\$<SCRIPT_DIR_VAR>\""
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -d "$output" ]   # 解決後パスが実在するディレクトリ

    run zsh -c "source '$HELPER_LIB_DIR/<helper>' && printf '%s' \"\$<SCRIPT_DIR_VAR>\""
    [ "$status" -eq 0 ]   # OUT_OF_SCOPE の場合は skip
    [ -n "$output" ]
    [ -d "$output" ]
  ```

### bats テストケース一覧（計 6 件）

| # | テストケース名 | 検証対象 helper | bash / zsh 検証 | SCRIPT_DIR 検証 | OUT_OF_SCOPE 想定 |
|---|---------------|----------------|-----------------|-----------------|-------------------|
| 1 | `zsh-source: aidlc-paths.sh source 動作確認` | `aidlc-paths.sh` | 両方 exit 0 | 不要（leaf helper） | なし |
| 2 | `zsh-source: aidlc-validate.sh source 動作確認` | `aidlc-validate.sh` | 両方 exit 0 | 不要（leaf helper） | なし |
| 3 | `zsh-source: aidlc-gh.sh source 動作確認` | `aidlc-gh.sh` | 両方 exit 0 | 不要（leaf helper） | なし |
| 4 | `zsh-source: aidlc-spool.sh source 動作確認` | `aidlc-spool.sh` | 両方 exit 0 | 不要（leaf helper） | なし |
| 5 | `zsh-source: predecessor-issue.sh source 動作確認 + SCRIPT_DIR` | `predecessor-issue.sh` | 両方 exit 0 | `__PRED_SCRIPT_DIR` が空でない有効な絶対パス | なし（修正対象） |
| 6 | `zsh-source: retrospective-issue.sh source 動作確認 + SCRIPT_DIR` | `retrospective-issue.sh` | bash exit 0 必須、zsh は skip 許容 | bash 経路で `__RETRO_ISSUE_SCRIPT_DIR` が空でない有効パス | あり（zsh 失敗時 OUT_OF_SCOPE） |

## データモデル概要

### shell 判定の分岐ロジック

```text
入力: ${ZSH_VERSION:-} 環境変数の値
判定:
  非空 (空文字以外)  → ShellRuntime=zsh  → ${(%):-%N} 経路
  空 / unset       → ShellRuntime=bash → ${BASH_SOURCE[0]} 経路
```

### bats テスト fixture 構造

```text
setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HELPER_LIB_DIR="$REPO_ROOT/skills/aidlc/scripts/lib"
  # zsh 利用可否チェック（fail-safe）
  if ! command -v zsh >/dev/null 2>&1; then
    # 全テストで zsh 部分を skip するためのフラグ
    AIDLC_ZSH_AVAILABLE=false
  else
    AIDLC_ZSH_AVAILABLE=true
  fi
}

teardown() {
  # 必要に応じて TMP cleanup（本 Unit は副作用ファイル生成なしのため通常不要）
  :
}
```

## 処理フロー概要

### 修正後の `predecessor-issue.sh` source 処理フロー

**ステップ**:

1. helper ファイルが zsh メインシェルから `source` される（または bash 経由）
2. `if [[ -n "${ZSH_VERSION:-}" ]]; then` で shell 判定
3. zsh 経路: `${(%):-%N}` がスクリプトファイル名を返す → `dirname` + `cd` + `pwd` で SCRIPT_DIR の絶対パスを得る
4. bash 経路: `${BASH_SOURCE[0]}` がスクリプトファイル名を返す → 同様に SCRIPT_DIR を解決
5. 後続の依存 helper（`aidlc-paths.sh` 等）の `source "${__PRED_SCRIPT_DIR}/<helper>.sh"` が成功

**関与するコンポーネント**: `predecessor-issue.sh`（SCRIPT_DIR 初期化部）/ `aidlc-paths.sh` 等の依存 helper

### bats テストの実行フロー

**ステップ**:

1. bats が `aidlc-helpers-zsh-source.bats` をロード（bats 自体は bash 動作）
2. `setup` で `REPO_ROOT` / `HELPER_LIB_DIR` / `AIDLC_ZSH_AVAILABLE` を解決
3. 各テストケースで `bash -c "source ..."` を `run` で実行 → exit code 検証
4. `AIDLC_ZSH_AVAILABLE=true` の場合のみ `zsh -c "source ..."` を `run` で実行 → exit code 検証
5. SCRIPT_DIR を持つ helper（5 / 6）は SCRIPT_DIR の値を `printf '%s' "$<VAR>"` で取得 → 空でない・実在ディレクトリであることを検証
6. テストケース 6（`retrospective-issue.sh`）の zsh 経路で失敗が発生した場合:
   - 実装フェーズで `gh issue create` でバックログ Issue 起票
   - bats テスト側で `skip "OUT_OF_SCOPE: see backlog #<NNN>"` を追加
   - bats 全体は pass 扱いになる（skip は failure ではない）

**関与するコンポーネント**: bats-core / bash / zsh / helper 群 / `gh` CLI（OUT_OF_SCOPE 時のみ）

### OUT_OF_SCOPE 判定フロー（ドメイン層）

**ステップ**（`OutOfScopeDetection.evaluate` の責務範囲）:

1. テストケース 6 の zsh 経路で `run zsh -c "source retrospective-issue.sh"` を実行 → 観測 (`zsh_exit_status` / `script_dir_value`)
2. ドメインポリシー `OutOfScopeDetection.evaluate(target_helper, observation)` が以下を返す:
   - `target_helper = retrospective-issue.sh` かつ `observation.zsh_exit_status != 0` のとき: `OutOfScopeJudgment{is_out_of_scope: true, reason: "zsh_source_compat_failure", evidence: {zsh_exit_status, script_dir_value}}`
   - 上記に該当しないとき: `OutOfScopeJudgment{is_out_of_scope: false, ...}`
3. ドメイン層の責務はここまで。判定結果イベント (`OutOfScopeJudgment`) を実装層 / Construction 手順に引き渡す

**関与するコンポーネント（ドメイン層）**: bats テスト（観測役） / `OutOfScopeDetection` ポリシー（判定役）

### OUT_OF_SCOPE 後段運用フロー（実装層 / Construction 手順）

**責務分離の境界**: 以下は **ドメイン層から分離された実装層 / Construction 手順** の責務。`OutOfScopeJudgment` を消費する運用アクションのみを扱い、判定ロジック自体はドメイン層に委譲する。

**ステップ**（`OutOfScopeJudgment.is_out_of_scope=true` を受け取った後）:

1. **Issue 起票**: 実装エージェント（人間 or AI）が `gh issue create` でバックログ Issue を起票
   - **タイトル**: `[Backlog] retrospective-issue.sh の zsh source 互換性問題（v2.5.4 Unit 004 OUT_OF_SCOPE）`
   - **ラベル**: `backlog`, `type:bugfix`
   - **本文テンプレート**:

     ```text
     ## 背景
     v2.5.4 Unit 004 で predecessor-issue.sh の zsh source 互換性を修正したが、
     同じ SCRIPT_DIR 解決パターンを持つ retrospective-issue.sh は DR-001（修正 1 ファイル限定）に従い OUT_OF_SCOPE 化した。

     ## 提案
     - retrospective-issue.sh の __RETRO_ISSUE_SCRIPT_DIR 解決を Unit 004 と同じ shell 判定分岐方式（案 B）に揃える
     - 既存 zsh source 互換性テスト（tests/aidlc-helpers-zsh-source.bats）の skip を解除する

     ## 関連
     - Unit 004（v2.5.4）: #659（predecessor-issue.sh の修正）
     - Inception DR-001: 修正対象 1 ファイル限定の意思決定
     ```

2. **テスト skip 反映**: bats テストケース 6 の zsh assertion 直前に以下を追加（実装層の責務）:

   ```text
   skip "OUT_OF_SCOPE: see backlog #<NNN>"
   ```

3. **履歴記録**: 履歴 (`construction_unit04.md`) に OUT_OF_SCOPE 判定結果と Issue 番号を記録

4. **障害伝播の分離**: `gh` CLI 障害時（GitHub 障害 / 権限不足 / ネットワーク断）は `PENDING_MANUAL` を skip マーカーに記録（`skip "OUT_OF_SCOPE: PENDING_MANUAL（gh 起票失敗）"`）し、ユーザーへ手動起票を依頼。**ドメイン判定層は GitHub 障害の影響を受けない**（判定済みの `OutOfScopeJudgment` は不変）

**関与するコンポーネント（実装層）**: 実装エージェント / `gh` CLI / bats テストファイル / 履歴ファイル

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: helper の SCRIPT_DIR 解決ロジック変更のみで関数実行時の性能影響なし
- **対応策**: if-else 分岐 1 回のみ追加。文字列比較 + 1 回の `cd`/`pwd` で従来と同等の処理コスト。bats テストの zsh 起動はオーバーヘッドあるが、テスト実行時のみで本番経路には影響なし

### セキュリティ

- **要件**: 既存の path traversal ガード等を維持
- **対応策**:
  - SCRIPT_DIR 解決パスは必ず絶対パス化（`pwd` 経由で正規化）
  - shell 判定は `[[ -n "${ZSH_VERSION:-}" ]]` のみ。環境変数注入による分岐の改竄は実害なし（zsh 経路を強制しても `${(%):-%N}` は zsh パーサ前提のため bash では構文エラー = 改竄成立しない）
  - 多重 source ガード（`__AIDLC_PREDECESSOR_ISSUE_SH_LOADED=1`）に変更なし

### スケーラビリティ

- **要件**: 影響なし
- **対応策**: 同上（1 行の if-else 分岐追加のみ）

### 可用性

- **要件**: zsh / bash 両対応により AI エージェントの実行環境依存性を解消
- **対応策**:
  - bash 経路は既存ロジック維持（後方互換完全保証）
  - zsh 経路を新規追加
  - bats テストで両経路を検証

### 後方互換性

- **要件**: bash での既存呼び出し経路は完全互換（exit code / stdout / stderr すべて維持）
- **対応策**: bash 経路の SCRIPT_DIR 解決ロジックは既存コード `${BASH_SOURCE[0]}` を if-else の `else` 分岐としてそのまま保持。bash 3.2（macOS デフォルト）でも構文エラーなく動作することを実機検証済み

### macOS / Linux 互換

- **要件**: macOS（zsh 5.9 系）/ Ubuntu（zsh 環境依存）両対応
- **対応策**:
  - shell 判定は POSIX 互換構文（`${ZSH_VERSION:-}`、`[[ -n ... ]]` は bash/zsh 両対応）
  - `${(%):-%N}` は zsh プロンプト展開（zsh 5.0 以降標準）。Ubuntu の zsh パッケージも `%N` 対応
  - bats テストの `command -v zsh` で zsh 不在時は skip（fail-safe）

## 技術選定

- **helper runtime（被テスト shell）**: bash 3.2+（macOS デフォルト互換）/ zsh 5.0+
- **テストフレームワーク**: bats-core（既存、bash 上で動作）
- **テスト実行 runtime**: bats が要求する bash バージョン（bats-core 1.10+ では bash 3.2 でも動作可）
- **シェル判定**: POSIX 互換 `[[ ]]` test
- **zsh パラメータ展開**: `${(%):-%N}`（zsh プロンプト展開、source されたファイル名取得）
- **bash パラメータ展開**: `${BASH_SOURCE[0]}`（既存）

**重要**: helper runtime は bash 3.2+ で動作する必要があり、本 Unit の修正コードも bash 3.2 でパースエラーなく動作することを実機検証済み（案 B 採用根拠）。bats 実行 runtime は bats-core の要求に従う（通常 bash 3.2 以上）。

## 実装上の注意事項

### shellcheck 対応

- `${(%):-%N}` は shellcheck（bash 前提）でパースエラーになる可能性が高いため、該当 if-else ブロックに `# shellcheck disable=SC1083`（unrecognized parameter expansion）または `# shellcheck disable=SC2154`（変数未定義）を行単位で付与
- 抑制理由を必ずコメントとして残す: `# zsh パラメータ展開（${(%):-%N}）は shellcheck（bash 前提）で警告となるが、ZSH_VERSION 判定下でのみ評価されるため安全`

### bash 後方互換テスト

- 既存呼び出し経路（`bash skills/aidlc/scripts/lib/predecessor-issue.sh` 直接実行 / `source` 経由 / `retrospective-resend.sh` 経由）の挙動が修正前後で完全互換であることを手動回帰テストで確認
- 手動回帰テストの実施ポイント:
  - `bash -c "source <helper> && declare -p __PRED_SCRIPT_DIR"` で SCRIPT_DIR 値が修正前と同一
  - 公開関数 `predecessor_resolve_issue v2.5.3` の出力（NDJSON / stderr 診断）が修正前と同一

### bats テスト分離戦略

- 新規 `tests/aidlc-helpers-zsh-source.bats` は **zsh 互換性専用**として作成
- 既存 `tests/aidlc-helpers-migration.bats` は **移管契約テスト専用**として維持し、本 Unit では一切変更しない
- 凝集度: 1 ファイル 1 責務（移管契約 vs zsh 互換性）

### OUT_OF_SCOPE handling の判定タイミング

- bats テスト初回実行時に `retrospective-issue.sh` の zsh 経路 exit code を確認
- exit !=0 の場合のみ `gh issue create` を実行 + skip マーカーを追加
- exit 0 の場合（仮に retrospective-issue.sh が pass した場合）は OUT_OF_SCOPE 起票せず、テストはそのまま pass

### 4 leaf helper の失敗時ポリシー（DR-001 不変条件）

- `aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` は SCRIPT_DIR を持たない leaf helper のため通常は zsh source で失敗しない
- **仮に失敗しても DR-001 準拠で当該 helper への構造変更は禁止**。`skip "OUT_OF_SCOPE: see backlog #<NNN>"` でテストを skip 化 + バックログ Issue 起票で next-cycle 候補化のみ実施
- 修正対象は `predecessor-issue.sh` の 1 ファイルに限定の不変条件を維持

## 既存ガイド文書との照合

`.aidlc/rules.md` の「設計レビュー時のガイド照合ルール」に従い、以下のガイドとの整合を確認:

- **`guides/exit-code-convention.md`**: 本 Unit の **設計上の終了コード契約はガイド準拠**（`0=成功 / 1=バリデーションエラー / 2=システムエラー`）。`predecessor-issue.sh` の **既存実装挙動**（コメント上 `1=継続不能 / 2=引数エラー`、cycle 検証失敗で `return 2` 等）は本 Unit の **修正対象外**（SCRIPT_DIR 修正のみ）であり、既存実装とガイド規約の差分は **OUT_OF_SCOPE バックログ Issue 候補**として next-cycle 以降で対応。本 Unit の修正は SCRIPT_DIR 解決ロジック変更に限定するため、終了コード返却挙動への直接影響なし
- **`guides/error-handling.md`**: SCRIPT_DIR 解決失敗時のエラー処理は既存の `cd ... 2>&1` の silent 処理を維持。新規エラーパスの導入なし
- **`tools:cross-platform-review`**: macOS BSD / Linux GNU 互換は `${ZSH_VERSION}` 環境変数 / POSIX `[[ ]]` 構文使用で両対応。zsh `${(%):-%N}` は zsh 標準で macOS / Linux 共通

## 不明点と質問

[Question] 設計フェーズでの不明点はなし

[Answer] -（実機検証で案 A の bash 非互換性が確認され、案 B 採用が確定）
