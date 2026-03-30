# Unit 003 計画: 旧パス参照一掃・スタイル統一

## 概要

Unit 002で対応しきれない旧パス参照の残りを一掃し、CLAUDE.md/AGENTS.mdの`@`参照スタイルを統一する。

## 変更対象

### 1. `prompts/setup-prompt.md` マイグレーション先修正（#414 D1）

マイグレーションコード内の `docs/cycles/rules.md` → `.aidlc/cycles/rules.md` に更新。
v2ではサイクルデータは `.aidlc/cycles/` に格納されるため。

### 2. `@` 参照スタイル統一（#414 D2）

`skills/aidlc/CLAUDE.md` の `@steps/common/compaction.md` を `` @`steps/common/compaction.md` `` に変更。
AGENTS.mdのバッククォート付きスタイルに統一。

### 3. ユーザー向け参照更新（#415 B6）

| ファイル | 現状 | 修正後 |
|---------|------|--------|
| `skills/aidlc/templates/index.md:17` | `prompts/setup-prompt.md` パス表示 | `/aidlc setup` コマンド |
| `skills/aidlc/steps/operations/04-completion.md:178` | `prompts/setup-prompt.md` フォールバック | `/aidlc setup` |

### 4. v1互換コード明示化（#415 D1-D3）

`prompts/setup-prompt.md` のv1マイグレーションブロックに `v1互換コード` コメントを追加。

### 5. 非AIDLCプロジェクトガード確認（#414 D4）

確認済み: `skills/aidlc/AGENTS.md` のガードは `.aidlc/config.toml` 存在チェックで正しく実装。対応不要。

## 除外事項

- `docs/aidlc/guides/` 参照（`skills/` 内）: ユーザープロジェクトでの正しいデプロイパス
- `prompts/setup-prompt.md` の実装パス参照（`skills/aidlc-setup/SKILL.md`, `setup/02-generate-config.md`）: 実ファイルパス

## 完了条件

- [x] `docs/cycles/` 参照が `prompts/setup-prompt.md` から0件（`.aidlc/cycles/` に更新）
- [x] `@` 参照スタイルが統一（バッククォート付き）
- [x] ユーザー向け `prompts/setup-prompt.md` 参照が `/aidlc setup` に更新（skills/のみ、prompts/package/はv1スタイル維持）
- [x] v1互換コードにコメント付与
- [x] #414 D4 ガード確認済み
