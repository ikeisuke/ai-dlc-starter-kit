# ドメインモデル: Construction Phaseバックログステップ削除

## 概要

Construction Phase 01-setup.mdからステップ8（バックログ確認）を削除し、後続ステップ番号を再整合する。プロンプトファイルのステップ構造変更に伴うクロスリファレンス整合を保証する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### StepDefinition
- **ID**: ステップ番号（Integer: 1-13、削除後は1-12）
- **属性**:
  - number: Integer - ステップの連番
  - title: String - ステップのタイトル（例: "バックログ確認"）
  - body: Markdown - ステップの本文
  - suffix: Optional[String] - サブステップ識別子（例: "a"）
- **振る舞い**:
  - renumber(offset): ステップ番号をオフセット分ずらす

### CrossReference
- **ID**: ファイルパス + 行番号
- **属性**:
  - sourceFile: FilePath - 参照元ファイル
  - targetStepNumber: Integer - 参照先ステップ番号
  - context: String - 参照を含む文脈テキスト
- **振る舞い**:
  - updateReference(oldNumber, newNumber): 参照先ステップ番号を更新する

## 値オブジェクト（Value Object）

### StepNumberMapping
- **属性**: oldNumber: Integer, newNumber: Integer
- **不変性**: マッピングは一度決定したら変更しない
- **等価性**: oldNumber と newNumber の組で判定

## 集約（Aggregate）

### SetupStepStructure
- **集約ルート**: 01-setup.md ファイル全体
- **含まれる要素**: StepDefinition（1-13）、内部CrossReference
- **境界**: 01-setup.md内のステップ番号体系
- **不変条件**: ステップ番号は1から連番で欠番なし、内部参照は有効なステップ番号を指す

## ドメインサービス

### StepRenumberingService
- **責務**: ステップ削除後の番号再整合とクロスリファレンス更新
- **操作**:
  - deleteStep(8) - ステップ8を削除
  - renumberSubsequentSteps({9→8, 9a→8a, 10→9, 11→10, 12→11, 13→12}) - 後続番号再整合
  - updateCrossReferences(mappings) - 全クロスリファレンスを更新

## 影響ファイルと変更マッピング

| ファイル | 変更箇所 | 旧値 | 新値 |
|---------|---------|------|------|
| 01-setup.md | ステップ8セクション | 存在 | 削除 |
| 01-setup.md | ステップ9 | ### 9. | ### 8. |
| 01-setup.md | ステップ9a | ### 9a. | ### 8a. |
| 01-setup.md | ステップ10 | ### 10. | ### 9. |
| 01-setup.md | ステップ11 | ### 11. | ### 10. |
| 01-setup.md | ステップ12 | ### 12. | ### 11. |
| 01-setup.md | ステップ13 | ### 13. | ### 12. |
| 01-setup.md L89 | ステップ9で | ステップ8で |
| 01-setup.md L138 | ステップ9 | ステップ8 |
| task-management.md L15 | ステップ9a | ステップ8a |

## ユビキタス言語

- **ステップ**: 01-setup.mdの見出し `### N.` で定義される手順単位
- **クロスリファレンス**: 他のステップや他ファイルからステップ番号で参照する箇所
- **番号再整合**: ステップ削除後に欠番が生じないよう後続ステップの番号を詰める操作

## 不明点と質問（設計中に記録）

なし（要件が明確）
