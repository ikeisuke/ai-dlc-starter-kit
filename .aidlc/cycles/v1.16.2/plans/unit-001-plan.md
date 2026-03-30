# Unit 001 計画: 設定基盤リファクタ

## 概要

aidlc.tomlの設定キー構造を統一し（`[backlog]` → `[rules.backlog]`）、read-config.shのデフォルト値を集中管理に移行する。

## 変更対象ファイル

### スクリプト修正（prompts/package/ を編集、docs/aidlc/ はrsyncで反映）

| ファイル | 修正内容 |
|--------|--------|
| `prompts/package/bin/read-config.sh` | defaults.toml レイヤー追加（4階層に拡張） |
| `prompts/package/bin/check-backlog-mode.sh` | resolve-backlog-mode.sh を source して解決 |
| `prompts/package/bin/env-info.sh` | resolve-backlog-mode.sh を source して解決 |
| `prompts/package/bin/init-cycle-dir.sh` | resolve-backlog-mode.sh を source して解決 |

### 設定ファイル修正

| ファイル | 修正内容 |
|--------|--------|
| `docs/aidlc.toml` | `[backlog]` セクションを `[rules.backlog]` に移動（このリポジトリ自身の設定） |
| `prompts/setup/templates/aidlc.toml.template` | テンプレートの `[backlog]` を `[rules.backlog]` に更新 |

### プロンプト修正

空値フォールバック時に `[backlog].mode` を直接参照しているプロンプトを `[rules.backlog].mode` に更新:

| ファイル | 行 | 修正内容 |
|--------|-----|--------|
| `prompts/package/prompts/construction.md` | 204 | `[backlog]` → `[rules.backlog]` |
| `prompts/package/prompts/inception.md` | 213, 380 | `[backlog].mode` → `[rules.backlog].mode` |
| `prompts/package/prompts/operations.md` | 146 | `[backlog]` → `[rules.backlog]` |
| `prompts/package/prompts/common/agents-rules.md` | 39 | `[backlog].mode` → `[rules.backlog].mode` |
| `prompts/package/guides/backlog-management.md` | 42, 106 | `[backlog]` → `[rules.backlog]` |
| `prompts/setup-prompt.md` | 651-665, 1341 | `[backlog]` セクション生成・参照を `[rules.backlog]` に更新 |

### 新規作成ファイル

| ファイル | 内容 |
|--------|------|
| `prompts/package/config/defaults.toml` | デフォルト値定義ファイル |
| `prompts/package/bin/resolve-backlog-mode.sh` | バックログモード解決共通ロジック |

### --default引数について

プロンプト内の `--default` 使用箇所（5箇所）は全て `rules.*` 形式を既に使用しており、defaults.toml 移行後も後方互換で動作する。defaults.toml に同じデフォルト値を定義し、将来的に `--default` を削除可能にする。

## 新旧キー競合時の仕様

- **新キー優先**: `rules.backlog.mode` が有効値（git/issue/git-only/issue-only）なら採用
- **不正値フォールバック**: `rules.backlog.mode` が不正値の場合は旧キー `backlog.mode` を評価
- **旧キーフォールバック**: `rules.backlog.mode` が未定義の場合も `backlog.mode` を参照
- **競合時（両方存在・値不一致）**: 新キーを使用し、stderrに警告ログを出力
- **最終フォールバック**: 新旧とも不正値または未定義の場合はデフォルト `git`
- **テストマトリクス**: 新キーのみ / 旧キーのみ / 両方一致 / 両方不一致 / 両方なし / 新キー不正+旧キー有効 / 新旧とも不正

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 設定キー構造、デフォルト値レイヤーの責務定義
2. **論理設計**: read-config.sh の4階層読み込みロジック、フォールバック戦略
3. **設計レビュー**

### Phase 2: 実装

4. **コード生成**:
   - 4.1 `prompts/package/config/defaults.toml` 新規作成
   - 4.2 `docs/aidlc.toml` の `[backlog]` → `[rules.backlog]` 移動
   - 4.3 `prompts/setup/templates/aidlc.toml.template` の `[backlog]` → `[rules.backlog]` 更新
   - 4.4 `prompts/package/bin/read-config.sh` に defaults.toml レイヤー追加
   - 4.5 `prompts/package/bin/resolve-backlog-mode.sh` 新規作成（共通ロジック）
   - 4.6 `prompts/package/bin/check-backlog-mode.sh` resolve-backlog-mode.sh をsource
   - 4.7 `prompts/package/bin/env-info.sh` resolve-backlog-mode.sh をsource
   - 4.8 `prompts/package/bin/init-cycle-dir.sh` resolve-backlog-mode.sh をsource
   - 4.9 プロンプト・ガイド内の `[backlog]` 参照を `[rules.backlog]` に更新（5ファイル）
   - 4.10 `prompts/setup-prompt.md` の `[backlog]` 生成・参照を `[rules.backlog]` に更新
5. **テスト生成**: 各スクリプトの動作確認テスト（新旧キー競合テストマトリクス含む）
6. **統合とレビュー**: ビルド・テスト実行、AIレビュー

## 完了条件チェックリスト

- [ ] aidlc.tomlの`[backlog]`セクションが`[rules.backlog]`に移動されている
- [ ] resolve-backlog-mode.shが新規作成され、バックログモード解決ロジックが共通化されている
- [ ] check-backlog-mode.sh、env-info.sh、init-cycle-dir.shがresolve-backlog-mode.shを使用している
- [ ] デフォルト値定義ファイル（`prompts/package/config/defaults.toml`）が作成されている
- [ ] read-config.shにデフォルト値レイヤーが追加されている
- [ ] プロンプト内の`--default`指定箇所の移行が完了している（defaults.tomlに集約）
- [ ] プロンプト内の`[backlog]`直接参照が`[rules.backlog]`に更新されている
- [ ] init-cycle-dir.shが新旧どちらのキー構造でも正常動作する
- [ ] aidlc.toml.templateが`[rules.backlog]`形式に更新されている
- [ ] setup-prompt.mdの`[backlog]`生成・参照が`[rules.backlog]`に更新されている
- [ ] 新旧キー競合テスト（7パターン）が通過している
