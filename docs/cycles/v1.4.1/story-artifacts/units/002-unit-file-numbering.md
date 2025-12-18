# Unit: Unit定義ファイル番号付け

## 概要
Unit定義ファイル名に実行順序番号を付与し、依存関係の実行順序を明示する。

## 含まれるユーザーストーリー
- ストーリー4: Unit定義ファイルに実行順序番号を付与

## 責務
- inception.md に Unit 定義ファイル作成時の番号付けルールを追加
- construction.md に Unit ファイル読み込み時の番号順処理を追加
- unit_definition_template.md にファイル名規則の説明を追加

## 境界
- 既存の Unit 定義ファイルのリネームは含まない（新規作成時のルールのみ）

## 依存関係

### 依存する Unit
- 001-remove-commit-hash-recording（依存理由: 同じ unit_definition_template.md を変更するため、先に完了している方が良い）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- ファイル名形式: `{NNN}-{unit-name}.md`（例: `001-setup-database.md`）
- 番号は3桁の0埋め
- 連番の重複は禁止
- 変更対象ファイル:
  - `prompts/package/prompts/inception.md`
  - `prompts/package/prompts/construction.md`
  - `prompts/package/templates/unit_definition_template.md`

## 実装優先度
Medium

## 見積もり
中（複数ファイルの修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
