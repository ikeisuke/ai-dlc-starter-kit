# Unit 002 計画: プリフライトチェック・設定値一括提示

## 概要

各フェーズ開始時にツール存在・認証状態を自動チェックし、主要設定値を一括提示する共通プリフライト機構を実装する。既存の環境確認ステップ（`env-info.sh`, `check-backlog-mode.sh`）を `preflight.md` に統合し、唯一の環境確認入口とする。

## 変更対象ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `prompts/package/prompts/common/preflight.md` | 新規作成 | プリフライトチェック共通プロンプト |
| `prompts/package/prompts/inception.md` | 修正 | 既存環境確認をpreflight参照に置換 |
| `prompts/package/prompts/construction.md` | 修正 | 既存環境確認をpreflight参照に置換 |
| `prompts/package/prompts/operations.md` | 修正 | 既存環境確認をpreflight参照に置換 |

## 設計方針

### チェック項目の重大度分類

各チェック項目に `severity` を定義し、失敗時の挙動を固定化する:

| チェック項目 | severity | 失敗時の挙動 | retryable |
|-------------|----------|-------------|-----------|
| git存在確認 | blocker | フェーズ中断 | Yes |
| aidlc.toml存在確認 | blocker | フェーズ中断 | Yes |
| gh状態確認（`env-info.sh` の `gh:` 行を唯一の情報源として使用） | warn | 警告表示、gh依存機能を無効化して続行 | Yes |
| `[project].name` 存在確認 | warn | 警告表示、続行 | Yes |
| レビューツール存在確認（`review_mode != disabled` かつ `tools` 非空の場合のみ実行。`tools=[]` はチェックを実施しない正常系） | info | 情報表示のみ | No |
| 設定値個別取得（`read-config.sh <key> --default <value>` を各キーに実行） | info | 失敗時はデフォルト値を使用して続行 | No |

### 既存環境確認との統合方針

- `preflight.md` が `env-info.sh` と `check-backlog-mode.sh` の呼び出しを包含する
- gh状態は `env-info.sh` の `gh:` 出力を唯一の情報源とする（`check-gh-status.sh` は呼び出さない）
- 各フェーズプロンプトの既存環境確認ステップを `preflight.md` 参照に**置換**（二重実行を防止）
- preflight結果をコンテキスト変数として保持し、以降のステップはこれを参照する

### 統合位置の統一規約

全フェーズで「最初に必ず実行すること」セクションの**同一タイミング**にpreflight参照を配置:

| フェーズ | 現在の環境確認位置 | preflight挿入位置 | 置換対象 |
|---------|-------------------|-------------------|----------|
| Inception | Part 1 ステップ1 (`env-info.sh --setup`) + Part 2 ステップ14 | Part 1 ステップ1をpreflight参照に置換 + ステップ1a（Inception固有情報取得）を追加。Part 2 ステップ14はpreflight結果の参照に置換 | `env-info.sh --setup` の環境確認機能 |
| Construction | ステップ3 (`check-gh-status.sh` + `check-backlog-mode.sh`) | ステップ3をpreflight参照に置換 | `check-gh-status.sh`, `check-backlog-mode.sh` の個別呼び出し |
| Operations | 同上のステップ3相当 | 同上 | 同上 |

### 出力キー名の正規化

preflight内で既存スクリプトの出力キーを正規化し、統一されたコンテキスト変数名を定義:

| コンテキスト変数名 | 取得元 | 値の例 | 互換エイリアス |
|-------------------|--------|--------|--------------|
| `gh_status` | `env-info.sh` の `gh:` 行 | `available` / `not-installed` / `not-authenticated` | `gh`（既存フェーズプロンプト互換） |
| `backlog_mode` | `check-backlog-mode.sh` の出力 | `git` / `issue` / `git-only` / `issue-only` | - |
| `depth_level` | `read-config.sh rules.depth_level.level --default "standard"` | `minimal` / `standard` / `comprehensive` | - |
| `automation_mode` | `read-config.sh rules.automation.mode --default "manual"` | `manual` / `semi_auto` | - |
| `review_mode` | `read-config.sh rules.reviewing.mode --default "recommend"` | `required` / `recommend` / `disabled` | - |
| `review_tools` | `read-config.sh rules.reviewing.tools --default "['codex']"` | `['codex']` / `[]` | - |
| `squash_enabled` | `read-config.sh rules.squash.enabled --default "false"` | `true` / `false` | - |
| `markdown_lint` | `read-config.sh rules.linting.markdown_lint --default "false"` | `true` / `false` | - |
| `unit_branch_enabled` | `read-config.sh rules.unit_branch.enabled --default "false"` | `true` / `false` | - |
| `history_level` | `read-config.sh rules.history.level --default "standard"` | `standard` / `detailed` / `minimal` | - |

### レビューツールチェックの条件分岐

`review_mode != disabled` かつ `review_tools` が非空（`tools = []` でない）場合のみ実行。`tools = []` は「外部CLIを使用しない明示的な意思表示」として扱い、チェックを実施しない正常系とする。

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

プリフライトチェックの構成要素を定義:

- **チェックカテゴリ**: blocker / warn / info の3段階重大度
- **チェック項目**: 上記の重大度分類テーブルに従う
- **設定値取得**: `read-config.sh` 単一キーモード + `--default` で個別取得（キー欠落を確実に防止）
- **結果判定**: blocker項目が1つでもfailならフェーズ中断、warnは警告表示して続行、infoは情報表示のみ
- **再チェックフロー**: blocker/warn項目の失敗時、ユーザー対処後に当該項目のみ再チェック（最大3回）

#### ステップ2: 論理設計

`common/preflight.md` の構造設計:

1. **環境チェックセクション**: `env-info.sh` + `check-backlog-mode.sh` の呼び出し手順
2. **結果判定セクション**: severity別の続行/中断判定ロジック
3. **設定値個別取得セクション**: `read-config.sh <key> --default <value>` の個別呼び出し定義
4. **結果提示セクション**: 統一フォーマットでのチェック結果と設定値の提示
5. **各フェーズプロンプトへの統合方式**: 既存環境確認の置換パターン

### Phase 2: 実装

#### ステップ4: コード生成

1. `common/preflight.md` の新規作成
   - blocker/warn/info分類に基づくチェック実行
   - gh状態は `env-info.sh` を唯一の情報源として使用
   - `review_mode != disabled` かつ `tools` 非空条件でのレビューツールチェック
   - `read-config.sh` 単一キーモード + `--default` による設定値個別取得
   - 統一フォーマットの結果提示
   - blocker失敗時の再チェックフロー（最大3回）

2. `inception.md` の修正
   - Part 1 ステップ1をpreflight参照に置換（`env-info.sh` はpreflight内部で `--setup` なしで実行）
   - ステップ1a追加: Inception固有情報（`current_branch`, `latest_cycle`）をpreflight後に個別取得
   - Part 2 ステップ14の環境確認をpreflight結果の参照に置換

3. `construction.md` の修正
   - ステップ3をpreflight参照に置換（既存の `check-gh-status.sh`/`check-backlog-mode.sh` 個別呼び出しを削除）

4. `operations.md` の修正
   - construction.md と同様の置換パターンを適用

#### ステップ5: テスト

- 各フェーズプロンプトの初期化シーケンスの一貫性確認（全フェーズで同一タイミング）
- blocker/warn/info各レベルの失敗シナリオ網羅確認
- 既存スクリプト出力とpreflight結果の整合性確認

#### ステップ6: 統合とレビュー

- ビルド確認（Markdownlint）
- AIレビュー実施

## 完了条件チェックリスト

- [ ] `common/preflight.md` が新規作成され、blocker/warn/info分類に基づくチェック項目が定義されている
- [ ] `common/preflight.md` にaidlc.toml存在確認（blocker）が定義されている
- [ ] `common/preflight.md` に必須ツール存在確認（git=blocker）が定義されている
- [ ] `common/preflight.md` にgh状態確認（warn、`env-info.sh` を唯一の情報源として使用）が定義されている
- [ ] `common/preflight.md` にレビューツール存在確認（info、`review_mode != disabled` かつ `tools` 非空条件付き）が定義されている
- [ ] `common/preflight.md` にaidlc.toml必須キー存在チェック（`[project].name`=warn）が定義されている
- [ ] `common/preflight.md` に `read-config.sh` 単一キーモード + `--default` による設定値個別取得が定義されている
- [ ] `common/preflight.md` にblocker失敗時の再チェックフロー（最大3回）が定義されている
- [ ] `inception.md` の既存環境確認がpreflight参照に統合され、ステップ1a（`current_branch`/`latest_cycle` 取得）が追加されている
- [ ] `construction.md` の既存環境確認がpreflight参照に置換されている
- [ ] `operations.md` の既存環境確認がpreflight参照に置換されている
- [ ] 出力キー名が全フェーズで統一されている（正規化済みコンテキスト変数名、`gh_status` 互換エイリアス定義を含む）
