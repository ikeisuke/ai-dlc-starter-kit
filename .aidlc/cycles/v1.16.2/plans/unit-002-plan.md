# Unit 002 計画: Issueテンプレート差分確認スクリプト

## 概要

ローカルとリモート（デフォルトブランチ）のGitHub Issueテンプレートの差分を自動検出するスクリプト `check-issue-templates.sh` を新規作成する。

## 前提知識

### 既存パターン
- `check-gh-status.sh`: シンプル状態確認（gh存在・認証チェック）
- `check-open-issues.sh`: オプション解析・一時ファイル・エラーハンドリング
- 出力形式: `key:value` 統一パターン（フラット、インデントなし）

### 対象ファイル
- `.github/ISSUE_TEMPLATE/`: backlog.yml, bug.yml, feature.yml, feedback.yml

## 成果物

| ファイル | 内容 |
|--------|------|
| `prompts/package/bin/check-issue-templates.sh` | 差分検出スクリプト（新規） |

## 実装計画

### Phase 1: 設計・計画承認

1. 計画ドキュメント作成（本ファイル）
2. AIレビュー
3. ユーザー承認

### Phase 2: 実装

4. `check-issue-templates.sh` 新規作成
   - gh/git存在・認証チェック（check-gh-status.shパターン流用）
   - リポジトリ・デフォルトブランチ自動検出
   - gh apiでリモートテンプレートファイル一覧取得
   - ローカルファイルとの差分比較（diff）
   - 結果をフラット統一形式で出力

5. rsync同期（docs/aidlc/bin/へ反映）
6. テスト実行
7. AIレビュー
8. ユーザー承認

## スクリプト設計

### 入力
- `--ref <branch>`: 比較対象ブランチ（オプション、デフォルト: リポジトリのdefaultBranchRef）

### 出力形式
```
template_diff:none                                 # 差分なし
template_diff:found                                # 差分あり
template_diff_local_only:file1.yml,file2.yml       # ローカルのみ存在（差分ありの場合）
template_diff_remote_only:file3.yml                # リモートのみ存在（差分ありの場合）
template_diff_modified:file4.yml,file5.yml         # 内容差分あり（差分ありの場合）
error:gh-not-installed                             # gh未インストール
error:gh-not-authenticated                         # gh未認証
error:git-not-installed                            # git未インストール
error:no-repo                                      # gitリポジトリ外
error:gh-api-failed:contents                       # リモートテンプレート一覧取得失敗
error:gh-api-failed:file:<filename>                # リモートファイル内容取得失敗
error:remote-template-path-not-found               # リモートに.github/ISSUE_TEMPLATE/が存在しない
```

**出力ルール**: すべてフラット（トップレベル1行）。`template_diff:found`の場合、後続行に`template_diff_local_only`/`template_diff_remote_only`/`template_diff_modified`が0行以上続く（該当カテゴリのみ出力）。

### 処理フロー
1. gh存在確認（`command -v gh`）
2. git存在確認（`command -v git`）
3. gh認証確認（`gh auth status`）
4. gitリポジトリ確認（`git rev-parse --is-inside-work-tree`）
5. リポジトリ情報取得（`gh repo view --json owner,name`）
6. 比較対象ブランチ決定（`--ref`指定 or `gh repo view --json defaultBranchRef`）
7. リモートテンプレート一覧取得（`gh api /repos/{owner}/{repo}/contents/.github/ISSUE_TEMPLATE?ref={branch}`）
8. ローカルテンプレート一覧取得（`find .github/ISSUE_TEMPLATE -maxdepth 1 -type f -name '*.yml' | sort`）
9. 差分比較:
   - ローカルのみ存在するファイル
   - リモートのみ存在するファイル
   - 両方に存在するが内容が異なるファイル（gh apiでリモート内容取得→diffで比較）
10. 結果出力

### 終了コード
- 0: 正常終了（差分の有無に関わらず）
- 1: エラー発生（gh/git未インストール、未認証、API失敗等）

**終了コード方針**: check-open-issues.shのデータ取得系パターンに準拠。事前条件エラー（ツール未インストール等）とAPI失敗はexit 1、正常差分検出はexit 0。

### エラーハンドリング
- gh未インストール → `error:gh-not-installed`、exit 1
- git未インストール → `error:git-not-installed`、exit 1
- gh未認証 → `error:gh-not-authenticated`、exit 1
- gitリポジトリ外 → `error:no-repo`、exit 1
- gh api失敗（一覧取得） → `error:gh-api-failed:contents`、exit 1
- gh api失敗（ファイル取得） → `error:gh-api-failed:file:<filename>`、exit 1
- リモートにテンプレートディレクトリなし → `error:remote-template-path-not-found`、exit 1
- .github/ISSUE_TEMPLATE/ ローカル不在 → ローカル側を空として扱う（正常処理）

## 完了条件チェックリスト

- [ ] check-issue-templates.sh が新規作成されている
- [ ] ローカルとリモートの差分を正しく検出できる
- [ ] gh未インストール時にエラーメッセージを出力する（exit 1）
- [ ] gh未認証時にエラーメッセージを出力する（exit 1）
- [ ] gh api失敗時に詳細なエラーを出力する（exit 1）
- [ ] --refオプションで比較対象ブランチを指定できる
- [ ] 既存スクリプトのパターン（フラット出力、終了コード）に準拠している
