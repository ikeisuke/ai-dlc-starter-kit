# Unit 004 計画: gh-project-cli ensure-fields の field options 差分同期

## 対象

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/004-gh-project-cli-options-sync.md`
- 関連 Issue: #682（type:defer-from-review / priority:medium / v2.6.0 Unit 006 R1 #2）
- 関連先行: v2.6.0 Unit 006（GitHub Projects 移行 / `bin/gh-project-cli.sh` / `bin/lib/gh-project-repo.sh` 本体整備）

## 目的

`bin/gh-project-cli.sh ensure-fields` が、spec.yaml 改訂後の再実行で **既存 field に新規 option を冪等同期できる**ようにする。現状の `field:exists` 分岐は「field 名一致で即スキップ」のため、初回作成時にしか spec.fields[*].options が反映されず、「Status に新オプション追加」「`priority:*` ラベル拡張に伴う Cycle field 拡張」等の運用変更を取り込めない。

`field:exists` 分岐に options 差分同期ロジック（spec → 既存への片方向追加）を加え、dry-run / strict / soft の既存モードと整合させる。

## スコープ

### 含まれるもの

1. `bin/gh-project-cli.sh::_subcmd_ensure_fields` の `field:exists` 分岐拡張:
   - 既存 field の `.options[].name` を `existing_fields` JSON から抽出
   - spec 側 `fields[$i].options`（配列形式）との差分集合 `to_add = spec_options - existing_options` を計算
   - 差分 option を `gh_project_repo_add_field_option <owner> <number> <field_id> <name>` で順次追加
2. 内部ヘルパー `_sync_field_options()` を `gh-project-cli.sh` 内に追加（subcommand スコープ内 / 既存スタイルに準拠）:
   - **確定シグネチャ**: `_sync_field_options <field_id> <field_name> <existing_options_json> <spec_options_json> <owner> <number>`（R1 設計レビュー指摘 #3 反映: 引数を JSON 配列文字列化）
     - `mode` / `dry_run` は引数で受け取らず、**既存グローバル変数 `_DRY_RUN` / `_MODE` を直接参照**（`_subcmd_*` 他関数と同一規約）
     - `owner` / `number` は内部で `gh_project_repo_add_field_option` 呼出に必要なため引数化（環境変数経由にしない）
   - 動作: 差分計算 → `_DRY_RUN` / `_MODE` に応じて追加 API 呼出 / 予定出力 / warn。**strict + extraneous は fail-fast**（追加 API を呼ばず即 return 3 / R1 設計レビュー指摘 #2 反映）
   - 戻り値: 成功 0 / 引数不正 1 / strict 違反 3 / strict + API 失敗 3 / soft 時の任意失敗 0
3. 出力規約（既存 CLI 規約との整合）:
   - **stdout（plain text、構造化シグナル）**: 既存 `field:exists:<name>` / `field:created:<name>` と同列の構造化メッセージ
     - 通常追加: `field:<name>:options-added:<count>:names=<n1>,<n2>,...`
     - dry-run: `field:<name>:options-would-add:<count>:names=<n1>,<n2>,...`
     - 全件既存（no-op）: 追加出力なし（既存 `field:exists:<name>` のみが直前に出力済み）
   - **stderr（JSON、機械可読）**: 既存 `_emit_error` ヘルパーと同形式を踏襲
     - strict 違反（spec にない既存 options を検出）: 新規ヘルパー `_emit_warn "options_extraneous" "field=<name>:names=<n1>,..."` を導入（`_emit_error` と同じ `{error_type, details}` 形式の JSON、ただしストリームは stderr / process は exit せず）
     - soft API 失敗: `_emit_warn "gh_api_error" "options_add_failed:field=<name>:option=<n>"`
     - strict API 失敗: `_emit_error "gh_api_error" "options_add_failed:field=<name>:option=<n>"` + exit 3
   - 規約の二重化を避けるため、本 Unit では **`warn\t...` のタブ区切り形式は導入しない**（指摘 #4 反映）。warn 系も JSON 統一
4. モード別動作（観測可能性確定）:

   | モード | 入力（spec / existing） | stdout | stderr | exit |
   |--------|------------------------|--------|--------|------|
   | strict | spec=existing（差分なし） | `field:exists:<name>` のみ | なし | 0 |
   | strict | spec ⊋ existing（追加方向のみ） | `field:exists` + `options-added:<count>:names=...` | なし | 0 |
   | strict | spec ⊊ existing（既存に余分） | `field:exists` のみ | `_emit_warn options_extraneous` JSON | 3 |
   | strict | spec / existing 双方向差分 | `field:exists` のみ（fail-fast: `options-added` 出力なし） | `_emit_warn options_extraneous` JSON | 3 |
   | strict | API 失敗 | `field:exists` のみ | `_emit_error gh_api_error` JSON | 3 |
   | soft | spec=existing | `field:exists:<name>` のみ | なし | 0 |
   | soft | spec ⊋ existing | `field:exists` + `options-added` | なし | 0 |
   | soft | spec ⊊ existing | `field:exists` のみ | `_emit_warn options_extraneous` | 0 |
   | soft | API 失敗 | `field:exists` のみ | `_emit_warn gh_api_error` | 0 |
   | dry-run | spec ⊋ existing | `field:exists` + `options-would-add` | なし（API 呼ばれない） | 0 |
   | dry-run | spec ⊊ existing | `field:exists` のみ | `_emit_warn options_extraneous` | 0（dry-run 整合） |
5. bats テスト追加（新規ファイル `bin/tests/gh-project/ensure_fields_options_sync.bats`、確定 10 ケース。詳細は「実装方針 §4」参照）:
   - no-op / 1 件追加 / 複数追加 / strict 既存余分（fail-fast）/ strict 双方向差分（fail-fast）/ soft 既存余分 / dry-run + 追加 / dry-run + 既存余分 / strict + API 失敗 / soft + API 失敗
6. 既存 fixture / モックパターンの拡張: `bin/tests/gh-project/cli_args.bats` / `spec.bats` 構成と整合する形で gh CLI モック（`field-list` / `gh api graphql` 呼び出し）を導入
7. shellcheck / shellharden / markdownlint 通過（既存スクリプトの規約踏襲）

### 含まれないもの

- options の **削除方向** 同期（spec - existing の逆。strict は検出のみ。実削除は本 Unit 対象外）
- options の **順序** 保証（GitHub Projects API の制約上、テストは集合一致で判定）
- field 自体の create / delete ロジック改変（既存 `field:create` 経路は不変）
- `options == "dynamic"` の field（現状 Cycle field のみ）への差分同期。実 milestone 投入は `sync-items` 経路の責務であり、本 Unit のスコープ外
- `ensure-views` / `sync-items` / `audit` への波及（本 Unit は `ensure-fields` のみ）
- `gh_project_repo_add_field_option` ヘルパーのインターフェース変更（既存シグネチャをそのまま利用）
- Unit 005（副作用 bats 整備 / gh API モックフレームワーク）の責務（本 Unit は「機能テスト」のみ。回帰テスト本体は Unit 005 Phase 2 で吸収）

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [x] `_subcmd_ensure_fields` の `field:exists` 分岐に options 差分同期ロジックが追加されている
- [x] 既存 field の `.options[].name` 取得 + spec 側 `fields[*].options` との差分計算が実装されている
- [x] 差分 option が `gh_project_repo_add_field_option` で順次追加される
- [x] dry-run / strict / soft 各モードの正しい動作が実装されている
- [x] 同期処理の出力フォーマット（`field:<name>:options-added:<count>:names=<n1>,<n2>,...`）が定義通り出力される
- [x] bats テストが追加され、確定 10 ケース（no-op / 1 件追加 / 複数追加 / strict 既存余分 / soft 既存余分 / dry-run + 追加 / dry-run + 既存余分 / strict + API 失敗 / soft + API 失敗）が全 pass する

### Issue #682 受け入れ基準

- [x] spec.yaml 改訂後の `ensure-fields` 再実行で、既存 field に新 option が追加される（冪等同期）
- [x] 初回 Project 作成時の挙動は変わらない（`field:create` 経路は不変）
- [x] dry-run / strict / soft の各モードが既存の他 subcommand と一貫した動作をする
- [x] `priority:*` ラベル拡張 / Cycle field 拡張等の運用想定で差分同期が機能する（テスト fixture で再現）

### 非機能要件（NFR）

- [x] **冪等性**: 同一 spec で複数回実行しても結果が変わらない（既存 options 検出 → no-op、bats `no-op` ケースで検証）
- [x] **可観測性**: 追加した option 名と件数が stdout に明示される（`options-added:<count>:names=<...>` フォーマット）
- [x] **モード対応**: dry-run / strict / soft が一貫動作（bats 各モードケースで検証）
- [x] **可搬性**: macOS / Linux 双方の bash で動作（jq / gh / bash のみ依存、stat -c %s 等の非可搬コマンドは未使用）
- [x] **テスタビリティ**: 機能 AC が bats で自動検証可能（確定 10 ケース、全 pass。詳細は「実装方針 §4」のテスト表参照）
- [x] **エラー出力の機械可読性**: stderr に JSON `{error_type, details}` 形式（既存 `_emit_error` 規約踏襲）。warn 系は新規 `_emit_warn` ヘルパー（同形式 / stderr / exit せず）に統一（R1 指摘 #4 / R2 指摘 #1 反映、tab 区切りは導入しない）

### Intent 制約適合

- [x] **破壊的変更なし**: 既存 `field:create` 経路は変更しない。`field:exists` 分岐の加算のみ（bats `no-op` / `create` 経路非干渉ケースで検証）
- [x] **ドッグフーディング特殊処理禁止**: 自リポジトリ判定による分岐は導入しない（consumer プロジェクトでも同一の差分同期ロジックが動作）
- [x] **コマンド置換の取り扱い**: 既存 `gh-project-cli.sh` の **bash スクリプト内部ローカル変数代入での `$(...)` 使用は許容**（既存スタイル踏襲）。一方、CLAUDE.md / `.aidlc/rules.md` で禁じられる **AI Bash プロンプト経由のコマンド置換 / commit message 内のコマンド置換** は新規導入しない。「実装内」を「AI Bash プロンプトおよび git commit -m に渡す文字列内」と読み替える（指摘 #1 反映）

## 実装方針（概略 / 設計レビューで詳細化）

### 1. ヘルパー関数の追加

`bin/gh-project-cli.sh` に内部ヘルパーを追加（subcommand スコープ）:

```bash
# 差分計算 + モード別 dispatch（JSON 配列ベース / strict は fail-fast）
_sync_field_options() {
    local field_id="$1"            # 既存 field の Node ID
    local field_name="$2"
    local existing_options_json="$3"  # 既存 options.name の JSON 配列（例: '["A","B"]'）
    local spec_options_json="$4"      # spec.fields[i].options の JSON 配列（array 由来のみ。dynamic は呼出側で除外）
    local owner="$5"
    local number="$6"

    # 1. 引数検証（JSON 配列の妥当性チェック / jq -e 'type=="array"'）
    # 2. 差分計算（to_add = spec - existing / extraneous = existing - spec）
    # 3. extraneous 検出: stderr に _emit_warn / strict + !dry_run なら追加 API を呼ばず即 return 3（fail-fast）
    # 4. to_add 処理: dry-run なら options-would-add、それ以外は順次 add_field_option（strict 失敗は即 return 3、soft 失敗は continue）
    # 5. stdout は表示層で jq join(",") により CSV 整形（内部表現は JSON のまま）
}
```

差分計算は jq による集合演算で実装（既存パターン踏襲）。R1 設計レビュー指摘 #3 に基づき、内部表現は JSON 配列に統一する。

### 2. `_subcmd_ensure_fields` の `field:exists` 分岐拡張

```bash
if [[ -n "$exists" ]]; then
    printf 'field:exists:%s\n' "$fname"
    # spec options を取得（array 形式のみ。dynamic / null はスキップ）
    local opts_kind spec_opts_json existing_opts_json field_id
    opts_kind="$(printf '%s' "$spec_json" | jq -r ".fields[$i].options | type")"
    if [[ "$opts_kind" == "array" ]]; then
        # 内部表現は JSON 配列のまま（CSV 化しない / R1 設計レビュー指摘 #3 反映）
        spec_opts_json="$(printf '%s' "$spec_json" | jq -c ".fields[$i].options")"
        existing_opts_json="$(printf '%s' "$existing_fields" | jq -c --arg n "$fname" '.fields[] | select(.name==$n) | .options // [] | map(.name)')"
        field_id="$exists"
        _sync_field_options "$field_id" "$fname" "$existing_opts_json" "$spec_opts_json" "$owner" "$number" || rc=$?
        if [[ $rc -ne 0 ]]; then exit "$rc"; fi
    fi
else
    # 既存 field:create 経路（変更なし）
fi
```

### 3. モード別動作

| モード | 差分（追加方向） | strict 違反（spec にない既存） | API 失敗 |
|--------|------------------|-------------------------------|---------|
| dry-run | `options-would-add` 出力、API 呼ばず | warn 出力、exit せず | （API 呼ばず該当なし） |
| strict | API 呼出 + `options-added` 出力 | warn 出力 + exit 3 | exit 3 |
| soft | API 呼出 + `options-added` 出力 | warn 出力 + 継続 | warn 出力 + 継続 |

### 4. bats テスト設計

新規 `bin/tests/gh-project/ensure_fields_options_sync.bats`（指摘 #3 / #5 反映後の確定 10 ケース）:

| # | ケース | mode | 入力（spec / existing） | stdout 期待 | stderr 期待 | 期待 exit | gh api graphql 呼出回数 |
|---|--------|------|-------------------------|-------------|-------------|-----------|----------------------|
| 1 | no-op（差分なし） | strict | {A,B} / {A,B} | `field:exists:Status`（`options-added` 含まない） | なし | 0 | 0 |
| 2 | 1 件追加 | strict | {A,B} / {A} | `field:exists:Status` + `field:Status:options-added:1:names=B` | なし | 0 | 1（option=B） |
| 3 | 複数追加 | strict | {A,B,C} / {A} | `field:exists:Status` + `field:Status:options-added:2:names=B,C` | なし | 0 | 2（option=B, option=C） |
| 4 | strict 既存余分（fail-fast / spec ⊊ existing） | strict | {A} / {A,B} | `field:exists:Status` のみ | `options_extraneous` JSON（`names=B`） | 3 | 0 |
| 4-bis | strict + 双方向差分（fail-fast） | strict | {A,C} / {A,B} | `field:exists:Status` のみ（`options-added` なし） | `options_extraneous` JSON（`names=B`） | 3 | 0（fail-fast で追加 API 呼ばれない） |
| 5 | soft 既存余分 | soft | {A} / {A,B} | `field:exists:Status` のみ | `options_extraneous` JSON（`names=B`） | 0 | 0 |
| 6 | dry-run + 追加方向差分 | dry-run | {A,B} / {A} | `field:exists:Status` + `field:Status:options-would-add:1:names=B` | なし | 0 | 0（API 呼ばれない） |
| 7 | dry-run + 既存余分 | dry-run | {A} / {A,B} | `field:exists:Status` のみ | `options_extraneous` JSON | 0 | 0 |
| 8 | strict + API 失敗 | strict | {A,B} / {A} + mock fail | `field:exists:Status` のみ（部分追加なし） | `gh_api_error` JSON | 3 | 1（失敗注入） |
| 9 | soft + API 失敗 | soft | {A,B} / {A} + mock fail | `field:exists:Status` のみ | `gh_api_error` warn JSON | 0 | 1（失敗注入） |

#### モック契約（指摘 #5 反映）

**`gh project field-list` モック**:
- 入力期待: `gh project field-list --owner <owner> <number> --format json`（既存 `gh_project_state_get_fields` の呼出形）
- 出力: bats fixture JSON ファイルから読み込み（テストケース別に内容を差し替え）
- 呼出回数: 1 回（subcommand 起動ごと、既存 `existing_fields` 取得段階）
- スキーマ: `{"fields":[{"id":"<node_id>","name":"<field>","options":[{"name":"<opt>"},...]}]}`

**`gh api graphql` モック（`gh_project_repo_add_field_option` 内部）**:
- 入力期待: `gh api graphql -f query=... -f fieldId=<node_id> -f option=<name>`（既存ヘルパー L87-96 の呼出形）
- 失敗注入: 環境変数 `MOCK_GH_API_GRAPHQL_FAIL=1` を設定したテストでは exit 1 を返す
- 呼出回数アサート: モック内部で `${BATS_TEST_TMPDIR}/gh_api_graphql_calls.log` に各呼出を 1 行ずつ追記し、`wc -l` で回数を検証
- 引数アサート: `gh_api_graphql_calls.log` の各行から `option=<name>` を抽出して期待集合と一致確認

**既存パターン踏襲**:
- `bin/tests/gh-project/cli_args.bats` の `MOCK_DIR` / `PATH` 上書きパターンを再利用
- `bin/tests/gh-project/spec.bats` の fixture JSON 読み込みパターンを再利用
- ランタイムバインディング（`_read_runtime_binding "project_number"`）も mock し、固定値（例: `123`）を返す

### 5. 整合性確保

- `_DRY_RUN` / `_MODE` の既存パース結果を `_sync_field_options` に直接参照させる（環境変数 / グローバル変数）
- 出力先（stdout / stderr）の使い分けは既存 subcommand と完全一致させる
- `_emit_error` ヘルパーの既存規約（stderr に JSON `{error_type, details}` を出力）を使用。warn 系は新規 `_emit_warn`（同 JSON 形式 / stderr / exit せず）を追加して統一する

## 依存・前提

- bash + jq + gh CLI: 既存 `gh-project-cli.sh` の動作環境
- `gh_project_repo_add_field_option` ヘルパー（既存実装 / GraphQL mutation 経由）
- `gh_project_state_get_fields` ヘルパー（既存実装 / `--format json` で options 含む JSON 返却）
- bats / shellcheck / shellharden: 既存テスト環境
- `bin/tests/gh-project/` の既存 mock yq / mock gh パターン

## リスクと緩和

| リスク | 影響 | 緩和策 |
|--------|------|--------|
| `gh project field-list --format json` の options フィールドが想定と異なる構造 | 中 | 設計レビューで JSON スキーマを fixture で固定し、bats テストで検証 |
| `gh_project_repo_add_field_option` の GraphQL mutation 仕様変更 | 低 | 既存ヘルパーのシグネチャをそのまま使い、変更が必要なら別 Unit |
| dynamic field（Cycle）が混在する spec で差分同期が誤発火 | 中 | `opts_kind == "array"` ガードで dynamic / null をスキップ。bats fixture に dynamic field を含めて回帰検証 |
| strict / soft の判定が既存 subcommand と乖離 | 中 | 既存 `ensure-fields` の rc 制御フローを踏襲（`exit "$rc"`）。bats 各モードケースで網羅 |
| 出力フォーマットの csv エスケープ漏れ | 低 | option name に `,` が含まれない GitHub の制約に依存。設計時に NFR として明示 |
| API 呼出失敗時の部分追加（途中まで成功）の扱い | 中 | strict では即 exit 3 / soft では warn 継続。両モードでテストを追加 |

## 想定タイムライン

- Phase 1 設計: 0.5 時間（ドメインモデル + 論理設計 + 設計レビュー）
- Phase 2 実装: 1.0〜1.5 時間（ヘルパー `_sync_field_options` + `_emit_warn` 実装 + 既存分岐改修 + bats 10 ケース + gh モック契約整備）
- 完了処理: 0.5 時間
- 合計: 約 2〜2.5 時間（0.5〜1 日相当 / Unit 見積もり下限〜中央）

## 関連

- Unit 005（gh-project 副作用 bats テスト整備）: Unit 004 完了後の Phase 2 で options 差分同期の **回帰テスト** を吸収する責務境界。本 Unit はあくまで「機能テスト」を担う
- v2.6.0 Unit 006 R1 #2（#673 由来）: 本 Unit の defer 起点
