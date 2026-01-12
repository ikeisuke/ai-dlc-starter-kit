# Unit: バックログ管理改善

## 概要
バックログ管理機能を改善し、モード対応と方針の明文化を行う。

## 含まれるユーザーストーリー
- ストーリー 3-1: バックログ移行処理のモード対応 (#38)
- ストーリー 3-2: AGENTS.mdへのバックログ管理方針追加 (#41)
- ストーリー 3-3: backlog.single_sourceオプション追加 (ローカル)

## 責務
- バックログ移行時にmodeに応じた適切な移行先を提案
- AGENTS.mdにバックログ管理方針（mode設定と保存先の対応表）を記載
- aidlc.tomlにbacklog.single_sourceオプションを追加
- 各フェーズプロンプトでsingle_source設定を参照

## 境界
- バックログの新規作成UIは対象外
- GitHub Issues連携のAPI呼び出し部分は既存を利用

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub CLI（gh）: Issue操作に使用

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- prompts/package/prompts/AGENTS.md にバックログ管理セクションを追加
- prompts/setup-prompt.md のaidlc.tomlテンプレートにsingle_sourceオプションを追加
- prompts/package/prompts/inception.md, operations.md でsingle_source設定を参照
- 旧形式（backlog.md）からの移行ロジックをmode対応に修正

## 実装優先度
Medium

## 見積もり
AI-DLCでは見積もりを行わない

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
