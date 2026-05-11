# 論理設計: Unit 004 — gh-project-cli ensure-fields の field options 差分同期

## 概要

`bin/gh-project-cli.sh::_subcmd_ensure_fields` の `field:exists` 分岐に options 差分同期ロジックを追加する。集合差分を計算する内部ヘルパー `_sync_field_options` と、warn 系メッセージを `_emit_error` と同形式の JSON で stderr 出力する `_emit_warn` を新設する。

**重要**: この論理設計では **コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコードは Phase 2 で作成する。

---

## アーキテクチャパターン

- **採用パターン**: 既存の **shell-script procedural + 内部ヘルパー関数による責務分割**（Unit 006 v2.6.0 で確立された `gh-project-cli.sh` の構成を踏襲）
- **選定理由**:
  - 既存 `_subcmd_*` / `_parse_common_opts` / `_emit_error` / `_check_scopes_or_exit` の責務分割パターンと整合する
  - shell script の制約（オブジェクト指向不可）下で、関数粒度を細かく保ち単体性を高める
- **不採用**:
  - 別ファイル（例: `bin/lib/gh-project-options-sync.sh`）への切り出しは、本 Unit のロジックが `_subcmd_ensure_fields` の文脈（`_DRY_RUN` / `_MODE` グローバル変数 + spec_json コンテキスト）と密接に結合しており、現時点での切り出しは過剰設計と判断。将来 Unit 005 等で副作用テスト基盤が整備された段階で再評価

---

## コンポーネント構成

### モジュール構成

```text
bin/
├── gh-project-cli.sh
│   ├── _emit_error          # 既存（変更なし）
│   ├── _emit_warn           # 新規（本 Unit）
│   ├── _parse_common_opts   # 既存（変更なし）
│   ├── _subcmd_ensure_fields
│   │   └── field:exists 分岐
│   │       └── _sync_field_options 呼出  ← 新規（本 Unit）
│   └── _sync_field_options  # 新規（本 Unit）
├── lib/
│   ├── gh-project-repo.sh
│   │   └── gh_project_repo_add_field_option  # 既存ヘルパー（呼出のみ、変更なし）
│   └── gh-project-state.sh
│       └── gh_project_state_get_fields       # 既存ヘルパー（変更なし）
└── tests/gh-project/
    └── ensure_fields_options_sync.bats       # 新規（本 Unit）
```

### コンポーネント詳細

#### `_subcmd_ensure_fields`（既存、拡張）

- **責務**: spec の各 field に対し、existing field の有無を判定し、必要に応じて field 作成 / options 差分同期を実施
- **依存**: `gh_project_state_get_fields` / `gh_project_repo_create_field` / **`_sync_field_options`（新規）**
- **公開インターフェース**: `ensure-fields` サブコマンド（既存 CLI）
- **本 Unit での変更**:
  - `field:exists` 分岐（L253-254 付近）の `printf 'field:exists:%s\n' "$fname"` の直後に、spec.options が `array` 形式の場合のみ `_sync_field_options` を呼ぶ条件分岐を追加
  - `_sync_field_options` の戻り値が非 0 の場合は `exit "$rc"` で伝播（既存 `create_field` 経路の rc 制御と同パターン）

#### `_sync_field_options`（新規）

- **責務**: 1 field の options 差分同期処理一式
  - jq による集合差分計算（`spec - existing` および `existing - spec`）
  - `_DRY_RUN` / `_MODE` を参照したモード別 dispatch
  - `gh_project_repo_add_field_option` への順次呼出（dry-run 時は呼ばない）
  - stdout / stderr への出力
- **依存**: `gh_project_repo_add_field_option` / `_emit_warn`（新規）/ `_emit_error`
- **公開インターフェース**: bash 関数（subcommand 内部スコープ）

#### `_emit_warn`（新規）

- **責務**: warn メッセージを `_emit_error` と同じ JSON 形式で stderr に出力する。process は exit しない
- **依存**: jq（既存 `_emit_error` と同じ）
- **公開インターフェース**: bash 関数（subcommand / ヘルパー共通スコープ）
- **既存 `_emit_error` との関係**:
  - 同じ JSON スキーマ（`{error_type, details}`）
  - 同じ stderr 出力先
  - 唯一の差: `_emit_warn` は exit しない / `_emit_error` は呼出側が exit 制御

---

## インターフェース設計

### スクリプトインターフェース: `bin/gh-project-cli.sh ensure-fields`（既存、本 Unit で動作拡張）

#### 概要

GitHub Project の SINGLE_SELECT field を spec.yaml に合わせて確保する。field が未作成なら作成、作成済みなら **options 差分を spec → 既存方向に同期**（本 Unit で追加）。

#### 引数（既存、変更なし）

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--spec <path>` | 任意 | spec.yaml のパス（既定: `.aidlc/gh-project-spec.yaml`） |
| `--dry-run` | 任意 | 実 API を呼ばず予定動作のみ出力 |
| `--strict` | 任意 | extraneous 検出 / API 失敗で exit 3（既定 mode） |
| `--soft` | 任意 | extraneous 検出 / API 失敗を warn で継続 |

#### 成功時出力（本 Unit で追加分のみ抜粋）

```text
field:exists:Status                                    # 既存
field:Status:options-added:1:names=Foo                 # 新規（通常追加）
field:Status:options-would-add:2:names=Foo,Bar         # 新規（dry-run）
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力（本 Unit で追加分のみ抜粋）

```text
{"error_type":"options_extraneous","details":"field=Status:names=DeprecatedOption"}
{"error_type":"gh_api_error","details":"options_add_failed:field=Status:option=Foo"}
```

- 終了コード: `3`（strict 違反 / API 失敗）/ `0`（soft / dry-run）
- 出力先: stderr

---

### コマンド: `_sync_field_options`（新規ヘルパー）

#### パラメータ（R1 指摘 #3 反映: CSV → JSON 配列文字列）

| パラメータ | 必須/任意 | 型 | 説明 |
|-----------|----------|----|------|
| `$1` field_id | 必須 | String | 既存 field の Node ID（GraphQL `fieldId`） |
| `$2` field_name | 必須 | String | 対象 field の表示名（出力用） |
| `$3` existing_options_json | 必須 | String | 既存 options.name の **JSON 配列文字列**（例: `["Todo","In Progress"]`）。空配列 `[]` = options なし |
| `$4` spec_options_json | 必須 | String | spec.fields[i].options の **JSON 配列文字列**（`array` 形式のみ。dynamic / null は呼出側で除外） |
| `$5` owner | 必須 | String | GitHub Project owner（`@me` or `@<org>`） |
| `$6` number | 必須 | String | GitHub Project number |

**入力検証**: `$3` / `$4` が有効な JSON 配列でない場合は `_emit_error "args_invalid" "options_json_invalid:field=<name>"` + return 1（防御的失敗）。集合演算は jq の `--argjson` で直接渡し、bash 文字列分割は使用しない。

#### 戻り値

- `0`: 成功（no-op / 追加成功 / soft で warn 出力）
- `1`: 引数エラー（実装不整合。`_emit_error args_invalid`）
- `3`: strict 違反（extraneous 検出 or API 失敗）

#### 副作用

- stdout: `field:<name>:options-(would-)added:<count>:names=...`（追加方向の差分があるとき）
- stderr: `_emit_warn` / `_emit_error` JSON（extraneous / API 失敗時）
- GitHub Projects API: `gh_project_repo_add_field_option` 呼出（`_DRY_RUN=false` 時のみ）
- グローバル変数 `_DRY_RUN` / `_MODE` を **読取のみ**（書き換えない）

#### 内部ステップ（R1 指摘 #2 反映: strict は fail-fast）

1. **引数検証**: 必須引数 6 個 + `existing_options_json` / `spec_options_json` が有効な JSON 配列であることを `jq -e 'type=="array"'` で検証。不正なら `_emit_error "args_invalid" "options_json_invalid:field=<name>"` + return 1
2. **差分計算**: jq の `--argjson` で JSON 配列を直接渡し、集合差分を計算
   - `to_add = spec - existing`（順序は spec 順を保持: `spec_json | map(select(. as $x | existing_json | index($x) | not))`）
   - `extraneous = existing - spec`（同様に existing 順を保持）
3. **extraneous 処理（fail-fast）**:
   - `extraneous` が空でない場合、`_emit_warn "options_extraneous" "field=<name>:names=<n1>,..."` を stderr 出力
   - **`_DRY_RUN=false` かつ `_MODE=strict`**: 追加 API は呼ばずに即 return 3（fail-fast。`options-added` 等の stdout 出力もしない）
   - `_DRY_RUN=true` または `_MODE=soft`: warn を出して to_add 処理に継続
4. **to_add 処理**:
   - `to_add` が空 → 何も出力せず return 0
   - `_DRY_RUN=true`: 表示層で JSON 配列を CSV に整形し、`printf 'field:%s:options-would-add:%d:names=%s\n' "$field_name" "$count" "$names_csv"` を出力 + return 0
   - `_DRY_RUN=false`:
     - `to_add` の各 option を順次 `gh_project_repo_add_field_option "$owner" "$number" "$field_id" "$opt"` で追加
     - 失敗時:
       - `_MODE=strict` → `_emit_error "gh_api_error" "options_add_failed:field=<name>:option=<n>"` + return 3（部分追加で停止）
       - `_MODE=soft` → `_emit_warn "gh_api_error" "options_add_failed:field=<name>:option=<n>"` + 次の option へ継続
     - 全成功 / soft 完了時 → 表示層で JSON 配列を CSV に整形し、`printf 'field:%s:options-added:%d:names=%s\n' "$field_name" "$added_count" "$names_csv"` を出力（added_names は実際に成功したもの）
5. **CSV 整形の責務境界**: ステップ 2 / 3 の集合演算は全て JSON 配列上で完結。CSV への変換はステップ 4 の `printf` 直前の表示整形でのみ実施（jq の `join(",")` 1 回）
6. **戻り値決定**:
   - 引数不正 → 1
   - strict + extraneous 検出（即 return）→ 3
   - strict + API 失敗 → 3
   - その他 → 0

---

### コマンド: `_emit_warn`（新規ヘルパー）

#### パラメータ

| パラメータ | 必須/任意 | 型 | 説明 |
|-----------|----------|----|------|
| `$1` error_type | 必須 | String | warn の分類（例: `options_extraneous`, `gh_api_error`） |
| `$2` details | 必須 | String | 詳細メッセージ |

#### 戻り値

- `0`: 常に成功（exit しない）

#### 副作用

- stderr: `{"error_type":"<type>","details":"<details>"}` JSON 1 行
- jq 不在時のフォールバック: `printf '{"error_type":"%s","details":"jq_unavailable"}\n'`（既存 `_emit_error` と同パターン）

---

## データモデル概要

### spec.yaml の `fields[*].options` 構造（既存）

```yaml
fields:
  - name: Status
    data_type: single_select
    options: [Todo, In Progress, Done]  # array
  - name: Cycle
    data_type: single_select
    options: dynamic                    # cycle_map 経由で派生
```

- 本 Unit が処理するのは `options` が **array** の field のみ
- `dynamic` の field は `_subcmd_ensure_fields` 側で除外して `_sync_field_options` を呼ばない

### `gh project field-list --format json` レスポンス構造（既存）

```json
{
  "fields": [
    {
      "id": "PVTSSF_xxxxx",
      "name": "Status",
      "options": [
        {"id": "<opt_id>", "name": "Todo"},
        {"id": "<opt_id>", "name": "In Progress"}
      ]
    }
  ]
}
```

- `options[].name` を集合演算の入力に使う
- option の `id` は本 Unit では使用しない（add_field_option は GraphQL mutation で名前指定）

### 集合演算の内部表現（R1 指摘 #3 反映）

- 集合演算は **JSON 配列**のみで実施し、CSV を内部表現としない
- jq の `--argjson` 経由で JSON 配列を直接渡し、bash の `IFS=,` 文字列分割は使わない
- CSV への変換は表示層（`printf` 直前）でのみ jq `join(",")` を 1 回適用
- GitHub Projects の option 名に `,` が含まれるケース（仕様変更等）が発生しても、内部表現が JSON のため集合演算は壊れない。表示の CSV は最終出力時のみの整形であり、復号する用途がないため許容

---

## 処理フロー概要

### ユースケース 1: spec 改訂後の差分同期（通常運用）

**入力**: spec.yaml に新 option 追加 → `ensure-fields` 再実行

**ステップ**:
1. `_subcmd_ensure_fields` が `gh project field-list` で existing fields を取得
2. spec の各 field を順に走査
3. `field:exists` 判定 true の field について、spec.options が array であれば `_sync_field_options` を呼ぶ
4. `_sync_field_options` が差分を計算し、to_add に対して `gh_project_repo_add_field_option` を順次呼出
5. stdout に `field:<name>:options-added:<count>:names=<n1>,...` を出力
6. exit 0 で正常終了

**関与するコンポーネント**: `_subcmd_ensure_fields`, `_sync_field_options`, `gh_project_repo_add_field_option`, `gh_project_state_get_fields`

### ユースケース 2: dry-run での予定確認

**入力**: `ensure-fields --dry-run`

**ステップ**:
1. ユースケース 1 と同じだが、`_DRY_RUN=true` のため API は呼ばれない
2. `_sync_field_options` は `options-would-add` を出力
3. extraneous 検出時は `_emit_warn` のみで exit せず

**関与するコンポーネント**: 同上 + `_emit_warn`

### ユースケース 3: strict 違反（既存余分検出 / fail-fast）

**入力**: spec から option を削除した状態で `ensure-fields --strict`（既定）

**ステップ**:
1. `_sync_field_options` が existing にあって spec にない option を検出
2. `_emit_warn "options_extraneous" ...` を stderr 出力
3. `_MODE=strict` のため **追加 API は呼ばずに**戻り値 3 を呼出側に返す（fail-fast / R1 指摘 #2 反映）
4. `_subcmd_ensure_fields` が `exit 3` で終了。`options-added` 等の stdout 出力なし

**関与するコンポーネント**: `_sync_field_options`, `_emit_warn`, `_subcmd_ensure_fields`

### ユースケース 4: soft + API 失敗

**入力**: `ensure-fields --soft`、`gh api graphql` 失敗

**ステップ**:
1. `_sync_field_options` が `gh_project_repo_add_field_option` を呼出 → 失敗
2. `_emit_warn "gh_api_error" ...` を stderr 出力
3. 次の option / 次の field へ継続
4. exit 0（soft なので継続成功扱い）

**関与するコンポーネント**: `_sync_field_options`, `_emit_warn`, `gh_project_repo_add_field_option`

---

## 非機能要件（NFR）への対応

### 冪等性

- **要件**: 同一 spec / 同一 existing 状態で複数回実行しても結果が変わらない
- **対応策**: 集合演算による差分計算（spec - existing）。追加成功後の 2 回目以降は差分が空になり no-op

### 可観測性

- **要件**: 追加した option 名と件数が stdout に明示される
- **対応策**: `field:<name>:options-added:<count>:names=<n1>,...` 形式で出力。既存 `field:exists` / `field:created` と同列の構造化シグナル

### モード対応

- **要件**: dry-run / strict / soft が他 subcommand と一貫した動作をする
- **対応策**: `_DRY_RUN` / `_MODE` グローバル変数を参照し、既存 `_subcmd_ensure_views` 等と同じ条件分岐パターンを採用

### 可搬性

- **要件**: macOS / Linux 双方の bash で動作
- **対応策**: jq / gh / bash 標準機能のみ使用。BSD/GNU 差のある `stat -c %s` / `realpath -m` 等は不使用

### テスタビリティ

- **要件**: 機能 AC が bats で自動検証可能（確定 10 ケース、R1 設計レビュー指摘 #2 反映で `strict + 双方向差分 fail-fast` ケースを追加）
- **対応策**:
  - gh / gh api graphql のモックを `MOCK_DIR` / `PATH` 上書きで注入
  - 呼出回数アサート用に `${BATS_TEST_TMPDIR}/gh_api_graphql_calls.log` を活用
  - fixture JSON で existing fields の状態を制御

### エラー出力の機械可読性

- **要件**: stderr 出力は JSON 形式（既存 `_emit_error` 規約）
- **対応策**: 新規 `_emit_warn` を既存 `_emit_error` と同形式（`{error_type, details}`）にする。tab 区切り形式は導入しない

---

## 技術選定

- **言語**: bash（既存スクリプトの言語）
- **依存ツール**:
  - `gh` CLI（GitHub Projects v2 API）
  - `jq`（JSON 処理 + 集合演算）
  - `bats`（テストフレームワーク、既存）
  - `shellcheck` / `shellharden`（静的検証、既存）

---

## 実装上の注意事項

- **既存 `field:create` 経路を変更しない**: `field:exists` 判定 false 時の処理は本 Unit のスコープ外（破壊的変更なしの担保）
- **dynamic field のガード**: spec.options が `dynamic` / `null` の場合は `_sync_field_options` を呼ばない（呼出側 `_subcmd_ensure_fields` で `jq -r ".fields[$i].options | type"` 判定）
- **部分追加の扱い**: strict + API 失敗時は途中で停止（残りの option を処理しない）。soft では継続。テストで両ケース検証
- **bash + jq の集合演算**: `--argjson` で JSON 配列を渡し、jq 内部で `subtract` / `unique` を使う。bash 文字列分割 `IFS=,` は避ける（option 名に空白を含むケース対応）
- **既存 `_emit_error` 互換**: 新規 `_emit_warn` の jq 不在時フォールバックは既存 `_emit_error` のロジックをコピーする（jq 不在時の挙動が分岐しないように）
- **`_DRY_RUN` / `_MODE` の参照規約**: 関数引数で受けず、グローバル変数を直接参照する。これは既存 `_subcmd_*` の規約に合わせる選択であり、テスト時はモック側で `_DRY_RUN=true` / `_MODE=strict` を export して制御する

---

## 不明点と質問

[Question] なし。設計レビューで追加質問があれば追記する。
