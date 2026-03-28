# AIエージェント許可リストガイド

AI-DLCで使用するコマンドの許可リストと、各AIエージェントの設定方法をまとめたガイドです。

---

## 1. はじめに

### 目的

AI-DLCでは多くのGitコマンドやファイル操作を実行します。毎回の確認は開発体験を損なうため、安全なコマンドを許可リストに登録することで効率的に開発できます。

### 適用範囲

- Claude Code
- Kiro CLI

### 重要な注意事項

- **Git hooks/aliasのリスク**: Gitコマンドは `.git/hooks/` のスクリプトや `git config --global alias.*` で任意のコードを実行できます。許可リストに登録しても、hooksやaliasを通じて意図しないコマンドが実行される可能性があります。
- **データ漏洩リスク**: 読み取り専用コマンド（`cat`, `grep`等）でも、ネットワークアクセス可能な環境ではデータ漏洩のリスクがあります。

---

## 2. 推奨アプローチ

### アプローチA: 許可リスト + denylist

個別のコマンドを許可し、危険なコマンドをdenylistで拒否する方式。

**メリット**: 細かい制御が可能
**デメリット**: シェル演算子（`&&`, `|` 等）を含むコマンドは都度承認が必要

### アプローチB: sandbox環境での実行（推奨）

sandbox環境で実行することで、被害を限定する方式。

**メリット**:
- 万が一の悪意あるコマンドも被害が限定的
- AI-DLCの複合コマンドも問題なく実行可能

**推奨設定**:

| ツール | sandbox設定 | 承認ポリシー |
|--------|------------|-------------|
| Claude Code | Docker/コンテナ | 必要に応じて緩和 |
| Kiro CLI | sandbox設定 | 適宜設定 |

**警告**:
- `danger-full-access` や `approval-policy: "never"` の組み合わせは、prompt injection攻撃時に被害が拡大するため、本番環境では非推奨です。
- `--dangerously-skip-permissions` は開発環境のコンテナ内でのみ使用してください。

---

## 3. コマンドカテゴリ一覧

### 3.1 読み取り専用（許可推奨）

状態を変更しない安全なコマンド。

**注意**: ネットワークアクセス可能な環境では、読み取りコマンドでもデータ漏洩のリスクがあります。

| コマンド | 説明 | 使用フェーズ |
|---------|------|-------------|
| `git status` | 作業ツリー状態表示 | 全フェーズ |
| `git log` | コミット履歴表示 | 全フェーズ |
| `git branch` | ブランチ一覧表示 | 全フェーズ |
| `git branch --show-current` | 現在ブランチ表示 | 全フェーズ |
| `git diff` | 差分表示 | 全フェーズ |
| `git show` | コミット内容表示 | Construction, Operations |
| `git rev-parse` | Git参照解決 | Setup |
| `git show-ref` | 参照一覧表示 | Setup |
| `git worktree list` | worktree一覧表示 | Setup |
| `git remote`（引数なし/`-v`のみ） | リモート一覧表示 | Operations |
| `ls` | ファイル一覧表示 | 全フェーズ |
| `cat` | ファイル内容表示 | 全フェーズ |
| `head` | ファイル先頭表示 | 全フェーズ |
| `tail` | ファイル末尾表示 | 全フェーズ |
| `grep` | テキスト検索 | 全フェーズ |
| `rg` (ripgrep) | 高速テキスト検索 | 全フェーズ |
| `find` | ファイル検索 | 全フェーズ |
| `jq` | JSON処理 | 全フェーズ |
| `date` | 日時取得 | 全フェーズ |
| `pwd` | 現在ディレクトリ表示 | Setup |
| `command -v` | コマンド存在確認 | Setup, Operations |
| `gh auth status` | GitHub CLI認証状態 | Inception, Operations |
| `gh pr list` | PR一覧表示 | Inception, Operations |
| `gh pr view` | PR詳細表示 | Operations |
| `gh issue list` | Issue一覧表示 | Inception |

### 3.2 作成系（許可推奨）

ファイル/ブランチ作成の操作。

| コマンド | 説明 | 使用フェーズ |
|---------|------|-------------|
| `git checkout -b` | ブランチ作成・切り替え | Setup, Inception |
| `git switch -c` | ブランチ作成・切り替え | Setup |
| `git worktree add` | worktree作成 | Setup |
| `git add` | ステージング | 全フェーズ |
| `mkdir -p` | ディレクトリ作成 | Setup |
| `touch` | 空ファイル作成 | Setup |

### 3.3 Git操作（条件付き許可）

状態を変更する操作。Git hooksが実行される可能性あり。

| コマンド | 説明 | 注意事項 |
|---------|------|----------|
| `git commit` | コミット作成 | pre-commit/commit-msg hooks実行 |
| `git push` | リモートにプッシュ | pre-push hooks実行 |
| `git checkout` | ブランチ切り替え | post-checkout hooks実行 |
| `git stash` | 変更一時退避 | - |
| `gh pr create` | PR作成 | - |
| `gh pr ready` | PRをReady化 | - |

### 3.4 破壊的操作（注意が必要）

データ削除や上書きの可能性がある操作。明示的な確認を推奨。

| コマンド | 説明 | リスク |
|---------|------|--------|
| `git branch -d/-D` | ブランチ削除 | ブランチ削除 |
| `git tag -d` | タグ削除 | タグ削除 |
| `git worktree remove` | worktree削除 | ディレクトリ削除 |
| `tee` | ファイル書き込み | 上書きの可能性 |
| `rsync` | ファイル同期 | `--delete`で削除の可能性。AI-DLCではスクリプト（`sync-package.sh`, `aidlc-setup.sh`）内でのみ実行されるため、個別許可は通常不要 |
| `gh pr merge` | PRマージ | リモートへの不可逆変更 |
| `gh release create` | リリース作成 | リモートへの変更 |

### 3.5 除外対象（許可非推奨）

破壊的・履歴改変の可能性があるコマンド。`ask`への追加を推奨（必要な時は承認して使用可能）。

| コマンド | 説明 | リスク |
|---------|------|--------|
| `git push --force` / `-f` | 強制プッシュ | 履歴上書き |
| `git push --force-with-lease` | 条件付き強制プッシュ | 履歴上書き（安全性は限定的） |
| `git reset --hard` | ハードリセット | 変更完全破棄 |
| `git clean -fd` | 未追跡ファイル削除 | ファイル削除 |
| `git rebase -i` | インタラクティブリベース | 履歴書き換え |
| `rm -rf` | 再帰的強制削除 | ファイル削除 |
| `curl` / `wget` | 外部URL取得 | データ漏洩・マルウェアダウンロード |

**例外**: 特定の信頼できるURL（例: スターターキットのGitHub raw URL）に限定して`curl`を許可する場合は、allowリストでURLパターンを厳密に指定することでリスクを軽減できます。設定例のセクション4.1を参照してください。

---

## 4. AIエージェント別設定方法

### 4.1 Claude Code

**設定ファイル**:
- `.claude/settings.json`（プロジェクト共有、git管理）
- `.claude/settings.local.json`（個人のプロジェクト固有、gitignore推奨）
- `~/.claude/settings.json`（ユーザー全体）

**優先順位**:
```text
deny（最優先）→ ask → allow（最低優先）
```

- `deny`: 完全ブロック（承認不可）
- `ask`: 確認を求める（承認すれば使える）
- `allow`: 自動許可

**設定例（AI-DLC推奨）**:
```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git branch --show-current)",
      "Bash(gh auth status)",
      "Bash(date)",
      "Bash(git worktree list)",
      "Bash(git rev-parse:*)",
      "Bash(git log:*)",
      "Bash(git branch)",
      "Bash(git branch -a)",
      "Bash(git branch -r)",
      "Bash(git branch -v:*)",
      "Bash(git diff:*)",
      "Bash(git remote)",
      "Bash(git remote -v)",
      "Bash(git remote show:*)",
      "Bash(git show:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(grep:*)",
      "Bash(command -v:*)",
      "Bash(gh pr list:*)",
      "Bash(gh issue list:*)",
      "Bash(git checkout -b:*)",
      "Bash(git switch:*)",
      "Bash(git worktree add:*)",
      "Bash(git add:*)",
      "Bash(mkdir:*)",
      "Bash(git commit -m:*)",
      "Bash(git push:*)",
      "Bash(git reset --soft:*)",
      "Bash(git worktree remove:*)",
      "Bash(git stash:*)",
      "Bash(tee -a docs/cycles/*/history/*)",
      "Bash(curl * https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/*)",
      "Bash(npx markdownlint-cli2:*)",
      "WebSearch"
    ],
    "ask": [
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git push --force-with-lease:*)",
      "Bash(git reset --hard:*)",
      "Bash(git clean:*)",
      "Bash(wget:*)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)"
    ]
  }
}
```

**設定のポイント**:
- `git branch:*` ではなく読み取り系のみ（`-d/-D` 除外）
- `git remote:*` ではなく読み取り系のみ（削除系除外）
- `git commit -m:*` で `-m` 必須（`--amend` 除外）
- `git push:*` はallowだが、`-f`/`--force`/`--force-with-lease`はaskで確認を要求
- `tee` は履歴ファイル限定（`docs/cycles/*/history/*`）
- `rsync` はスクリプト（`sync-package.sh`, `aidlc-setup.sh`）内でのみ実行されるため、個別許可は不要。スクリプト実行の許可で代替される（詳細はミニマル推奨セットを参照）
- `curl` はスターターキットURL限定（セクション3.5の例外に該当）

**ワイルドカード**:
- `:*` - プレフィックスマッチ（末尾のみ）
- `*` - 任意位置マッチ
- ワイルドカードなし - 完全一致のみ

**絞り込み例**:
- `Bash(git branch)` → `git branch` のみ許可。`git branch -D` は承認が必要
- `Bash(git commit -m:*)` → `-m` 必須。`git commit --amend` 単体は許可されない

**使い分けの指針**:
- `allow`: 読み取り専用など安全なコマンド
- `ask`: 破壊的だが必要な場合もあるコマンド（確認後に使用可能）
- `deny`: 機密ファイルへのアクセスなど絶対に許可しないもの

#### AI-DLC運用時の推奨設定パターン

上記の「設定例（AI-DLC推奨）」は各コマンドを個別に列挙した**詳細リファレンス**（コピペで即利用可）です。ここでは、その設定を**カテゴリ別に整理したミニマルセット**を紹介します。ワイルドカードによる統合で設定数を削減しつつ、同等のカバレッジを提供します。どちらを採用しても構いません。

##### なぜ相対パスを推奨するか

許可パターンには**相対パス**を使用してください。絶対パスは以下の理由で問題になります:

- **worktree環境**: `.worktree/dev/` 経由のパスと直接パスが異なる
- **チーム共有**: 他のメンバーのホームディレクトリが異なる
- **テンプレート化**: settings.local.json を新規プロジェクトにコピーできない

```text
# NG - 絶対パス（環境依存）
"Bash(/Users/alice/repos/my-project/skills/aidlc/scripts/write-history.sh:*)"

# OK - 相対パス（環境非依存）
"Bash(skills/aidlc/scripts/write-history.sh:*)"
```

##### ミニマル推奨セット

以下の設定で AI-DLC の全フェーズ（Inception / Construction / Operations）の基本操作を承認なしで実行できます。ただし、シェル演算子（`&&`, `|` 等）を含むコマンドは別途承認が必要な場合があります（詳細はセクション5.1参照）。

**AI-DLCスクリプト群**（1エントリで全スクリプトをカバー）:

| パターン | 対象 |
|---------|------|
| `Bash(skills/aidlc/scripts/:*)` | write-history.sh, read-config.sh, issue-ops.sh, pr-ops.sh, squash-unit.sh 等すべて |

**Git操作**:

| パターン | 用途 | 備考 |
|---------|------|------|
| `Bash(git add:*)` | ステージング | |
| `Bash(git commit -m:*)` | コミット | `-m` 必須。`--amend` は許可されない |
| `Bash(git checkout:*)` | ブランチ切り替え・作成 | `checkout -- <file>` も許可される点に注意。ファイル復元を制限したい場合は `git checkout -b:*` に限定 |
| `Bash(git pull:*)` | リモート取得 | |
| `Bash(git push:*)` | リモートプッシュ | 上記「設定例」と同一。`--force` は ask で制御されるが、`git push origin main --force`（後置フラグ）は ask をすり抜ける可能性あり。**セキュリティ優先の場合は `git push:*` を ask に移動**を推奨 |

**GitHub CLI**:

| パターン | 用途 |
|---------|------|
| `Bash(gh pr view:*)` | PR詳細表示 |
| `Bash(gh pr create:*)` | PR作成 |
| `Bash(gh pr ready:*)` | ドラフト→Ready |
| `Bash(gh pr list:*)` | PR一覧 |
| `Bash(gh issue create:*)` | Issue作成 |
| `Bash(gh issue view:*)` | Issue詳細表示 |
| `Bash(gh issue list:*)` | Issue一覧 |


> **注**: `gh api:*` は DELETE/PATCH/POST を含む全APIメソッドを許可するため、ミニマルセットには含めていません。AI-DLC運用では上記の `gh pr`/`gh issue` 系コマンドで大半の操作が完結します。`gh api` が必要な場合は下記の ask 推奨セクションを参照してください。

**AIレビューSkill**:

| パターン | 用途 |
|---------|------|
| `Skill(reviewing-code)` | コードレビュー |
| `Skill(reviewing-architecture)` | アーキテクチャレビュー |
| `Skill(reviewing-security)` | セキュリティレビュー |
| `Skill(reviewing-inception)` | Inceptionレビュー |

##### オプション追加

プロジェクトの利用状況に応じて追加してください。

| パターン | いつ必要か | リスク |
|---------|-----------|--------|
| `Bash(claude:*)` | Claudeサブプロセスでレビューを実行する場合 | サブプロセスが親の権限制御外で動作する。**`ask` への配置を推奨**。プロンプト注入経由の意図しない実行リスクあり |
| `Bash(dasel:*)` | daselでTOML設定を読み取る場合 | 書き込みオプション（`-w`）も許可される。読み取り専用に限定する場合は `Bash(dasel -r toml:*)` に変更 |
| `Bash(rsync:*)` | スクリプト外でrsyncを直接実行する場合（通常不要） | `--delete` や任意パス指定が可能。rsyncは `sync-package.sh` / `aidlc-setup.sh` 内に閉じ込められているため、通常はスクリプト許可で十分 |
| `Bash(prompts/package/bin/setup-:*)` | セットアップスクリプト（`prompts/package/bin/setup-*.sh`）を実行する場合 | - |

##### ask推奨（破壊的操作）

上記の「設定例」のask設定に加え、以下の追加を推奨します:

| パターン | リスク |
|---------|-------|
| `Bash(gh api:*)` | 全APIメソッド（DELETE含む）が実行可能 |
| `Bash(gh pr merge:*)` | PRマージ（不可逆） |
| `Bash(gh release create:*)` | リリース作成 |

##### deny推奨（セキュリティ）

機密情報への読み取りをブロックします。

| パターン | 保護対象 |
|---------|---------|
| `Read(.env)` | 環境変数ファイル |
| `Read(.env.*)` | 環境変数ファイル（派生） |
| `Read(~/.ssh/**)` | SSH鍵 |
| `Read(~/.aws/**)` | AWSクレデンシャル |

利用環境に応じて以下も追加を検討してください:

| パターン | 保護対象 |
|---------|---------|
| `Read(.envrc)` | direnv環境変数 |
| `Read(~/.config/gh/**)` | GitHub CLIトークン |
| `Read(~/.npmrc)` | npmレジストリトークン |
| `Read(~/.docker/**)` | Dockerクレデンシャル |
| `Read(~/.kube/**)` | Kubernetes設定 |
| `Read(**/*.pem)` | PEM証明書・秘密鍵 |
| `Read(**/*.key)` | 秘密鍵ファイル |

##### 既存設定からの移行

現在の `settings.local.json` に絶対パスや重複エントリがある場合:

1. **絶対パスの特定**: `/Users/` や `/home/` で始まるエントリを検索
2. **相対パスに置換**: プロジェクトルートからの相対パスに変更
3. **統合パターンで置換**: 個別スクリプトエントリを `Bash(skills/aidlc/scripts/:*)` に統合
4. **不要エントリの削除**: Claude Code専用ツール（Read/Grep/Glob/Write）でカバーされる `ls`/`cat`/`grep` 等のBashエントリは削除可能

### 4.2 Kiro CLI

**設定ファイル**:
- `~/.kiro/settings.json`（macOS）
- `~/.config/kiro/settings.json`（Linux）

**設定例**:
```json
{
  "toolSettings": {
    "shell": {
      "allowedCommands": [
        "git status",
        "git log",
        "git diff",
        "git branch --show-current",
        "git add",
        "ls",
        "cat",
        "mkdir",
        "date"
      ],
      "deniedCommands": [
        "&&",
        "||",
        ";",
        "|",
        "&",
        "rm -rf",
        "git push --force",
        "git reset --hard",
        "git clean",
        "curl",
        "wget"
      ],
      "autoAllowReadonly": true
    }
  }
}
```

**重要**:
- deniedCommandsは**substring matching**。`&&` を拒否すると、`&&` を含むすべてのコマンドがブロックされます。
- `&` を拒否すると `2>&1` もブロックされます。セクション5.1の「`>/dev/null 2>&1`への置換」と矛盾する場合は、`&` をdenylistから除外するか、別の回避策を検討してください。
- コマンドチェーンの扱いは現在議論中（Issue #1602）。安全のためシェル演算子をdenylistに追加することを推奨。

---

## 5. セキュリティ上の注意事項

### 5.1 シェル演算子とリダイレクトの扱い

以下の演算子やリダイレクトを含むコマンドは、許可リストに登録しても承認を求められる場合がある：

| パターン | 用途 | 承認 | 対策 |
|----------|------|------|------|
| `&&` | AND実行 | 条件付き | プロジェクト内パスなら許可される場合あり |
| `\|\|` | OR実行 | 条件付き | 同上 |
| `;` | 順次実行 | 条件付き | 同上 |
| `\|` | パイプ | 条件付き | 同上 |
| `&` | バックグラウンド | 必要 | 制御外実行のため |
| **`&>/dev/null`** | stdout+stderr抑制 | **必要** | `>/dev/null 2>&1` に置換 |
| `>/dev/null` | stdout抑制 | 不要 | そのまま使用可 |
| `2>/dev/null` | stderr抑制 | 不要 | そのまま使用可 |

**重要**: `&>/dev/null`（bash省略記法）は許可リストに関係なく承認が必要になる場合があります。`>/dev/null 2>&1` に置き換えることで承認なしで実行できます。

**対策**:
- **Claude Code**: `&>/dev/null` を `>/dev/null 2>&1` に置換
- **Kiro CLI**: `deniedCommands` でシェル演算子を拒否（設定例はセクション4.2を参照）

### 5.2 ワイルドカードの限界

- `Bash(git:*)` は `git status` にマッチ
- しかし以下でバイパス可能：
  - 変数経由: `URL=http://... && curl $URL`
  - プロセス置換: `cmd <(malicious)`
  - コマンド置換: `cmd $(malicious)`

### 5.3 Git hooks/aliasのリスク

許可リストはGitコマンド自体をチェックしますが、以下は制御できません：

- `.git/hooks/` 内のスクリプト（pre-commit, post-checkout等）
- `git config --global alias.*` で定義されたエイリアス

**対策**:
- 信頼できないリポジトリでは `git config core.hooksPath /dev/null` で hooks を無効化
- sandbox環境での実行

### 5.4 推奨対策

1. **sandbox環境**での実行を推奨（最も安全）
2. **破壊的コマンド**を`ask`に追加（確認後に使用可能）
3. **機密ファイル**（`.env`, `~/.ssh/`等）は`deny`で完全ブロック
4. **定期的なレビュー**で許可リストを見直す
5. **Git hooks**の確認と必要に応じた無効化

---

## 6. 推奨ツール

### 6.1 dasel（TOML/YAML/JSONパーサー）

AI-DLCの設定ファイル（`docs/aidlc.toml`）を読み取るために、`dasel` の使用を推奨します。

**なぜ dasel か**:
- `awk`/`grep`/`sed` を使った複雑なTOML読み取りが不要になる
- 許可リストが簡潔になる（`dasel` だけ許可すればOK）
- JSON/YAML/TOML すべて対応

**インストール**:
```bash
# macOS（v3がインストールされます）
brew install dasel

# Go（v3系）
go install github.com/tomwright/dasel/v3/cmd/dasel@latest

# その他（バイナリダウンロード）
# https://github.com/TomWright/dasel/releases
```

**使用例（dasel v3系）**:
```bash
# AIレビューモード取得
cat docs/aidlc.toml | dasel -i toml 'rules.reviewing.mode' | tr -d "'"
```

**dasel未インストール時の動作**:

AIエージェントが `docs/aidlc.toml` をReadツールで直接読み取り、設定値を解釈します。

```text
# AI-DLCプロンプト内での使用例（setup.md, construction.md等）

daselが利用可能な場合:
  cat docs/aidlc.toml | dasel -i toml 'rules.reviewing.mode' | tr -d "'"

daselが利用できない場合:
  AIがReadツールでdocs/aidlc.tomlを読み取り、該当の設定値を抽出
```

この動作により、daselの導入有無に関わらずAI-DLCは正常に機能します。

### 6.2 aidlc-* スクリプトの活用

AI-DLCには、頻繁に使用する読み取り系コマンドをまとめたスクリプトが用意されています。

**提供スクリプト**:

| スクリプト | 機能 | 置換可能なコマンド |
|------------|------|-------------------|
| `aidlc-env-check.sh` | 環境チェック | `command -v`, `gh auth status` |
| `aidlc-git-info.sh` | Git状態取得 | `git status`, `git branch`, `git log` |
| `aidlc-cycle-info.sh` | サイクル情報 | ブランチ名解析、ディレクトリ走査 |

**許可リストでの活用**:

従来の設定では多くの個別コマンドを許可する必要がありました:

```json
"allow": [
  "Bash(git status)",
  "Bash(git branch --show-current)",
  "Bash(git log:*)",
  "Bash(command -v:*)",
  "Bash(gh auth status)",
  ...
]
```

スクリプトを活用すると簡潔になります:

```json
"allow": [
  "Bash(prompts/package/bin/aidlc-env-check.sh)",
  "Bash(prompts/package/bin/aidlc-git-info.sh)",
  "Bash(prompts/package/bin/aidlc-cycle-info.sh)",
  ...
]
```

または、ワイルドカードで一括許可:

```json
"allow": [
  "Bash(prompts/package/bin/aidlc-*:*)",
  ...
]
```

**メリット**:

- 許可リストの行数削減
- 出力形式が統一（パース容易）
- 新しいコマンド追加時もスクリプト修正のみで対応

**注意**: スクリプトはPATHに含まれないため、許可リストには相対パスを含める必要があります。

---

## 7. 参考リンク

- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Kiro CLI Settings](https://kiro.dev/docs/cli/reference/settings/)
- [Kiro CLI Permissions](https://kiro.dev/docs/cli/chat/permissions/)
