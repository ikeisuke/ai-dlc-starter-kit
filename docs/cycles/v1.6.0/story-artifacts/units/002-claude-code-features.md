# Unit: Claude Code機能活用

## 概要
Claude Code固有の機能（AskUserQuestion、AGENTS.md）を活用し、開発者体験を向上させる。

## 含まれるユーザーストーリー
- ストーリー3: AskUserQuestion機能の活用
- ストーリー4: AGENTS.mdによるプロンプト自動解決

## 責務
- CLAUDE.mdにAskUserQuestion活用ルールを追記
- AGENTS.mdによるプロンプト自動解決の検証と文書化
- **【追加】** CLAUDE.md/AGENTS.mdテンプレートの配置場所修正とセットアップフローへのコピー処理追加

## 境界
- CLAUDE.md、AGENTS.md のみを対象
- 各プロンプトファイルへの記載は行わない（Claude Code固有設定はCLAUDE.mdに集約）
- **【追加】** setup-prompt.md（テンプレートコピー処理追加）

## 依存関係

### 依存する Unit
- なし（独立して実装可能）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- AskUserQuestionは選択肢が明確な場合に使用
- 自由回答が必要な場合はテキストで質問
- AGENTS.mdの参照により、AIが自動的に適切なプロンプトを読み込めるか検証が必要
- **【追加】** CLAUDE.md/AGENTS.mdテンプレートの配置:
  - 現在: `prompts/package/templates/` （rsync対象、不適切）
  - 変更後: `prompts/setup/templates/` （初回のみコピー、rsync対象外）
- **【追加】** setup-prompt.mdにコピー処理追加（rules.mdと同様、存在しない場合のみコピー）

## 実装優先度
Medium

## 見積もり
1時間

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
