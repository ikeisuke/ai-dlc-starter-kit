# Unit 006 計画: アップグレードパスフォールバック

## 概要

setup-prompt.mdとaidlc-setup.shで、docs/aidlc/bin/のスクリプトが存在しない場合にスターターキット側のスクリプトにフォールバックする。鶏と卵問題（sync前にdocs/aidlc/bin/のスクリプトを使えない）を解消する。

## 根本原因

初回セットアップやsync前のアップグレード時、`docs/aidlc/bin/` にスクリプトがまだ存在しないため、`setup-ai-tools.sh` などの参照が失敗する。setup-prompt.mdの一部スクリプト参照にはフォールバックパスが記載されているが、`setup-ai-tools.sh` には記載がない。また `aidlc-setup.sh` では `docs/aidlc/bin/setup-ai-tools.sh` がハードコードされており、sync前の環境でフォールバックが効かない。

## 変更対象ファイル

1. `prompts/setup-prompt.md` - setup-ai-tools.shのフォールバックパス追加（セクション8.2.7）
2. `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` - setup-ai-tools.shパス解決にフォールバック追加

## 実装計画

### setup-prompt.md の修正

1. セクション8.2.7のsetup-ai-tools.sh参照を既存の3パターン記載方式（他スクリプト参照と同一形式）に統一:
   - メタ開発モード: `prompts/package/bin/setup-ai-tools.sh`
   - アップグレードモード（同期済み）: `docs/aidlc/bin/setup-ai-tools.sh`
   - 初回セットアップ: `[スターターキットパス]/prompts/package/bin/setup-ai-tools.sh`

### aidlc-setup.sh の修正

1. Step 7（AIツール設定、L372-390）のsetup-ai-tools.shパス解決を改善:
   - 優先: `docs/aidlc/bin/setup-ai-tools.sh`（sync後に存在する場合）
   - フォールバック: `${STARTER_KIT_ROOT}/prompts/package/bin/setup-ai-tools.sh`（sync前でもスターターキット側を使用）
   - 両方不在の場合: `warn:setup-ai-tools-not-found` を出力（現行動作維持）
   - フォールバック使用時: `info:setup-ai-tools-fallback` を出力し、どのパスを使用したか明示する

## 完了条件チェックリスト

- [ ] setup-prompt.mdの全スクリプト参照でフォールバックパスが記載されていること（特にsetup-ai-tools.sh）
- [ ] aidlc-setup.shのsetup-ai-tools.shパス解決にスターターキット側フォールバックが追加されていること
- [ ] 既存の同期済み環境（docs/aidlc/bin/が存在する場合）の動作に影響しないこと
