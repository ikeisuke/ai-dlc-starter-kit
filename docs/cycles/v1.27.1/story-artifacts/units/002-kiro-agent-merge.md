# Unit: setup_kiro_agent 実ファイルマージ対応

## 概要
setup_kiro_agent()に実ファイル（ユーザーカスタマイズ済み）の場合のallowedCommands差分マージロジックを追加する。

## 含まれるユーザーストーリー
- ストーリー 2: setup_kiro_agent 実ファイルマージ対応（#388）

## 責務
- 実ファイル検出時のマージロジック実装（jq/python両対応）
- テンプレートとのallowedCommands差分計算
- ワイルドカード包含チェック
- マージ結果の出力

## 境界
- symlink状態のファイル管理ロジックは変更しない
- Kiroエージェント設定のallowedCommands以外のフィールドは対象外
- setup_claude_permissions()の既存ロジックは変更しない

## 依存関係

### 依存する Unit
なし

### 外部依存
- jq（優先）またはPython3（フォールバック）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし（セットアップ時のみ実行）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: jq/python両方が使えない環境では従来のWarning動作を維持

## 技術的考慮事項
- 正本は `prompts/package/bin/setup-ai-tools.sh` を編集
- setup_claude_permissions()の_merge_permissions_jq()/_merge_permissions_python()を参考にするが、Kiro側のJSON構造（toolsSettings.shell.allowedCommands）に合わせて調整
- _generate_template()相当の関数が必要（Kiro用テンプレートJSON生成）

## 実装優先度
High

## 見積もり
中規模（マージロジック実装 + jq/pythonフォールバック + テスト）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-22
- **完了日**: 2026-03-23
- **担当**: @ai
