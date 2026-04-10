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

ドラフト PR を Ready for Review に変更。`gh:available` 以外はスキップ。Ready 化後はバグ修正以外の変更を加えない。

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

PR 本文の `Closes #XX` を最終確認。admin バイパスは案内しない（Branch protection 前提、未整備時は `guides/branch-protection.md`）。`gh_status` != `available` → 手動案内 / `merge_method=ask` → AskUserQuestion で選択 / 他 → 指定方式実行（「merge_method 設定に基づき {method} マージを実行します」と表示）。

```bash
scripts/operations-release.sh merge-pr --pr {PR番号} --method <merge|squash|rebase>
```

結果は `merged` / `auto-merge-set` / `error:<code>`。エラー対処は `merge-pr --help`。判定困難な error は AskUserQuestion で再試行 / 中断を選択。
