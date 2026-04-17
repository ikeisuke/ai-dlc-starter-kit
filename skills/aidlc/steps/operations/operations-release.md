# Operations Phase - ステップ7: リリース準備

> 全体フローは `02-deploy.md`。自動化工程は `scripts/operations-release.sh`（`version-check` / `lint` / `pr-ready` / `verify-git` / `merge-pr`）に集約、詳細は `--help`。既存スクリプトを透過呼び出し（stdout / exit code そのまま）。本 markdown は人間判断工程のみ残す。

**前提条件**: ステップ1〜6完了、共通ルール読み込み済み、環境情報確認済み。

---

## 7.1 バージョン確認

```bash
scripts/operations-release.sh version-check [--ios-skip-marketing-version]
```

`project.type` で分岐:

- **general（その他）**: `suggest-version.sh` を実行
- **ios（フラグなし）**: `suggest-version.sh`（MARKETING_VERSION 確認）→ `ios-build-check.sh`（ビルド番号確認）の順で実行
- **ios（`--ios-skip-marketing-version` 付与）**: `ios-build-check.sh` のみ実行

Inception 履歴に「iOSバージョン更新実施」記録があれば AI が `--ios-skip-marketing-version` を付与してマーケティングバージョン確認をスキップ。iOS は `vX.Y.Z` → `X.Y.Z`。最終承認はユーザー判断。

## 7.2〜7.6 CHANGELOG / README / 履歴 / lint / progress

- `rules.release.changelog = true` の場合のみ CHANGELOG を Keep a Changelog 形式で更新（CHANGELOG は `[X.Y.Z]`、git タグは `vX.Y.Z`、`history/` / `story-artifacts/units/` / コミットから収集）、README にサイクル変更内容を追記
- `/write-history` で `history/operations.md` に記録
- `operations-release.sh lint --cycle {{CYCLE}}`（エラー時修正、`markdownlint:skipped` は設定スキップ）
- progress.md のステップ7を「完了」に更新し 7.7 のコミットに含める

## 7.7 Git コミット

コミットなしで 7.8 に進まない。`commit-flow.md` の「Operations Phase 完了コミット」に従い全変更をコミット。

## 7.8 ドラフト PR Ready 化【重要】

ドラフト PR を Ready for Review に変更。`gh:available` 以外はスキップ。Ready 化後はバグ修正以外の変更を加えない。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。

**PR 本文**: `templates/pr_body_template.md` を基に作成。`construction/units/*-review-summary.md` / `inception/*-review-summary.md` があれば「Closes」直前にレビューサマリセクションを挿入し GitHub blob URL（`{REPO_URL}/blob/cycle/{{CYCLE}}/...`）でリンク。

```bash
scripts/operations-release.sh pr-ready --cycle {{CYCLE}} --body-file <PR本文の一時ファイル>
```

`get-related-issues` → `find-draft` → `ready` → `gh pr edit --body-file` を順次実行。ドラフト不在時は同ブランチの非ドラフト open PR を検索し（部分成功 retry 冪等化）、見つかれば ready 化をスキップして `gh pr edit` のみ実行（重複 PR 作成を防止）。既存 PR が一切見つからない場合のみ `gh pr create --base main --title "{{CYCLE}}" --body-file <PATH>`（`--draft` なし）を実行。

**PR 番号の永続化（Unit 005 追加）**: 7.8 で `gh pr create` により初回 PR 作成されるエッジケース（Inception で `draft_pr=never` / `gh_status` 不可だった場合等）では、PR 作成直後に `operations/progress.md` の `pr_number=` スロットを取得した PR 番号で更新し、追加コミット（`chore: [{{CYCLE}}] PR番号記録 - operations/progress.md`）を行う。この追加コミットはマージ前に必ず main に取り込まれる構造とする。初回 PR 作成前のセッション再開では `pr_number` 欠損は正常状態であり、復帰判定は `release_done=false` を返して本ステップの継続を促す。

**Closes/Relates 区別**: `get-related-issues` は3行出力（`issues:`/`closes:`/`relates:`）。PR本文構築時は `closes:` 行の Issue を `Closes #XX` として記載し、`relates:` 行の Issue は `Relates to #XX（部分対応）` として記載する。`closes:none` の場合は Closes セクション省略、`relates:none` の場合は Related Issues セクション省略。記載漏れの手動照合は `closes:` + `relates:` の合計で確認する。

## 7.9〜7.11 事前チェック【必須】

```bash
scripts/operations-release.sh verify-git
```

末尾に `verify-git:summary:uncommitted=<s>:remote-sync=<s>:default-branch=<s>` を出力。`validate-git.sh` 契約を透過（通常 exit 0、ハードエラー exit 2）、`default-branch` は推奨（fetch 失敗は `skipped`）。

`remote-sync=<s>` の `<s>` は以下を取りうる:

- `ok`: 完全一致（続行）
- `warning`: unpushed（追加コミット / `git push` を案内、マージ停止しない）または behind（merge / rebase を案内、マージ停止しない）
- `diverged`（新規）: ローカルとリモートの履歴が分岐（squash 後等）。`validate-git.sh` の stdout 内 `recommended_command:` 行の**実値**をそのまま表示してユーザーに手動 force push を促し、完了後に再チェック。**マージ停止しない**（exit 0 扱い）
- `error`: マージ停止（`fetch-failed` / `no-upstream` / `branch-unresolved` / `upstream-resolve-failed` / `merge-base-failed` / `log-failed` のいずれか）

**UI 表示の文字列契約【重要】**: `diverged` 時の推奨コマンドは `validate-git.sh` の stdout から `^recommended_command:` 行を抽出してコロン以降を**そのまま**表示する。markdown 内にリテラル `<remote> <branch>` / `<resolved_*>` プレースホルダー文字列を書かない。force push の自動実行は禁止（ユーザー手動実行のみ）。

**事前確認の案内【必須】**: `diverged` の推奨コマンドは「ローカル履歴が正当な上書き対象」（自分の squash / rebase / amend 結果）を前提とする。他者の push や tracking 設定違いでも diverged は発生し、その場合 force push は他者の作業を破壊する。`recommended_command` を表示する際は、ユーザーに以下の事前確認を必ず依頼する:

- `git log HEAD..<remote>/<upstream_branch>` で upstream 側の差分コミットを確認（他者の作業が含まれていないか）
- `git log <remote>/<upstream_branch>..HEAD` でローカル側の差分コミットを確認（上書きする意図どおりか）
- 上記を確認した上で「ローカル履歴を正として上書きしてよい」場合のみ実行

他者コミットが upstream に含まれる・tracking 設定違いが疑われる場合は実行を中止し、ユーザー判断で対応（rebase / tracking 再設定 / 個別相談）を行う。

progress.md・history は stash せずコミット。

## 7.12 PR マージ前レビュー【推奨】

`git diff {DEFAULT_BRANCH}...HEAD` → `codex review --base {DEFAULT_BRANCH}`（利用可能時）→ `reviewing-operations-premerge` → `.aidlc/rules.md` のルール。GitHub PR レビュー実行時は `gh pr view --json reviewDecision` で判定（`APPROVED` → マージへ / `CHANGES_REQUESTED` → 修正・再レビュー / その他 → 待機またはスキップ）。

## 7.13 PR マージ【重要】

PR 本文の `Closes #XX` を最終確認。admin バイパスは案内しない（Branch protection 前提、未整備時は `guides/branch-protection.md`）。

**マージ方法の確定**: `gh_status` != `available` → 手動案内 / `merge_method=ask` → AskUserQuestion でマージ方法を選択 / 他 → `merge_method` 設定値をそのまま使用。いずれの場合もこの時点ではマージ方法の確定のみを行い、マージは実行しない。

**設定保存フロー**（`merge_method=ask` でユーザーがマージ方法を選択した場合のみ）:

選択後、「この選択を設定に保存しますか？」と確認:
- **はい**: 保存先を選択（デフォルト: `config.local.toml`（個人設定）、代替: `config.toml`（プロジェクト共有））
  ```bash
  scripts/write-config.sh rules.git.merge_method "<選択した値>" --scope <local|project>
  ```
  成功時: 「設定を保存しました」と表示。失敗時: 警告表示して続行
- **いいえ**: 今回の選択のみ使用して続行

**マージ実行確認【ユーザー選択: automation_mode に関わらず常にユーザー確認必須】**:

マージ方法の確定後、マージスクリプト実行前に `AskUserQuestion` でマージ実行の可否をユーザーに確認する。PRマージは破壊的・不可逆操作であり、SKILL.md「AskUserQuestion使用ルール」の「ユーザー選択」に分類されるため、`automation_mode` に関わらず（`full_auto` を含む全モードで）自動化対象外。

確認メッセージには以下の情報を提示:
- PR番号
- 適用されるマージ方法（`resolved_merge_method`）

ユーザー承認 → マージスクリプト実行へ / ユーザー拒否 → マージ中断（ユーザー判断で次のアクションを決定）。

```bash
scripts/operations-release.sh merge-pr --pr {PR番号} --method <merge|squash|rebase>
```

結果は `merged` / `auto-merge-set` / `error:<code>`。エラー対処は `merge-pr --help`。判定困難な error は AskUserQuestion で再試行 / 中断を選択。
