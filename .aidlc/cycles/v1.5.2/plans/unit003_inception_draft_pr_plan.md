# Unit 003: Inception Phase ドラフトPR作成 - 実行計画

## 概要
Inception Phase完了時にドラフトPRを自動作成し、複数Unitを並列開発する準備を整える。

## 対象ファイル
- `prompts/package/prompts/inception.md` - ドラフトPR作成ステップを追加

## 変更内容

### Phase 1: 設計

#### 1. ドメインモデル設計
- ドラフトPR作成フローの責務定義
- 前提条件（GitHub CLI利用可能性）の整理
- エラーハンドリング方針

#### 2. 論理設計
- `inception.md`への追加箇所の特定
- 追加するセクションの構造設計
- 既存フローとの整合性確認

### Phase 2: 実装

#### 3. コード生成（プロンプト編集）
- 「完了時の必須作業」セクションにドラフトPR作成ステップを追加
- GitHub CLI利用可否チェックのコマンド追記
- PR作成コマンドとエラーハンドリングの追記

#### 4. 動作確認
- プロンプト内容の整合性確認
- 既存フローへの影響確認

## 成果物
- `docs/cycles/v1.5.2/design-artifacts/domain-models/inception_draft_pr_domain_model.md`
- `docs/cycles/v1.5.2/design-artifacts/logical-designs/inception_draft_pr_logical_design.md`
- `prompts/package/prompts/inception.md`（更新）
- `docs/cycles/v1.5.2/construction/units/inception_draft_pr_implementation.md`

## 注意事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集）
- 変更は次回セットアップ時に `docs/aidlc/` に反映される

## 作成日
2025-12-25
