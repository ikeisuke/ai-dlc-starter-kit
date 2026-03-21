# Unit 001 計画: Kiroエージェント許可設定セットアップ

## 概要

setup-ai-tools.shの`setup_kiro_agent`関数を拡張し、Kiroエージェント設定ファイル（`aidlc.json`）にAI-DLCワークフロー用の許可設定（allowedTools, toolsSettings）を含める。ファイル状態に応じた分岐処理（symlink/実ファイル/不正JSON/不在）を実装する。

## 変更対象ファイル

1. `prompts/package/kiro/agents/aidlc.json` — テンプレートに許可設定（allowedTools, toolsSettings）を追加
2. `prompts/package/bin/setup-ai-tools.sh` — `setup_kiro_agent`関数を拡張:
   - ファイル状態判定（symlink→テンプレートリンク / 実ファイル / 不正JSON / 不在）
   - 実ファイル時のマージロジック（`_merge_kiro_permissions_jq` / `_merge_kiro_permissions_python`）
   - 不正JSON時の警告出力
3. `tests/` — テストスクリプト（該当する場合）

## 実装計画

### Phase 1: 設計

1. ドメインモデル設計 — エンティティ・値オブジェクト・責務の定義
2. 論理設計 — コンポーネント構成・インターフェース定義
3. 設計レビュー

### Phase 2: 実装

4. テンプレートファイル（`aidlc.json`）に許可設定を追加
5. `setup_kiro_agent`関数の拡張:
   - ファイル状態判定ロジック（symlink判定 → リンク先確認 / 実ファイル → JSON検証 / 不在 → 新規作成）
   - Kiro用マージ関数の実装（jq版・python3版）
   - set-differenceマージ: テンプレートの許可設定のうち既存ファイルにないものだけ追加
6. テスト作成・実行
7. 統合とレビュー

## 完了条件チェックリスト

- [ ] Kiroエージェント設定テンプレート（`prompts/package/kiro/agents/aidlc.json`）に許可設定を追加
- [ ] `setup_kiro_agent`関数を拡張し、ファイル状態に応じた分岐処理を実装
- [ ] symlinkの場合はsymlink更新のみ（現行動作維持）
- [ ] 実ファイル（ユーザーカスタマイズ済み）の場合はテンプレートの許可設定をマージ
- [ ] 不正JSONの場合は上書きせず警告メッセージを出力
- [ ] ファイル不在の場合はテンプレートへのsymlinkを新規作成（現行動作維持）
- [ ] Source of truth: テンプレートファイルが許可設定の正本として機能
