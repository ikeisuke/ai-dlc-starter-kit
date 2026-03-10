# Unit: 既存プロンプトのテンポラリファイルパス統一

## 概要
既存プロンプト・スキル内の固定テンポラリファイルパスをUnit 004で策定した規約に統一する。

## 含まれるユーザーストーリー
- ストーリー5: 既存プロンプトのテンポラリファイルパス統一

## 責務
- CLAUDE.md内の固定パス（`/tmp/commit-msg.txt`）を規約に統一する
- common/rules.md内の`<一時ファイルパス>`プレースホルダーの説明を規約セクション参照に更新する
- common/commit-flow.md内の一時ファイル記述を規約に統一する
- common/review-flow.md内の一時ファイル記述を規約に統一する
- squash-unit/SKILL.md内のテンポラリファイルパス（`/tmp/squash-msg.txt`）を規約に統一する
- 上記5ファイルの全一時ファイルパス記述が規約準拠であることをチェックリストで検証する

## 境界
- 規約の定義自体はUnit 004の責務
- シェルスクリプト内部のテンポラリファイル処理は対象外

## 依存関係

### 依存する Unit
- Unit 004: テンポラリファイル出力先規約策定（依存理由: 規約が策定されていないと統一先パスが確定しない）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし（プロンプト変更のみ）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 変更対象ファイル一覧（5ファイル）:
  1. `prompts/package/prompts/CLAUDE.md`
  2. `prompts/package/prompts/common/rules.md`
  3. `prompts/package/prompts/common/commit-flow.md`
  4. `prompts/package/prompts/common/review-flow.md`
  5. `prompts/package/skills/squash-unit/SKILL.md`

## 実装優先度
High

## 見積もり
S（5ファイルの置換箇所は事前に特定済み、各ファイルの一時ファイルパス記述は1-2箇所のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
