# Unit 006 実行計画: 履歴記録スクリプト

## 概要

履歴ファイルへの追記を標準化されたフォーマットで行うスクリプト `write-history.sh` を作成する。

## 対象Unit

- Unit名: 履歴記録スクリプト
- 関連Issue: #34
- 依存Unit: Unit 003（完了済み）

## Phase 1: 設計

### ステップ1: ドメインモデル設計

履歴記録に関するドメイン概念を定義:

- 履歴エントリ（フェーズ、ステップ、内容、成果物）
- フォーマット仕様
- ファイル出力先の決定ロジック

### ステップ2: 論理設計

スクリプトのインターフェースと処理フローを設計:

- 引数仕様（--cycle, --phase, --step, --content, --artifacts等）
- 出力フォーマット
- エラーハンドリング

### ステップ3: 設計レビュー

設計ドキュメントのレビューと承認

## Phase 2: 実装

### ステップ4: コード生成

`prompts/package/bin/write-history.sh` を作成

### ステップ5: テスト生成・実行

動作確認テストを実行

### ステップ6: 統合とレビュー

- 実装記録の作成
- コードレビュー

## 成果物

- `prompts/package/bin/write-history.sh`（新規作成）
- `docs/cycles/v1.8.0/design-artifacts/domain-models/write-history_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/write-history_logical_design.md`
- `docs/cycles/v1.8.0/construction/units/write-history_implementation.md`

## 注意事項

- メタ開発のため、`prompts/package/bin/` に作成する（`docs/aidlc/` ではない）
- Operations Phase で rsync により `docs/aidlc/bin/` に反映される
