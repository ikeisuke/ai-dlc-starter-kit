# Unit 005 計画: `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化

## 概要

v2.6.0 Unit 007 で opt-in シグナル方式にリファクタした `skills/aidlc/scripts/squash-unit.sh` の CI 構造チェック（`bin/check-skill-references.sh` / `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh`）について、本体スクリプトに 3 種固定でハードコードされている部分を `.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` 設定キー経由に置き換える。CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」への準拠度を上げ、本体から starter kit 固有のチェックスクリプト名・配置の知識を完全排除する。

## 採用方針

### 設定不在時の契約統一（Round 1 指摘 #1 反映）

設定不在時の挙動について、Unit 定義「技術的考慮事項」と Issue #687 末尾には旧案として「設定不在 / セクション不在で既存 3 種を fallback default で読み込み（non-breaking）」の表現が残るが、本 Unit では **「集約 skip + info ログ」を契約として一意に採用** する（CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」原則準拠 / 本体から starter kit 固有 3 種の知識を完全排除）。

**非採用案（fallback default 3 種読み込み）の不採用理由**:

- 3 種ファイル名の知識を本体に残すことになり、本 Unit の最終目的（本体スクリプトから固有知識排除）に反する
- starter kit 自身は `.aidlc/config.toml` に明示設定を持つため、後方互換性は設定追加で担保可能（実質 non-breaking と等価）
- consumer プロジェクトは元々 `bin/check-*.sh` を持たないため、現状（実体不在で個別 skip → 集約 info）と新方針（設定不在で集約 skip）は観測上ほぼ同等

**影響範囲**:

- starter kit リポジトリ自身: `.aidlc/config.toml` に設定を追加することで従来 3 種実行を継続（dogfood 確認で担保）
- consumer プロジェクト（既存ユーザー）: 設定不在で集約 skip。観測トークンは `squash:info:internal-ci-checks-skipped` のまま維持（reason suffix を別行で追加するため、既存 grep ルールは互換）
- starter kit fork（自前で 3 種を継承したいケース）: `.aidlc/config.toml` への明示設定が必要。README / docs への反映は別 Issue（v2.7.0 backlog）

Unit 定義ファイル `005-squash-unit-ci-checks-config-driven.md` の「技術的考慮事項」は、設計レビュー Round 1 時点で **計画と同期済み**（fallback default 不採用 / no-config = 集約 skip 統一）。レビュー時点の真実は一意化されており、後続の実装レビューでも本契約のみが判定基準となる。

### 配列パース責務の境界（Round 1 指摘 #2 反映）

`read-config.sh` の現行配列出力形式（Python 風 list literal `['a', 'b']`）を `squash-unit.sh` 側で直接パースするのは、設定読取層のシリアライズ形式とドメイン処理層の密結合となるため、責務境界として理想ではない。

本 Unit では以下の **暫定 IF + 移行計画** を採用する:

**暫定 IF（本 Unit のスコープ内）**:

- `squash-unit.sh` 内に局所ヘルパ関数 `parse_config_array()` を定義し、配列パース責務をこの関数に閉じ込める
- 関数仕様: 入力 = `read-config.sh` の生出力文字列（`['a', 'b']` 形式）、出力 = 改行区切りの要素列（stdout）。空配列 / セクション不在 → 0 行出力
- `run_internal_ci_checks_or_skip()` は `parse_config_array` の戻り値（行配列）のみに依存し、`['` `]` `'` `,` 等の文字構造には依存しない
- これにより将来の置換時、`run_internal_ci_checks_or_skip()` 本体は変更不要となる

**将来の置換条件 / 移行計画（本 Unit のスコープ外）**:

- `read-config.sh` に配列安全出力モード（例: `--format=lines` で改行区切り出力）を追加する別 Unit / 別 Issue を起票候補とする
- 移行時は `squash-unit.sh` 側で `parse_config_array` 呼び出しを `read-config.sh --format=lines` 直接呼び出しに置換し、局所ヘルパ関数を削除
- 同モードの追加は `squash-unit.sh` 以外（将来の他スクリプト）からも需要が見込まれるため、汎用化価値は高い
- 起票時の関連 Issue: 本 Unit 完了後に backlog として GitHub Issue 化

**本 Unit でこの汎用化を取り込まない理由**: スコープ拡大（read-config.sh / lib/toml-reader.sh 改修 + 他スクリプト影響範囲調査 + バッチモード `--keys` との整合）を伴うため、Unit 単体の見積もり（1 day）を超過する。本 Unit のコア目的（squash-unit.sh から 3 種ハードコード排除）を阻害しない範囲で局所封じ込めにとどめる。

### 設定キー設計

`.aidlc/config.toml`（starter kit リポジトリのみ）に以下を追加:

```toml
[rules.squash.internal_ci_checks]
# squash-unit.sh が Unit 完了時に opt-in で実行する CI 構造チェックスクリプト一覧
# - リポジトリルート相対パスのみ許容（絶対パス・..traversal は警告して個別 skip）
# - 設定リストの各エントリについて、ファイル存在チェック（opt-in シグナル）を維持
#   実体不在エントリは個別 skip
# - 設定セクション不在 / 空配列の場合は集約 skip + info ログ
#   （consumer プロジェクトのデフォルト挙動）
scripts = [
    "bin/check-skill-references.sh",
    "bin/check-bash-substitution.sh",
    "bin/check-test-isolation.sh",
]
```

`config/defaults.toml` には追加しない（理由: defaults.toml は consumer プロジェクトにも適用される。starter kit 固有のチェックスクリプト名を defaults に入れると、本体スクリプトから 3 種の知識を排除する目的が defaults にスライドするだけで本質的解決にならない。consumer プロジェクトでは設定不在 → 集約 skip が正しい挙動）。

### `squash-unit.sh` の変更

`run_internal_ci_checks_or_skip()` を以下の責務に整理:

1. `bash scripts/read-config.sh rules.squash.internal_ci_checks.scripts` で設定値を取得（exit code 0/1/2 を解釈）
2. exit 2（read-config.sh エラー）→ 警告 + 安全側 fallback（集約 skip + info ログ）
3. exit 1（キー不在 = consumer プロジェクト想定）→ 集約 skip + info ログ + 安定トークン
4. exit 0 + 値が空配列 `[]` → 集約 skip + info ログ + 安定トークン（reason=empty-config）
5. exit 0 + 値が非空配列 → エントリをパースして個別実行
   - 各エントリのパス正規化バリデーション（絶対パス禁止 / `..` 禁止 / 空文字禁止）
     - 不正エントリは警告 + 個別 skip（squash 自体は中断しない）
   - リポジトリルート相対で `${repo_root}/${entry}` の存在チェック → 不在は個別 skip（既存挙動互換）
   - 存在するエントリは `bash` で実行、失敗時は安定トークン出力 + return 2

### 配列パース方針

「配列パース責務の境界」セクション参照。`squash-unit.sh` 内に局所ヘルパ関数 `parse_config_array()` を実装し、以下の方針でパースする:

- `[` `]` `'` `"` を除去
- カンマで分割
- 各要素を trim

許容文字: `[A-Za-z0-9_./-]+`（スクリプトパスとして合理的な範囲）。範囲外文字を含む要素は警告 + 個別 skip。

`run_internal_ci_checks_or_skip()` は `parse_config_array()` の出力（改行区切り行配列）のみを利用し、`read-config.sh` の生出力形式の知識を直接持たない。これにより将来の `read-config.sh --format=lines` 等への移行時、ヘルパ関数の差し替えのみで本体ロジックを変更しない構造を保つ。

### opt-in シグナルとの関係

- 設定リスト内の各スクリプトについて、ファイル存在チェック（opt-in）を維持
- 「設定にあるが実体が無い」ケースは個別 skip（現状の挙動と互換）
- 設定が空配列 / セクション不在の場合は集約 skip + info ログ

### 安定トークン（Round 2 指摘 #2 反映 / 形式を 1 つに固定）

互換性確保のため、**既存の集約 skip トークンは形式変更せず、reason は常に別行で必ず出力する** 2 行契約に固定する（suffix 形式は採用しない）。これにより、既存パーサ（`squash:info:internal-ci-checks-skipped` を grep するもの）はそのまま動作し、reason を取得したい新規パーサは別行を読み足すだけで済む。

**集約 skip 時の出力契約**（2 行 / 順序固定 / stdout）:

```text
squash:info:internal-ci-checks-skipped
squash:info:internal-ci-checks-skipped:reason=<reason>
```

| `<reason>` | 発生条件 |
|-----------|----------|
| `no-config` | 設定セクション不在（`read-config.sh` exit 1 = consumer プロジェクト想定）|
| `config-read-error` | `read-config.sh` 実行系エラー（exit 2 = dasel 未インストール / TOML 破損等 / 設計レビュー Round 1 で no-config から分離）|
| `invalid-config-format` | `parse_config_array()` が想定外フォーマットを検出（設計レビュー Round 1 で追加）|
| `empty-config` | 設定が空配列 `[]` |
| `no-script-present` | 設定リスト内の全エントリが実体不在または不正パス |

**個別 skip / エラー時の出力契約**（1 行 / stdout）:

| トークン | 発生条件 |
|---------|---------|
| `squash:warn:internal-ci-check-skipped:reason=invalid-path:script=<entry>` | 不正パス（絶対パス / `..` 含む / 不正文字 / 空エントリ）|
| `squash:info:internal-ci-check-skipped:reason=script-not-found:script=<entry>` | エントリ自体は妥当だが実体ファイル不在 |
| `squash:error:<basename>-failed` | チェック実行が失敗（既存トークン、変更なし）|

`<basename>` はチェックスクリプトのファイル名から `.sh` を除いた basename（既存挙動維持）。`<entry>` は設定リストの該当行（リポジトリルート相対パス）。

これにより bats テストや CI ログから reason 別に動作検証が可能になり、かつ既存監視ルールを break しない。

## 完了条件チェックリスト

### Unit 005 受け入れ基準（Issue #687 完了条件）

- [x] `.aidlc/config.toml` に `[rules.squash.internal_ci_checks].scripts` 設定キーが追加されている（diff 確認）
- [x] `squash-unit.sh` の `run_internal_ci_checks_or_skip()` が設定リスト駆動に変更され、本体スクリプトに `check-skill-references` / `check-bash-substitution` / `check-test-isolation` という固有名がハードコードされていない（grep 検証 / exit 1）
- [x] starter kit デフォルト設定で従来 3 種が読み込まれることを bats で検証（`config-driven: 3 種指定 + 全実体存在` ケース pass）
- [x] 設定空配列 / セクション不在で全 skip + info ログが動作することを bats で検証（`empty-config` / `no-config` ケース pass）
- [x] consumer プロジェクト想定で設定不在時のデフォルト挙動を検証（reason=no-config の集約 skip + info ログ）

### Unit 定義「責務」セクション

- [x] `.aidlc/config.toml` に `[rules.squash.internal_ci_checks].scripts` 設定キーを追加し、starter kit デフォルトとして既存 3 種を指定
- [x] `skills/aidlc/scripts/squash-unit.sh` の `run_internal_ci_checks_or_skip()` を設定リスト駆動に変更
- [x] 設定不在 / 空配列 / 一部スクリプト不在の各ケースで適切に動作する fallback ロジック（reason=no-config / empty-config / no-script-present + 個別 skip）
- [x] bats テストで上記分岐を検証（28/28 pass）

### Construction Phase 共通

- [x] 計画レビュー（reviewing-construction-plan）: codex 4 round / 3 + 3 + 1 + 0 件 / unresolved 0
- [x] 設計レビュー（reviewing-construction-design）: codex 4 round / 4 + 3 + 1 + 0 件 / unresolved 0
- [x] コードレビュー（reviewing-construction-code）: codex 3 round / 2 + 1 + 0 件 / unresolved 0
- [x] 統合レビュー（reviewing-construction-integration）: codex 1 round / 3 件（履歴・チェックリスト・状態更新の指摘 → 完了処理で対応）
- [x] markdownlint 実行（`bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1`）でエラー 0 件（4 files / 0 errors）
- [x] 設計と実装の整合性チェック（ドメインモデル 5 概念 / 論理設計 4 関数すべて実装に対応）

### 観測可能な判定指標

- [x] **本体ハードコード排除チェック**: `grep -nE 'check-skill-references|check-bash-substitution|check-test-isolation' skills/aidlc/scripts/squash-unit.sh` → exit 1 / 0 件
- [x] **設定キー追加確認**: `bash skills/aidlc/scripts/read-config.sh rules.squash.internal_ci_checks.scripts` → exit 0 / `['bin/check-skill-references.sh', 'bin/check-bash-substitution.sh', 'bin/check-test-isolation.sh']`
- [x] **bats 全 green**: `bats bin/tests/squash-unit/internal_ci_checks_config_driven.bats` → 28/28 ok
- [x] **既存挙動保持（dogfood）**: starter kit `.aidlc/config.toml` への明示設定追加で 3 種実行を継続。GATE-8 4 ケースで設定の存在を保証

## スコープ

### 含まれるもの

- `.aidlc/config.toml` への `[rules.squash.internal_ci_checks].scripts` セクション追加（starter kit リポジトリのみ）
- `skills/aidlc/scripts/squash-unit.sh` の `run_internal_ci_checks_or_skip()` 改修
  - 設定読取（`read-config.sh` 経由、exit code 0/1/2 解釈）
  - bash 内配列パーサ実装
  - パス正規化バリデーション（絶対パス禁止 / `..` 禁止 / 不正文字禁止 / 空文字禁止）
  - 安定トークン体系の整理（reason 区別追加）
- bats テストの新規追加（配置先: 既存テスト群と同居 `bin/tests/squash-unit/` 配下）
  - 既存ファイル: `bin/tests/squash-unit/internal_ci_checks_optin.bats`（v2.6.0 Unit 007 由来 / GATE-8 starter kit 3 種揃い保証）→ 本 Unit でも維持（regression 担保）
  - 新規ファイル: `bin/tests/squash-unit/internal_ci_checks_config_driven.bats`（本 Unit 追加 / 設定駆動分岐の検証）
  - 新規ファイルのケース:
    - 設定 3 種指定 + 全実体存在 → 全実行成功（既存と同等動作）
    - 設定 3 種指定 + 一部実体不在 → 個別 skip + 残り実行成功
    - 空配列指定 → 集約 skip + reason=empty-config
    - セクション不在 → 集約 skip + reason=no-config（consumer プロジェクト想定）
    - 不正パス（絶対パス / traversal / 不正文字）→ 警告 + 個別 skip
    - チェック失敗 → 既存安定トークン + return 2

**テスト配置ポリシー（Round 1 指摘 #3 反映）**: `bin/tests/` は本 Unit のテスト対象（`bin/check-*.sh` および `skills/aidlc/scripts/squash-unit.sh`）と同階層の bats テスト群（`bin/tests/squash-unit/` / `bin/tests/check-test-isolation/` 等）を集約する配置。`tests/` は AI-DLC スキル全体のテスト群（`retrospective` / `feedback-*` / `aidlc-setup` 等）の集約配置。本 Unit のテストは「`squash-unit.sh` 関数 + `bin/check-*.sh` opt-in シグナル」を対象とするため、既存配置ポリシーに従い `bin/tests/squash-unit/` 配下に追加する。

### 含まれないもの

- `bin/check-*.sh` 各チェックスクリプト本体のロジック変更
- `read-config.sh` への `--array` モード追加（汎用化は別 Unit / 別 Issue）
- `defaults.toml` への 3 種デフォルト追加（CLAUDE.md 原則上、starter kit 固有設定は starter kit リポジトリの config.toml に閉じる）
- consumer プロジェクト向けの「独自 CI チェック追加ガイド」documentation
- Issue #691（汎用 CI チェックをスキル本体に取り込む設計検討、v2.7.0 へ送り）
- CHANGELOG / docs / README への波及（必要時 Operations Phase で別途）

## 関連ファイル（修正対象）

| ファイル | 変更内容 |
|---------|---------|
| `.aidlc/config.toml` | `[rules.squash.internal_ci_checks]` セクション + `scripts` 配列を末尾に追加 |
| `skills/aidlc/scripts/squash-unit.sh` | `run_internal_ci_checks_or_skip()` を設定駆動に書き換え。bash 内配列 parser ヘルパ関数追加。パス正規化バリデーション追加。安定トークン体系整理 |
| `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` | 新規テストファイル（6 ケース以上） |
| `.aidlc/cycles/v2.6.1/story-artifacts/units/005-squash-unit-ci-checks-config-driven.md` | 設計レビュー Round 1 時点で「技術的考慮事項」を計画と同期済み（fallback default 不採用 / no-config = 集約 skip / config-read-error 分離 / invalid-config-format 分離） |

## 設計フェーズ（Phase 1）の対象

`depth_level=standard` のため Phase 1（設計）を実施する。設計の論点:

- **論点 1**: 配列パーサの bash 内実装の堅牢性（quote 種類混在 / 改行混入時の挙動）
- **論点 2**: 安定トークンの命名（既存 `squash:info:internal-ci-checks-skipped` の後方互換と reason 区別の両立）
- **論点 3**: 「実体不在のみで全 skip」の reason 命名（`no-script-present` か `all-not-found` か）
- **論点 4**: パス正規化の許容文字セット範囲（`[A-Za-z0-9_./-]+` で十分か）

ドメインモデル（CI チェック設定エンティティ + 各エントリの個別実行可否判定）と論理設計（`run_internal_ci_checks_or_skip()` の制御フロー + parser ヘルパ関数のシグネチャ）を整理する。

## 実装フェーズ（Phase 2）の対象（Round 2 指摘 #1 反映 / 編集 4 ファイル）

- 4 ファイルの編集
  - `.aidlc/config.toml`（`[rules.squash.internal_ci_checks].scripts` 追加）
  - `skills/aidlc/scripts/squash-unit.sh`（`run_internal_ci_checks_or_skip()` 改修 + `parse_config_array()` 追加）
  - `bin/tests/squash-unit/internal_ci_checks_config_driven.bats`（新規 / 6 ケース以上）
  - `.aidlc/cycles/v2.6.1/story-artifacts/units/005-squash-unit-ci-checks-config-driven.md`（「技術的考慮事項」記述更新 / 計画と契約統一）
- bats 実行
  - `bats bin/tests/squash-unit/internal_ci_checks_config_driven.bats`（新規）
  - `bats bin/tests/squash-unit/internal_ci_checks_optin.bats`（既存 regression）
- shellcheck 実行（`shellcheck skills/aidlc/scripts/squash-unit.sh`）
- markdownlint 実行（`bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1`）
- dogfood 確認（`bash skills/aidlc/scripts/squash-unit.sh --cycle v2.6.1 --unit 005 --vcs git --dry-run` 等）

## リスク

| リスク | 影響度 | 対応 |
|-------|-------|------|
| `read-config.sh` の配列出力形式（`['a', 'b']`）パースで quote 種類混在やエスケープ文字混入時に誤動作 | 中 | パス文字に許容文字セットを限定（`[A-Za-z0-9_./-]+`）。範囲外は警告 + 個別 skip。本 Unit のユースケース（`bin/check-*.sh`）には十分。複雑なパス／special char 混入は YAGNI で別 Issue |
| 既存挙動の後方互換 break（starter kit 自身の Unit squash で 3 種が走らなくなる） | 高 | starter kit `.aidlc/config.toml` に明示追加。dogfood 確認を完了条件に追加。Unit 005 の squash 自体で動作検証 |
| `defaults.toml` に追加しないことで、本リポジトリ以外の consumer fork（starter kit を fork して独自開発するケース）で 3 種が走らなくなる | 低 | 本 Unit 完了後の README / docs に「starter kit fork で 3 種チェックを継承するには `.aidlc/config.toml` に設定を追加」と明示する Issue を別途起票（v2.7.0 backlog） |
| 不正パス検出ロジックでパス traversal 攻撃 surface を残す | 高 | 許容文字セット `[A-Za-z0-9_./-]+` のみでは `..` を排除できないため、**独立した条件チェック** で担保する。具体的には (1) 絶対パス reject = `[[ "$entry" == /* ]]`、(2) traversal reject = `[[ "$entry" == *".."* ]]`、(3) 許容文字 reject = `[[ ! "$entry" =~ ^[A-Za-z0-9_./-]+$ ]]`、(4) 空エントリ reject = `[[ -z "$entry" ]]` の 4 条件を OR で評価し、いずれか該当時は警告 + 個別 skip。テストで `../etc/passwd` / `/etc/passwd` / `bin/../bin/x.sh` 等のケースを検証 |
| 安定トークン拡張（reason 付き）が既存パーサ（CI ログ集約 / 監視）を break | 低 | 既存トークン `squash:info:internal-ci-checks-skipped` は集約 skip 時に必ず 1 行目として出力し、reason は **別行固定**（2 行契約）で出力（suffix 形式は採用しない）。詳細は「安定トークン」セクション参照。既存 grep ルールは無改修で互換 |

## 見積もり

1 day（設計 + 実装 + bats テスト追加 + dogfood 検証 + レビュー反復）

## 関連

- Issue: #687
- 依存: Unit 004（推奨 / `read-config.sh` 経由統一の規約反映後に着手するのが望ましい / 強制依存ではない）
- 関連 Issue: #691（汎用 CI チェックの v2.7.0 設計検討、本 Unit のスコープ外）
- 関連経緯: v2.6.0 Unit 007（opt-in シグナル方式リファクタ / 起票元）
- 関連原則: CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」

## 完了条件達成証跡（2026-05-11）

| 項目 | コマンド / 観測 | 結果 |
|------|---------------|------|
| markdownlint | `bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1` | exit 0 / 4 files / 0 errors |
| 本体ハードコード排除 | `grep -nE 'check-skill-references\|check-bash-substitution\|check-test-isolation' skills/aidlc/scripts/squash-unit.sh` | exit 1 / 0 件 |
| 設定キー読取 | `bash skills/aidlc/scripts/read-config.sh rules.squash.internal_ci_checks.scripts` | exit 0 / 3 種 list literal |
| bats（新規 + GATE-8） | `bats bin/tests/squash-unit/internal_ci_checks_config_driven.bats` | 28/28 ok |
| 計画レビュー | reviewing-construction-plan / codex 4 round | resolve 3+3+1+0 / unresolved 0 |
| 設計レビュー | reviewing-construction-design / codex 4 round | resolve 4+3+1+0 / unresolved 0 |
| コードレビュー | reviewing-construction-code / codex 3 round | resolve 2+1+0 / unresolved 0 |
| 統合レビュー | reviewing-construction-integration / codex 1 round | 3 件（履歴・チェックリスト・状態 / 完了処理で全対応） |
