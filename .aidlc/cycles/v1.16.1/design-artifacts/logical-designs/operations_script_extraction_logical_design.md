# 論理設計: operations.md定型処理スクリプト化

## 概要

operations.mdのセクション6.6.5（コミット漏れ確認）・6.6.6（リモート同期確認）をシェルスクリプトに切り出し、プロンプト内にはスクリプト呼び出しと結果判定のみを残す。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**パイプ&フィルター + AIインタープリター**

- スクリプト（フィルター）: git状態を検査し、機械可読な結果を出力
- operations.md（インタープリター）: スクリプト出力を解釈し、ユーザー向けアクションを決定

## コンポーネント構成

```text
prompts/package/
├── bin/
│   ├── validate-uncommitted.sh   [新規] コミット漏れ検証
│   └── validate-remote-sync.sh   [新規] リモート同期検証
└── prompts/
    └── operations.md              [修正] 6.6.5・6.6.6をスクリプト呼び出しに置換
```

## スクリプトインターフェース設計

### validate-uncommitted.sh

#### 概要

作業ディレクトリに未コミット変更が存在するかを検出し、key:value形式で結果を出力する。

#### 引数

なし

#### 処理フロー

1. `git status --porcelain` を実行
2. 出力が空 → `status:ok` を出力
3. 出力が非空 → `status:warning` + `files_count:{N}` + 各ファイルを `file:{porcelain行}` で出力

#### 成功時出力

変更なし:
```text
status:ok
```

変更あり:
```text
status:warning
files_count:2
file:M docs/cycles/v1.16.1/operations/progress.md
file:?? temp.txt
```

- 終了コード: `0`（正常終了）
- 出力先: stdout
- 注意: gitコマンド自体の失敗は `set -euo pipefail` によりスクリプトが非0で終了する（出力契約外のインフラエラー）

#### 使用コマンド

```bash
docs/aidlc/bin/validate-uncommitted.sh
```

### validate-remote-sync.sh

#### 概要

ローカルの全コミットがリモートにpush済みかを検証し、key:value形式で結果を出力する。

#### 引数

なし

#### 処理フロー

```text
Step 0: ブランチ名・リモート名解決
  BRANCH=$(git branch --show-current)
    → 空（detached HEAD）: status:error + error:branch-unresolved → exit 1
    → 非空: BRANCH設定
  REMOTE=$(git config branch.$BRANCH.remote)
    → 取得成功: REMOTE設定
    → 取得失敗: REMOTE="origin"

Step A: リモートfetch
  git fetch $REMOTE → 成功: Step Bへ
                    → 失敗: status:error + error:fetch-failed → exit 1

Step B: 追跡ブランチ解決
  git rev-parse --abbrev-ref @{u} → 成功: REMOTE_REF設定
                                  → 失敗: フォールバック
    git show-ref --verify refs/remotes/$REMOTE/$BRANCH >/dev/null 2>&1
      → 存在: REMOTE_REF="$REMOTE/$BRANCH"
      → 不在: status:error + error:no-upstream → exit 1

Step C: 未pushコミット検出
  git log $REMOTE_REF..HEAD --oneline → 失敗: status:error + error:log-failed → exit 1
                                      → 空: status:ok → exit 0
                                      → 非空: status:warning + unpushed_commits:{N} → exit 0
```

**stdoutルール**: gitコマンドの標準出力（`git show-ref`等）は `>/dev/null` で抑制し、stdoutには契約で定義されたkey:value行のみを出力する。

#### 成功時出力

同期済み:
```text
status:ok
```

未pushコミットあり:
```text
status:warning
remote:origin
branch:cycle/v1.16.1
unpushed_commits:3
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

ブランチ未解決（detached HEAD）:
```text
status:error
remote:unknown
branch:unknown
error:branch-unresolved
```

fetch失敗:
```text
status:error
remote:origin
branch:cycle/v1.16.1
error:fetch-failed
```

追跡ブランチなし:
```text
status:error
remote:origin
branch:cycle/v1.16.1
error:no-upstream
```

git log失敗:
```text
status:error
remote:origin
branch:cycle/v1.16.1
error:log-failed
```

- 終了コード: `1`
- stderr: `Error: {エラー詳細}` 形式のデバッグ情報
- 出力先: stdout（status/error行）+ stderr（デバッグ情報）

#### 使用コマンド

```bash
docs/aidlc/bin/validate-remote-sync.sh
```

## operations.md置換設計

### 6.6.5 コミット漏れ確認（置換後）

現在の33行を以下に置換（約15行）:

```markdown
#### 6.6.5 コミット漏れ確認【必須】

PRマージ前に未コミットの変更がないことを確認します。

**確認コマンド**:

\```bash
docs/aidlc/bin/validate-uncommitted.sh
\```

**結果に応じた対応**:

- **`status:ok`**: 次のステップ（6.6.6 リモート同期確認）へ進む
- **`status:warning`**: 以下を実行

  \```text
  【警告】未コミットの変更があります。PRマージ前にコミットしてください。

  変更されているファイル:
  {スクリプト出力のfile行を列挙}

  以下の手順で対応してください：
  1. コミット漏れのファイルを追加コミットする（推奨）
  2. 変更を確認して不要であれば破棄する（※下記注意参照）

  コミット完了後、再度このステップを実行してください。
  \```

**注意**:

- stashは推奨しません。progress.mdやhistoryファイルの変更は履歴として残すべきです。
- **破棄してよいファイル**: 明らかな誤生成ファイル、一時ファイル（`.tmp`等）のみ
- **破棄NG**: progress.md、historyファイル、Unit定義ファイル、設計・実装成果物
```

### 6.6.6 リモート同期確認（置換後）

現在の97行を以下に置換（約35行）:

```markdown
#### 6.6.6 リモート同期確認【必須】

PRマージ前にローカルの全コミットがリモートにpushされていることを確認します。

**確認コマンド**:

\```bash
docs/aidlc/bin/validate-remote-sync.sh
\```

**結果に応じた対応**:

- **`status:ok`**: 次のステップ（6.7 PRマージ）へ進む

- **`status:warning`**（未pushコミットあり）: 以下を表示してマージを停止

  \```text
  【警告】リモートにpushされていないコミットがあります。

  未pushコミット数: {unpushed_commitsの値}

  PRマージ前にpushしてください：
  git push {remoteの値} {branchの値}

  push完了後、再度このステップを実行してください。
  リモートとの同期が確認できるまでPRマージに進まないでください。
  \```

- **`status:error`**（`error:fetch-failed`）: 以下を表示してマージを停止

  \```text
  【エラー】git fetchに失敗しました。

  ネットワーク接続を確認し、以下を実行してください：
  1. ネットワーク接続を確認
  2. `git fetch {remoteの値}` を手動で実行
  3. 成功後、再度このステップを実行

  リモートとの同期が確認できるまでPRマージに進まないでください。
  \```

- **`status:error`**（`error:no-upstream`）: 以下を表示してマージを停止

  \```text
  【エラー】リモート追跡ブランチが特定できません。

  PRマージ前に以下を確認してください：
  1. `git push -u {remoteの値} {branchの値}` でリモートにpushする
  2. push完了後、再度このステップを実行

  リモートとの同期が確認できるまでPRマージに進まないでください。
  \```

- **`status:error`**（`error:branch-unresolved`）: 以下を表示してマージを停止

  \```text
  【エラー】現在のブランチを特定できません（detached HEAD状態の可能性）。

  以下を確認してください：
  1. `git branch --show-current` でブランチ名を確認
  2. ブランチにチェックアウトしてから再度このステップを実行

  リモートとの同期が確認できるまでPRマージに進まないでください。
  \```

- **`status:error`**（`error:log-failed`）: 以下を表示してマージを停止

  \```text
  【エラー】未pushコミットの確認に失敗しました。

  リモート参照の状態を手動で確認し、問題を解決してから再度このステップを実行してください。
  \```
```

### 行数見積もり

- 6.6.5 削減: 33行 → 約22行（-11行）
- 6.6.6 削減: 97行 → 約50行（-47行）
- 合計削減: 約58行
- 置換後の見込み行数: 1033 - 58 = 約975行

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: スクリプトのローカル処理部分が5秒以内に完了（git fetchのネットワーク通信時間は計測対象外）
- **対応策**: 追加の外部ツール呼び出しなし。git標準コマンドのみ使用

## 技術選定

- **言語**: Bash（既存スクリプトと統一）
- **シェル設定**: `set -euo pipefail`
- **依存ツール**: git（既存環境で利用可能が前提）

## 実装上の注意事項

- `file:` 行の値は `git status --porcelain` の出力をそのまま使用する（ステータス文字 + パス）
- `validate-remote-sync.sh` の各Stepでは、エラー発生時に先行して取得済みの `remote` / `branch` 情報も出力する（AIが復旧ガイダンスに利用するため）
- ヘッダコメントのスタイルは既存 `check-*.sh` と統一する
