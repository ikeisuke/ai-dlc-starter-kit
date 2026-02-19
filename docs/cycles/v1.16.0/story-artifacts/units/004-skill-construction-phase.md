# Unit: Construction Phaseスキル化

## 概要

Construction Phaseプロンプトを `.claude/skills/` 形式のスキルとして再実装する。

## 含まれるユーザーストーリー

- ストーリー2: Construction Phaseスキル化

## 責務

- `prompts/package/skills/construction-phase/SKILL.md` を作成
- 共通モジュールを `references/` に含める（Unit 003で確立したパターンに従う）
- AGENTS.md のルーティングにConstruction Phaseスキルを追加（Unit 003で確立した方式に従う）
- `~/.claude/skills/` 配置時の動作を確認（別リポジトリからの呼び出し）
- スキル未検出時のフォールバック案内を実装（Unit 003のパターンに従う）

## 境界

- Inception Phase / Operations Phase のスキル化は含まない
- 既存の `prompts/package/prompts/construction.md` は変更しない（後方互換維持）

## 依存関係

### 依存する Unit

- Unit 003: Inception Phaseスキル化（依存理由: スキル化の共通設計パターン・AGENTS.md更新方式をUnit 003で確立し、それに従うため）

### 外部依存

- Claude Code の `.claude/skills/` 仕様

## 非機能要件（NFR）

- **パフォーマンス**: スキル読み込み時間は既存プロンプト読み込みと同等
- **セキュリティ**: 該当なし
- **スケーラビリティ**: `~/.claude/skills/` に配置して複数リポジトリで再利用可能
- **可用性**: 該当なし

## 技術的考慮事項

- Unit 003で確立した共通モジュール管理方式に従う
- Construction Phase固有の参照（`construction.md` の `common/` 参照パターン）をスキル形式に変換
- AGENTS.md更新: Unit 003で確立したルーティング方式にConstruction Phaseエントリを追加（同一ファイルへの追記だが、Unit 003の後に実行するため競合なし）
- 編集対象は `prompts/package/skills/construction-phase/`（メタ開発ルール）

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
