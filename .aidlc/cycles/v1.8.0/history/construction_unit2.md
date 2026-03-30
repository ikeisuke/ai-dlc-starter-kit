# Construction Phase 履歴 - Unit 002

## Unit 002: 共通ラベル一括初期化スクリプト

### 完了日時

2026-01-17

### 成果物

#### ソースコード

- `prompts/package/bin/init-labels.sh` - 共通ラベル一括初期化スクリプト（新規作成）

#### プロンプト変更

- `prompts/package/prompts/setup.md` - ラベル作成セクションをスクリプト呼び出しに変更
- `prompts/package/guides/backlog-management.md` - ラベル設定セクションをスクリプト呼び出しに変更

#### 設計ドキュメント

- `docs/cycles/v1.8.0/design-artifacts/domain-models/002-init-labels_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/002-init-labels_logical_design.md`

#### 実装記録

- `docs/cycles/v1.8.0/construction/units/002-init-labels_implementation.md`

### 実装内容

11個の共通ラベル（backlog, type:*, priority:*）を一括作成するシェルスクリプトを実装。

主な機能:

- `--help`: ヘルプメッセージ表示
- `--dry-run`: 作成予定のラベルを表示（実際には作成しない）
- 既存ラベルのスキップ処理
- 機械可読形式の出力（`label:<名前>:<状態>`）

### AIレビュー結果

#### 設計レビュー（3回実施）

1回目: 7件の指摘 → 修正
2回目: 2件の指摘 → 修正
3回目: 0件 → 承認

主な修正点:

- パスの不整合（prompts/package/bin/ と docs/aidlc/bin/ の関係を明記）
- ラベル部分一致問題（`--search`から`--json name`による完全一致に変更）
- 出力形式の曖昧さ（stdout/stderr分離、3パート固定形式を明記）

#### 実装レビュー（2回実施）

1回目: 3件の指摘 → 修正
2回目: 1件の指摘 → 修正

主な修正点:

- ghエラーメッセージの抑制問題（stderrに出力するよう変更）
- 既存ラベル取得失敗時のフォールバック（明示的なエラー終了に変更）
- grepの`--`オプション追加（ラベル名がオプションと誤認されるのを防止）
- リダイレクト順序の修正（`2>&1 1>/dev/null`の正しい順序）

### テスト結果

- `--help`: ヘルプメッセージ正常表示
- `--dry-run`: 11ラベルの状態確認成功
  - `backlog`: exists（既存）
  - 他10ラベル: would-create（作成予定）

### 技術的決定事項

1. **既存ラベル一覧の一括取得**: API呼び出し回数削減のため、`gh label list --json name`で全ラベルを一括取得
2. **stdout/stderr分離**: 機械可読形式（stdout）と人間可読形式（stderr）を分離
3. **エラー継続処理**: `set -euo pipefail`を使用しつつ、ラベル作成失敗時は`if`文でエラーをキャッチして継続

### 関連Issue

- #34
