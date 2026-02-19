# Unit: Operations Phaseスキル化

## 概要

Operations Phaseプロンプトを `.claude/skills/` 形式のスキルとして再実装する。Unit 002で追加されたpush確認ステップを含む。

## 含まれるユーザーストーリー

- ストーリー3: Operations Phaseスキル化

## 責務

- `prompts/package/skills/operations-phase/SKILL.md` を作成
- 共通モジュールを `references/` に含める（Unit 003で確立したパターンに従う）
- Unit 002で追加された `6.6.6 リモート同期確認` ステップをスキル版にも反映
- AGENTS.md のルーティングを更新してスキル呼び出しに対応

## 境界

- Inception Phase / Construction Phase のスキル化は含まない
- 既存の `prompts/package/prompts/operations.md` は変更しない（後方互換維持、Unit 002の変更は除く）

## 依存関係

### 依存する Unit

- Unit 002: push確認ステップ追加（依存理由: Operations Phaseスキルは Unit 002 で変更された operations.md をベースに作成するため）
- Unit 003: Inception Phaseスキル化（依存理由: スキル化の共通設計パターンをUnit 003で確立し、それに従うため）

### 外部依存

- Claude Code の `.claude/skills/` 仕様

## 非機能要件（NFR）

- **パフォーマンス**: スキル読み込み時間は既存プロンプト読み込みと同等
- **セキュリティ**: 該当なし
- **スケーラビリティ**: `~/.claude/skills/` に配置して複数リポジトリで再利用可能
- **可用性**: 該当なし

## 技術的考慮事項

- Unit 003で確立した共通モジュール管理方式に従う
- Operations Phase固有のステップ（特に6.6.6 リモート同期確認）がスキル版でも正しく機能すること
- 編集対象は `prompts/package/skills/operations-phase/`（メタ開発ルール）

## 関連Issue

- なし

## 実装優先度

High

## 見積もり

中規模（Unit 003のパターンに従うため、003より作業量は少ない）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
