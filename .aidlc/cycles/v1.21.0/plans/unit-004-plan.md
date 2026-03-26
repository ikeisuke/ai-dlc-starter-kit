# Unit 004 計画: jj関連コード削除

## 概要

jj（Jujutsu）VCSに関連するコードをスターターキット本体から完全に削除する。v1.19.0で非推奨化済み。

## 変更対象ファイル

### 削除対象

| ファイル/ディレクトリ | 種類 |
|---|---|
| `prompts/package/skills/versioning-with-jj/` | ディレクトリ（SKILL.md, references/jj-support.md） |
| `docs/aidlc/skills/versioning-with-jj/` | ミラーディレクトリ |
| `.claude/skills/versioning-with-jj` | シンボリックリンク |
| `.kiro/skills/versioning-with-jj` | シンボリックリンク |

### 修正対象（prompts/package/ = SoT）

#### スクリプト（prompts/package/bin/）

| ファイル | 修正内容 |
|---|---|
| `prompts/package/bin/aidlc-git-info.sh` | `.jj`検出・`jj log`/`jj diff`分岐の削除 |
| `prompts/package/bin/aidlc-cycle-info.sh` | jj検出と`jj log -r @`分岐の削除 |
| `prompts/package/bin/squash-unit.sh` | `--vcs jj`オプション、`find_base_commit_jj()`、`squash_jj()`の削除 |
| `prompts/package/bin/aidlc-env-check.sh` | `jj`コマンドチェックの削除 |
| `prompts/package/bin/env-info.sh` | jjツールチェック・bookmark検出の削除 |
| `prompts/package/bin/migrate-config.sh` | `[rules.jj]`セクション追加処理の削除 |

#### プロンプト（prompts/package/prompts/）

| ファイル | 修正内容 |
|---|---|
| `prompts/package/prompts/common/rules.md` | jjサポート設定セクションの削除 |
| `prompts/package/prompts/common/ai-tools.md` | versioning-with-jjスキル登録の削除 |
| `prompts/package/prompts/common/commit-flow.md` | jj環境の手順参照の削除 |
| `prompts/package/prompts/operations.md` | jjタグ操作注意の削除 |
| `prompts/package/prompts/inception.md` | jjステータス行・jj環境参照の削除 |
| `prompts/package/prompts/construction.md` | jj環境参照の削除 |

#### 設定（config）

| ファイル | 修正内容 |
|---|---|
| `docs/aidlc.toml` | `[rules.jj]`セクションの削除 |
| `prompts/package/config/defaults.toml` | `[rules.jj]`セクションの削除 |

#### スキル

| ファイル | 修正内容 |
|---|---|
| `prompts/package/skills/squash-unit/SKILL.md` | `rules.jj.enabled`参照の削除 |
| `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` | jj設定検出時の移行案内を追加 |

#### ガイド（prompts/package/guides/ = SoT）

| ファイル | 修正内容 |
|---|---|
| `prompts/package/guides/config-merge.md` | jj設定マージ例の削除 |
| `prompts/package/guides/skill-usage-guide.md` | versioning-with-jjスキル記載の削除 |
| `prompts/package/guides/ai-agent-allowlist.md` | jjコマンドのallowlist削除 |

#### セットアップ系

| ファイル | 修正内容 |
|---|---|
| `prompts/setup-prompt.md` | jj関連記述の削除 |
| `prompts/setup/templates/aidlc.toml.template` | `[rules.jj]`セクションの削除 |

### 退避対象

| ファイル | 退避先 |
|---|---|
| `prompts/package/skills/versioning-with-jj/` 一式 | `docs/cycles/v1.21.0/jj-backup/` |

### docs/aidlc/側（ミラー同期）

`docs/aidlc/` は `prompts/package/` のrsyncコピー（SoT = prompts/package/）。Operations Phaseの`/aidlc-setup`実行で正式同期されるが、開発中はプロンプトが直接参照されるため以下を手動同期する:

- `docs/aidlc/prompts/common/rules.md`
- `docs/aidlc/prompts/common/ai-tools.md`
- `docs/aidlc/prompts/common/commit-flow.md`
- `docs/aidlc/prompts/operations.md`
- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/construction.md`
- `docs/aidlc/config/defaults.toml`
- `docs/aidlc/skills/squash-unit/SKILL.md`
- `docs/aidlc/guides/config-merge.md`
- `docs/aidlc/guides/skill-usage-guide.md`
- `docs/aidlc/guides/ai-agent-allowlist.md`

## 実装計画

1. **削除前退避**: versioning-with-jjスキルファイルを `docs/cycles/v1.21.0/jj-backup/` に退避
2. **スキルディレクトリ・シンボリックリンクの削除**
3. **スクリプトからjj関連コードの削除**（6ファイル）
4. **設定ファイルのjjセクション削除**（docs/aidlc.toml, defaults.toml）
5. **プロンプトファイルのjj参照削除**（6ファイル）
6. **スキルファイルのjj参照削除**（squash-unit SKILL.md）
7. **ガイドファイルのjj参照削除**（3ファイル）
8. **aidlc-setup.shにjj設定検出時の移行案内を追加**
9. **docs/aidlc/側のミラーファイル同期編集**
10. **残留確認**: `prompts/package/`全体 + `docs/aidlc/` + `docs/aidlc.toml` を対象に検索。除外対象は `docs/cycles/v1.21.0/jj-backup/` と `docs/cycles/*/history/` のみ

## 完了条件チェックリスト

- [ ] 削除前退避: versioning-with-jjの移行元ファイル一式を `docs/cycles/v1.21.0/jj-backup/` に退避・記録
- [ ] `prompts/package/skills/versioning-with-jj/` ディレクトリの削除
- [ ] 各スクリプトからjj関連コードの削除（aidlc-git-info.sh, aidlc-cycle-info.sh, squash-unit.sh, aidlc-env-check.sh, env-info.sh, migrate-config.sh）
- [ ] 設定ファイルの `[rules.jj]` セクション削除（docs/aidlc.toml, defaults.toml）
- [ ] プロンプトファイル（rules.md, commit-flow.md, ai-tools.md, operations.md, inception.md, construction.md）のjj参照削除
- [ ] スキルファイル（squash-unit SKILL.md）のjj参照削除
- [ ] ガイドファイル（config-merge.md, skill-usage-guide.md, ai-agent-allowlist.md）のjj参照削除
- [ ] シンボリックリンク削除（.claude/skills/versioning-with-jj, .kiro/skills/versioning-with-jj）
- [ ] `aidlc-setup.sh` にjj設定検出時の移行案内を追加
- [ ] 実行系ファイル + docs/aidlc/ を対象にjj関連コード残留なしを確認（退避先・履歴は除外）
