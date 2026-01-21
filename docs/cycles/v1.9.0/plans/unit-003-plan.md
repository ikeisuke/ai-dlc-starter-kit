# Unit 003 実装計画: AIレビューフロー外部化

## 概要

AIレビューフロー記述を外部ファイルに切り出し、inception.md, construction.md, operations.mdから参照する形式に変更する。Unit 002（共通セクション外部化）と同様の手法を適用。

## 変更対象ファイル

### 新規作成

- `prompts/package/prompts/common/review-flow.md` - AIレビューフロー共通ドキュメント

### 変更

- `prompts/package/prompts/inception.md` - AIレビューフロー部分を参照に置き換え
- `prompts/package/prompts/construction.md` - AIレビューフロー部分を参照に置き換え
- `prompts/package/prompts/operations.md` - AIレビューフロー部分を参照に置き換え

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - 外部化対象セクションの特定と構造化
   - 各プロンプト固有の差分を洗い出し

2. **論理設計**
   - 参照形式の決定（Unit 002と同様の「今すぐ `docs/aidlc/...` を読み込んで」形式）
   - ファイル構造とコンテンツ配置

### Phase 2: 実装

1. **review-flow.md 作成**
   - 共通部分の抽出と統合（反復レビュー含む完全共通化）

2. **各プロンプトの更新**
   - 重複記述の削除
   - 参照形式への置き換え

3. **テスト・レビュー**
   - AIレビュー実行
   - 人間レビュー

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/common/review-flow.md`の作成
- [ ] inception.md, construction.md, operations.mdからレビューフロー記述の削除
- [ ] 外部ファイル参照形式への置き換え

## 技術的考慮事項

- **完全共通化を採用**: 反復レビュー（1セット最大3回、合計最大6回）を全フェーズに適用
- **参照形式**: Unit 002と同様の「今すぐ `docs/aidlc/prompts/common/review-flow.md` を読み込んで」形式を使用
- rules.md の「AIレビューツールの使用ルール」との整合性維持

## 依存関係

- Unit 001: 参照方式PoC（完了済み - 参照形式が動作することを確認済み）
- Unit 002: 共通セクション外部化（完了済み - intro.md, rules.md を参照可能）
