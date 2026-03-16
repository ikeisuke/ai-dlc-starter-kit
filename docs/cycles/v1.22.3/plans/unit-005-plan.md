# Unit 005 計画: sync-package.sh配置見直しとlib同期検証

## 概要

`sync-package.sh` を rsync同期対象外に移動し、`lib/` 同期の動作を検証する。

## 変更対象ファイル

- `prompts/package/bin/sync-package.sh` → `prompts/bin/sync-package.sh` に移動
- `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` — sync-package.sh参照パス更新
- `docs/aidlc/bin/sync-package.sh` — 削除（不要コピー）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 移動先・参照パスの定義
2. **論理設計**: 移動手順・参照パス更新箇所の特定
3. **設計レビュー**: AIレビュー実施

### Phase 2: 実装

4. **コード生成**: ファイル移動・参照パス更新
5. **テスト生成**: sync-package.sh動作確認・lib同期検証
6. **統合とレビュー**: AIレビュー実施

## 完了条件チェックリスト

- [ ] `sync-package.sh` が `prompts/bin/` に移動されている
- [ ] `prompts/package/bin/sync-package.sh` が削除されている
- [ ] `docs/aidlc/bin/sync-package.sh` が削除されている
- [ ] `aidlc-setup.sh` の参照パスが更新されている
- [ ] `lib/` ディレクトリの同期が正しく動作している（validate.shが同期される）
- [ ] sync-package.sh自体の動作に影響がない
