# Unit: Kiroエージェント許可設定セットアップ

## 概要
setup-ai-tools.shのsetup_kiro_agent関数を拡張し、Kiroエージェント設定ファイルにAI-DLCワークフロー用の許可設定を含める。

## 含まれるユーザーストーリー
- ストーリー 1: Kiroエージェント許可設定の自動セットアップ

## 関連Issue
- #385

## 責務
- Kiroエージェント設定テンプレート（`prompts/package/kiro/agents/aidlc.json`）に許可設定を追加
- `setup_kiro_agent`関数を拡張し、ファイル状態に応じた分岐処理を実装:
  - **symlink → テンプレートへのリンク**: リンク先テンプレートに許可設定が含まれるため、symlink更新のみ（現行動作）
  - **実ファイル（ユーザーカスタマイズ済み）**: テンプレートの許可設定を実ファイルにマージ（Claude Code側の`_merge_permissions_jq`/`_merge_permissions_python`と同様のset-differenceマージ）
  - **不正JSON**: 上書きせず警告メッセージを出力
  - **ファイル不在**: テンプレートへのsymlinkを新規作成（現行動作）
- Source of truth: テンプレートファイル（`prompts/package/kiro/agents/aidlc.json`）が許可設定の正本

## 境界
- Claude Code側のパーミッション管理ロジック（`_generate_template`/`_merge_permissions_*`）は変更しない
- Kiro以外のエージェント設定ファイルは対象外
- translate-permissionsスキルのロジックは参照のみ（スキル自体は変更しない）
- symlinkが正常なテンプレートリンクの場合、マージは不要（テンプレート更新で自動反映）

## 依存関係

### 依存するUnit
- なし

### 外部依存
- jq または python3（JSONマージ用）

## 非機能要件（NFR）
- **パフォーマンス**: 特になし（セットアップ時のみ実行）
- **セキュリティ**: 許可ルールは最小権限原則に基づく
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 新規セットアップ時はsymlink方式を維持。ユーザーがsymlinkを実ファイルに置き換えてカスタマイズした場合はマージ方式に切り替え
- Kiro JSON形式（tools, allowedTools, toolsSettings）は`translate-permissions`スキルの変換ロジックを参考に構成

## 実装優先度
High

## 見積もり
小〜中規模（テンプレート更新 + マージロジック追加）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-21
- **完了日**: 2026-03-21
- **担当**: -
