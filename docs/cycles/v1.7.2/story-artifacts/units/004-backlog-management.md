# Unit: バックログ管理改善

## 概要
バックログ管理機能を改善し、モード対応と方針の明文化を行う。

## 含まれるユーザーストーリー
- ストーリー 3-1: バックログ移行処理のモード対応 (#38)
- ストーリー 3-2: AGENTS.mdへのバックログ管理方針追加 (#41)
- ストーリー 3-3: backlog.modeに"git-only"/"issue-only"オプション追加 (ローカル)

## 責務
- バックログ移行時にmodeに応じた適切な移行先を提案
- AGENTS.mdにバックログ管理方針（mode設定と保存先の対応表）を記載
- aidlc.tomlのbacklog.modeに"git-only"/"issue-only"オプションを追加
- 各フェーズプロンプトで排他モード（*-only）を参照

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
- **編集対象**:
  - `prompts/package/prompts/AGENTS.md`（テンプレート側。Operations Phaseでrsyncにより`docs/aidlc/prompts/AGENTS.md`に反映）
  - `prompts/setup-prompt.md` のaidlc.tomlテンプレートにgit-only/issue-onlyオプションを追加
  - `prompts/package/prompts/inception.md`, `construction.md`, `operations.md` で排他モード（*-only）を参照
- **注意**: `docs/aidlc/` は直接編集禁止。必ず `prompts/package/` を編集すること
- 旧形式（backlog.md）からの移行ロジックをmode対応に修正

## 実装優先度
Medium

## 見積もり
AI-DLCでは見積もりを行わない

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-13
- **完了日**: -
- **担当**: @ai
