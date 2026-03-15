# Unit: アップグレードパスフォールバック

## 概要
setup-prompt.mdとaidlc-setup.shで、docs/aidlc/bin/のスクリプトが存在しない場合にスターターキット側のスクリプトにフォールバックする

## 含まれるユーザーストーリー
- ストーリー 5（分割2/2）

## 責務
setup-prompt.mdの全スクリプト参照（resolve-starter-kit-path.sh、sync-package.sh、migrate-config.sh、setup-ai-tools.sh）でのフォールバックパス追加、aidlc-setup.shのsetup-ai-tools.shパス解決改善

## 境界
アップグレード判定ロジック（check-setup-type.sh/check-version.sh）の修正はUnit 005の範囲

## 依存関係

### 依存する Unit
Unit 005（アップグレード判定が正しくなっていることが前提）

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
対象ファイル: prompts/setup-prompt.md、prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh。鶏と卵問題: sync前にdocs/aidlc/bin/のスクリプトを使えない→スターターキット側のスクリプトを優先使用する方針

## 実装優先度
High

## 見積もり
小〜中規模（複数ファイル横断修正＋回帰確認）。回帰確認項目: (1) initial環境（docs/aidlc/なし）でのセットアップ、(2) upgrade環境（docs/aidlc/あり）でのアップグレード、(3) docs/aidlc/bin/なし環境でのフォールバック動作

## 関連Issue
- なし

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-15
- **完了日**: 2026-03-15
- **担当**: @claude
