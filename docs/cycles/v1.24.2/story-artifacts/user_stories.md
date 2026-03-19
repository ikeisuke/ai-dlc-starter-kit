# ユーザーストーリー

## Epic: rsync許可ルールの簡素化

### ストーリー 1: rsync個別許可ルールの削除
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to AIエージェントの許可ルールからrsync個別許可（`Bash(rsync *)`）を削除したい
So that rsyncコマンドへの直接アクセス許可というセキュリティリスクを排除できる

**受け入れ基準**:
- [ ] `ai-agent-allowlist.md` から `Bash(rsync * docs/aidlc/prompts/)`、`Bash(rsync * docs/aidlc/templates/)`、`Bash(rsync * docs/aidlc/guides/)` の3行が削除されている
- [ ] rsyncの直接実行許可に代わる説明（スクリプト経由での実行で許可が代替される旨）が記載されている
- [ ] 既存の同期機能（`aidlc-setup.sh`、`sync-package.sh`）が正常に動作する（スクリプト実行の許可で十分であることの確認）

**技術的考慮事項**:
- rsyncは既に `sync-package.sh` と `aidlc-setup.sh` 内に閉じ込められている
- スクリプト実行（`Bash(docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh:*)`等）の許可があればrsync個別許可は不要
- `_has_file_diff()` 内のrsync dry-runもスクリプト内で完結している
