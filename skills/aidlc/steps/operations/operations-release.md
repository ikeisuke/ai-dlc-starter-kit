# Operations Phase - ステップ7: リリース準備

> 全体フローは `steps/operations/02-deploy.md` を参照。

**前提条件**: ステップ1〜6完了、共通ルール読み込み済み、環境情報確認済み。

---

## 7.1 バージョン確認

### iOSプロジェクトの場合

`project.type = "ios"` の場合のみ実行（未設定/エラー時は `general` 扱い）。

- Inception履歴に「iOSバージョン更新実施」記録あり → MARKETING_VERSION確認スキップ、ビルド番号確認へ
- 記録なし → 通常のバージョン確認を実行

**iOSビルド番号確認**:

```bash
scripts/ios-build-check.sh
```

| status | comparison | 対応 |
|--------|------------|------|
| not-found | - | スキップ |
| multiple | - | ユーザーにファイル選択→再実行 |
| found | updated | 続行 |
| found | same | 警告（App Storeは同一番号で再提出拒否） |
| found | unknown | 手動確認案内 |

### 通常のバージョン確認

`.aidlc/operations.md` の「バージョン確認設定」に従い確認。設定がなければ対話形式で対象特定。

バージョン未更新の場合は更新を提案。iOSプロジェクトはvプレフィックス除去（`v1.7.1` → `1.7.1`）。

## 7.2 CHANGELOG更新

`rules.release.changelog = true` の場合のみ実行（デフォルト `false`）。

Keep a Changelog形式で更新。表記: CHANGELOG `[X.Y.Z]`（vなし）、gitタグ `vX.Y.Z`（vあり）。

変更内容の収集元: history/、story-artifacts/units/、コミット履歴。

## 7.3 README更新

今回のサイクルの変更内容を追記。

## 7.4 履歴記録

`/write-history` スキルで `.aidlc/cycles/{{CYCLE}}/history/operations.md` に記録。

## 7.5 Markdownlint実行

```bash
scripts/run-markdownlint.sh {{CYCLE}}
```

エラーあれば修正してから次へ。`markdownlint:skipped` は設定によるスキップ。

## 7.6 progress.md更新

ステップ7を「完了」（= PR準備完了）に更新。この更新を7.7のコミットに含める。

## 7.7 Gitコミット

> **順序制約**: コミットが存在しない状態で7.8に進んではいけない。

Operations Phaseで作成した全ファイル（progress.md、履歴含む）をコミット。`commit-flow.md` の「Operations Phase完了コミット」に従う。

## 7.8 ドラフトPR Ready化【重要】

Inception Phaseで作成したドラフトPRをReady for Reviewに変更。`gh:available` 以外はスキップ。

**Ready化後の注意**: バグ修正・追加要件がない限り新たな変更を加えない。

### Closes記載確認

```bash
scripts/pr-ops.sh get-related-issues {{CYCLE}}
```

PR本文に全関連Issueの `Closes #XX` が記載されているか確認。記載漏れがあれば警告。

### ドラフトPR検索・Ready化

```bash
scripts/pr-ops.sh find-draft          # ドラフトPR検索
scripts/pr-ops.sh ready {PR番号}       # Ready化
```

### PR本文更新

テンプレート `templates/pr_body_template.md` を基にPR本文を作成。

```bash
gh pr edit {PR番号} --body-file <一時ファイルパス>
```

**レビューサマリの記載**: `.aidlc/cycles/{{CYCLE}}/construction/units/*-review-summary.md` と `inception/*-review-summary.md` が存在する場合、「Closes」セクション直前に「レビューサマリ」セクションを挿入。GitHub blob URL形式でリンク（`{REPO_URL}/blob/cycle/{{CYCLE}}/...`）。

### ドラフトPRが見つからない場合

新規PR作成を提案。Issue番号は `intent.md` → `setup-context.md` の順で取得。

```bash
gh pr create --base main --title "{{CYCLE}}" --body-file <一時ファイルパス>
```

## 7.9 コミット漏れ確認【必須】

```bash
scripts/validate-git.sh uncommitted
```

| status | 対応 |
|--------|------|
| `ok` | 次へ |
| `warning` | 未コミットファイル一覧を表示、追加コミットを推奨 |
| `error` | マージ停止、git状態の確認を案内 |

**注意**: progress.md・historyファイルはstashではなくコミットすべき。

## 7.10 リモート同期確認【必須】

```bash
scripts/validate-git.sh remote-sync
```

| status | 対応 |
|--------|------|
| `ok` | 次へ |
| `warning` | 未pushコミットあり。`git push` を案内 |
| `error` | エラー種別に応じて対処案内（fetch失敗/upstream未設定/branch不明/log失敗） |

## 7.11 mainブランチとの差分チェック【推奨】

リモートfetch後、デフォルトブランチ（`git remote show origin` → fallback: main → master）との差分を確認。

```bash
git merge-base --is-ancestor origin/{DEFAULT_BRANCH} HEAD
```

| 結果 | 対応 |
|------|------|
| 成功（up-to-date） | 次へ |
| 失敗（behind） | merge/rebase推奨。続行も可能（ユーザー選択） |
| fetch失敗 | スキップして続行 |

## 7.12 PRマージ前レビュー【推奨】

### サブステップ0: ローカルレビュー

1. `git diff {DEFAULT_BRANCH}...HEAD` で差分確認
2. Codex CLI利用可能時: `codex review --base {DEFAULT_BRANCH}`
3. reviewingスキル: `skill="reviewing-operations-premerge"` で実行

両方失敗してもサブステップ1で品質確認可能なため中断不要。

### サブステップ1: プロジェクト固有レビュー

`.aidlc/rules.md` にPRマージ前レビュールールがあれば実行。なければスキップ。

### サブステップ2: PRレビュー状態確認

サブステップ1でGitHub PRレビューを実行した場合のみ。

```bash
gh pr view {PR番号} --json reviewDecision --jq '.reviewDecision'
```

| reviewDecision | 対応 |
|----------------|------|
| `APPROVED` | マージへ |
| `CHANGES_REQUESTED` | 修正→コミット→push→サブステップ1へ戻る |
| その他/空 | レビュー完了待ちまたはスキップ（ユーザー選択） |

## 7.13 PRマージ【重要】

PR本文の `Closes #XX` 記載を最終確認。

```bash
gh pr view {PR番号} --json reviewDecision,state  # 承認状況確認
scripts/pr-ops.sh merge {PR番号}                   # 通常マージ
scripts/pr-ops.sh merge {PR番号} --squash           # Squashマージ
scripts/pr-ops.sh merge {PR番号} --rebase           # Rebaseマージ
```

### マージ方法の決定

1. **`gh_status` != `available`**: merge_methodに関わらず手動マージを案内
2. **`merge_method` == `"ask"`**: AskUserQuestionでマージ方法を選択させる（通常マージ / Squashマージ / Rebaseマージ）
3. **`merge_method` == `"merge"` / `"squash"` / `"rebase"`**: 指定方法で自動実行。「merge_method設定に基づき {method} マージを実行します。」と表示
4. **マージ失敗時**:
   - `gh` 利用不可系エラー（未認証、CLI異常、`require_gh`失敗相当）→ 手動マージ案内にフォールバック
   - その他のエラー → エラー内容を表示し、AskUserQuestionでマージ方法を再選択（通常マージ / Squashマージ / Rebaseマージ / 中断する）
