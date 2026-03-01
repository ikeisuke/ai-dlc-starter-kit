# Unit: write-history.sh安全性ドキュメント改善

## 概要
write-history.shの--content引数がセキュアであることを文書化し、プロンプト内の呼び出し例を安全なパターンに統一する。

## 含まれるユーザーストーリー
- ストーリー 2: write-history.shの安全性ドキュメント改善 (#254)

## 責務
- スクリプトの安全性確認結果の文書化
- プロンプト内のheredoc例の安全パターン統一（`<<'EOF'` クォート形式）
- 終端トークンインジェクション防止の注意書き追加

## 境界
- write-history.shスクリプト自体の変更は行わない（既にセキュア）
- 新機能の追加は行わない

## 依存関係

### 依存する Unit
- Unit 001: operations.md分割リファクタリング（依存理由: heredoc修正対象にoperations.mdが含まれるが、分割後はoperations-release.mdも対象になるため、分割完了後に修正する）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: heredocパターンの安全性確保
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 正本は `prompts/package/` 配下のプロンプトファイル
- review-flow.md, commit-flow.md, construction.md, operations.md等のheredoc例が対象
- 関連Issue: #254

## 実装優先度
Medium

## 見積もり
小（ドキュメント修正のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
