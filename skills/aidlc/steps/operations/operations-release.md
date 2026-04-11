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

`get-related-issues` → `find-draft` → `ready` → `gh pr edit --body-file` を順次実行。ドラフト不在時は同ブランチの非ドラフト open PR を検索し（部分成功 retry 冪等化）、見つかれば ready 化をスキップして `gh pr edit` のみ実行（重複 PR 作成を防止）。既存 PR が一切見つからない場合のみ `gh pr create --base main --title "{{CYCLE}}" --body-file <PATH>`（`--draft` なし）を実行。`get-related-issues` 出力から全関連 Issue の `Closes #XX` 記載漏れを手動照合（漏れは修正 → 再実行）。

## 7.9〜7.11 事前チェック【必須】

```bash
scripts/operations-release.sh verify-git
```

末尾に `verify-git:summary:uncommitted=<s>:remote-sync=<s>:default-branch=<s>` を出力。`validate-git.sh` 契約を透過（通常 exit 0、ハードエラー exit 2）、`default-branch` は推奨（fetch 失敗は `skipped`）。`warning` は追加コミット / `git push` / merge-rebase を案内、`error` はマージ停止。progress.md・history は stash せずコミット。

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
