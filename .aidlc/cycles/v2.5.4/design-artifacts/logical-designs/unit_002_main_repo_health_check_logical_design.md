# Unit 002 論理設計: メインリポジトリ Health Check

## 1. 関数構成

`skills/aidlc/scripts/main-repo-health-check.sh` の関数階層:

```
main()                          # エントリポイント
├── show_help()                 # --help / -h
├── resolve_main_repo_path()    # MainRepositoryPath 解決
├── check_unmerged_paths()      # HealthCheckItem: unmerged-paths
├── check_merge_in_progress()   # HealthCheckItem: merge-in-progress
└── check_conflict_marker()     # HealthCheckItem: conflict-marker
```

> **注**: 当初は `emit_status()` を含めていたが、Round 1 レビューでエラー message 引数の設計上の問題が指摘されたため廃止し、`main()` 内で直接 stdout 出力する方針に統一した（§1.6 参照）。

### 1.1 `main()`

```bash
# グローバル変数: エラー理由文字列（resolve_* / check_* がエラー時に書き込む）
__MRHC_ERROR_REASON=""

main() {
    local main_repo_path
    main_repo_path=$(resolve_main_repo_path)
    local resolve_ec=$?
    if [ "$resolve_ec" -ne 0 ]; then
        echo "status:error"
        echo "error:git-path-resolve-failed:${__MRHC_ERROR_REASON:-unknown}"
        exit 2
    fi

    local has_warning=0 has_error=0
    check_unmerged_paths "$main_repo_path"
    case $? in
        0) ;;
        1) has_warning=1 ;;
        *) has_error=1 ;;
    esac

    check_merge_in_progress "$main_repo_path"
    case $? in
        0) ;;
        1) has_warning=1 ;;
        *) has_error=1 ;;
    esac

    check_conflict_marker "$main_repo_path"
    case $? in
        0) ;;
        1) has_warning=1 ;;
        *) has_error=1 ;;
    esac

    if [ "$has_error" -eq 1 ]; then
        echo "status:error"
        exit 2
    fi
    if [ "$has_warning" -eq 1 ]; then
        echo "status:warning"
    else
        echo "status:ok"
    fi
    exit 0
}
```

警告検出時も `exit 0` を維持（`exit-code-convention.md` 準拠）。エラー検出時は `exit 2`。各 `check_*` 関数の戻り値:

- `0`: 健全
- `1`: 警告検出（`has_warning=1` を立てる）
- `>=2`: システムエラー（`has_error=1` を立てる、最終的に exit 2）

エラー理由の機械可読文字列は `__MRHC_ERROR_REASON` グローバル変数経由で `resolve_*` から渡し、`emit_status` 経由ではなく `main()` で直接 `error:<code>:<reason>` を組み立てる。`emit_status` は不要のため削除。

### 1.2 `resolve_main_repo_path()`

```bash
resolve_main_repo_path() {
    local toplevel git_common_dir
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
        __MRHC_ERROR_REASON="git rev-parse --show-toplevel failed"
        return 2
    }
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || {
        __MRHC_ERROR_REASON="git rev-parse --git-common-dir failed"
        return 2
    }

    # 相対パスの場合は worktree top を基準に絶対化
    case "$git_common_dir" in
        /*) ;;  # 既に絶対パス
        *) git_common_dir=$(cd "$toplevel" && cd "$git_common_dir" && pwd) || {
            __MRHC_ERROR_REASON="cannot absolutize git-common-dir from toplevel=${toplevel}"
            return 2
        } ;;
    esac

    # main repo top = git-common-dir の親 (.git を 1 階層上に上がる)
    dirname "$git_common_dir"
}
```

- 戻り値: stdout に絶対パス（main repo の worktree top）
- エラー時: return 2 + `__MRHC_ERROR_REASON` グローバル変数に reason 文字列を設定
- 呼び出し側（`main()`）は `__MRHC_ERROR_REASON` を読んで `error:git-path-resolve-failed:<reason>` を stdout に出力

### 1.3 `check_unmerged_paths()`

```bash
check_unmerged_paths() {
    local main_repo_path="$1"
    local porcelain
    # porcelain v1 を明示固定（将来フォーマット変更を予防）
    porcelain=$(git -C "$main_repo_path" status --porcelain=v1 2>/dev/null) || {
        echo "health-check:unmerged-paths:error:git-status-failed"
        return 2
    }

    # grep -c は「マッチ件数を出力、未マッチ時 exit 1」。set -e + pipefail 環境下では
    # || true でガードし、失敗時 0 を採用する。
    local unmerged_count
    unmerged_count=$(printf '%s\n' "$porcelain" | grep -c -E "^(UU|AA|DD|DU|UD|AU|UA) " || true)

    if [ "$unmerged_count" -gt 0 ]; then
        echo "health-check:unmerged-paths:warning:count=${unmerged_count}"
        return 1
    else
        echo "health-check:unmerged-paths:ok:count=0"
        return 0
    fi
}
```

- **porcelain v1 前提**: `--porcelain=v1` を明示固定し、将来 `--porcelain=v2` 等のフォーマット変更で破綻しないよう契約を凍結
- マージコンフリクト行の検出: `git status --porcelain` 出力の先頭 2 文字を見て XX 状態（XY where one or both is U/A/D conflict marker）を抽出
- **`grep -c` + `|| true`**: `grep -c` は未マッチ時 exit 1 を返すが `|| true` で吸収。`set -euo pipefail` 環境下でも安全
- 警告時: return 1（呼び出し側で `has_warning=1` を立てる）

#### porcelain v1 のマージコンフリクト 7 種

`git status --porcelain=v1` で先頭 2 文字が以下のときマージコンフリクト:

| パターン | 意味 |
|----------|------|
| `UU` | 両方変更 |
| `AA` | 両方追加 |
| `DD` | 両方削除 |
| `DU` | 自分側削除 / 相手側変更 |
| `UD` | 自分側変更 / 相手側削除 |
| `AU` | 自分側追加 / 相手側変更 |
| `UA` | 自分側変更 / 相手側追加 |

### 1.4 `check_merge_in_progress()`

```bash
check_merge_in_progress() {
    local main_repo_path="$1"

    # git -C "$main_repo_path" に固定して main repo コンテキストで rev-parse する。
    # これにより検出対象は <main-repo>/.git/MERGE_HEAD のみ（linked worktree 側の
    # 進行中状態は本 Unit では検出しない / scope 外）。
    local merge_head_path cherry_path rebase_path
    merge_head_path=$(git -C "$main_repo_path" rev-parse --git-path MERGE_HEAD 2>/dev/null) || {
        echo "health-check:merge-in-progress:error:git-path-failed"
        return 2
    }
    cherry_path=$(git -C "$main_repo_path" rev-parse --git-path CHERRY_PICK_HEAD 2>/dev/null) || {
        echo "health-check:merge-in-progress:error:git-path-failed"
        return 2
    }
    rebase_path=$(git -C "$main_repo_path" rev-parse --git-path REBASE_HEAD 2>/dev/null) || {
        echo "health-check:merge-in-progress:error:git-path-failed"
        return 2
    }

    local in_progress_files=()
    [ -e "$merge_head_path" ] && in_progress_files+=("MERGE_HEAD")
    [ -e "$cherry_path" ] && in_progress_files+=("CHERRY_PICK_HEAD")
    [ -e "$rebase_path" ] && in_progress_files+=("REBASE_HEAD")

    if [ "${#in_progress_files[@]}" -gt 0 ]; then
        local joined
        joined=$(printf '%s,' "${in_progress_files[@]}" | sed 's/,$//')
        echo "health-check:merge-in-progress:warning:files=${joined}"
        return 1
    else
        echo "health-check:merge-in-progress:ok:files=none"
        return 0
    fi
}
```

**重要**: 本 helper は **メインリポジトリ作業ツリーの進行中状態のみ検査する**:

- `git -C "$main_repo_path" rev-parse --git-path MERGE_HEAD` は **main repo コンテキスト**で評価され、`<main-repo>/.git/MERGE_HEAD` を返す
- 結果として、検出対象は `<main-repo>/.git/MERGE_HEAD` / `CHERRY_PICK_HEAD` / `REBASE_HEAD` のみ
- linked worktree 配下の進行中状態（`.git/worktrees/<name>/MERGE_HEAD`）は **本 helper の scope 外**

> **設計判断**: Unit 002 の責務は「メインリポジトリの状態異常検出」であり、Unit 定義および Intent でも「メインリポジトリの `git status --porcelain` / `MERGE_HEAD` 有無」と明示されている。本 helper は **linked worktree 側の進行中状態を検出しない**（`resolve_main_repo_path()` は呼び出し元コンテキストにかかわらず main repo の worktree top を返し、`git -C "$main_repo_path"` で main repo コンテキストに固定するため、検査対象は `<main-repo>/.git/MERGE_HEAD` 等のみ）。
>
> linked worktree 側の進行中状態（`.git/worktrees/<name>/MERGE_HEAD`）が必要な場合は、本 helper の責務外として別 Unit / 別 helper で対応する（次サイクル以降の候補）。本 Unit のスコープ保護のため、本 helper では検出しない。

### 1.5 `check_conflict_marker()`

```bash
check_conflict_marker() {
    local main_repo_path="$1"
    local matches matches_count

    # git grep -I (binary 自動除外) + -n (行番号) + -E (regex)
    # exit code 1 は「マッチなし」、exit code 0 はマッチあり、exit code >=2 はエラー
    set +e
    matches=$(git -C "$main_repo_path" grep -I -n -E "^<<<<<<< |^>>>>>>> |^=======$" 2>/dev/null)
    local grep_ec=$?
    set -e

    if [ "$grep_ec" -ge 2 ]; then
        echo "health-check:conflict-marker:error:git-grep-failed"
        return 2
    fi

    if [ -z "$matches" ]; then
        echo "health-check:conflict-marker:ok:count=0"
        return 0
    fi

    matches_count=$(printf '%s\n' "$matches" | wc -l | tr -d ' ')
    echo "health-check:conflict-marker:warning:count=${matches_count}"
    return 1
}
```

- **主経路**: `git grep -I -n -E ...` (BSD/GNU 両対応、tracked + バイナリ自動除外)
- 戻り値の解釈: `git grep` の exit code は `0`=マッチあり / `1`=マッチなし / `>=2`=エラー
- マッチ件数を `wc -l` で算出（マッチ行数 = マーカー行数）

### 1.6 `emit_status` 関数の廃止

Round 1 レビューで `emit_status` 経由のエラー message 引数が exit code 数値になる設計上の問題が指摘されたため、本関数は **削除**する。代わりに `main()` 内で `__MRHC_ERROR_REASON` グローバル変数を読んで `error:<code>:<reason>` を直接出力する。`status:ok` / `status:warning` も `main()` で直接 echo する（§1.1 参照）。

## 2. stdout フォーマット契約（再掲）

### 健全時

```
status:ok
health-check:unmerged-paths:ok:count=0
health-check:merge-in-progress:ok:files=none
health-check:conflict-marker:ok:count=0
```

exit 0

### 警告時（例: コンフリクトマーカー残骸）

```
status:warning
health-check:unmerged-paths:ok:count=0
health-check:merge-in-progress:ok:files=none
health-check:conflict-marker:warning:count=6
```

exit 0

### エラー時（例: git rev-parse 失敗）

```
status:error
error:git-path-resolve-failed:rev-parse failed
```

exit 2

## 3. Cross-platform 互換戦略

### 3.1 `git grep` 主経路化

- **採用**: `git grep -I -n -E "<pattern>"`
  - `-I`: バイナリ自動除外（macOS BSD / Linux GNU 両対応）
  - `-n`: 行番号付加
  - `-E`: 拡張正規表現
- **回避**: `grep` 単体 + `git ls-files` の組み合わせ（BSD は `-I` の挙動が異なる、`-z` ヘッダー処理の差異）

### 3.2 POSIX 互換オプション

`grep -E "^(UU|AA|DD|DU|UD|AU|UA) "` は POSIX ERE 標準に準拠（BSD/GNU 両対応）。代替の `egrep` は廃止扱いのため使わない。

### 3.3 `wc -l | tr -d ' '`

`wc -l` の出力に macOS BSD はスペースを前置する場合がある。`tr -d ' '` で正規化。

### 3.4 `dirname` / `cd` / `pwd`

POSIX 標準で BSD/GNU 共通動作。

## 4. 01-setup.md への挿入

### 4.1 挿入位置

既存番号体系（`1, 2, 3, 4, 5, 6, 6a, 6b, 7, 8, 9, 10, 11`）を維持。**step:3a** を新設し、step 3（プリフライトチェック）の直後 / step 4（セッション判別設定）の前に挿入する。

### 4.2 挿入文言

`skills/aidlc/steps/operations/01-setup.md` の step 3 直後に以下のセクションを追加:

```markdown
### 3a. メインリポジトリ Health Check【重要】

worktree 環境で AI-DLC を運用する際、過去の `git stash pop` 残骸 / マージ進行中状態 / unmerged paths を Operations Phase 開始時に早期検出する（v2.5.3 で発生した `post-merge-cleanup.sh` 失敗の再発防止、Unit 002 / #657）。

**チェック手順**:

```bash
scripts/main-repo-health-check.sh
```

出力の `status:` 行と `health-check:<item>:<status>:<detail>` 行から判定する。**AI エージェントは独自の git 判定を行わず、helper の出力をそのまま消費する**（検出ロジックは helper 内に閉じる）。

**正規化状態と分岐**:

| helper 出力 | 動作 |
|------------|------|
| `status:ok` | 「✓ メインリポジトリ health check: 異常なし」表示、続行 |
| `status:warning` + `health-check:<item>:warning:<detail>` | 「⚠ メインリポジトリ health check で警告検出: <item> (<detail>)」表示 → `AskUserQuestion`「復旧手順を実施 / スキップして続行 / 中断」 |
| `status:error` + `error:<code>:<message>` | 「⚠ メインリポジトリ health check 実行失敗: <code> - <message>」表示、続行（致命的でない場合）または中断（git 環境破損等） |

**warning 時の復旧手順案内例**（呼び出し側で表示する内容）:

- `unmerged-paths`: メインリポジトリの worktree top に移動し `git status` で詳細確認 → 各ファイルを手動編集してコンフリクトを解消 → `git add <files>` でステージ → 進行中状態に応じて `git merge --continue` / `git cherry-pick --continue` / `git rebase --continue` で継続、もしくは `git merge --abort` / `git cherry-pick --abort` / `git rebase --abort` で中断
- `merge-in-progress`: メインリポジトリで `git status` で進行中の操作種別を確認 → 完了させるなら上記 `--continue`、放棄するなら `--abort`
- `conflict-marker`: 該当ファイルでコンフリクトマーカー（`<<<<<<<` / `>>>>>>>` / `=======`）を手動編集して解消 → `git add` してコミット

> **注**: `git checkout --` は意図しないファイル破棄を引き起こす可能性があるため、上記復旧手順例には**含めない**。ユーザーが個別に判断する局面（編集中の変更を破棄したい等）で別途使用する想定。

**AskUserQuestion 必須性**: warning は「ユーザー選択」（SKILL.md「AskUserQuestion 使用ルール」）に分類され、`automation_mode` に関わらず対話を省略してはならない。

**呼び出し側は exit code を warning として扱わない**: helper の exit code は `0`（健全 + 警告）または `2`（システムエラー）。warning は **stdout の `status:warning` を判定**して検出する。

---
```

### 4.3 後続 step 番号の不変

step 4-11 はすべて再採番せず、既存番号を維持する。

## 5. bats fixture 設計

### 5.1 fixture 構造

`tests/main-repo-health-check.bats` の各シナリオは `BATS_TEST_TMPDIR` 配下に独立した bare/working repo を生成し、`teardown()` で破棄する。

```bash
setup() {
    export FIXTURE_REPO="${BATS_TEST_TMPDIR}/fake-main-repo"
    # 既定ブランチを main に明示（環境依存を排除、git ≥ 2.28 必要）
    git init -b main "$FIXTURE_REPO" >/dev/null
    cd "$FIXTURE_REPO"
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "initial" > README.md
    git add README.md
    git commit -m "initial" >/dev/null
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}/fake-main-repo"
}
```

### 5.2 シナリオ 1: 健全（exit 0 + status:ok）

```bash
@test "healthy: clean repo returns exit 0 + status:ok" {
    cd "$FIXTURE_REPO"
    run bash "${BATS_TEST_DIRNAME}/../skills/aidlc/scripts/main-repo-health-check.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ status:ok ]]
    [[ "$output" =~ health-check:unmerged-paths:ok ]]
    [[ "$output" =~ health-check:merge-in-progress:ok ]]
    [[ "$output" =~ health-check:conflict-marker:ok ]]
}
```

### 5.3 シナリオ 2: unmerged paths（exit 0 + status:warning）

```bash
@test "warning: unmerged paths detected returns exit 0 + status:warning" {
    cd "$FIXTURE_REPO"
    # 2 ブランチを作成し意図的にコンフリクトを発生させる
    git checkout -b branch-a
    echo "from a" > conflict.txt
    git add conflict.txt
    git commit -m "branch-a change" >/dev/null

    git checkout -b branch-b main
    echo "from b" > conflict.txt
    git add conflict.txt
    git commit -m "branch-b change" >/dev/null

    git merge branch-a || true  # コンフリクトで失敗、unmerged 状態が残る

    run bash "${BATS_TEST_DIRNAME}/../skills/aidlc/scripts/main-repo-health-check.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ status:warning ]]
    [[ "$output" =~ health-check:unmerged-paths:warning ]]
}
```

### 5.4 シナリオ 3: MERGE_HEAD（exit 0 + status:warning）

```bash
@test "warning: MERGE_HEAD exists returns exit 0 + status:warning" {
    cd "$FIXTURE_REPO"
    # MERGE_HEAD ファイルを直接作成（マージ進行中状態の擬似再現）
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir)
    echo "0000000000000000000000000000000000000000" > "${git_common_dir}/MERGE_HEAD"

    run bash "${BATS_TEST_DIRNAME}/../skills/aidlc/scripts/main-repo-health-check.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ status:warning ]]
    [[ "$output" =~ health-check:merge-in-progress:warning ]]
    [[ "$output" =~ MERGE_HEAD ]]

    rm -f "${git_common_dir}/MERGE_HEAD"
}
```

### 5.5 シナリオ 4: コンフリクトマーカー残骸（v2.5.3 再現、exit 0 + status:warning）

```bash
@test "warning: conflict marker残骸 (v2.5.3 reproduction) returns exit 0 + status:warning" {
    cd "$FIXTURE_REPO"
    # v2.5.3 で実害発生したパターンを fixture で再現:
    # コンフリクトマーカー 6 件含む tracked ファイルを commit
    cat > review-flow-mock.md <<'EOF'
some content

<<<<<<< Updated upstream
local change
=======
upstream change
>>>>>>> Stashed changes

other content

<<<<<<< Updated upstream
another local
=======
another upstream
>>>>>>> Stashed changes
EOF
    git add review-flow-mock.md
    git commit -m "fixture: stash pop conflict marker remains" >/dev/null

    run bash "${BATS_TEST_DIRNAME}/../skills/aidlc/scripts/main-repo-health-check.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ status:warning ]]
    [[ "$output" =~ health-check:conflict-marker:warning ]]
    [[ "$output" =~ count=[1-9] ]]  # 1 件以上のマーカー検出
}
```

### 5.6 fixture 隔離の保証

- 各テストは `setup()` / `teardown()` で独立した repo を生成・破棄
- `BATS_TEST_TMPDIR` は bats が自動生成・自動 cleanup するため、テスト間の干渉なし
- `cd` 操作によるカレントディレクトリ汚染は bats の `setup()` / `teardown()` 内に閉じる

## 6. Self-Healing ループ条件

実装フェーズで bats テストが失敗した場合、`max_retry=3` まで自動修正を試行する:

| エラー分類 | 対応 |
|-----------|------|
| `non_recoverable`（環境依存・git 未インストール等） | 即時フォールバック |
| `transient`（git command flaky） | 1 回再試行 |
| `recoverable`（テストロジック誤り・正規表現ミス等） | 最大 3 回まで自動修正 |

## 6.5. error-handling.md 規約との関係

`skills/aidlc/guides/error-handling.md` は「エラーメッセージは標準エラー出力（`>&2`）に出す」を共通原則としている。本 helper は `validate-git.sh` と同じ「**stdout 契約優先**」の例外として扱う:

- **stdout**: 機械可読の `status:<kind>` / `health-check:<item>:<status>:<detail>` / `error:<code>:<reason>` のみ出力（呼び出し側がパース）
- **stderr**: 人間向けデバッグ補足（実装で `>&2` 経由で例外時のスタックトレース等を出す場合）。本 helper では空でも可
- **`exit-code-convention.md` との整合**: `exit 0` で stdout の `status:` 行を返す方針は `exit-code-convention.md` の「警告内容は stdout の `status:warning` 等で通知」と一致

> 本例外は `validate-git.sh` の前例があるため新規逸脱ではなく、`error-handling.md` 共通原則と `exit-code-convention.md` の双方に整合する形で運用される。

## 7. 検証 grep（実装後）

```bash
# 1. last_two_rounds_clean が確実に消えていること（Unit 005 の前提を残す）
grep -c "last_two_rounds_clean" skills/aidlc/steps/common/review-flow.md  # → 0

# 2. step:3a が 01-setup.md に追加されていること
grep -c "### 3a\." skills/aidlc/steps/operations/01-setup.md  # → 1
grep -c "main-repo-health-check.sh" skills/aidlc/steps/operations/01-setup.md  # → 1 以上

# 3. helper が新設されていること
test -f skills/aidlc/scripts/main-repo-health-check.sh

# 4. helper の終了コード規約コメントが exit-code-convention.md 準拠
grep -c "exit-code-convention" skills/aidlc/scripts/main-repo-health-check.sh  # → 1 以上

# 5. bats テストが新設されていること
test -f tests/main-repo-health-check.bats
grep -c "@test" tests/main-repo-health-check.bats  # → 4 以上

# 6. 既存ガード仕様の維持確認（変更前 baseline と比較）
# (Unit 005 と同様、変更前 HEAD で baseline を採取)
```

## 8. 後続 step 番号の維持確認

`01-setup.md` の既存番号（1, 2, 3, 4, 5, 6, 6a, 6b, 7, 8, 9, 10, 11）と新設 3a を確認:

```bash
grep -E "^### [0-9]+" skills/aidlc/steps/operations/01-setup.md | head -20
```

期待出力:
```
### 1. サイクル存在確認
### 2. 追加ルール確認
### 3. プリフライトチェック
### 3a. メインリポジトリ Health Check【重要】
### 4. セッション判別設定【オプション】
### 5. Depth Level確認
### 6. 進捗管理ファイル確認【重要】
...
```

step 4-11 が再採番されていないことを目視確認。
