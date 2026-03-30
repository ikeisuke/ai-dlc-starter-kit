# Unit: session-titleスキル移行

## 概要
session-titleスキルをai-dlc-starter-kitから削除し、各フェーズプロンプトの参照をclaude-skillsリポジトリからのインストール案内に更新する。

## 含まれるユーザーストーリー
- ストーリー 1: session-titleスキルの外部リポジトリ移行

## 責務
- prompts/package/skills/session-title/ ディレクトリの削除
- inception.md, construction.md, operations.md のsession-title呼び出し箇所の更新
- common/ai-tools.md, guides/skill-usage-guide.md の参照更新

## 境界
- claude-skillsリポジトリ側の作業は含まない
- session-titleの不具合修正（#328）は含まない（外部リポジトリ側で対応）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし（claude-skills側の作業は本サイクルの完了条件外）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- メタ開発ルール: prompts/package/ を編集すること
- session-titleはオプション機能。削除後も各フェーズは正常に動作する（既存仕様）
- 参照箇所: inception.md L176, construction.md L208/L311, operations.md L148, ai-tools.md L29/L63, skill-usage-guide.md L40/L82-83/L100/L128

## 関連Issue
- #333, #328

## 実装優先度
Medium

## 見積もり
小〜中（複数ファイルの参照更新）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-15
- **完了日**: 2026-03-15
- **担当**: -
