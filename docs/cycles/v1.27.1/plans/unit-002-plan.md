# Unit 002 計画: setup_kiro_agent 実ファイルマージ対応

## 概要

setup_kiro_agent()に実ファイル（ユーザーカスタマイズ済み）のallowedCommands差分マージロジックを追加する。

## 関連Issue

- #388: setup_kiro_agent 実ファイルマージ対応

## 変更対象ファイル

- `prompts/package/bin/setup-ai-tools.sh` — setup_kiro_agent() の改修、新規関数追加（正本）
- `docs/aidlc/bin/setup-ai-tools.sh` — rsync同期で反映

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: マージロジックの構造と責務定義
2. **論理設計**: allowedCommands差分計算、ワイルドカード包含チェックのアルゴリズム設計
3. **設計レビュー**

### Phase 2: 実装

4. **コード生成**:
   - `_generate_kiro_template()`: Kiroテンプレート JSON生成（`toolsSettings.shell.allowedCommands` のみ抽出）
   - `_merge_kiro_commands_jq()`: jqベースの allowedCommands マージ（ワイルドカード包含チェック付き）
   - `_merge_kiro_commands_python()`: Python3 フォールバック実装
   - `setup_kiro_agent()` 改修: 実ファイル検出時に `_detect_json_state()` → マージロジックを呼び出し
5. **テスト生成**: マージロジックのユニットテスト
6. **統合とレビュー**: ビルド・テスト実行、AIレビュー

## 完了条件チェックリスト

- [x] 実ファイル検出時のマージロジック実装（jq/python両対応）
- [x] テンプレートとのallowedCommands差分計算
- [x] ワイルドカード包含チェック
- [x] マージ結果の出力
