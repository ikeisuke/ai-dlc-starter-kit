# Unit 008 計画: aidlc-upgradeスキル改善

## 概要

aidlc-upgradeスキルをagentskills.ioベストプラクティスに準拠させる。命名パターンの統一（`reviewing-*`, `versioning-with-*` に合わせて `upgrading-aidlc` にリネーム）、description三人称化、setup-prompt.md検索フロー効率化を実施する。

**スコープ拡張**: Unit定義の「nameがagentskills.io仕様を満たすことを確認・修正」に加え、ユーザー指示によりプロジェクト内の命名パターン統一のためのスキル名リネーム（`aidlc-upgrade` → `upgrading-aidlc`）をUnit 008のスコープに含める。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|----------|
| `prompts/package/skills/aidlc-upgrade/` → `prompts/package/skills/upgrading-aidlc/` | ディレクトリリネーム |
| `prompts/package/skills/upgrading-aidlc/SKILL.md` | frontmatter修正（name + description）+ 検索フロー記述追加 |
| `docs/cycles/v1.14.0/story-artifacts/units/008-improve-aidlc-upgrade.md` | Unit定義にスコープ拡張（リネーム）を追記 |
| `docs/cycles/v1.14.0/story-artifacts/units/009-docs-and-links.md` | Unit 009定義内の `aidlc-upgrade` → `upgrading-aidlc` 参照更新 |

**注意**:

- `docs/aidlc/skills/aidlc-upgrade/` は `prompts/package/` のrsyncコピーのため直接編集しない。
- Operations Phaseでrsync実行時に `prompts/package/skills/upgrading-aidlc/` → `docs/aidlc/skills/upgrading-aidlc/` として反映される。**現サイクル中は旧パス `docs/aidlc/skills/aidlc-upgrade/` が残存するため、既存の `.claude/skills/aidlc-upgrade` シンボリックリンク経由でのスキル呼び出しは引き続き動作する。**
- 受け入れ基準の検証は `prompts/package/` 側のファイルに対して実施する。
- `.claude/skills/` シンボリックリンク、AGENTS.md、rules.md等の参照更新はUnit 009のスコープ。

## 実装計画

### 1. ディレクトリリネーム

```bash
\mv prompts/package/skills/aidlc-upgrade prompts/package/skills/upgrading-aidlc
```

### 2. frontmatter修正

**name**: `aidlc-upgrade` → `upgrading-aidlc`（ディレクトリ名と一致させる）

**description**: 三人称に変更

- 現在: `AI-DLC環境をアップグレードする。スターターキットの最新バージョンにプロンプト・テンプレートを更新。「AIDLCアップデート」「update aidlc」「start upgrade」と指示された場合に使用。`
- 変更後: `Upgrades the AI-DLC environment to the latest version. Syncs prompts and templates from the starter kit. Use when the user says "AIDLCアップデート", "update aidlc", or "start upgrade".`

### 3. 検索フロー記述の追加

SKILL.md本文の「実行方法」セクションを更新し、setup-prompt.mdの検索フローを明記する:

1. `prompts/setup-prompt.md` の存在確認を1回実行
2. 存在する場合 → そのまま読み込み
3. 存在しない場合 → `docs/aidlc.toml` から `starter_kit_path` を取得し、`ghq root` 経由でパスを解決
4. Glob等の再帰検索は行わない

### 4. Unit定義の更新

- Unit 008定義にスコープ拡張（リネーム追加）を追記
- Unit 009定義ファイル内の `aidlc-upgrade` 参照を `upgrading-aidlc` に更新

## 検証手順

| 完了条件 | 検証方法 |
|---------|----------|
| nameが小文字英数字+ハイフン | `grep '^name:' prompts/package/skills/upgrading-aidlc/SKILL.md` で `upgrading-aidlc` であることを確認 |
| descriptionが三人称 | `grep '^description:' prompts/package/skills/upgrading-aidlc/SKILL.md` で三人称動詞（Upgrades等）で始まることを確認 |
| 検索フロー記載 | SKILL.md本文に「存在確認」「1回」のフローステップが記載されていることを目視確認 |
| 再帰検索禁止の明記 | SKILL.md本文に「Glob等の再帰検索は行わない」旨の禁止記述が含まれていることを確認（`grep '再帰検索' prompts/package/skills/upgrading-aidlc/SKILL.md`） |
| 旧ディレクトリ削除確認 | `ls prompts/package/skills/aidlc-upgrade 2>/dev/null` でエラーになること |

## 完了条件チェックリスト

- [ ] SKILL.md frontmatterのnameが小文字英数字+ハイフンのみで構成されている（`upgrading-aidlc`）
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている
- [ ] SKILL.mdに検索フローが記載されている: (1) `prompts/setup-prompt.md` 存在確認を1回実行 (2) 不在時は `docs/aidlc.toml` 経由で解決 (3) Glob等の再帰検索は行わない
