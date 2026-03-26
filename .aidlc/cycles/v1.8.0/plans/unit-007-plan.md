# Unit 007 計画書: rsync同期スクリプト

## 概要

prompts/package配下の同期（prompts, templates, guides, bin）を一括で行うスクリプトを作成する。

## 対象Unit

- **Unit名**: sync-prompts
- **Unit番号**: 007
- **依存**: なし（独立して実装可能）

## 実行ステップ

### Phase 1: 設計

1. **ドメインモデル設計**
   - スクリプトの責務と入出力を定義
   - 同期対象ディレクトリの構造を整理

2. **論理設計**
   - コマンドライン引数の仕様
   - rsyncオプションの選定
   - エラーハンドリング方針

3. **設計レビュー**
   - ユーザー承認を得る

### Phase 2: 実装

4. **コード生成**
   - `prompts/package/bin/sync-prompts.sh` を作成
   - 引数パース、同期処理、出力メッセージを実装

5. **テスト**
   - 手動テスト（dry-run等で動作確認）

6. **統合とレビュー**
   - 実装記録を作成
   - Markdownlintチェック
   - コミット

## 成果物

| 種類 | パス |
|------|------|
| ドメインモデル | `docs/cycles/v1.8.0/design-artifacts/domain-models/sync-prompts_domain_model.md` |
| 論理設計 | `docs/cycles/v1.8.0/design-artifacts/logical-designs/sync-prompts_logical_design.md` |
| 実装コード | `prompts/package/bin/sync-prompts.sh` |
| 実装記録 | `docs/cycles/v1.8.0/construction/units/007-sync-prompts_implementation.md` |

## 見積もり

Unit定義より: 20分
