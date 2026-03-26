# 実装記録: バックログ完了項目移動

## 実装日時
2025-12-06

## 作成ファイル

### ソースコード
N/A（プロンプト/テンプレート修正のため）

### テスト
N/A

### 設計ドキュメント
- docs/cycles/v1.2.1/design-artifacts/domain-models/unit2_domain_model.md
- docs/cycles/v1.2.1/design-artifacts/logical-designs/unit2_logical_design.md

### 新規作成
- docs/aidlc/templates/cycle_backlog_template.md - サイクル固有バックログテンプレート

### 修正
- docs/aidlc/prompts/operations.md
  - バックログ整理手順追加（3. バックログ整理）
  - 気づき記録ルール追加
  - サイクル固有バックログ確認ステップ追加（5ステップに変更）
- prompts/setup-cycle.md
  - サイクル固有バックログ作成ステップ追加（6. サイクル固有バックログの作成）
- docs/aidlc/prompts/construction.md
  - 気づき記録ルール追加
  - Unit作業開始時のサイクル固有バックログ確認追加
- docs/aidlc/prompts/inception.md
  - 気づき記録ルール追加

## ビルド結果
N/A（プロンプト変更のため）

## テスト結果
N/A（プロンプト変更のため）

## コードレビュー結果
- [x] セキュリティ: OK（機密情報なし）
- [x] コーディング規約: OK
- [x] エラーハンドリング: N/A
- [x] テストカバレッジ: N/A
- [x] ドキュメント: OK

## 技術的な決定事項
1. サイクル固有バックログを導入し、コンフリクトを最小化
2. バックログを「発見した項目」と「共通から転記した項目」の2セクションで管理
3. Operations Phase完了時に共通バックログへ反映（マージ直前）
4. 各フェーズ開始時にサイクル固有バックログを確認し、対応可能な項目を検討

## 課題・改善点
なし

## 状態
**完了**

## 備考
当初はoperations.mdにのみ手順追加の予定だったが、設計対話を通じてサイクル固有バックログの導入に方針変更。コンフリクト回避と明確な管理を実現。
