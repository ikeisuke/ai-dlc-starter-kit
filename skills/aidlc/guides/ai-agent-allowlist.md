# AIエージェント許可リストガイド

AI-DLCで使用するコマンドの許可リストと各AIエージェントの設定方法。

## 重要な注意事項

- **Git hooks/aliasのリスク**: `.git/hooks/` や `git config alias.*` で任意コード実行の可能性あり
- **データ漏洩リスク**: 読み取り専用コマンドでもネットワーク環境ではリスクあり

---

## 推奨アプローチ

| アプローチ | 概要 | 推奨度 |
|-----------|------|--------|
| A: 許可リスト + denylist | 個別コマンド制御 | △ シェル演算子で都度承認 |
| B: sandbox環境 | Docker等で被害限定 | ◎ 推奨 |

**警告**: `danger-full-access` + `approval-policy: "never"` はprompt injection時に被害拡大。`--dangerously-skip-permissions` はコンテナ内のみ。

---

## コマンドカテゴリ

### 読み取り専用（許可推奨）

| コマンド | 説明 |
|---------|------|
| `git status/log/branch/diff/show/rev-parse/show-ref/worktree list/remote -v` | Git読み取り系 |
| `ls/cat/head/tail/grep/rg/find/jq/date/pwd/command -v` | ファイル・システム系 |
| `gh auth status/pr list/pr view/issue list` | GitHub CLI読み取り系 |

### 作成系（許可推奨）

`git checkout -b`, `git switch -c`, `git worktree add`, `git add`, `mkdir -p`, `touch`

### Git操作（条件付き許可）

`git commit`（hooks実行）, `git push`（hooks実行）, `git checkout`, `git stash`, `gh pr create/ready`

### 破壊的操作（注意が必要）

`git branch -d/-D`, `git tag -d`, `git worktree remove`, `tee`, `gh pr merge`, `gh release create`

### 除外対象（許可非推奨、askに配置）

`git push --force/-f`, `git reset --hard`, `git clean -fd`, `git rebase -i`, `rm -rf`, `curl/wget`

**例外**: スターターキットGitHub raw URLに限定して `curl` を許可する場合はURLパターンを厳密に指定。

---

## Claude Code 設定

**設定ファイル**: `.claude/settings.json`（プロジェクト共有）、`.claude/settings.local.json`（個人）、`~/.claude/settings.json`（ユーザー全体）

**優先順位**: `deny`（最優先）→ `ask` → `allow`

**ワイルドカード**: `:*`=プレフィックスマッチ、`*`=任意位置マッチ、なし=完全一致

### ミニマル推奨セット

**相対パスを使用すること**（worktree環境・チーム共有・テンプレート化のため）。

**AI-DLCスクリプト**（1エントリで全スクリプトカバー）:

```json
"Bash(skills/aidlc/scripts/:*)"
```

**allow**:

```json
{
  "permissions": {
    "allow": [
      "Bash(skills/aidlc/scripts/:*)",
      "Bash(git status)", "Bash(git branch:*)", "Bash(git log:*)",
      "Bash(git diff:*)", "Bash(git show:*)", "Bash(git rev-parse:*)",
      "Bash(git remote:*)", "Bash(git worktree list)",
      "Bash(git add:*)", "Bash(git commit -m:*)", "Bash(git push:*)",
      "Bash(git checkout:*)", "Bash(git switch:*)", "Bash(git stash:*)",
      "Bash(git worktree add:*)", "Bash(git reset --soft:*)",
      "Bash(ls:*)", "Bash(cat:*)", "Bash(grep:*)", "Bash(mkdir:*)",
      "Bash(command -v:*)", "Bash(date)", "Bash(jq:*)",
      "Bash(gh auth status)", "Bash(gh pr list:*)", "Bash(gh pr view:*)",
      "Bash(gh pr create:*)", "Bash(gh pr ready:*)",
      "Bash(gh issue list:*)", "Bash(gh issue view:*)", "Bash(gh issue create:*)",
      "Bash(curl * https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/*)",
      "Bash(npx markdownlint-cli2:*)",
      "Skill(reviewing-inception-intent)", "Skill(reviewing-inception-stories)",
      "Skill(reviewing-inception-units)", "Skill(reviewing-construction-plan)",
      "Skill(reviewing-construction-design)", "Skill(reviewing-construction-code)",
      "Skill(reviewing-construction-integration)",
      "Skill(reviewing-operations-deploy)", "Skill(reviewing-operations-premerge)",
      "WebSearch"
    ],
    "ask": [
      "Bash(rm -rf:*)", "Bash(git push --force:*)", "Bash(git push -f:*)",
      "Bash(git push --force-with-lease:*)", "Bash(git reset --hard:*)",
      "Bash(git clean:*)", "Bash(wget:*)",
      "Bash(gh api:*)", "Bash(gh pr merge:*)", "Bash(gh release create:*)"
    ],
    "deny": [
      "Read(.env)", "Read(.env.*)", "Read(~/.ssh/**)", "Read(~/.aws/**)"
    ]
  }
}
```

**設定のポイント**:
- `git commit -m:*` で `-m` 必須（`--amend` 除外）
- `git push:*` はallow、`--force`系はaskで制御（後置フラグすり抜けリスクあり、セキュリティ優先ならaskに移動）
- `gh api:*` はDELETE含む全メソッド許可のためaskに配置

### オプション追加

| パターン | いつ必要か | リスク |
|---------|-----------|--------|
| `Bash(claude:*)` | Claudeサブプロセスでレビュー時 | ask推奨。プロンプト注入リスク |
| `Bash(dasel:*)` | TOML設定読み取り時 | 書き込みも許可される |

### deny追加候補

| パターン | 保護対象 |
|---------|---------|
| `Read(.envrc)` | direnv環境変数 |
| `Read(~/.config/gh/**)` | GitHub CLIトークン |
| `Read(~/.npmrc)` | npmトークン |
| `Read(**/*.pem)`, `Read(**/*.key)` | 証明書・秘密鍵 |

---

## Kiro CLI 設定

**設定ファイル**: `~/.kiro/settings.json`（macOS）、`~/.config/kiro/settings.json`（Linux）

```json
{
  "toolSettings": {
    "shell": {
      "allowedCommands": [
        "git status", "git log", "git diff", "git branch --show-current",
        "git add", "ls", "cat", "mkdir", "date"
      ],
      "deniedCommands": [
        "&&", "||", ";", "|",
        "rm -rf", "git push --force", "git reset --hard", "git clean",
        "curl", "wget"
      ],
      "autoAllowReadonly": true
    }
  }
}
```

**注意**: `deniedCommands` はsubstring matching。`&` を拒否すると `2>&1` もブロックされる。

---

## セキュリティ注意事項

### シェル演算子

| パターン | 承認 | 対策 |
|----------|------|------|
| `&&`, `\|\|`, `;`, `\|` | 条件付き | プロジェクト内パスなら許可される場合あり |
| `&>/dev/null` | **必要** | `>/dev/null 2>&1` に置換 |
| `>/dev/null`, `2>/dev/null` | 不要 | そのまま使用可 |

### ワイルドカードの限界

`Bash(git:*)` は変数経由・プロセス置換・コマンド置換でバイパス可能。

### 推奨対策

1. sandbox環境での実行（最も安全）
2. 破壊的コマンドを `ask` に配置
3. 機密ファイルは `deny` で完全ブロック
4. 定期的な許可リストレビュー

---

## 参考リンク

- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Kiro CLI Settings](https://kiro.dev/docs/cli/reference/settings/)
- [Kiro CLI Permissions](https://kiro.dev/docs/cli/chat/permissions/)
