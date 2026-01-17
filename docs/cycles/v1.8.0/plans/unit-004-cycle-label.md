# Unit 004 計画: サイクルラベル操作スクリプト

## 作成日時

2026-01-17 12:59:48 JST

## 概要

サイクルラベル（cycle:vX.X.X）の確認と作成を一括で行うスクリプトを作成する。

## Phase 1: 設計

### ステップ1: ドメインモデル設計

- スクリプトの責務とインターフェースを定義
- 入出力フォーマットの設計
- エラーハンドリング方針の決定

### ステップ2: 論理設計

- スクリプトの処理フロー設計
- GitHub CLI（gh）との連携方法
- 既存プロンプトへの組み込み方法

### ステップ3: 設計レビュー

- 設計内容をユーザーに提示し承認を得る

## Phase 2: 実装

### ステップ4: コード生成

- `prompts/package/bin/cycle-label.sh` の作成
- 実行権限の付与

### ステップ5: テスト生成

- 手動テストによる動作確認
- 各出力パターンの確認

### ステップ6: 統合とレビュー

- `prompts/package/prompts/inception.md` への呼び出し追加
- Markdownlintの実行
- 実装記録の作成
- コミット

## 成果物

- `prompts/package/bin/cycle-label.sh`（新規）
- `prompts/package/prompts/inception.md`（更新）
- `docs/cycles/v1.8.0/design-artifacts/domain-models/cycle-label_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/cycle-label_logical_design.md`
- `docs/cycles/v1.8.0/construction/units/cycle-label_implementation.md`

## 依存関係

- Unit 001（環境情報でgh確認）: 完了済み

## 見積もり

20分
