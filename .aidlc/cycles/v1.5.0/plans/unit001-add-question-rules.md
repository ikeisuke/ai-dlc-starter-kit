# Unit 001 実行計画: 予想禁止・一問一答質問ルール追加

## 概要

AIが予想で方針を決定せず、不明点を一問一答形式で質問するルールを各フェーズプロンプトに追加する。

## 対象ファイル

### メインプロンプト（prompts/package/prompts/）
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

### Lite版プロンプト（prompts/package/prompts/lite/）
- `prompts/package/prompts/lite/inception.md`
- `prompts/package/prompts/lite/construction.md`
- `prompts/package/prompts/lite/operations.md`

### セットアッププロンプト（prompts/）
- `prompts/setup-prompt.md`
- `prompts/setup-init.md`
- `prompts/setup-cycle.md`

**注意**: `docs/aidlc/` は直接編集禁止（Operations Phase の rsync で上書きされる）

## 実行ステップ

### Phase 1: 設計

1. **ドメインモデル設計**
   - 「一問一答質問ルール」の構造と責務を定義
   - 各フェーズでの適用範囲を明確化
   - 既存の質問ロジックとの整合性を確認

2. **論理設計**
   - 各プロンプトファイルへの追加箇所を特定
   - ルール文言の統一フォーマットを定義

3. **設計レビュー**
   - ユーザー承認を取得

### Phase 2: 実装

4. **コード生成**
   - `prompts/package/prompts/inception.md` にルールを追加
   - `prompts/package/prompts/construction.md` にルールを追加
   - `prompts/package/prompts/operations.md` にルールを追加

5. **テスト・統合**
   - ルールの整合性確認
   - 実装記録の作成

## 完了基準

- 3つのフェーズプロンプトすべてにルールが追加されていること
- 既存の質問ロジックと矛盾がないこと
- 実装記録に「完了」が明記されていること

## 関連バックログ

- `docs/cycles/backlog/rule-no-assumption-one-by-one-question.md`

---

作成日: 2025-01-20
