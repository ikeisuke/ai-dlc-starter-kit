# Unit: アップグレードスキル化

## 概要
アップグレード処理（setup-prompt.md）をスキルとして定義し、`/upgrade`コマンドで呼び出せるようにする。

## 含まれるユーザーストーリー
- ストーリー8: アップグレード処理のスキル化

## 責務
- `docs/aidlc/skills/upgrade/SKILL.md`の新規作成
- AGENTS.mdへのスキル参照追加

## 境界
- setup-prompt.md自体の内容変更はUnit 003で対応済み
- 他のスクリプトのスキル化は含まない

## ソースファイル管理
- **新規作成**: `prompts/package/skills/upgrade/SKILL.md`（ソース）
- **修正対象**: `prompts/package/prompts/AGENTS.md`（スキル参照追加）
- **同期先**: `docs/aidlc/skills/upgrade/SKILL.md`、`docs/aidlc/prompts/AGENTS.md` はrsync同期で自動更新（Operations Phaseで実施）
- このリポジトリはメタ開発のため、`prompts/package/`がソースオブトゥルース

## 依存関係

### 依存するUnit
- Unit 003: setup-prompt.md関連の変更（依存理由: スキルがsetup-prompt.mdを参照するため、Unit 003で旧形式バックログ移行の追加と完了メッセージの更新が完了している必要がある）

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 既存のスキル（codex-review等）の構造を参考にする
- スキルはsetup-prompt.mdへのリダイレクト的な役割
- rsync同期のためprompts/package/skills/配下に作成

## 実装優先度
Medium（Should-have）

## 見積もり
小規模（新規ファイル1つ + AGENTS.md更新）

## 関連Issue
- #133（部分）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-05
- **完了日**: 2026-02-05
- **担当**: Claude
