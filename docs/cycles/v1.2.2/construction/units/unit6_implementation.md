# Unit 6: ファイル構成整理 - 実装記録

## 概要
docs/aidlc/ をスターターキット由来のファイルのみにし、rsync --delete で完全同期可能にする

## 実装日
2025-12-06

## 変更内容

### 1. ファイル構成の変更

| 変更前 | 変更後 |
|--------|--------|
| `docs/aidlc/project.toml` | `docs/aidlc.toml` |
| `docs/aidlc/prompts/additional-rules.md` | `docs/cycles/rules.md` |
| `docs/aidlc/version.txt` | 廃止（aidlc.toml に統合） |

### 2. 変更したファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | モード判定変更、移行処理追加、パス参照更新 |
| `prompts/setup-prompt.md` | パス参照更新、後方互換性セクション追加 |
| `prompts/package/prompts/construction.md` | additional-rules.md → rules.md |
| `prompts/package/prompts/inception.md` | additional-rules.md → rules.md |
| `prompts/package/prompts/operations.md` | additional-rules.md → rules.md |
| `prompts/package/prompts/additional-rules.md` | templates/rules_template.md に移動 |

### 3. 新機能

- **移行モード**: 旧形式（project.toml）から新形式（aidlc.toml）への自動移行
- **移行通知**: 移行実行時にユーザーへ通知メッセージを表示

## 状態
完了
