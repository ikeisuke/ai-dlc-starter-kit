# 論理設計: Unit 002 - 必須 Checks の常時 PASS 報告化

## 概要

Unit 002 で採用する案2（既存 workflow の job を常時起動 + 内部 step 分岐）の具体的な YAML 構造、Detect skip ロジック、step-level skip 制御を論理レベルで定義する。本 Unit は YAML 編集であるためコードを書かないが、各 workflow の差分仕様と Detect skip step のシェル ロジックを記述する。

**重要**: この論理設計ではコードは書かず、変更後の YAML 構造・Detect skip step の擬似コード仕様のみを定義する。実装は Phase 2 で行う。

## 採用案の確定

### 案1 採用ゲート判定

**判定結果**: 案2 を確定採用（案1 は不採用）

判定根拠:

- 案1 採用ゲートの 3 条件（GitHub 仕様確認 + PASS 報告 PoC + FAIL 伝播 PoC）のうち、本サイクル v2.4.1（patch サイクル）では PoC 実施工数が見積もり超過するため実施しない
- 案2 は GitHub Actions 標準機能のみで実装でき、FAIL 伝播が workflow 単位で自然に成立する（同名 check 衝突リスクなし）
- v2.3.6 の Draft skip による runner 課金抑制効果は、本処理 step の `if:` 制御で実質的に維持できる（skip 条件下では Detect skip step のみが軽量に実行）

### 案2 採用後の不確定要素

- 案1 を将来検討する場合、別 Unit / 別サイクルで PoC を実施し、FAIL 伝播挙動を確認した上で案1 を再評価する（v2.5.0 以降の課題候補）

## アーキテクチャパターン

GitHub Actions の **常時起動 + 内部分岐** パターン:

- workflow trigger は `pull_request` の paths 非依存（`paths:` 削除）
- job-level の `if:` は削除（常時起動）
- step 1（Detect skip）で Draft 状態 + paths 該当性を判定し、`should_skip` 出力を設定
- 後続 step すべてに `if: steps.detect.outputs.should_skip != 'true'` を付与し、skip 条件下では skip 扱い（job 全体の `conclusion` は `success`）

## 改訂対象 workflow と変更構造

### 共通: 全 3 workflow の変更点

| 変更項目 | Before | After |
|---------|--------|-------|
| `on.pull_request.paths:` | 各 workflow ごとに paths 指定あり | **削除**（trigger は常に発火） |
| `jobs.<job>.if:` | `github.event.pull_request.draft == false` | **削除**（job は常に起動） |
| `jobs.<job>.permissions:` | `contents: read`（workflow-level） | `contents: read` + `pull-requests: read`（changed-files 取得用、job-level に追加 OR workflow-level を維持） |
| `jobs.<job>.steps[].id` 追加 | なし | 1 番目の step に `id: detect`（skip 判定の参照用） |
| `jobs.<job>.steps[].if:` 追加 | なし | Checkout 以降のすべての step に `if: steps.detect.outputs.should_skip != 'true'` |

### Detect skip step（共通仕様）

各 workflow の各 job の最初に挿入する step:

```yaml
- name: Detect skip
  id: detect
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    PR_NUMBER: ${{ github.event.pull_request.number }}
    PR_DRAFT: ${{ github.event.pull_request.draft }}
    PATHS_REGEX: '<workflow ごとの正規表現>'
  run: |
    set -eu
    if [ "$PR_DRAFT" = "true" ]; then
      printf 'should_skip=true\n' >> "$GITHUB_OUTPUT"
      printf 'reason=draft\n' >> "$GITHUB_OUTPUT"
      echo "Skip reason: Draft PR"
      exit 0
    fi
    gh api "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/files" --paginate --jq '.[].filename' > "$RUNNER_TEMP/changed-files.txt"
    if grep -E "$PATHS_REGEX" "$RUNNER_TEMP/changed-files.txt" >/dev/null; then
      printf 'should_skip=false\n' >> "$GITHUB_OUTPUT"
      printf 'reason=paths-match\n' >> "$GITHUB_OUTPUT"
      echo "Skip reason: none (paths matched)"
    else
      printf 'should_skip=true\n' >> "$GITHUB_OUTPUT"
      printf 'reason=paths-no-match\n' >> "$GITHUB_OUTPUT"
      echo "Skip reason: paths not match"
    fi
```

設計上の注記:

- `set -eu` で未定義変数・コマンド失敗時に即座に異常終了させる
- `gh api ... --paginate --jq '.[].filename'` で **すべての変更ファイル**を取得し `$RUNNER_TEMP/changed-files.txt` に書き出す（paginate 必須、PR が大きい場合に取りこぼさない）
- 変更ファイル一覧はファイル経由で `grep -E` に渡す。`$(...)` コマンド置換は使用しない（プロジェクトルール準拠 — CLAUDE.md「シェルコマンド置換 `$(...)` の絶対禁止」）
- `grep -E` の正規表現は workflow ごとに異なる値を `PATHS_REGEX` env から渡す
- `$RUNNER_TEMP` は GitHub Actions が job 単位で提供する一時ディレクトリ（job 終了時に自動破棄）
- `gh` コマンドの実行は `pull-requests: read` 権限が必要（後述）

### Workflow ごとの paths 正規表現（PATHS_REGEX）

**glob → regex 変換規則**:

| glob パターン | 意図 | regex 翻訳 |
|--------------|------|-----------|
| `**.md` | 任意ディレクトリ配下（ルート含む）の `.md` | `^.+\.md$` |
| `**.toml` | 任意ディレクトリ配下（ルート含む）の `.toml` | `^.+\.toml$` |
| `<dir>/**` | `<dir>/` 配下の任意階層のファイル（少なくとも 1 ファイル） | `^<dir>/.+$` |
| `<dir>/**/<file>` | `<dir>/` 直下も含む 0 階層以上配下の `<file>` | `^<dir>/(.+/)?<file>$` |
| `<file>` | 完全一致 | `^<file>$` |

注: GitHub Actions の `**` は「0 個以上の任意階層」を意味するため、`<dir>/**/<file>` は `<dir>/<file>` も `<dir>/sub/<file>` もマッチさせる必要がある（中間階層は省略可）。

#### pr-check.yml

```text
^(.+\.md|.+\.toml|\.markdownlint\.json|\.github/workflows/pr-check\.yml|bin/check-bash-substitution\.sh|bin/check-defaults-sync\.sh|version\.txt|skills/(.+/)?version\.txt)$
```

該当チェック: 3 jobs（`Markdown Lint` / `Bash Substitution Check` / `Defaults TOML Sync Check`）すべてが同じ paths を共有

注意: `skills/**/version.txt` は GitHub Actions の `**` 仕様により `skills/version.txt` も `skills/foo/version.txt` も `skills/foo/bar/version.txt` もマッチする必要があるため、`skills/(.+/)?version\.txt` で 0 階層以上の中間ディレクトリを許容する。

#### migration-tests.yml

```text
^(skills/aidlc-migrate/scripts/migrate-.*\.sh|skills/aidlc-migrate/scripts/lib/.+|tests/migration/.+|tests/fixtures/.+|\.github/workflows/migration-tests\.yml)$
```

該当チェック: 1 job（`Migration Script Tests`）

#### skill-reference-check.yml

```text
^(skills/.+|bin/check-skill-references\.sh|\.github/workflows/skill-reference-check\.yml)$
```

該当チェック: 1 job（`Skill Reference Check`）

注: 上記すべての翻訳は「変換規則表」に従い、特に `**` を含む glob は 0 階層以上を確実に許容する。設計レビューで翻訳の妥当性を確認する。

### Job 構造の改訂例（pr-check.yml の markdown-lint）

#### Before

```yaml
jobs:
  markdown-lint:
    name: Markdown Lint
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Run markdownlint
        uses: DavidAnson/markdownlint-cli2-action@v18
        with:
          globs: |
            docs/translations/**/*.md
            prompts/**/*.md
            *.md
```

#### After

```yaml
jobs:
  markdown-lint:
    name: Markdown Lint
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
    steps:
      - name: Detect skip
        id: detect
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          PR_DRAFT: ${{ github.event.pull_request.draft }}
          PATHS_REGEX: '^(.+\.md|.+\.toml|\.markdownlint\.json|\.github/workflows/pr-check\.yml|bin/check-bash-substitution\.sh|bin/check-defaults-sync\.sh|version\.txt|skills/(.+/)?version\.txt)$'
        run: |
          set -eu
          if [ "$PR_DRAFT" = "true" ]; then
            printf 'should_skip=true\n' >> "$GITHUB_OUTPUT"
            exit 0
          fi
          gh api "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/files" --paginate --jq '.[].filename' > "$RUNNER_TEMP/changed-files.txt"
          if grep -E "$PATHS_REGEX" "$RUNNER_TEMP/changed-files.txt" >/dev/null; then
            printf 'should_skip=false\n' >> "$GITHUB_OUTPUT"
          else
            printf 'should_skip=true\n' >> "$GITHUB_OUTPUT"
          fi
      - name: Checkout
        if: steps.detect.outputs.should_skip != 'true'
        uses: actions/checkout@v4
      - name: Run markdownlint
        if: steps.detect.outputs.should_skip != 'true'
        uses: DavidAnson/markdownlint-cli2-action@v18
        with:
          globs: |
            docs/translations/**/*.md
            prompts/**/*.md
            *.md
```

注: 上記 YAML 内の bash ブロックは `$(...)` コマンド置換を使用していない（プロジェクトルール準拠）。`gh api` の出力は `$RUNNER_TEMP/changed-files.txt` に書き出してから `grep -E` でファイル経由で評価する。

### permissions の追加について

`gh api` で `repos/{owner}/{repo}/pulls/{N}/files` を呼び出すには、デフォルトの `GITHUB_TOKEN` で `pull-requests: read` 権限が必要。既存の `permissions: contents: read` を維持しつつ、各 job に `pull-requests: read` を追加する（NFR セキュリティ要件「最低限の権限」を維持）。

## 非機能要件（NFR）への対応

### パフォーマンス

- skip 条件下では Detect skip step のみが実行される（runner 起動 + `gh api` 呼び出し）。所要時間は約 5-10 秒。`Checkout` 以降の step は GitHub Actions の `if:` 評価により skip され、本処理コスト（markdownlint 実行 等）は発生しない
- paths 該当 + Ready 時は、Detect skip step（5-10秒）+ 従来の本処理 step が走る。本処理に比べて Detect skip のオーバーヘッドは無視できる範囲

### セキュリティ

- `permissions: contents: read` + `pull-requests: read` のみに限定（書き込み権限なし）
- `GH_TOKEN` は `secrets.GITHUB_TOKEN` の自動発行 token を使用（外部 secret 不要）
- `set -eu` でエラー時の伝播を確実にする

### スケーラビリティ

- `--paginate` で大きな PR（変更ファイル 100+ 件）にも対応

### 可用性

- `gh api` 呼び出し失敗時は `set -eu` により step が `failure` で終了し、required check も `failure` 報告となる（誤って PASS 報告して隠蔽しない）
- changed-files 取得失敗の頻度が高い場合は将来的に `tj-actions/changed-files` 等の検討余地

## 実装上の注意事項

- **既存 workflow の挙動回帰**: 案2 採用により全 PR で 5 job が起動するため、Detect skip step の正規表現が誤って paths 非該当判定すると本処理が走らず PASS だけ返ってしまう（実害は本処理スキップだが、検証ケース1 で必ず確認）
- **正規表現の正確性**: `**.md` を `.+\.md` に翻訳する際の挙動差（`a.md` / `dir/a.md` などの一致範囲）を Phase 2b 検証ケース 1〜3 で確認
- **`gh api` の rate limit**: GitHub API rate limit は通常 5000 req/h（authenticated）。3 workflow × 5 job = 5 job が同時に呼ぶため、PR 1 件あたり 5 リクエスト。日常的な PR 頻度では問題なし
- **ワークフロー権限**: `permissions:` を job-level に追加する形式とし、workflow-level の既存記述は維持する（影響範囲を job 単位に閉じる）

## 技術選定

- **対象ファイル形式**: GitHub Actions YAML（`.github/workflows/*.yml`）
- **使用ツール**: `gh api`（GitHub CLI、ランナー標準搭載）、`grep -E`（POSIX 拡張正規表現）
- **新規 action 追加**: なし（標準機能のみ）

## 不明点と質問（設計中に記録）

[Question] `gh api ... --paginate --jq` の出力が空（変更ファイル 0 件）になるケースで挙動が破綻しないか？
[Answer] `pull_request` イベントの定義上、変更ファイル 0 件の PR は存在しないが、`grep` が空入力に対し exit 1 を返すケースを `set -eu` 環境で扱う必要がある。実装時は `if grep -E "$PATHS_REGEX" "$RUNNER_TEMP/changed-files.txt"; then ... else ... fi` の構造で grep 失敗（パス非該当）も正常分岐として扱う設計（`if` 文中の grep は exit 1 でも `set -e` を発動しない POSIX 仕様）。

[Question] 案2 で paths 判定を入れることで、既存 paths フィルタ（workflow trigger）の役割との二重化が発生しないか？
[Answer] 二重化は発生する（paths 判定が trigger と step の両方に存在）。ただし trigger 側の `paths:` を削除しているため、step 側のみに paths 判定が集約される。既存 workflow の paths 一覧と step 側の正規表現を Phase 2 で正確に同期する責務がある。

[Question] check 名と job 名の維持は本当に Branch protection 側の変更なしで成立するか？
[Answer] Yes。Branch protection の required check 名は workflow ファイル内の `name:` 属性（job 名）と一致するため、本 Unit では job 名（5 つすべて）を変更しないことで Branch protection 設定の改修は不要。
