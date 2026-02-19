# Unit: Inception Phaseスキル化

## 概要

Inception Phaseプロンプトを `.claude/skills/` 形式のスキルとして再実装する。

## 含まれるユーザーストーリー

- ストーリー1: Inception Phaseスキル化

## 責務

- `prompts/package/skills/inception-phase/SKILL.md` を作成
- 共通モジュール（rules, review-flow, commit-flow, intro, project-info, compaction, phase-responsibilities, progress-management）を `references/` に含める
- AGENTS.md のルーティングを更新してスキル呼び出しに対応（3フェーズ共通方式を確立）
- `~/.claude/skills/` 配置時の動作を確認（別リポジトリからの呼び出し）
- スキル未検出時のフォールバック案内を実装
- `docs/aidlc/bin/` 未デプロイ時の `upgrading-aidlc` 実行案内を実装

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
- `docs/aidlc/bin/` スクリプトへの依存: スキルはリポジトリの `docs/aidlc/bin/` が存在する前提で動作する。グローバルスキル（`~/.claude/skills/`）利用時も、対象リポジトリで `upgrading-aidlc` スキルによるデプロイが完了していることが前提条件。スキル初回呼び出し時に `docs/aidlc/bin/` の存在を確認し、未デプロイの場合は `upgrading-aidlc` の実行を案内する
- SKILL.md の frontmatter: `description` に「start inception」「インセプション進めて」等のトリガー条件を記載
- AGENTS.md のルーティング更新: 本Unitで3フェーズ共通のルーティング方式を確立し、Unit 004/005はその方式に従う
- スキル未検出時のフォールバック: スキルが利用不可の場合、従来の `docs/aidlc/prompts/inception.md` 読み込みを案内
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
