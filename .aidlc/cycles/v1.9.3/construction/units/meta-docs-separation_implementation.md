# 実装記録: メタ開発ドキュメント整理

## 概要

prompts/package/ 内のメタ開発向け（非ユーザー向け）ドキュメントを調査し、不要なファイルの削除・移動を行った。

## 実装内容

### 調査結果

`prompts/package/` 配下の全ファイルを調査し、Codex CLIによるレビューも実施。

分類基準:
- **ユーザー向け**: AI-DLCワークフローの実行に必要なファイル
- **開発者向け**: AI-DLCスターターキット自体の開発・テスト・検証に使用するファイル

### 削除（PoC検証用ファイル）

| 削除ファイル |
|-------------|
| `prompts/package/prompts/common/poc-test-level1.md` |
| `prompts/package/prompts/common/poc-test-level2.md` |
| `prompts/package/prompts/common/poc-test-level3.md` |
| `docs/aidlc/prompts/common/poc-test-level1.md` |
| `docs/aidlc/prompts/common/poc-test-level2.md` |
| `docs/aidlc/prompts/common/poc-test-level3.md` |

### 移動（開発者向けツール・ガイド）

| 移動元 | 移動先 |
|-------|-------|
| `prompts/package/bin/sync-prompts.sh` | `prompts/dev/bin/sync-prompts.sh` |
| `prompts/package/bin/check-references.sh` | `prompts/dev/bin/check-references.sh` |
| `prompts/package/guides/reference-guide.md` | `prompts/dev/guides/reference-guide.md` |
| `prompts/package/guides/deprecation.md` | `prompts/dev/guides/deprecation.md` |

対応する `docs/aidlc/` 側のファイルも削除。

### 参照の更新

`deprecation.md` への参照を GitHub URL に変更:
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/setup.md`
- `docs/aidlc/prompts/construction.md`
- `docs/aidlc/prompts/setup.md`

## テスト結果

- rsync --dry-run で同期状態を確認: 正常動作
- Codex CLIによる追加調査: 実施済み

## 完了条件の確認

- [x] prompts/package/ 内の開発者向けドキュメントの特定
- [x] docs/development/ または別の場所への移動（→ prompts/dev/ に移動）
- [x] rsync 同期対象の確認

## 状態

完了
