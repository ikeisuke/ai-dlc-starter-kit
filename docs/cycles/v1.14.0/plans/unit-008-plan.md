# Unit 008 計画: aidlc-upgradeスキル改善

## 概要

aidlc-upgradeスキルのSKILL.md frontmatterをagentskills.ioベストプラクティスに準拠させ、setup-prompt.md検索フローを効率化する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|----------|
| `prompts/package/skills/aidlc-upgrade/SKILL.md` | frontmatter修正 + 検索フロー記述追加 |

**注意**: `docs/aidlc/skills/aidlc-upgrade/SKILL.md` は `prompts/package/` のrsyncコピーのため、`prompts/package/` 側のみ編集する。

## 実装計画

### 1. frontmatter修正

**name**: `aidlc-upgrade` → 変更不要（小文字英数字+ハイフンの仕様を満たしている）

**description**: 三人称に変更

- 現在: `AI-DLC環境をアップグレードする。スターターキットの最新バージョンにプロンプト・テンプレートを更新。「AIDLCアップデート」「update aidlc」「start upgrade」と指示された場合に使用。`
- 変更後: `Upgrades the AI-DLC environment to the latest version. Syncs prompts and templates from the starter kit. Use when the user says "AIDLCアップデート", "update aidlc", or "start upgrade".`

### 2. 検索フロー記述の追加

SKILL.md本文の「実行方法」セクションを更新し、setup-prompt.mdの検索フローを明記する:

1. `prompts/setup-prompt.md` の存在確認を1回実行
2. 存在する場合 → そのまま読み込み
3. 存在しない場合 → `docs/aidlc.toml` から `starter_kit_path` を取得し、`ghq root` 経由でパスを解決
4. Glob等の再帰検索は行わない

## 完了条件チェックリスト

- [ ] SKILL.md frontmatterのnameが小文字英数字+ハイフンのみで構成されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている
- [ ] SKILL.mdに検索フローが記載されている: (1) `prompts/setup-prompt.md` 存在確認を1回実行 (2) 不在時は `docs/aidlc.toml` 経由で解決 (3) Glob等の再帰検索は行わない
