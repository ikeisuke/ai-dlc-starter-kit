# Unit 001 計画: aidlc-setupリネーム

## 概要

`upgrading-aidlc` スキルを `aidlc-setup` にリネームし、`upgrade-aidlc.sh` を `aidlc-setup.sh` にリネームする。関連する全参照箇所を更新し、旧名を完全削除する。

> **互換期間不要の根拠**: v1.19.0 で `upgrading-aidlc` は非推奨化済み（Unit定義 `001-rename-aidlc-setup.md` の「技術的考慮事項」に明記）。2サイクル以上経過しているため、互換エイリアスなしで即時削除する。

## 変更対象ファイル

### ディレクトリリネーム

| 変更前 | 変更後 |
|--------|--------|
| `prompts/package/skills/upgrading-aidlc/` | `prompts/package/skills/aidlc-setup/` |
| `docs/aidlc/skills/upgrading-aidlc/` | `docs/aidlc/skills/aidlc-setup/` |

### スクリプトリネーム

| 変更前 | 変更後 |
|--------|--------|
| `prompts/package/skills/aidlc-setup/bin/upgrade-aidlc.sh` | `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` |
| `docs/aidlc/skills/aidlc-setup/bin/upgrade-aidlc.sh` | `docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh` |

### シンボリックリンク更新

| 変更前 | 変更後 |
|--------|--------|
| `.claude/skills/upgrading-aidlc` → `../../docs/aidlc/skills/upgrading-aidlc` | `.claude/skills/aidlc-setup` → `../../docs/aidlc/skills/aidlc-setup` |
| `.kiro/skills/upgrading-aidlc` → `../../docs/aidlc/skills/upgrading-aidlc` | `.kiro/skills/aidlc-setup` → `../../docs/aidlc/skills/aidlc-setup` |

### 参照更新（prompts/package/ 側 = 編集対象）

| ファイル | 更新内容 |
|---------|---------|
| `prompts/package/skills/aidlc-setup/SKILL.md` | スキル名・スクリプトパス参照を更新 |
| `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` | スクリプト内のコメント・ログ出力のみ（パス参照は動的解決のため変更不要の見込み） |
| `prompts/package/guides/skill-usage-guide.md` | スキルディレクトリ名・パス参照を更新 |
| `prompts/package/guides/ai-agent-allowlist.md` | スキル名参照を更新 |
| `prompts/package/prompts/operations.md` | `/upgrading-aidlc` → `/aidlc-setup` |
| `prompts/package/prompts/common/ai-tools.md` | スキルパス参照を更新 |
| `prompts/package/prompts/inception.md` | ディレクトリツリー・スキル一覧を更新 |
| `prompts/setup-prompt.md` | ディレクトリツリー・スキル一覧を更新 |

### 参照更新（docs/aidlc/ 側 = rsyncコピー、現サイクル動作のため同期更新）

> **注意**: `prompts/package/` がSoT（Single Source of Truth）。`docs/aidlc/` はrsyncコピーだが、Operations Phaseまでrsyncが実行されないため、現サイクルの動作を保証するために同一内容を同期更新する。Operations Phase の rsync 実行時に `prompts/package/` から自動上書きされる。

| ファイル | 更新内容 |
|---------|---------|
| `docs/aidlc/skills/aidlc-setup/SKILL.md` | prompts/package/ 側と同等 |
| `docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh` | prompts/package/ 側と同等 |
| `docs/aidlc/guides/skill-usage-guide.md` | prompts/package/ 側と同等 |
| `docs/aidlc/guides/ai-agent-allowlist.md` | prompts/package/ 側と同等 |
| `docs/aidlc/prompts/operations.md` | prompts/package/ 側と同等 |
| `docs/aidlc/prompts/common/ai-tools.md` | prompts/package/ 側と同等 |
| `docs/aidlc/prompts/inception.md` | prompts/package/ 側と同等 |

### プロジェクト固有ファイル

| ファイル | 更新内容 |
|---------|---------|
| `docs/cycles/rules.md` | `/upgrading-aidlc` → `/aidlc-setup` |

### 変更しないファイル（歴史的参照）

- `README.md` - CHANGELOG記述内の歴史的参照
- `CHANGELOG.md` - 過去リリースの記述
- `docs/cycles/v1.14.0/` 〜 `docs/cycles/v1.20.2/` - 過去サイクルの成果物

## 実装計画

1. **ディレクトリ・ファイルリネーム**: `prompts/package/skills/upgrading-aidlc/` と `docs/aidlc/skills/upgrading-aidlc/` をリネーム
2. **スクリプトリネーム**: `upgrade-aidlc.sh` → `aidlc-setup.sh`（両ディレクトリ）
3. **SKILL.md更新**: スキル名・パス参照を更新（両ディレクトリ）
4. **aidlc-setup.sh更新**: 必要に応じてコメント・ログ出力を更新（両ディレクトリ）
5. **ドキュメント参照更新**: 上記一覧の全ファイルで `upgrading-aidlc` → `aidlc-setup`、`upgrade-aidlc` → `aidlc-setup` を更新
6. **シンボリックリンク更新**: 旧リンク削除→新リンク作成
7. **検証**: `grep -r upgrading-aidlc` および `grep -r upgrade-aidlc` で旧名残留がないことを確認（歴史的ファイルを除く）
8. **動作確認**: `readlink` でシンボリックリンク解決確認、`test -x` でスクリプト実行可能性確認、`--help` でスモークテスト実行

## 完了条件チェックリスト

- [ ] `prompts/package/skills/upgrading-aidlc/` → `prompts/package/skills/aidlc-setup/` のディレクトリリネーム完了
- [ ] `upgrade-aidlc.sh` → `aidlc-setup.sh` のスクリプトリネーム完了
- [ ] ai-tools.md, operations.md, inception.md, setup-prompt.md, skill-usage-guide.md, ai-agent-allowlist.md 等のスキル参照更新完了
- [ ] `docs/aidlc/` 側の同期更新完了（rsyncコピー）
- [ ] `docs/cycles/rules.md` のプロジェクト固有参照更新完了
- [ ] シンボリックリンクの更新完了（`.claude/skills/`, `.kiro/skills/`）
- [ ] 旧名の完全削除完了（`prompts/package/skills/`, `docs/aidlc/skills/`, `.claude/skills/`, `.kiro/skills/`）
- [ ] `grep -r` で旧名残留がないことを確認済み（歴史的ファイルを除く）
- [ ] シンボリックリンクが正しく解決されることを `readlink` で確認済み
- [ ] リネーム後のスクリプトが実行可能であることを確認済み（`test -x` + `--help` スモークテスト）
