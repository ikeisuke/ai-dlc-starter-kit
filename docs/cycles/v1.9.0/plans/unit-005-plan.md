# Unit 005 計画: 設定確認スクリプト整備

## 概要

プロンプト内の重複bashコードをスクリプト化し、プロンプトの簡潔化と保守性向上を実現する。

## 変更対象ファイル

### 新規作成

- `prompts/package/bin/check-backlog-mode.sh` - バックログモード確認スクリプト
- `prompts/package/bin/check-gh-status.sh` - GitHub CLI確認スクリプト

### 変更

- `prompts/package/prompts/inception.md` - スクリプト呼び出しに変更
- `prompts/package/prompts/construction.md` - スクリプト呼び出しに変更
- `prompts/package/prompts/operations.md` - スクリプト呼び出しに変更
- `prompts/package/prompts/setup.md` - スクリプト呼び出しに変更

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - スクリプトの入出力仕様を定義
   - 既存スクリプトとの整合性確認

2. **論理設計**
   - スクリプトの詳細仕様（引数、出力形式、エラー処理）
   - プロンプトの変更箇所特定

### Phase 2: 実装

1. **スクリプト作成**
   - `check-backlog-mode.sh` 作成
   - `check-gh-status.sh` 作成
   - 単体テスト実行

2. **プロンプト変更**
   - 4つのプロンプトをスクリプト呼び出しに変更
   - 行数削減の検証

3. **統合テスト**
   - 各プロンプトからスクリプトが正常動作することを確認

## 完了条件チェックリスト

- [ ] `prompts/package/bin/check-backlog-mode.sh`の作成
- [ ] `prompts/package/bin/check-gh-status.sh`の作成
- [ ] プロンプトのスクリプト呼び出しへの変更（4ファイル）
- [ ] 約100行の削減達成
