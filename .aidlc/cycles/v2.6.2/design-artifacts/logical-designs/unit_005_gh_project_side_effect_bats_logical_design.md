# 論理設計: Unit 005 — gh-project 副作用 bats テスト整備（gh API モックフレームワーク）

## 概要

`bin/tests/gh-project/_helpers.bash` を新設し、gh API モックフレームワーク（PATH override + wrapper script + 呼出ログ + 失敗注入 + fixture）を提供する。その上で 4 スクリプト（`setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh`）の本体動作 bats を追加する。Phase 2 末尾で Unit 004 の既存 `ensure_fields_options_sync.bats` を新フレームワーク経由に移行する。

**重要**: この論理設計では **コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコードは Phase 2 で作成する。

---

## アーキテクチャパターン

- **採用パターン**: **PATH override + wrapper script + heredoc 埋込 dispatcher**（既存 `ensure_fields_options_sync.bats` で実証済みの方式を `_helpers.bash` ヘルパー群として正式化）
- **選定理由**:
  - 4 スクリプトはすべて bats `run` から **bash subprocess として起動** されるため、bash function override (`gh () { ... }`) は subprocess に継承されず不適
  - PATH 先頭への `${MOCK_DIR}` 挿入は subprocess に継承され、subject 内部の `gh` / `dasel` / `yq` 呼出を透過的に hijack できる
  - heredoc 埋込 dispatcher により単一 wrapper で API 別 fixture / 失敗注入を吸収（factory パターン）
- **不採用**:
  - **bash function override**: subprocess 透過性が無いため不採用
  - **bats-mock 等の外部依存**: プロジェクトの既存テスト環境（bats core + shellcheck + shellharden）に依存追加が必要となり、Intent 制約（最小依存）に反する
  - **fixture JSON を bats ファイル内に heredoc 直書き**: 4 スクリプト × 多数 API × 多数ケースで肥大化し、SoT 単一化原則に反する。リポジトリ commit 対象 fixture を `bin/tests/gh-project/fixtures/` に分離する形を採用

---

## コンポーネント構成

### モジュール構成

```text
bin/
├── (4 スクリプト本体 + gh-project-cli.sh)  ← 本 Unit で変更なし
└── tests/gh-project/
    ├── _helpers.bash                          ← 新規（本 Unit / Phase 1）
    ├── fixtures/                              ← 新規ディレクトリ（本 Unit / Phase 1）
    │   │                                         （命名は ApiSelector dispatch 表を SoT とする / 指摘 #1 #2 反映）
    │   ├── project-list.json
    │   ├── project-create.json
    │   ├── project-edit.json
    │   ├── project-field-list-default.json
    │   ├── project-field-list-with-cycle.json
    │   ├── project-field-create.json
    │   ├── project-view-list.json
    │   ├── project-view-create.json
    │   ├── project-item-add.json
    │   ├── project-item-list.json
    │   ├── project-item-edit.json
    │   ├── issue-list.json
    │   ├── issue-view.json
    │   ├── issue-create.json
    │   ├── issue-edit.json
    │   ├── issue-close.json
    │   ├── issue-delete.json
    │   ├── api-graphql.json
    │   └── probe-evidence-{within,exceeded,unknown,missing}.json   ← audit bats 用
    ├── cli_args.bats                          ← 既存（変更なし）
    ├── scope_check.bats                       ← 既存（変更なし）
    ├── spec.bats                              ← 既存（変更なし）
    ├── ensure_fields_options_sync.bats        ← 既存（Phase 2 末尾で _helpers 経由化）
    ├── setup-github-project.bats              ← 新規（本 Unit / Phase 2）
    ├── migrate-issue-524.bats                 ← 新規（本 Unit / Phase 2）
    ├── probe-github-project.bats              ← 新規（本 Unit / Phase 2）
    └── audit-github-project.bats              ← 新規（本 Unit / Phase 2）
```

### コンポーネント詳細

#### `_helpers.bash`（新規 / Phase 1）

- **責務**: gh API モックフレームワークの公開ヘルパー API 一式を提供する
- **公開関数**:
  - `gh_project_setup_env`
  - `gh_project_mock_gh` / `gh_project_mock_dasel` / `gh_project_mock_yq`
  - `gh_project_set_fixture`
  - `gh_project_inject_failure`
  - `gh_project_assert_gh_call_count` / `gh_project_assert_gh_call_contains`
- **依存**: bash / jq / 既存 bats core
- **bats からの参照形式**: `load '_helpers'`（bats 同一ディレクトリの `_helpers.bash` が解決される）
- **インターフェース契約**: 詳細は §「インターフェース設計」参照

#### `fixtures/` ディレクトリ（新規 / Phase 1）

- **責務**: gh API レスポンスの SoT JSON ファイルを格納
- **命名規約**: ApiSelector 値の半角スペース・ハイフンを `-` に正規化した `<api>.json`（例: `project-list.json` / `project-item-add.json` / `issue-delete.json`）。同一 API で複数バリアントが必要な場合は `<api>-<variant>.json`（例: `project-field-list-with-cycle.json`）。命名は **ドメインモデルの ApiSelector dispatch 表を SoT** とし、本ファイル内のすべての参照は dispatch 表に追従する
- **fixture スキーマ**: 4 スクリプト本体が `jq` で参照する **実際のキー構造と一致させる**（mock false positive 防止）。論理設計フェーズで実装の `jq` クエリと突き合わせて確定する
- **commit 対象**: リポジトリ commit 対象（bats `setup()` から `gh_project_set_fixture` でランタイム展開先にコピー）

#### `setup-github-project.bats`（新規 / Phase 2）

- **責務**: `bin/setup-github-project.sh`（orchestrator）の本体動作テスト 4 ケース
- **依存**: `_helpers.bash` / fixtures
- **対象スクリプト**: `bin/setup-github-project.sh` + 経由する `bin/gh-project-cli.sh`
- **ケース**: §「Phase 2 bats ケース表」参照

#### `migrate-issue-524.bats`（新規 / Phase 2）

- **責務**: `bin/migrate-issue-524.sh` の本体動作テスト 4 ケース
- **依存**: `_helpers.bash` / fixtures（`issue-view.json` / `issue-edit.json`）
- **対象スクリプト**: `bin/migrate-issue-524.sh`
- **ケース**: §「Phase 2 bats ケース表」参照

#### `probe-github-project.bats`（新規 / Phase 2）

- **責務**: `bin/probe-github-project.sh` の本体動作テスト 4 ケース
- **依存**: `_helpers.bash` / fixtures（`issue-create.json` / `project-item-add.json` / `issue-close.json` / `issue-delete.json`）
- **対象スクリプト**: `bin/probe-github-project.sh`
- **ケース**: §「Phase 2 bats ケース表」参照
- **重要**: cleanup は `gh_project_repo_delete_issue` 経由で `gh issue delete` を呼ぶ（`gh project item-delete` ではない / 計画書 R1 指摘 #2 反映）

#### `audit-github-project.bats`（新規 / Phase 2）

- **責務**: `bin/audit-github-project.sh` の本体動作テスト 5 ケース
- **依存**: `_helpers.bash` / fixtures（`probe-evidence-*.json` / `project-field-list-*.json`）
- **対象スクリプト**: `bin/audit-github-project.sh`
- **ケース**: §「Phase 2 bats ケース表」参照

#### `ensure_fields_options_sync.bats`（既存 / Phase 2 末尾で改修）

- **責務**: Unit 004 で追加済みの 10 ケースを **`_helpers.bash` 経由に置換**
- **改修方針**:
  - `setup()` 内の gh / yq / dasel モック実装（約 80 行）を `load '_helpers'` + `gh_project_setup_env` + `gh_project_mock_gh` + `gh_project_mock_yq` + `gh_project_mock_dasel` の組合せに置換
  - 各 `@test` の assert 本体は変更しない（既存 10 ケース全件 green を維持確認）
  - 置換前に各テストの呼出 API を `_helpers.bash` の dispatcher 表に登録済みであることを確認（`api graphql` / `project field-list` 等）

---

## インターフェース設計

### `_helpers.bash` 公開関数

#### `gh_project_setup_env()`

- **入力**: 引数なし（環境変数 `BATS_TEST_TMPDIR` / 既存 export 値を尊重）
- **動作**:
  - `AIDLC_REPO_ROOT="$BATS_TEST_TMPDIR"` を export
  - `BATS_TEST_TMPDIR/.aidlc/cache` / `BATS_TEST_TMPDIR/config` を mkdir
  - `MOCK_DIR`（デフォルト `BATS_TEST_TMPDIR/mock-bin`）/ `GH_PROJECT_FIXTURE_DIR`（デフォルト `BATS_TEST_TMPDIR/fixtures`）/ `GH_PROJECT_CALL_LOG`（デフォルト `BATS_TEST_TMPDIR/gh_calls.log`）を export + mkdir / 空ファイル化
  - `PATH` の先頭に `MOCK_DIR` を挿入
- **出力**: なし
- **戻り値**: 0（常に成功）
- **副作用**: bats `BATS_TEST_TMPDIR` 配下と環境変数のみ

#### `gh_project_mock_gh()`

- **入力**: 引数なし
- **動作**: `${MOCK_DIR}/gh` に bash wrapper script を heredoc で生成し chmod +x
- **wrapper の内部仕様**:
  1. `printf '%s\n' "$*" >> "${GH_PROJECT_CALL_LOG:-/dev/null}"`（CallLogEntry 追記）
  2. `case "$1 $2"` で `auth status` 即応答（`echo "Logged in"; exit 0`）
  3. グローバル `MOCK_GH_FAIL` 評価（立てば即 exit 1）
  4. `case "$1 $2"` で ApiSelector dispatch（各分岐内で per-api `MOCK_<API>_FAIL` 評価 → fixture 変数代入）
  5. `*)` で `echo "unmocked: $*" >&2; exit 99`
  6. fixture ファイル存在チェック → `cat` で stdout 出力 / 不在なら `exit 98`
- **出力**: wrapper script のファイル生成
- **戻り値**: 0
- **dispatch 表**: ドメインモデルの §「ApiSelector dispatch 表」を SoT として参照

#### `gh_project_mock_dasel()`

- **入力**: 引数なし
- **動作**: `${MOCK_DIR}/dasel` に Unit 004 と同等の wrapper を生成（v2 `-f <file> <key>` / v3 `< <file>` 双方を吸収）
- **fixture 配置**: `<toml>.json` 形式のサイドカーファイルから値を返す

#### `gh_project_mock_yq()`

- **入力**: 引数なし
- **動作**: `${MOCK_DIR}/yq` に Unit 004 と同等の wrapper を生成（`<file>.json` を返す）

#### `gh_project_set_fixture(api, src)`

- **入力**:
  - `api`: ハイフン区切り fixture key（例: `project-list`）
  - `src`: コピー元パス（リポジトリ commit 対象 fixture）
- **動作**: `cp "$src" "${GH_PROJECT_FIXTURE_DIR}/${api}.json"`
- **戻り値**: cp の戻り値（src 不在で非 0）

#### `gh_project_inject_failure(api)`

- **入力**: `api`（ApiSelector 値、スペース区切り例: `"project list"` / `"issue delete"`）
- **動作**:
  - `api` を `tr '[:lower:][:space:]-' '[:upper:][:space:]_' | tr ' ' '_'` で正規化
  - `MOCK_<UPPER_UNDERSCORE>_FAIL=1` を export
- **特殊ケース**: グローバル失敗は呼出側で `export MOCK_GH_FAIL=1` を直接実行（本ヘルパーは per-api 専用）
- **戻り値**: 0

#### `gh_project_assert_gh_call_count(pattern, expected)`

- **入力**:
  - `pattern`: 拡張正規表現（`grep -E` 対象）
  - `expected`: 期待呼出回数（非負整数）
- **動作**: `grep -c -E "$pattern" "$GH_PROJECT_CALL_LOG"` の結果を `expected` と比較
- **戻り値**: 一致 0 / 不一致 1（差分を stderr に出力）

#### `gh_project_assert_gh_call_contains(pattern)`

- **入力**: `pattern`（拡張正規表現）
- **動作**: `grep -q -E "$pattern" "$GH_PROJECT_CALL_LOG"`
- **戻り値**: マッチあり 0 / なし 1（pattern を stderr に出力）

---

## Phase 2 bats ケース表（確定 17 ケース）

### `setup-github-project.bats`（4 ケース）

| # | テスト名 | 期待 stdout（要約） | 期待 stderr | 期待 exit | gh API 呼出 |
|---|---------|--------------------|-------------|-----------|-----------|
| 1 | `--dry-run` で 5 subcommand 順次実行 | `== ensure-project ==` 〜 `== audit (spec-conformance) ==` 全 5 セクション + `setup-github-project: completed` | なし | 0 | dry-run なので write API 呼出なし、`auth status` / `project list` / `project field-list` 等の read のみ |
| 2 | `--strict` 透過 | 各 subcommand 内で strict 動作（既存 cli_args.bats と整合） | なし | 0 | `project create` / `project item-add` 等の write 呼出あり |
| 3 | 途中失敗で fail-fast（`ensure-fields` で失敗注入） | `== ensure-project ==` + `== ensure-fields ==` まで出力、`ensure-views` 以降は出力なし | `_emit_error gh_api_error` JSON | 非 0（set -e による） | 失敗注入対象 API のみ呼ばれる |
| 4 | audit ステップで `--dry-run` が除去される | audit セクションで `--dry-run` なしの呼出 | なし | 0 | audit 呼出時に `--dry-run` 引数が含まれていないことを `gh_project_assert_gh_call_contains` で検証 |

### `migrate-issue-524.bats`（4 ケース）

| # | テスト名 | 期待 | exit |
|---|---------|------|------|
| 1 | `--dry-run` 時の Issue body diff 表示（`gh issue edit` は呼ばれないが `gh issue view` は呼ばれる / 指摘 #4 反映 — 実装は dry-run でも `gh issue view 524` を実行して旧本文取得・バックアップを行う） | stdout に project URL リダイレクト diff + `issue-524:backup-saved` 行、`gh_project_assert_gh_call_count "issue edit" 0` + `gh_project_assert_gh_call_count "issue view" 1` | 0 |
| 2 | バックアップが `.aidlc/cycles/v2.6.0/operations/issue-524-backup.md` に作成される | バックアップファイル存在 + 内容に元 Issue body 含む（`issue-view.json` fixture の body と一致） | 0 |
| 3 | `--strict` scope 不足（`gh auth status` mock で scope 欠落注入） | stderr に `scope_insufficient` JSON | 2 |
| 4 | unknown option | stderr に `unknown_option:--bogus` | 1 |

### `probe-github-project.bats`（4 ケース）

| # | テスト名 | 期待 | exit |
|---|---------|------|------|
| 1 | `--probe workflow-item-closed --dry-run` で structure-only evidence JSON | stdout に `cleanup_status: null` を含む JSON | 0 |
| 2 | sandbox 操作（issue create → item-add → issue edit close → cleanup）の cleanup が `gh issue delete` で呼ばれる（R1 指摘 #2 反映） | `gh issue delete` 呼出 1 回 + evidence JSON に `cleanup_status: "succeeded"` | 0 |
| 3 | `--probe` 値欠落 | stderr に `missing_value_for_option:--probe` | 1 |
| 4 | `--strict` scope 不足 | stderr に `scope_insufficient` JSON | 2 |

### `audit-github-project.bats`（6 ケース / 指摘 #3 反映で `--check all` 追加）

| # | テスト名 | fixture probe-evidence | 期待 | exit |
|---|---------|----------------------|------|------|
| 1 | `--check workflow-item-closed` + within_sla | `probe-evidence-within.json`（直近 24h 以内） | stdout に `sla:within_sla` | 0 |
| 2 | `--check workflow-item-closed` + sla_exceeded（strict） | `probe-evidence-exceeded.json`（古い timestamp） | stdout に `sla:sla_exceeded` + stderr に warn | 3 |
| 3 | `--check workflow-item-closed` + unknown | `probe-evidence-unknown.json`（timestamp 欠落） | stdout に `sla:unknown` | 0 |
| 4 | probe-evidence 不在 | （fixture 配置なし） | stderr に `evidence_missing` JSON | 5 |
| 5 | `--check spec-conformance` 単独（drift 有） | （probe 不要 / `project-field-list` fixture で spec 不整合を再現） | stdout に `audit:spec-conformance:drift:exit=3` + audit-summary.json 生成 | 3（strict） |
| 6 | `--check all`（workflow-item-closed + spec-conformance の集約 / 指摘 #3 反映） | `probe-evidence-within.json` + drift 有の `project-field-list` | stdout に 2 系統の結果行（`audit:workflow-item-closed:...` + `audit:spec-conformance:drift:exit=3`）+ `audit-summary:...` 行を順次出力、overall_exit は 0 と drift の max（strict=3 / soft=0） | 3（strict）/ 0（soft、warn のみ） |

---

## bats `setup()` の標準パターン

各 bats ファイルの `setup()` は以下の最小パターンを採用する（具体的な fixture / failure 注入は `@test` 内で実施）:

```text
load '_helpers'

setup() {
    gh_project_setup_env
    gh_project_mock_gh
    gh_project_mock_dasel
    gh_project_mock_yq
    # 必要なデフォルト fixture を配置
    gh_project_set_fixture project-list "${BATS_TEST_DIRNAME}/fixtures/project-list.json"
    gh_project_set_fixture project-field-list "${BATS_TEST_DIRNAME}/fixtures/project-field-list-default.json"
    # ... 各 bats が必要とする最小 fixture を列挙
}
```

`teardown()` は bats が `BATS_TEST_TMPDIR` を自動 cleanup するため不要。

---

## fixture スキーマ確定方針（設計レビュー → Phase 2 実装の境界）

| fixture | 参照する subject / 関数 | 確定すべきキー |
|---------|------------------------|---------------|
| `project-list.json` | `gh_project_state_get_or_create_project` | `.projects[].number` / `.title` / `.owner.login` |
| `project-create.json` | `gh-project-repo.sh:39` `gh project create` | `.number` / `.url` |
| `project-edit.json` | `gh-project-repo.sh:52` `gh project edit --visibility public` | （空 JSON `{}` 許容、status のみ） |
| `project-field-list-default.json` | `gh_project_state_get_fields` | `.fields[].id` / `.name` / `.options[].name` |
| `project-field-list-with-cycle.json` | 同上（Cycle field 含む drift 検証用） | 同上 + dynamic Cycle field |
| `project-field-create.json` | `gh-project-repo.sh:70` `gh project field-create` | `.id` / `.name` |
| `project-view-list.json` | `gh-project-state.sh:105` `gh project view-list` | `.views[].id` / `.name` / `.layout` |
| `project-view-create.json` | `gh-project-repo.sh:124` `gh project view-create` | `.id` / `.name` |
| `project-item-add.json` | `gh-project-repo.sh:151` `gh project item-add` | `.id` / `.content.url` |
| `project-item-list.json` | `gh_project_state_get_items` | `.items[].id` / `.content.url` / `.fields` |
| `project-item-edit.json` | `gh-project-repo.sh:169` `gh project item-edit` | （空 JSON `{}` 許容、status のみ） |
| `issue-list.json` | `gh-project-cli.sh:530` `gh issue list --label backlog --state open --json url` | `[{ "url": "https://github.com/.../issues/N" }, ...]`（JSON 配列） |
| `issue-view.json` | `migrate-issue-524.sh:63` + `gh-project-cli.sh:522` `gh issue view --json body --jq '.body'` | `.body`（jq `--jq '.body'` の結果として string が返る点に注意 — モックは `cat fixture` で JSON 全体を返すため、fixture 側で `.body` 抽出後を想定するかどうかは Phase 2 実装時に gh wrapper の挙動と整合を確認する） |
| `issue-create.json` | `gh-project-repo.sh:175` `gh issue create` | stdout に Issue URL を 1 行で出力（JSON ではない / 実装は `head -n1` で URL 取得）。fixture は raw text として配置 |
| `issue-edit.json` | `migrate-issue-524.sh:112` `gh issue edit --body-file` | （空 JSON `{}` 許容、status のみ） |
| `issue-close.json` | `gh-project-repo.sh:182` `gh issue close` | （空 JSON `{}` 許容、status のみ） |
| `issue-delete.json` | `gh-project-repo.sh:188` `gh issue delete` | （空 JSON `{}` 許容、status のみ） |
| `api-graphql.json` | `gh-project-repo.sh:87` `gh api graphql` | `.data.updateProjectV2SingleSelectField.projectV2Field.options` |
| `probe-evidence-*.json` | `audit-github-project.sh`（`gh_project_evidence_load`） | `.probe.timestamp` / `.probe.workflow_item_closed_evidence` |

**注記**: `issue-view.json` / `issue-create.json` は `gh` の `--json` / 純 text 出力の違いがあるため、Phase 2 実装時に `gh` wrapper の dispatcher 分岐内で **`cat` 出力形式（JSON / raw text）** を fixture に合わせる必要がある。設計レビューで判明した両者の混在パターンへの対応:

- `issue-view.json`: `gh issue view --json body --jq '.body'` の呼出は `gh` 内部で jq が走るため、wrapper 側では `.body` を含む JSON を返すか、`--jq` 引数を解釈して値のみ返すかの選択になる。前者（JSON を返す）を採用し、`--jq` 引数を持つ呼出は wrapper 側で `jq -r "$jq_arg"` を経由する形に拡張する（Phase 1 完了マーカー bats で動作確認）
- `issue-create.json`: 実装は `head -n1` で 1 行目を URL として取得するため、fixture は raw text 形式（1 行目に URL）で配置

設計レビュー時に各ヘルパー関数の `jq` クエリを grep し、参照キーと fixture スキーマの一致を確認する。スキーマ不一致は Phase 2 実装中に発見されると非効率なため、論理設計フェーズで確定する。

---

## API 設計（既存への波及なし）

本 Unit は **テスト追加のみ** であり、既存 CLI / シェル関数の公開 API には一切変更を加えない。`_helpers.bash` の公開関数は bats テスト専用の内部 API であり、`bin/` 配下のスクリプトからは参照されない。

---

## エラーハンドリング

| エラー種別 | 検出箇所 | 動作 |
|-----------|---------|------|
| 未モック API | `gh` wrapper `*)` 分岐 | `unmocked:<args>` 表示 + exit 99（bats 側で `[ "$status" -eq 99 ]` を期待しないテストはすべて fail） |
| fixture 不在 | `gh` wrapper の `cat` 直前 | `fixture not found: <path>` + exit 98 |
| `BATS_TEST_TMPDIR` 不在 | `gh_project_setup_env` の `: "${BATS_TEST_TMPDIR:?}"` | bats 未起動時に即 fail |
| グローバル / per-api 失敗注入 | `gh` wrapper 内部 | `gh mock: <reason> injected failure` + exit 1（mock 由来であることを stderr に明示） |
| 既存 subject 内のエラー | subject 自身 | 既存規約踏襲（`_emit_error` / exit 1〜5） |

---

## 拡張性

- **新規 gh API 追加**: 以下 2 ステップで完了
  1. `_helpers.bash` の `gh_project_mock_gh` 内 case 文に 1 ブロック追加（`"<api>") [[ -n "${MOCK_<API>_FAIL:-}" ]] && fail; _f="..."`）
  2. `bin/tests/gh-project/fixtures/<api>.json` を追加
- **新規 subject 追加**: 既存 4 bats と同形式で `<subject>.bats` を新設し、`setup()` で `load '_helpers'` + factory 呼出
- **fixture バリアント追加**: 同一 ApiSelector で複数 fixture が必要な場合、`<api>-<variant>.json` 命名で SoT 側に配置し、`@test` 内で `gh_project_set_fixture` 切替

---

## テスト戦略

- **ヘルパー自身のテスト**: 最小限（`gh_project_setup_env` 呼出後の環境変数 / mkdir の確認は Phase 2 完了マーカー bats で吸収）
- **モック false positive 防止**: fixture スキーマを論理設計フェーズで確定（§「fixture スキーマ確定方針」参照）
- **未モック検出機構の検証**: 専用 `@test` を 1 件以上設け、想定外 API 呼出が exit 99 を返すことを明示確認

---

## 非機能要件への対応

| NFR | 設計上の担保 |
|-----|------------|
| 保守性 | dispatcher の case 文 1 行 + fixture 1 ファイル追加で API 拡張可能（拡張性セクション参照） |
| 検出力 | `*)` 分岐の exit 99 + fixture 不在の exit 98（false positive 二重防止） |
| 保証性 | 既存 28 件 + Unit 004 追加 10 件 + Phase 2 新規 17 件の合計 55 件相当が `bats bin/tests/gh-project/` で全件 green |
| 可搬性 | bash / jq / bats / shellcheck / shellharden のみ依存（`stat -c %s` 等の非可搬コマンド未使用） |
| テスタビリティ | Phase 1 完了マーカー（setup bats 1 件動作）/ Phase 2 完了マーカー（4 bats 全件 pass + 既存 38 件並存）を明示 |

---

## 配置構造（変更前後）

### 変更前

```text
bin/tests/gh-project/
├── cli_args.bats
├── ensure_fields_options_sync.bats   # 個別モック実装 80 行
├── scope_check.bats
└── spec.bats
```

### 変更後

```text
bin/tests/gh-project/
├── _helpers.bash                     # 新規（Phase 1）
├── fixtures/                         # 新規（Phase 1）
│   └── *.json                        # 12〜14 ファイル
├── cli_args.bats                     # 既存（変更なし）
├── ensure_fields_options_sync.bats   # 既存（Phase 2 末尾で _helpers 経由化）
├── scope_check.bats                  # 既存（変更なし）
├── spec.bats                         # 既存（変更なし）
├── setup-github-project.bats         # 新規（Phase 2）
├── migrate-issue-524.bats            # 新規（Phase 2）
├── probe-github-project.bats         # 新規（Phase 2）
└── audit-github-project.bats         # 新規（Phase 2）
```

---

## 不明点と質問

[Question] なし。設計レビューで追加質問があれば追記する。
