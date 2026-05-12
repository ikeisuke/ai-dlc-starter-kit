# Unit 005 計画: gh-project 副作用 bats テスト整備（gh API モックフレームワーク）

## 対象

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/005-gh-project-side-effect-bats.md`
- 関連 Issue: #683（type:defer-from-review / priority:medium / v2.6.0 Unit 006 R1 #3）
- 関連先行: v2.6.0 Unit 006（4 スクリプト本体整備）/ v2.6.2 Unit 004（ensure-fields options 差分同期 + bats 内モック実装）

## 目的

v2.6.0 Unit 006 R1 #3 で defer された「副作用本体動作の bats テスト整備」を実施する。

- 現状: `bin/tests/gh-project/{cli_args,scope_check,spec}.bats` 28 件は引数検証 / scope check / spec 構造のみで、4 スクリプト（`setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh`）の **本体動作（副作用）** が未網羅
- Unit 004 で `ensure_fields_options_sync.bats` 内に gh / yq / dasel モックを実装したが、各 bats ファイルで個別に setup する形のため再利用性が低い

**Phase 1** で共通モックヘルパー（`bin/tests/gh-project/_helpers.bash`）を新設し、Unit 004 ですでに動作実証済みのモック手法（PATH override + wrapper script + 呼出ログ）を汎用化する。**Phase 2** で 4 スクリプトそれぞれの本体動作 bats を追加する。

## スコープ

### 含まれるもの

#### Phase 1: モック基盤整備

1. `bin/tests/gh-project/_helpers.bash` 新設（bats `load` で読み込む共通ヘルパー）:
    - `gh_project_setup_env()`: `AIDLC_REPO_ROOT` / `MOCK_DIR` / `.aidlc/cache` / `.aidlc/config.toml`（runtime binding）/ `config/github-project-spec.yaml` の標準セットアップ
    - `gh_project_mock_gh()`: `gh` wrapper script を `MOCK_DIR` に配置。fixture JSON ディレクトリを参照し、API 呼出をディスパッチ
    - `gh_project_mock_dasel()`: `dasel` wrapper（v2 / v3 構文双方を吸収）
    - `gh_project_mock_yq()`: `yq` wrapper（`<file>.json` を返す）
    - `gh_project_mock_git()`（必要時）: `git rev-parse --show-toplevel` のみ stub
    - `gh_project_assert_gh_call_count <api> <count>`: `${BATS_TEST_TMPDIR}/gh_calls.log` の呼出回数アサート
    - `gh_project_assert_gh_call_contains <api> <pattern>`: 呼出引数アサート
    - `gh_project_set_fixture <api> <fixture_file>`: fixture 切替 API
    - `gh_project_inject_failure <api>`: 失敗注入（`MOCK_<API>_FAIL=1` を export）
2. fixture JSON 配置ディレクトリ `bin/tests/gh-project/fixtures/` 新設。最小 fixture（`project-list-empty.json` / `field-list-default.json` 等）を Phase 1 完了マーカー検証に必要な範囲で同梱
3. **未モック API 検出機構**: `gh` wrapper のデフォルト動作で `unmocked: <args>` を stderr 出力 + exit 99（Unit 004 で実証済みのパターンを正式仕様化）
4. **Phase 1 完了マーカー**: `bin/tests/gh-project/setup-github-project.bats` の最小 1 ケース（orchestrator が 5 subcommand を順次呼出することを確認）が _helpers.bash 経由で動作 + 想定外引数で fail することを別ケースで確認

#### Phase 2: 4 スクリプト本体動作テスト

5. `bin/tests/gh-project/setup-github-project.bats` 新設:
    - orchestrator が `ensure-project` / `ensure-fields` / `ensure-views` / `sync-items` / `audit --check spec-conformance` を順次呼出
    - `--dry-run` 透過 / `--strict` / `--soft` 透過
    - 途中失敗時の即時 exit（set -e による fail-fast）
    - audit ステップで `--dry-run` を除去している挙動
    - 確定 4 ケース
6. `bin/tests/gh-project/migrate-issue-524.bats` 新設:
    - `--dry-run` 時の diff 出力（Issue body の差分表示 / API 呼ばれない）
    - バックアップ作成（`.aidlc/cycles/v2.6.0/operations/issue-524-backup.md` への書き出し）
    - `--strict` 時の scope 不足（project / read:org）で exit 2
    - 確定 4 ケース
7. `bin/tests/gh-project/probe-github-project.bats` 新設:
    - `--probe workflow-item-closed --dry-run` 時の evidence JSON 構造（sandbox 操作スキップ + structure-only 出力）
    - sandbox 操作失敗時の cleanup 実行（一時 item の削除確認）
    - `--probe` 値欠落で `args_invalid` (exit 1)
    - `--strict` 時の scope 不足で exit 2
    - 確定 4 ケース
8. `bin/tests/gh-project/audit-github-project.bats` 新設:
    - SLA 判定 3 ケース: `within_sla` / `sla_exceeded` / `unknown`（fixture probe-evidence JSON でドライブ）
    - probe-evidence 不在時 exit 5（`evidence_missing`）
    - `--check spec-conformance` 単独実行（既存 fields とのドリフト検出）
    - `--check all` での複数 check 集約
    - 確定 5 ケース
9. Unit 004 で `ensure_fields_options_sync.bats` 内に個別実装したモックを `_helpers.bash` 経由に **段階的に置き換える**（Phase 2 完了後 / 既存テスト全件 green 維持を確認）
10. shellcheck / shellharden / markdownlint 通過（既存スクリプトの規約踏襲。`_helpers.bash` は `bash` shebang 不要だが、shellcheck で source 検証）

#### Phase 2 完了マーカー

- 4 bats ファイル全件 pass
- 既存 28 件（`cli_args.bats` / `scope_check.bats` / `spec.bats`）+ Unit 004 追加 10 件と全件並存（合計 42 + Phase 2 新規 17 = 59 件相当）
- 想定外引数で fail する未モック API 検出機構が機能（少なくとも 1 ケースで明示検証）

### 含まれないもの

- 4 スクリプト本体の挙動変更（テスト追加のみ。設計上の不整合が見つかった場合は別 Issue / 別 Unit へ defer）
- `gh` 全 API のフルモック化（Unit 定義「境界」に従い 4 スクリプトが必要とする最小限のみ）
- `dasel` / `yq` の **完全モック化**（必要時最小限）
- E2E テスト（実 GitHub API を叩くテスト）の追加
- Unit 004 の `ensure_fields_options_sync.bats` の **本体ロジック** 変更（モック呼出箇所のヘルパー経由化のみ）
- `gh-project-cli.sh` 本体の bats 追加（Unit 004 でスコープ済み）
- CI ワークフロー（`.github/workflows/`）への新規 bats 組み込み（既存 `make test` 相当の経路で吸収する前提）

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [ ] `bin/tests/gh-project/_helpers.bash` が新設され、gh / dasel / yq / 呼出ログ / fixture / 失敗注入の各ヘルパーが提供される（Phase 1）
- [ ] fixture JSON ディレクトリ `bin/tests/gh-project/fixtures/` が新設され、4 bats が必要とする最小 fixture が同梱される（Phase 1）
- [ ] 想定外引数で fail する未モック API 検出機構が `gh` wrapper のデフォルト動作として実装される（Phase 1）
- [ ] `setup-github-project.bats` が追加され、orchestrator の subcommand 順次呼出 / mode 透過が網羅される（Phase 2）
- [ ] `migrate-issue-524.bats` が追加され、dry-run diff / バックアップ / strict scope の挙動が網羅される（Phase 2）
- [ ] `probe-github-project.bats` が追加され、evidence JSON / sandbox cleanup / scope の挙動が網羅される（Phase 2）
- [ ] `audit-github-project.bats` が追加され、SLA 3 判定 / probe-evidence 不在 / check 種別の挙動が網羅される（Phase 2）
- [ ] 既存 28 件 + Unit 004 追加 10 件と新規追加分が `bats bin/tests/gh-project/` 相当の経路で全件 green

### Issue #683 受け入れ基準

- [ ] 4 スクリプト（`setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh`）の本体動作 bats が整備される
- [ ] gh API mock（`gh project list` / `create` / `field-list` / `item-add` / `item-list` / `item-edit` / `issue delete`）が fixture JSON で擬装可能になる（**指摘 #2 反映**: probe-github-project.sh の cleanup は `gh_project_repo_delete_issue` 経由で `gh issue delete` を呼ぶため、`issue delete` をモック対象に追加）
- [ ] モックヘルパー追加時の改修コストが小さい（拡張ポイントが明確：fixture 追加 + dispatcher 1 行）

### 非機能要件（NFR）

- [ ] **保守性**: 新規 API モックを `_helpers.bash` の dispatcher テーブルに 1 行追加するだけで拡張可能（Phase 1 完了マーカーで dispatcher 構造を明示）
- [ ] **検出力**: 未モック API 呼出時にテストヘルパーが `unmocked:<args>` を stderr 出力 + exit 99 で fail
- [ ] **保証性**: 既存 28 件 + Unit 004 追加 10 件と並存し、`make test` 相当で全件 green
- [ ] **可搬性**: macOS / Linux 双方の bash で動作（bats / shellcheck / shellharden / bash + jq のみ依存。`stat -c %s` 等の非可搬コマンドは未使用）
- [ ] **テスタビリティ**: Phase 1 完了マーカー（最小 setup bats）と Phase 2 完了マーカー（4 bats 全件 pass）が明示

### Intent 制約適合

- [ ] **破壊的変更なし**: 4 スクリプト本体は変更しない。テスト追加 + Unit 004 既存 bats のモック経由化のみ
- [ ] **ドッグフーディング特殊処理禁止**: モックヘルパーは consumer プロジェクトでも動作する汎用形式（PATH override + wrapper script）で実装。自リポジトリ判定による分岐は導入しない
- [ ] **コマンド置換禁止**: テストヘルパー / fixture 操作で **AI Bash プロンプト経由 / commit message 内** のコマンド置換 `$(...)` を新規導入しない。bash スクリプト内部ローカル変数代入での `$(...)` は既存 Unit 004 と同様に許容（CLAUDE.md / `.aidlc/rules.md` の対象外）

## 実装方針（概略 / 設計レビューで詳細化）

### 1. モック手法の選定

| 手法 | 採否 | 理由 |
|------|------|------|
| (a) PATH override + wrapper script | **採用** | Unit 004 `ensure_fields_options_sync.bats` で実証済み。subprocess（bash スクリプト本体）からも有効。bats `setup()` で `export PATH="${MOCK_DIR}:${PATH}"` する既存パターンを継承 |
| (b) bash function override | 不採用 | `gh () { ... }` は subprocess（4 スクリプト本体）に継承されない。本 Unit の対象は 4 つの「別 bash スクリプト」を bats から実行する形のため不適 |
| (c) wrapper script + 一時 PATH | 採用（(a) と実質同義） | Unit 定義の選択肢として記載されているが、技術的には (a) と同じ実装 |

### 2. `_helpers.bash` の API 設計（概略）

**fixture ディレクトリの規約（指摘 #4 反映）**:

| 種別 | パス | 役割 |
|------|------|------|
| リポジトリ commit 対象 | `bin/tests/gh-project/fixtures/` | 各 bats が `load` 時に参照可能な fixture JSON の SoT |
| ランタイム展開先 | `${GH_PROJECT_FIXTURE_DIR}`（デフォルト: `${BATS_TEST_TMPDIR}/fixtures/`） | bats setup で `gh_project_set_fixture <api> <repo-fixture-path>` により上記リポジトリ commit 対象 fixture をコピー展開する先。`gh` wrapper はここのみを参照 |

両者を分離することで「fixture の SoT はリポジトリ commit」「テストごとの上書きは `BATS_TEST_TMPDIR` に隔離」を両立する。

**失敗注入の規約（指摘 #3 反映）**:

`gh_project_inject_failure <api>` は `MOCK_<UPPER_UNDERSCORE>_FAIL=1` を export する。`<api>` はスペース区切りの gh サブコマンド（例: `"project list"` → `MOCK_PROJECT_LIST_FAIL`、`"issue delete"` → `MOCK_ISSUE_DELETE_FAIL`）。`gh` wrapper は **dispatcher case 文の各分岐内で** 対応する `MOCK_<API>_FAIL` を参照する（グローバル `MOCK_GH_FAIL` も並存サポート）。

**dispatcher の API カバレッジ（指摘 #2 / #3 反映）**:

probe-github-project.sh の cleanup は `gh_project_repo_delete_issue` 経由で **`gh issue delete`** を呼ぶため、dispatcher に `"issue delete"` を含める。`gh project item-delete` は呼ばれない（誤記訂正）。

```bash
# bats から: load '_helpers'
# 標準セットアップ
gh_project_setup_env() {
    : "${BATS_TEST_TMPDIR:?}"
    export AIDLC_REPO_ROOT="$BATS_TEST_TMPDIR"
    mkdir -p "$BATS_TEST_TMPDIR/.aidlc/cache" "$BATS_TEST_TMPDIR/config"
    export MOCK_DIR="$BATS_TEST_TMPDIR/mock-bin"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    export GH_PROJECT_CALL_LOG="$BATS_TEST_TMPDIR/gh_calls.log"
    : > "$GH_PROJECT_CALL_LOG"
    # fixture ランタイム展開先（デフォルト位置）
    export GH_PROJECT_FIXTURE_DIR="${GH_PROJECT_FIXTURE_DIR:-$BATS_TEST_TMPDIR/fixtures}"
    mkdir -p "$GH_PROJECT_FIXTURE_DIR"
}

# gh モック factory
# fixture は GH_PROJECT_FIXTURE_DIR（デフォルト: $BATS_TEST_TMPDIR/fixtures）配下を参照
# リポジトリ commit 対象は bin/tests/gh-project/fixtures/ に置き、
# gh_project_set_fixture <api> <repo-fixture-path> でランタイム展開先にコピー
gh_project_mock_gh() {
    cat > "$MOCK_DIR/gh" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GH_PROJECT_CALL_LOG:-/dev/null}"
case "$1 $2" in
    "auth status") echo "Logged in"; exit 0 ;;
esac
# グローバル失敗注入（全 API 共通）
[[ -n "${MOCK_GH_FAIL:-}" ]] && { echo "gh mock: global injected failure" >&2; exit 1; }
# API 別失敗注入 + fixture dispatch（指摘 #2 / #3 反映で各分岐内に MOCK_<API>_FAIL チェックを配置）
case "$1 $2" in
    "project list")
        [[ -n "${MOCK_PROJECT_LIST_FAIL:-}" ]] && { echo "gh mock: project_list injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/project-list.json" ;;
    "project create")
        [[ -n "${MOCK_PROJECT_CREATE_FAIL:-}" ]] && { echo "gh mock: project_create injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/project-create.json" ;;
    "project field-list")
        [[ -n "${MOCK_PROJECT_FIELD_LIST_FAIL:-}" ]] && { echo "gh mock: project_field_list injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/field-list.json" ;;
    "project item-add")
        [[ -n "${MOCK_PROJECT_ITEM_ADD_FAIL:-}" ]] && { echo "gh mock: project_item_add injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/item-add.json" ;;
    "project item-list")
        [[ -n "${MOCK_PROJECT_ITEM_LIST_FAIL:-}" ]] && { echo "gh mock: project_item_list injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/item-list.json" ;;
    "project item-edit")
        [[ -n "${MOCK_PROJECT_ITEM_EDIT_FAIL:-}" ]] && { echo "gh mock: project_item_edit injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/item-edit.json" ;;
    "issue create")
        [[ -n "${MOCK_ISSUE_CREATE_FAIL:-}" ]] && { echo "gh mock: issue_create injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/issue-create.json" ;;
    "issue edit")
        [[ -n "${MOCK_ISSUE_EDIT_FAIL:-}" ]] && { echo "gh mock: issue_edit injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/issue-edit.json" ;;
    "issue delete")
        [[ -n "${MOCK_ISSUE_DELETE_FAIL:-}" ]] && { echo "gh mock: issue_delete injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/issue-delete.json" ;;
    "issue view")
        [[ -n "${MOCK_ISSUE_VIEW_FAIL:-}" ]] && { echo "gh mock: issue_view injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/issue-view.json" ;;
    "api graphql")
        [[ -n "${MOCK_API_GRAPHQL_FAIL:-}" ]] && { echo "gh mock: api_graphql injected failure" >&2; exit 1; }
        _f="${GH_PROJECT_FIXTURE_DIR}/api-graphql.json" ;;
    *) echo "unmocked: $*" >&2; exit 99 ;;
esac
[[ -f "$_f" ]] && cat "$_f" || { echo "fixture not found: $_f" >&2; exit 98; }
MOCK
    chmod +x "$MOCK_DIR/gh"
}

# fixture 切替: リポジトリ commit 対象 fixture をランタイム展開先にコピー
gh_project_set_fixture() {
    local api="$1" src="$2"
    cp "$src" "${GH_PROJECT_FIXTURE_DIR}/${api}.json"
}

# 呼出回数 / 引数 アサート
gh_project_assert_gh_call_count() {
    local pattern="$1" expected="$2" actual
    actual="$(grep -c -E "$pattern" "$GH_PROJECT_CALL_LOG" || true)"
    [[ "$actual" -eq "$expected" ]] || { echo "expected $expected calls of $pattern, got $actual" >&2; return 1; }
}
gh_project_assert_gh_call_contains() {
    grep -q -E "$1" "$GH_PROJECT_CALL_LOG" || { echo "no call matched: $1" >&2; return 1; }
}

# 失敗注入: gh_project_inject_failure <api>
#   <api> は gh サブコマンド（スペース区切り、例: "project list" / "issue delete"）
#   → MOCK_<UPPER_UNDERSCORE>_FAIL=1 を export（"project list" → MOCK_PROJECT_LIST_FAIL）
#   グローバル失敗は MOCK_GH_FAIL=1 を直接 export
gh_project_inject_failure() {
    local api="$1"
    local var
    var="MOCK_$(printf '%s' "$api" | tr '[:lower:][:space:]-' '[:upper:][:space:]_' | tr ' ' '_')_FAIL"
    export "$var=1"
}
```

### 3. fixture JSON 構造（最小例）

`bin/tests/gh-project/fixtures/project-list.json`:

```json
{"projects":[{"number":123,"title":"TestProject","owner":{"login":"@me"}}]}
```

`bin/tests/gh-project/fixtures/field-list-default.json`（Status + Cycle field 構造）:

```json
{"fields":[
  {"id":"PVTF_AAA","name":"Status","options":[{"name":"Todo"},{"name":"In Progress"},{"name":"Done"}]},
  {"id":"PVTF_BBB","name":"Cycle"}
]}
```

各 bats の `setup()` で `gh_project_setup_env` + `gh_project_mock_gh` を呼び、テストケース別に `gh_project_set_fixture` で fixture 上書き。

### 4. 4 bats のテスト設計（概略 / 確定値は設計レビューで詳細化）

#### setup-github-project.bats（4 ケース）

| # | ケース | 期待 stdout | gh 呼出 |
|---|--------|-------------|--------|
| 1 | dry-run で 5 subcommand 順次実行 | `== ensure-project ==` 〜 `== audit (spec-conformance) ==` 全 5 セクション + `setup-github-project: completed` | dry-run なので write 呼出なし |
| 2 | strict 透過（mode が `--strict` で gh-project-cli.sh に渡る） | 各 subcommand 内で strict 動作 | gh project list + create + field-list 等 |
| 3 | 途中 subcommand 失敗で fail-fast | 失敗 subcommand までの出力 + set -e による exit | 失敗注入で 1 回 |
| 4 | audit ステップで `--dry-run` が除去される | audit セクションで dry-run なし | audit 呼出 |

#### migrate-issue-524.bats（4 ケース）

| # | ケース | 期待 stdout / stderr | exit |
|---|--------|--------------------|------|
| 1 | dry-run 時に Issue body の diff 表示（API 呼ばれない） | diff 出力に project URL リダイレクト | 0 |
| 2 | バックアップが `.aidlc/cycles/v2.6.0/operations/issue-524-backup.md` に作成される | バックアップファイル存在 | 0 |
| 3 | strict scope 不足で exit 2（gh auth status を mock で scope 欠落注入） | `scope_insufficient` JSON | 2 |
| 4 | unknown option で args_invalid | `unknown_option:--bogus` | 1 |

#### probe-github-project.bats（4 ケース）

| # | ケース | 期待 | exit |
|---|--------|------|------|
| 1 | `--probe workflow-item-closed --dry-run` で evidence JSON 構造 | structure-only JSON 出力 | 0 |
| 2 | sandbox 操作（issue create → item-add → issue edit close → cleanup）の cleanup が呼ばれる（**指摘 #2 反映**: 実装は `gh_project_repo_delete_issue` 経由で `gh issue delete` を呼ぶ。`gh project item-delete` ではない） | `gh issue delete` 呼出 1 回 + `cleanup_status: "succeeded"` を含む evidence JSON | 0 |
| 3 | `--probe` 値欠落 | `missing_value_for_option:--probe` | 1 |
| 4 | strict scope 不足 | `scope_insufficient` JSON | 2 |

#### audit-github-project.bats（5 ケース）

| # | ケース | fixture probe-evidence | 期待 | exit |
|---|--------|----------------------|------|------|
| 1 | within_sla | 直近 24h 以内 | `sla:within_sla` | 0 |
| 2 | sla_exceeded | 古い timestamp | `sla:sla_exceeded` | 0（soft）/ 3（strict） |
| 3 | unknown | timestamp 欠落 | `sla:unknown` | 0 |
| 4 | probe-evidence 不在 | ファイル無し | `evidence_missing` JSON | 5 |
| 5 | `--check spec-conformance` 単独 | - | spec drift 出力 | 0 / 3（drift 有・strict） |

### 5. Unit 004 既存 bats のモック経由化（Phase 2 末尾）

- `ensure_fields_options_sync.bats` の `setup()` 内の gh / yq / dasel モック実装を `load '_helpers'` + `gh_project_setup_env` + `gh_project_mock_gh` + `gh_project_mock_yq` + `gh_project_mock_dasel` に置き換え
- 既存 10 ケースの assert は変更せず、テスト本体の挙動は同一であることを `bats` で確認
- モック実装の重複削減（Unit 004 で 約 80 行のモック実装 → ヘルパー load + factory 呼出 4 行）

## 依存・前提

- bats / shellcheck / shellharden: 既存テスト環境
- bash + jq: 既存パターン
- `bin/tests/gh-project/{cli_args,scope_check,spec,ensure_fields_options_sync}.bats` の既存パターン（PATH override / fixture / 呼出ログ）
- v2.6.0 Unit 006 の 4 スクリプト本体（変更しない）
- v2.6.2 Unit 004 完了済み（Unit 005 の Phase 2 終盤で既存 bats のモック経由化を実施するため依存）

## リスクと緩和

| リスク | 影響 | 緩和策 |
|--------|------|--------|
| `_helpers.bash` の dispatcher テーブルが膨張し保守性低下 | 中 | Phase 1 完了マーカーで dispatcher 構造（case 文 1 行 / fixture 1 ファイル）を確立し、Phase 2 で拡張する形に限定 |
| 既存 bats（特に Unit 004）のモック経由化で挙動変化 | 中 | Phase 2 末尾で実施。各 bats を 1 ファイルずつ移行し、`bats` で全件 green を都度確認 |
| 4 スクリプト本体の挙動と fixture の乖離（mock false positive） | 中 | fixture JSON の構造は 4 スクリプトが実際にパースする `jq` クエリと突き合わせて整合確認。設計レビューで fixture スキーマを固定 |
| `set -euo pipefail` + `IFS=$'\n\t'` のスクリプト内挙動が PATH override で再現できない | 低 | bats `run` 経由で実行 + `BATS_TEST_TMPDIR` 隔離。4 スクリプトの shebang `bash` を維持 |
| Phase 2 完了マーカーが大きく Phase 1 / Phase 2 分割の閾値設定が曖昧 | 低 | Phase 1 完了マーカー = setup bats 1 本動作。Phase 2 = 4 bats 全件 pass。設計レビューで Phase 1 / Phase 2 の境界を明文化 |
| 未モック API 検出機構の exit code 99 が `set -e` で他テストへ波及 | 低 | bats `run` 経由なので exit 99 は `$status` で捕捉可能。波及テストケースで明示検証 |

## 想定タイムライン

- Phase 1 設計: 0.5 時間（ドメインモデル + 論理設計 + 設計レビュー）
- Phase 1 実装: 1.0 時間（`_helpers.bash` 新設 + 最小 fixture + Phase 1 完了マーカー bats）
- Phase 2 実装: 2.0〜3.0 時間（4 bats 追加 + Unit 004 既存 bats のモック経由化）
- 完了処理: 0.5 時間
- 合計: 約 4〜5 時間（1〜1.5 日相当 / Unit 見積もり下限）

## 関連

- v2.6.0 Unit 006 R1 #3（#673 由来）: 本 Unit の defer 起点
- v2.6.2 Unit 004（gh-project-cli options 差分同期）: 既存モック実装の整理対象（Phase 2 末尾で `_helpers.bash` 経由に移行）
