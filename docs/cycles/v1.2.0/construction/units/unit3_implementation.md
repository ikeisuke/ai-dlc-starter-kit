# 実装記録: Unit 3 - セットアップ分離

## 実装日時
2025-12-04

## 作成ファイル

### プロンプトファイル
- `prompts/setup-prompt.md` - エントリーポイント（判定・誘導）
- `prompts/setup-init.md` - 初回セットアップ用プロンプト（新規）
- `prompts/setup-cycle.md` - サイクル開始用プロンプト（新規）

### 設計ドキュメント
- `docs/cycles/v1.2.0/design-artifacts/domain-models/unit3_domain_model.md`
- `docs/cycles/v1.2.0/design-artifacts/logical-designs/unit3_logical_design.md`

### 計画ドキュメント
- `docs/cycles/v1.2.0/plans/unit3_setup_separation_plan.md`

## ビルド結果
N/A（プロンプトファイルのため）

## テスト結果
手動テストシナリオ

### テストシナリオ 1: 初回セットアップフロー

**前提条件**: `docs/aidlc/project.toml` が存在しないプロジェクト

**手順**:
1. `prompts/setup-prompt.md` を読み込む
2. 実行環境確認でディレクトリを承認
3. `project.toml` が存在しないことを確認 → 初回セットアップに誘導
4. `prompts/setup-init.md` を読み込む
5. プロジェクト情報を入力
6. `project.toml` が生成される
7. 共通ファイルが配置される
8. サイクルディレクトリが作成される
9. Inception Phase への案内が表示される

**期待結果**: 初回セットアップが完了し、Inception Phase を開始できる状態になる

### テストシナリオ 2: サイクル開始フロー

**前提条件**: `docs/aidlc/project.toml` が存在するプロジェクト

**手順**:
1. `prompts/setup-prompt.md` を読み込む
2. 実行環境確認でディレクトリを承認
3. `project.toml` が存在することを確認 → サイクル開始に誘導
4. `prompts/setup-cycle.md` を読み込む
5. サイクルバージョンを入力
6. サイクルディレクトリが作成される
7. `history.md` が初期化される
8. Inception Phase への案内が表示される

**期待結果**: 新しいサイクルが開始され、Inception Phase を開始できる状態になる

### テストシナリオ 3: 後方互換性

**前提条件**: `docs/aidlc/version.txt` のみ存在し、`project.toml` は存在しない（旧バージョン）

**手順**:
1. `prompts/setup-prompt.md` を読み込む
2. 旧バージョンからの移行として初回セットアップに誘導される

**期待結果**: 移行ガイダンスが表示され、初回セットアップに進める

## コードレビュー結果
- [x] セキュリティ: OK（ファイル操作のみ、外部入力なし）
- [x] コーディング規約: OK（Markdown形式、日本語）
- [x] エラーハンドリング: OK（存在確認、後方互換性対応）
- [x] テストカバレッジ: OK（手動テストシナリオ作成）
- [x] ドキュメント: OK（各ファイルに説明あり）

## 技術的な決定事項

1. **ファイル分離方式**: 単一の大きなプロンプトではなく、責務ごとに3ファイルに分離
   - 理由: コンテキスト節約、保守性向上

2. **判定ロジック**: `project.toml` の存在有無で初回/継続を判定
   - 理由: シンプルで明確な判定基準

3. **後方互換性**: `version.txt` のみ存在する場合も検出
   - 理由: 旧バージョンからの移行サポート

4. **サイクル開始処理の統合**: 初回セットアップ時はサイクル開始処理も続けて実行
   - 理由: ユーザー操作の簡略化

## 課題・改善点

1. **Unit 4 で対応**: フェーズプロンプト（inception.md, construction.md, operations.md）の改修
   - `project.toml` 読み込み方式への変更
   - 変数置換方式の廃止

2. **Unit 4 で対応**: `additional-rules.md` の廃止と `project.toml` への統合

3. **将来対応**: バージョンアップ時の自動マイグレーション機能

## 状態
**完了**

## 備考
- 既存の `prompts/setup/` ディレクトリは Unit 4 完了まで維持
- `project.toml` のスキーマは Unit 2 の設計アーキテクチャに準拠
