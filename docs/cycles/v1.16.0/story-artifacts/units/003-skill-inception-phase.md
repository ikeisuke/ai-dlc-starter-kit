# Unit: Inception Phaseスキル化

## 概要

Inception Phaseプロンプトを `.claude/skills/` 形式のスキルとして再実装する。

## 含まれるユーザーストーリー

- ストーリー1: Inception Phaseスキル化

## 責務

- `prompts/package/skills/inception-phase/SKILL.md` を作成
- 共通モジュール（rules, review-flow, commit-flow, intro, project-info, compaction, phase-responsibilities, progress-management）を `references/` に含める
- AGENTS.md のルーティングを更新してスキル呼び出しに対応
- `~/.claude/skills/` 配置時の動作を確認

## 境界

- Construction Phase / Operations Phase のスキル化は含まない
- 既存の `prompts/package/prompts/inception.md` は変更しない（後方互換維持）

## 依存関係

### 依存する Unit

- なし（ただし Unit 004, 005 との共通設計方針を先行して決定するため、最初のスキル化Unitとして実装推奨）

### 外部依存

- Claude Code の `.claude/skills/` 仕様

## 非機能要件（NFR）

- **パフォーマンス**: スキル読み込み時間は既存プロンプト読み込みと同等
- **セキュリティ**: 該当なし
- **スケーラビリティ**: `~/.claude/skills/` に配置して複数リポジトリで再利用可能
- **可用性**: 該当なし

## 技術的考慮事項

- 既存の `inception.md` は `common/` ディレクトリのファイルを `【次のアクション】` で参照。スキル化時は `references/` に統合
- `docs/aidlc/bin/` スクリプトへの依存: スキルからは相対パス `docs/aidlc/bin/` を参照（リポジトリ内にデプロイ済み前提）
- SKILL.md の frontmatter: `description` に「start inception」「インセプション進めて」等のトリガー条件を記載
- 編集対象は `prompts/package/skills/inception-phase/`（メタ開発ルール）

## 関連Issue

- なし

## 実装優先度

High

## 見積もり

中規模（SKILL.md作成 + 共通モジュール統合 + AGENTS.md更新）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
