# Unit: コンパクション時のプロンプト読み込み

## 概要

コンテキストがコンパクション（自動要約）された後も、フェーズのルールと手順が維持されるよう、各フェーズプロンプトに再読み込み指示を追加する。

## 含まれるユーザーストーリー

- US4: コンパクション時のプロンプト読み込み (#170)

## 関連Issue

- #170

## 責務

- `prompts/package/prompts/inception.md` の「コンテキストリセット対応」セクションにコンパクション時の再読み込み指示を追加
- `prompts/package/prompts/construction.md` に同様の指示を追加
- `prompts/package/prompts/operations.md` に同様の指示を追加
- `prompts/package/templates/progress_inception_template.md` に「再開時に読み込むファイル」セクションを追加
- `prompts/package/templates/progress_construction_template.md` に「再開時に読み込むファイル」セクションを追加

**注**: operations用のprogress.mdテンプレートは存在しないため、inception/constructionのみ対象

## 境界

- プロンプトファイルへの指示追加のみ
- AIの動作変更は行わない（指示ベース）

## 依存関係

### 依存するUnit

- Unit 003（依存理由: 両方ともoperations.mdを変更するため、003で行数削減後に004でセクション追加を行う）

### 外部依存

- なし

## 非機能要件（NFR）

- **UX**: コンパクション後もスムーズに作業継続可能

## 技術的考慮事項

- 変更対象: `prompts/package/prompts/inception.md`, `prompts/package/prompts/construction.md`, `prompts/package/prompts/operations.md`
- 変更対象: `prompts/package/templates/progress_inception_template.md`, `prompts/package/templates/progress_construction_template.md`
- 「コンテキストリセット対応」セクションの拡張

## 実装優先度

Medium

## 見積もり

小規模（テキスト追加のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
