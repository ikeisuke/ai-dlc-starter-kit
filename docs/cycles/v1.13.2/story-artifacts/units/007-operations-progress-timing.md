# Unit: progress.md更新タイミング修正

## 概要

Operations Phaseのステップ6完了時にprogress.mdの「完了」更新がPRマージに含まれるよう、更新タイミングを修正する。

## 含まれるユーザーストーリー

- US8: progress.md更新タイミングの修正

## 関連Issue

- なし（サイクル中に発見した問題）

## 責務

- `prompts/package/prompts/operations.md` のステップ6フロー内で、progress.md更新タイミングをPRマージ前（Gitコミット前）に移動

## 境界

- operations.mdのステップ6のみを変更
- 他のフェーズ（inception.md, construction.md）のprogress.md更新タイミングは対象外
- Construction Phaseの同様の問題は別途検討（バックログ対象）

## 依存関係

### 依存するUnit

- Unit 003（依存理由: 両方ともoperations.mdを変更するため、003で行数削減後に007で修正を行う）

### 外部依存

- なし

## 非機能要件（NFR）

- **整合性**: PRマージ後のmainブランチでprogress.mdが正確な状態を反映

## 技術的考慮事項

- 変更対象: `prompts/package/prompts/operations.md`
- 現在のフロー:
  1. 6.5 Gitコミット
  2. 6.6 PR Ready化
  3. 6.6.5 コミット漏れ確認
  4. 6.7 PRマージ
  5. 「ステップ完了時: progress.mdでステップ6を「完了」に更新」← ここが問題
- 修正後のフロー:
  1. **6.4.5（新規）: progress.md更新** ← ここに移動
  2. 6.5 Gitコミット
  3. 6.6 PR Ready化
  4. 6.6.5 コミット漏れ確認
  5. 6.7 PRマージ

## 実装優先度

High（バグ修正）

## 見積もり

極小（テキスト移動のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-06
- **完了日**: 2026-02-06
- **担当**: @claude
