# Unit: Dependabot PR確認

## 概要
Inception Phase開始時にDependabot PRの有無を確認し、セキュリティ更新の見落としを防止する。

## 含まれるユーザーストーリー
- ストーリー4: Dependabot PR確認

## 責務
- GitHub CLIでDependabot PRの一覧を取得する
- PRがある場合、一覧を表示する
- 今回のサイクルで対応するかどうかをユーザーに確認する

## 境界
- PRのマージやクローズは行わない（確認のみ）
- Dependabot以外のPRは対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub CLI（gh）

## 非機能要件（NFR）
- **パフォーマンス**: 特になし
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: GitHub CLIが利用できない場合はスキップ

## 技術的考慮事項
- コマンド: `gh pr list --label "dependencies" --state open`
- GitHub CLIが未設定の場合のエラーハンドリング
- inception.mdのステップ3の前後に手順を追加

## 実装優先度
Medium

## 見積もり
小（プロンプト修正のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2025-12-12
- **完了日**: 2025-12-12
- **担当**: -
