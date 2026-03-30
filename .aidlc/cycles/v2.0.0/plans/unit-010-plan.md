# Unit 010 実装計画: クリーンアップ・マイグレーション

## 概要

旧構造の削除と移行ガイド作成。ただし、ランタイム参照が多数残る `docs/aidlc/templates/`, `docs/aidlc/bin/`, `docs/aidlc/config/`, `docs/aidlc/skills/` および sync ソースの `prompts/package/` は、ステップファイルから20件以上の参照があるため本Unitでは削除せず、バックログに登録する。

## 削除対象（安全）

| 対象 | 理由 |
|------|------|
| `docs/aidlc/prompts/` | `skills/aidlc/steps/` に完全移行済み |
| `docs/aidlc/tests/` | `skills/aidlc/scripts/tests/` に移行済み |

## 削除見送り（要バックログ登録）

| 対象 | 残存参照数 | 理由 |
|------|-----------|------|
| `docs/aidlc/templates/` | 20+ | ステップファイルからのランタイム参照。ユーザープロジェクトの標準配置先 |
| `docs/aidlc/bin/` | 10+ | セットアップ・マイグレーションスクリプト参照 |
| `docs/aidlc/config/` | 3 | defaults.toml が read-config.sh から必要 |
| `docs/aidlc/skills/` | 10+ | ai-tools.md、セットアップのスキル同期 |
| `prompts/package/` | 20+ | セットアップのsyncソース |
| `prompts/setup-prompt.md` | 5 | preflight.md、operations、setup参照 |
| `.claude/skills/` symlinks | - | 現在有効なスキル参照（skills/ディレクトリへのリンク） |

## 作業一覧

### 1. 安全な削除

- `docs/aidlc/prompts/` ディレクトリ全体を削除
- `docs/aidlc/tests/` ディレクトリ全体を削除

### 2. ステップファイルの旧パス参照更新

`docs/aidlc/prompts/` への参照を更新:
- `steps/common/phase-responsibilities.md` — フェーズ説明のパス参照
- `steps/operations/operations-release.md` — 旧operations.md参照
- `steps/common/context-reset.md` — フェーズファイル参照
- `steps/inception/01-setup.md` — inception.md参照
- `skills/aidlc/CLAUDE.md`, `AGENTS.md` — 後方互換性文言更新

### 3. migration guide 作成

`docs/aidlc/guides/migration-v1-to-v2.md` を作成:
- v1→v2 の主要変更点
- フェーズプロンプトのスキル化
- パス変更一覧
- 移行手順

## 影響範囲

- `docs/aidlc/prompts/` (削除)
- `docs/aidlc/tests/` (削除)
- ステップファイル6箇所 (参照更新)
- `docs/aidlc/guides/migration-v1-to-v2.md` (新規)
