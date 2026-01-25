# Unit 007 計画: rsync除外とセットアップスクリプト修正

## 概要

Issue #109 で報告された2つの問題を修正する：

1. **rsyncで.githubを除外**: `prompts/package/.github/` が `docs/aidlc/.github/` にコピーされる問題
2. **セットアップ用スクリプトの依存関係**: 初回セットアップ時にスクリプトが存在しない循環依存問題

## 変更対象ファイル

### 移動するファイル

| 移動元 | 移動先 |
|--------|--------|
| `prompts/package/bin/check-setup-type.sh` | `prompts/setup/bin/check-setup-type.sh` |
| `prompts/package/bin/check-version.sh` | `prompts/setup/bin/check-version.sh` |

### 修正するファイル

| ファイル | 修正内容 |
|----------|----------|
| `prompts/setup-prompt.md` | スクリプト参照パスを修正、rsync除外オプション追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: スクリプト配置の設計方針を明確化
2. **論理設計**: 具体的な変更箇所の特定
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

1. **ディレクトリ作成**: `prompts/setup/bin/` を作成
2. **スクリプト移動**: セットアップ専用スクリプトを移動
3. **setup-prompt.md修正**:
   - セクション2: `prompts/setup/bin/check-setup-type.sh` を参照
   - セクション8.2: rsyncに `--exclude='.github'` を追加
4. **テスト**: ドライランでrsync動作を確認

## 完了条件チェックリスト

- [ ] rsyncコマンドに `--exclude='.github'` オプションが追加されている
- [ ] セットアップ専用スクリプトが `prompts/setup/bin/` に配置されている
- [ ] `setup-prompt.md` のスクリプト参照パスが修正されている
- [ ] 既存の `docs/aidlc/bin/` にセットアップ専用スクリプトが残っていない
