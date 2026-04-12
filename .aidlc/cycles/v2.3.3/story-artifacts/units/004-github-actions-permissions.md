# Unit: GitHub Actions permissions追加

## 概要
pr-check.ymlとmigration-tests.ymlにワークフローレベルのpermissionsブロックを追加し、code-scanningアラートを解消する。

## 含まれるユーザーストーリー
- ストーリー 4: GitHub Actions permissions追加

## 責務
- pr-check.ymlへのpermissions定義追加
- migration-tests.ymlへのpermissions定義追加

## 境界
- 他のワークフロー（skill-reference-check.yml, auto-tag.yml）は既にpermissions定義済みのため対象外
- ワークフローのロジック・ジョブ内容の変更は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub Actions（permissions仕様）

## 非機能要件（NFR）
- **セキュリティ**: 最小権限原則に従ったpermissions設定
- **可用性**: 既存ジョブが権限不足で失敗しないこと

## 技術的考慮事項
- skill-reference-check.yml（`contents: read`）を参考モデルとする
- pr-check.ymlの3ジョブ（markdown-lint, bash-substitution-check, defaults-sync-check）はすべて読み取りのみ
- migration-tests.ymlのジョブ（migration-tests）も読み取りのみ
- workflow-level定義をjobが継承する前提で成功基準を満たす（job-level個別定義は不要）

## 関連Issue
- code-scanning アラート #1, #3, #5, #6

## 実装優先度
High

## 見積もり
XS（YAMLファイルにpermissionsブロックを追加するのみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-12
- **完了日**: 2026-04-12
- **担当**: Claude
- **エクスプレス適格性**: -
- **適格性理由**: -
