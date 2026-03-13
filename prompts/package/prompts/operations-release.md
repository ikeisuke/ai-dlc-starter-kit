# Operations Phase - ステップ6: リリース準備

> このファイルは `operations.md` のステップ6の詳細です。全体フローは `docs/aidlc/prompts/operations.md` を参照してください。

**前提条件**: このステップを開始する前に、以下が完了していること:

- ステップ0〜5が完了済み（progress.mdで確認）
- 共通ルール（`docs/aidlc/prompts/common/rules.md`）読み込み済み
- `docs/aidlc.toml` の設定確認済み
- 環境情報（gh/backlog_mode）確認済み（ステップ2.5）

---

## 6.0 バージョン確認

### iOSプロジェクトの場合の事前確認

`project.type = "ios"` の場合、Inception Phaseでバージョン更新済みかを確認。

**project.type確認**: AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `type` 値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `general` として扱う。

**iOSプロジェクトの場合**: Inception履歴を確認

```bash
grep -q "iOSバージョン更新実施" docs/cycles/{{CYCLE}}/history/inception.md 2>/dev/null
```

出力があれば `UPDATED_IN_INCEPTION`、なければ `NOT_UPDATED_IN_INCEPTION` と判断。

**判定結果**:
- **UPDATED_IN_INCEPTION**: 以下を表示してMARKETING_VERSION確認をスキップし、iOSビルド番号確認に進む
  ```text
  バージョン確認結果:
  - project.type: ios
  - Inception Phase履歴: MARKETING_VERSION更新実施済み

  Inception PhaseでMARKETING_VERSION更新済みです。「通常のバージョン確認」をスキップし、「iOSビルド番号確認」に進みます。
  ```
- **NOT_UPDATED_IN_INCEPTION または iOSプロジェクト以外**: 通常のバージョン確認を実行

### iOSビルド番号確認

**前提条件**: `project.type = "ios"` の場合のみ実行。それ以外のプロジェクトタイプではこのセクションをスキップ。

ビルド番号確認スクリプトを実行:

```bash
docs/aidlc/bin/ios-build-check.sh
```

**出力形式**:
- `status:found|not-found|multiple` - ファイル検出状態
- `current_build:XXX` - 現在のビルド番号
- `previous_build:XXX` - 前回のビルド番号
- `comparison:updated|same|unknown` - 比較結果
- `files:...` - status=multipleの場合、ファイル一覧

**判定結果に応じた対応**:

| status | comparison | 対応 |
|--------|------------|------|
| not-found | - | スキップ |
| multiple | - | ユーザーにファイル選択を求め、選択後に再実行 |
| found | updated | 続行 |
| found | same | 警告を表示し、更新を推奨 |
| found | unknown | 手動確認を案内 |

**status=multiple時の再実行**:
```bash
docs/aidlc/bin/ios-build-check.sh "[選択されたパス]"
```

**comparison=same時の警告**:
```text
【警告】iOSビルド番号が前回と同一です。App Storeは同一ビルド番号での再提出を拒否します。
```

### 通常のバージョン確認

運用引き継ぎ（`docs/cycles/operations.md`）の「バージョン確認設定」セクションを確認:
- **設定がある場合**: 設定に従ってバージョンを確認
- **設定がない場合**: 対話形式でバージョン確認対象を特定し、運用引き継ぎに保存

**確認手順**:
1. バージョン確認対象ファイルを特定（package.json, pyproject.toml等）
2. 現在のバージョンを確認
3. サイクルバージョンと整合性を確認
4. **バージョン未更新の場合**: 更新を提案し、ユーザー承認後に更新

**iOSプロジェクトの注意**: サイクルバージョン（v1.7.1）からvプレフィックスを除去して使用（1.7.1）。CFBundleShortVersionStringは数値ドット区切り形式のみ受け付けます。

**バージョン確認コマンド例**:
```bash
# Node.js
cat package.json | grep '"version"'

# Python
cat pyproject.toml | grep 'version'

# Go
cat go.mod | head -1
```

## 6.1 CHANGELOG更新

**設定確認**: `docs/aidlc.toml` の `[rules.release]` セクションを読み、`changelog` の値を確認

- `changelog = false`（デフォルト）: このステップをスキップ
- `changelog = true`: 以下を実行

CHANGELOG.mdを更新し、現在のサイクルの変更内容を記録します。

**CHANGELOG.md確認**:

```bash
ls CHANGELOG.md 2>/dev/null
```

出力があれば存在、エラーなら不存在と判断。

**存在しない場合**:
Keep a Changelog形式で新規作成する。

**存在する場合**:
現在のサイクルバージョンのエントリがあるか確認し、なければ追加する。

**注意**: Unreleasedセクションは使用しない。直接バージョン付きエントリを作成する。

**表記ルール**:
- CHANGELOG: `[X.Y.Z]` 形式（vなし、例: `[1.6.0]`）
- gitタグ: `vX.Y.Z` 形式（vあり、例: `v1.6.0`）
- サイクル名 `v1.6.0` → CHANGELOG `[1.6.0]` + タグ `v1.6.0`

**Keep a Changelog形式**: `## [X.Y.Z] - YYYY-MM-DD` + `### Added` / `### Changed` / `### Fixed`

**変更内容の収集元**:
- `docs/cycles/{{CYCLE}}/history/` - 各フェーズの履歴
- `docs/cycles/{{CYCLE}}/story-artifacts/units/` - Unit定義
- コミット履歴

**参考**: [Keep a Changelog](https://keepachangelog.com/)

## 6.2 README更新
README.mdに今回のサイクルの変更内容を追記

## 6.3 履歴記録
`docs/cycles/{{CYCLE}}/history/operations.md` に履歴を追記（write-history.sh使用）

## 6.4 Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

```bash
docs/aidlc/bin/run-markdownlint.sh {{CYCLE}}
```

**注意**: `docs/aidlc.toml` の `[rules.linting].markdown_lint` が `false`（デフォルト）の場合はスキップされます。

**エラーがある場合**: 修正してから次のステップへ進む。

## 6.4.5 progress.md更新

`docs/cycles/{{CYCLE}}/operations/progress.md` をPR準備完了（progress.mdの状態は「完了」）に更新し、完了日を記録します。

**更新内容**:
- ステップ6の状態: 進行中 → 完了（= PR準備完了）
- 完了日: 現在日付（YYYY-MM-DD形式）

**注意**: progress.mdでの「完了」は「PR準備完了」を意味します。この更新をGitコミット（6.5）に含めることで、PRに正確な状態が反映されます。6.6以降はPR準備完了後のレビュー・マージ作業です。

## 6.5 Gitコミット

Operations Phaseで作成したすべてのファイル（**operations/progress.md、履歴ファイルを含む**）をコミット。

`docs/aidlc/prompts/common/commit-flow.md` の「Operations Phase完了コミット」手順に従ってください。

## 6.6 ドラフトPR Ready化【重要】

Inception Phaseで作成したドラフトPRをReady for Reviewに変更します（ステップ2.5で確認した `gh` ステータスを参照）。

**注意**: PR Ready化後は、バグ修正や追加要件がない限り**新たな変更**を加えないでください。progress.mdは既に6.4.5で「PR準備完了」として更新済みです。6.6.5でコミット漏れが見つかった場合は、漏れていたファイルのみ追加コミットしてください。

**`gh:available` 以外の場合**: スキップ

**Closes記載の確認【Issue管理】**:

Ready化の前に、PRの「Closes」セクションに全関連Issueが記載されているか確認します。

```bash
# 関連Issue番号を取得
docs/aidlc/bin/pr-ops.sh get-related-issues {{CYCLE}}

# PRの本文を確認
gh pr view {PR番号} --json body --jq '.body'
```

**記載漏れがある場合**、以下の警告を表示してユーザーに対応を促す:

```text
【警告】PR本文に `Closes #XX` が記載されていないIssueがあります。

未記載のIssue:
- #[Issue番号]

PRマージ時にIssueが自動クローズされません。
PR本文の「Closes」セクションに追記してください。
```

修正方法: `gh pr view {PR番号} --web` でブラウザから編集してください。

**ドラフトPR検索**（`gh:available` の場合）:
```bash
docs/aidlc/bin/pr-ops.sh find-draft
```

**ドラフトPRが見つかった場合**: ユーザーにReady化を確認し、承諾された場合:
```bash
docs/aidlc/bin/pr-ops.sh ready {PR番号}
```

**PR本文の更新**（Ready化後、レビューサマリの記載手順は下記参照）:

1. Writeツールで一時ファイルを作成（内容: PR本文）:

```text
## Summary
[Intentから抽出した概要]

## 受け入れ基準
[各Unit計画ファイルの「完了条件チェックリスト」から集約して記載]

## 変更概要
[全Unitの主な変更点を箇条書き]

## Test plan
- [ ] 主要機能が動作する

## Closes
Closes #[Issue番号]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

2. 以下を実行:

```bash
gh pr edit {PR番号} --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**レビューサマリの記載手順**:
1. 以下のディレクトリでサマリファイルを検索:
   - `docs/cycles/{{CYCLE}}/construction/units/*-review-summary.md`
   - `docs/cycles/{{CYCLE}}/inception/*-review-summary.md`
2. リポジトリURLを取得: `gh repo view --json url --jq '.url'`
3. いずれかのファイルが存在する場合: 「## Closes」セクションの直前に「## レビューサマリ」セクションを挿入し、ファイルへのリンクを列挙。**リンクはGitHub blob URL形式で記載する**（GitHub PR本文の相対リンクはデフォルトブランチを参照するため、サイクルブランチのファイルに正しくリンクするには絶対URLが必要）
   - 形式: `- [Unit 001 レビューサマリ]({REPO_URL}/blob/cycle/{{CYCLE}}/docs/cycles/{{CYCLE}}/construction/units/001-review-summary.md)`
4. いずれも存在しない場合: レビューサマリセクションは追加しない（PR本文はheredocの内容のみ）

**ドラフトPRが見つからない場合**:

```text
サイクルブランチからのPRが見つかりません。

新規PRを作成しますか？

1. はい - 新規PRを作成
2. いいえ - スキップ（後で手動で作成可能）
```

選択1の場合:

**Issue番号の取得**:
1. `docs/cycles/{{CYCLE}}/requirements/intent.md` の「対象Issue」セクションからIssue番号を取得
2. intent.mdにない場合は `docs/cycles/{{CYCLE}}/requirements/setup-context.md` を確認
3. Issue番号が見つからない場合は「Closes」セクションを省略

**複数Issueがある場合**: 各Issue番号を別行で `Closes #xx` 形式で記載

1. Writeツールで一時ファイルを作成（内容: PR本文、上記Ready化時と同内容）

2. 以下を実行:

```bash
gh pr create --base main --title "{{CYCLE}}" --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**レビューサマリの記載手順**: Ready化時と同じ手順に従う（上記参照）。

**GitHub CLI利用不可時**: 手動でPRを作成してください。

## 6.6.5 コミット漏れ確認【必須】

PRマージ前に未コミットの変更がないことを確認します。

```bash
docs/aidlc/bin/validate-git.sh uncommitted
```

**結果に応じた対応**:

- **`status:ok`**: 次のステップ（6.6.6 リモート同期確認）へ進む
- **`status:warning`**: 以下をユーザーに提示（`file:`行はgit status porcelain形式: ステータス記号+パス）

  ```text
  【警告】未コミットの変更があります。PRマージ前にコミットしてください。

  変更されているファイル:
  {スクリプト出力のfile:行をそのまま列挙}

  以下の手順で対応してください：
  1. コミット漏れのファイルを追加コミットする（推奨）
  2. 変更を確認して不要であれば破棄する（※下記注意参照）

  コミット完了後、再度このステップを実行してください。
  ```

- **`status:error`**（スクリプト実行失敗/`error:git-status-failed`）: 以下を表示してマージを停止

  ```text
  【エラー】未コミット変更の確認に失敗しました。
  gitリポジトリの状態を確認し、問題を解決してから再度このステップを実行してください。
  ```

**注意**:

- stashは推奨しません。progress.mdやhistoryファイルの変更は履歴として残すべきです。
- **破棄してよいファイル**: 明らかな誤生成ファイル、一時ファイル（`.tmp`等）のみ
- **破棄NG**: progress.md、historyファイル、Unit定義ファイル、設計・実装成果物

## 6.6.6 リモート同期確認【必須】

PRマージ前にローカルの全コミットがリモートにpushされていることを確認します。

```bash
docs/aidlc/bin/validate-git.sh remote-sync
```

**結果に応じた対応**:

- **`status:ok`**: 次のステップ（6.6.7 mainブランチとの差分チェック）へ進む

- **`status:warning`**: 以下を表示してマージを停止

  ```text
  【警告】リモートにpushされていないコミットがあります。
  未pushコミット数: {unpushed_commitsの値}
  PRマージ前にpushしてください： git push {remoteの値} {branchの値}
  push完了後、再度このステップを実行してください。
  ```

- **`status:error`**（`error:fetch-failed`）: 以下を表示してマージを停止

  ```text
  【エラー】git fetchに失敗しました。
  1. ネットワーク接続を確認
  2. `git fetch {remoteの値}` を手動で実行
  3. 成功後、再度このステップを実行
  リモートとの同期が確認できるまでPRマージに進まないでください。
  ```

- **`status:error`**（`error:no-upstream`）: 以下を表示してマージを停止

  ```text
  【エラー】リモート追跡ブランチが特定できません。
  1. `git push -u {remoteの値} {branchの値}` でリモートにpushする
  2. push完了後、再度このステップを実行
  リモートとの同期が確認できるまでPRマージに進まないでください。
  ```

- **`status:error`**（`error:branch-unresolved`）: 以下を表示してマージを停止

  ```text
  【エラー】現在のブランチを特定できません（detached HEAD状態の可能性）。
  1. `git branch --show-current` でブランチ名を確認
  2. ブランチにチェックアウトしてから再度このステップを実行
  リモートとの同期が確認できるまでPRマージに進まないでください。
  ```

- **`status:error`**（`error:log-failed`）: 以下を表示してマージを停止

  ```text
  【エラー】未pushコミットの確認に失敗しました。
  リモート参照の状態を手動で確認し、問題を解決してから再度このステップを実行してください。
  ```

## 6.6.7 mainブランチとの差分チェック【推奨】

PRマージ前に、サイクルブランチがmainブランチの最新変更を取り込んでいるか確認します。

```bash
# リモートの最新情報を取得
GIT_TERMINAL_PROMPT=0 git fetch origin 2>/dev/null
```

**fetchに失敗した場合**:
```text
【情報】リモートの確認に失敗しました（オフライン環境等）。
mainブランチとの差分チェックをスキップして処理を続行します。
```
→ 次のステップ（6.7 PRマージ）へ進む

**fetchに成功した場合**:

リモートのデフォルトブランチを検出し、現在のブランチがその変更を含んでいるか確認する:

```bash
# デフォルトブランチの検出
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
if [ -z "$DEFAULT_BRANCH" ]; then
    # フォールバック: main → master の順で確認
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
        DEFAULT_BRANCH="main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
        DEFAULT_BRANCH="master"
    fi
fi

# 差分チェック
if [ -n "$DEFAULT_BRANCH" ]; then
    git merge-base --is-ancestor "origin/${DEFAULT_BRANCH}" HEAD
fi
```

**結果に応じた対応**:

- **デフォルトブランチが検出できない場合**: 警告を表示し、次のステップへ進む
  ```text
  【警告】リモートのデフォルトブランチを特定できませんでした。
  mainブランチとの差分チェックをスキップします。
  ```

- **up-to-date**（`merge-base --is-ancestor` が成功）:
  ```text
  mainブランチの変更はすべて取り込み済みです。
  ```
  → 次のステップ（6.7 PRマージ）へ進む

- **behind**（`merge-base --is-ancestor` が失敗）:
  ```text
  【警告】mainブランチに未取り込みの変更があります。
  PRマージ前にmainの変更を取り込むことを推奨します。

  推奨コマンド:
  → git merge origin/{DEFAULT_BRANCH}
  → または git rebase origin/{DEFAULT_BRANCH}

  マージ後、再度このステップを実行してください。
  ```

  AskUserQuestion機能で対応を確認:
  ```text
  1. mainの変更を取り込んでからマージする(推奨)
  2. そのままマージを続行する
  ```

  - 「1」選択時: ユーザーにマージ/リベース実行を促し、完了後に再度このステップを実行
  - 「2」選択時: 次のステップ（6.7 PRマージ）へ進む

## 6.7 PRマージ【重要】

PRがレビュー承認された後、マージを実行します。

**自動クローズについて【Issue管理】**:

PRがマージされると、PR本文に `Closes #XX` と記載されたIssueは自動的にクローズされます。

**マージ前の確認**:
- サイクルPRの「Closes」セクションに全対応Issueが記載されているか確認（6.6で実施済み）
- 記載漏れがある場合は、PR本文を編集して追加してから進む

**`gh:available` 以外の場合**: スキップ（手動でマージ）

**レビュー承認状況の確認**（`gh:available` の場合）:

```bash
gh pr view {PR番号} --json reviewDecision,state
```

- `APPROVED`: 承認済み → マージ可能
- `CHANGES_REQUESTED` / `REVIEW_REQUIRED`: レビュー承認後に再度実行

**マージ実行**: ユーザーにマージ方法を確認し実行

```bash
# 通常マージ（デフォルト）
docs/aidlc/bin/pr-ops.sh merge {PR番号}

# Squashマージ
docs/aidlc/bin/pr-ops.sh merge {PR番号} --squash

# Rebaseマージ
docs/aidlc/bin/pr-ops.sh merge {PR番号} --rebase
```

**GitHub CLI利用不可時**:

```text
GitHub CLIが利用できません。
GitHub上でレビュー承認を確認してから、手動でPRをマージしてください。
```
