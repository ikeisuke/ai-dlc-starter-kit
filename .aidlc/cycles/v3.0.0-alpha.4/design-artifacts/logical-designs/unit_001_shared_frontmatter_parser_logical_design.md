# 論理設計: Unit 001 — 共有 frontmatter parser ライブラリ集約（T1 + T2'）

## 概要

`lib/frontmatter.sh` の公開 API・consumer 別 API マッピング・conformance test の consumer 別期待 RC マトリクス・namespace 設計を確定する。ドメインモデルで定義した「frontmatter パース安全境界」を bash 共有ライブラリとして具体化する論理設計。**コードは書かず**、関数シグネチャ・責務・移行マッピングのみを定義する。

---

## アーキテクチャパターン

**共有ライブラリ（source 方式）+ consumer 責務分離**。`lib/frontmatter.sh` は `source`（`. "$SCRIPT_DIR/lib/frontmatter.sh"`、`SCRIPT_DIR` = スクリプト自身の配置ディレクトリ）で読み込まれる純粋関数群。**用語分離**: `dir` は work-items 入力ディレクトリ引数、`SCRIPT_DIR` はスクリプト配置基準（`BASH_SOURCE` ベースで解決 / cwd 非依存）。ライブラリ source は必ず `SCRIPT_DIR` 基準で行う。レイヤー上は「構造解釈レイヤー（共有）」と「意味検証レイヤー（consumer 固有）」の 2 層に分離する。アンチパターン回避: 共有レイヤーに consumer 固有の検証（enum 妥当性・依存実在・status 遷移）を吸い込まない（過剰共有 = false DRY を避ける）。

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-v3/scripts/
├── lib/
│   └── frontmatter.sh           # 共有: 構造解釈レイヤー（新設）
│       ├── fm_has_closing_frontmatter   # 終端ガード（公開述語）
│       ├── fm_extract_block             # frontmatter ブロック抽出（fail-closed 内包）
│       ├── fm_extract_body              # body 抽出（c>=2 / fail-closed 内包）
│       ├── fm_scalar                    # スカラー抽出（strict/loose / 両端引用符剥がす）
│       ├── fm_scalar_raw                # raw スカラー抽出（引用符非剥離 / assigned 用）
│       ├── fm_key_count                 # キー出現回数
│       └── fm_deps                      # dependencies 配列パース（fail-closed）
│       # 注: fm_split_file / fm_in_list は非導入（指摘4/5: shadowing回避・責務限定）
├── work-item-validate.sh        # consumer: SchemaValidator（移行）
├── work-item-next.sh            # consumer: Selector（移行）
├── work-item-status.sh          # consumer: StatusTransition（移行）
└── tests/
    └── test-frontmatter-parser.sh  # conformance suite（新設）
```

### コンポーネント詳細

#### lib/frontmatter.sh（共有構造解釈レイヤー）

- **責務**: frontmatter のブロック境界判定・ブロック/ body 抽出・スカラー抽出・配列パース・キー出現カウントを提供。malformed は return 1 でシグナルし、ユーザー向け文言・exit は出さない
- **依存**: bash 3.2+ / grep / sed / awk / tr（内部使用は許可）。外部スクリプト・state への依存なし
- **公開インターフェース**: `fm_*` 関数群（下記「コマンド/クエリ」参照）
- **不変条件**: stdout 返却のみ（result-out 不使用）/ 非破壊 / 決定的 / `set -e` 有無の両環境で安全

#### work-item-validate.sh（SchemaValidator）

- **責務**: data-model §4 の厳格 schema 検証。共有レイヤーへ委譲後も enum/必須キー一意性/assigned 型/本文セクション/依存実在/expected_status は自身で実施
- **依存**: lib/frontmatter.sh
- **撤去対象**: `read_scalar`（→ `fm_scalar` strict）/ frontmatter 抽出 awk（→ `fm_extract_block`）/ body 抽出 awk（→ `fm_extract_body`）/ 終端ガード awk（→ `fm_has_closing_frontmatter`）/ dependencies 配列パース(8)（→ `fm_deps`）/ キー count（→ `fm_key_count`）

#### work-item-next.sh（Selector）

- **責務**: 依存解決 + resume 優先選定。id はファイル名由来を維持。enum 非検証を維持
- **依存**: lib/frontmatter.sh
- **撤去対象**: `wi_scalar`（→ `fm_scalar` loose）/ `wi_deps`（→ `fm_deps`）/ frontmatter 抽出 awk（→ `fm_extract_block`）/ 終端ガード awk（→ `fm_has_closing_frontmatter`）。`id_lt` / `status_of_id` は選定ロジック固有のため残す

#### work-item-status.sh（StatusTransition）

- **責務**: status read / atomic write。status 行一意性・status enum・期待現在 status・atomic mv は自身で実施
- **依存**: lib/frontmatter.sh
- **撤去対象**: `has_closing_frontmatter`（→ `fm_has_closing_frontmatter`）/ `extract_frontmatter`（→ `fm_extract_block`）/ `read_status_value`（→ `fm_scalar` loose + 非空ガードは consumer 側）。status 行一意性カウントは `fm_key_count` を使用。awk による status 行置換（write）は status 固有のため残す

---

## スクリプトインターフェース設計

### lib/frontmatter.sh（公開 API）

すべて stdout 返却 + return code。引数の `<fm>` は `fm_extract_block` の出力（frontmatter テキスト）を指す。内部 local は `_fm_<fn略>_` で namespace 化。

#### `fm_has_closing_frontmatter <file>`
- **説明**: 先頭行 `---` かつ 2 番目の `---` が存在すれば return 0、なければ return 1（malformed）
- **入力**: file パス
- **戻り値**: return code のみ（stdout なし）
- **既存対応**: validate:122 awk / next:138 awk / status `has_closing_frontmatter`

#### `fm_extract_block <file>`（fail-closed 安全境界 / 指摘4 反映）
- **説明**: 先頭 `---` 〜 次の `---` の間の行を stdout 出力。**閉じ `---` が無い malformed file は内部で `fm_has_closing_frontmatter` 相当を実行し return 1（partial parse させない）**。安全境界 API として extract 自体が fail-closed であることを保証する
- **戻り値**: frontmatter テキスト（stdout）/ malformed 時 return 1
- **呼び出し規約**: `if ! fm="$(fm_extract_block "$f")"; then ...` で捕捉（`local fm="$(...)"` は return code をマスクするため避ける）。consumer は従来どおり明示ガードを併用してもよいが、extract 自体が fail-closed のためガード失念による partial parse は構造的に発生しない
- **既存対応**: validate:122+128 / next:138+142 / status `has_closing_frontmatter`+`extract_frontmatter`（従来「ガード→抽出」の 2 ステップを 1 API に内包。受理/拒否の決定は不変）

#### `fm_extract_body <file>`（fail-closed 安全境界 / 指摘4 反映）
- **説明**: 2 番目の `---`（frontmatter 終端）以降の全行を stdout 出力。本文中 `---` で打ち切らない（`c>=2`）。**閉じ `---` 不在の malformed file は return 1**（`fm_extract_block` と同じ fail-closed 契約）
- **戻り値**: body テキスト（stdout）/ malformed 時 return 1
- **既存対応**: validate:132（本 API 化で「個別 consumer の構造解釈禁止」規約と整合。fail-closed 内包で安全境界を保証）

> **設計判断（指摘4）**: extract API を「ガード呼び出し前提（precondition 明記）」ではなく「**ガード内包の fail-closed**」とする。理由: ライブラリが「安全境界」を名乗る以上、抽出 API 単体で未終端 partial parse を構造的に防ぐ方が堅い。既存 3 consumer はいずれも extract 前にガードを呼んでいるため、内包しても受理/拒否の outcome は不変（malformed は引き続き拒否）。
> **`fm_split_file`（result-out 版）は初版では導入しない**（YAGNI / shadowing リスク回避）。`fm_extract_block` + `fm_extract_body` の 2 関数で要件充足。

#### `fm_scalar <fm> <key> [token_atom]`
- **説明**: frontmatter から key のスカラー値を抽出して stdout 出力。inline コメント・前後空白除去、両端引用符を剥がす
  - `token_atom` 指定あり（**strict**）: 値が `(atom+|"atom+")` に一致しなければ return 1（片側引用符・空・余分記号を拒否）
  - `token_atom` 省略（**loose**）: 検証なし最小抽出。値が無ければ空文字を返す（return 0）
- **戻り値**: 抽出値（stdout）/ strict 失敗時 return 1
- **既存対応**: validate `read_scalar`（strict, token_atom 渡し）/ next `wi_scalar`（loose）/ status `read_status_value`（loose、非空判定は consumer 側で `[[ -n ]]`）

#### `fm_scalar_raw <fm> <key>`（raw 抽出 / 指摘1 反映）
- **説明**: frontmatter から key の値を抽出するが、**外側引用符を剥がさず raw 値で返す**（inline コメント・前後空白のみ除去）。`fm_scalar` loose が `"a b"` と `a b` を同一値に潰すのに対し、本関数は引用符・括弧の構造を保持する
- **用途**: validate の `assigned` 型判定（`null` / `"..."` quoted string / `[...]` array / `{...}` map / 空値 / bare token の 6 分岐）。raw 値でないと quoted と bare を区別できないため必須
- **戻り値**: raw 値（stdout）。値が無ければ空文字
- **既存対応**: validate:171 の独自 raw sed（`assigned_v="$(echo "$fm" | sed -nE 's/^assigned:...//p')"`）。これを共有 API 化し、consumer に個別 sed を残さない（T1 / T4 整合）

#### `fm_key_count <fm> <key>`
- **説明**: frontmatter 内で `^<key>:` に一致する行数を stdout 出力（整数）
- **戻り値**: 出現回数（stdout）
- **既存対応**: validate:138 キー count ループ / status:116 status 行カウント。一意性判定（0/1/複数の解釈）は consumer 責務

#### `fm_deps <fm>`
- **説明**: dependencies 配列の ID を空白区切りで stdout 出力（空配列は空出力）。dependencies 行不在 / 非配列 / 要素構文不正は return 1（fail-closed）
- **戻り値**: ID 列（stdout）/ malformed 時 return 1
- **既存対応**: next `wi_deps`（そのまま）/ validate(8)（validate は本関数の出力 ID 集合に対し実在検証を追加実施）
- **注意**: validate は従来 array 形式エラーと要素エラーで別メッセージだったが、共有化後は `fm_deps` の return 1 を受けて consumer がメッセージを出す。**受理/拒否境界（どの入力で拒否するか）は不変**、文言のみ consumer 側に集約

> **`fm_in_list` は frontmatter.sh に含めない（指摘5 反映）**: `in_list`（メンバシップ判定）は frontmatter 構造解釈ではなく汎用ユーティリティであり、`fm_` namespace に入れると「parser + general util」へ責務が膨らみ false DRY の入口になる。`frontmatter.sh` は delimiter / scalar / array / key count に責務を限定する。`in_list` は各 consumer（validate / status）に現状どおり残す（enum 値リスト `STATUS_ENUM` 等も consumer 保持）。汎用 util の共有が将来必要になれば別 `lib/common.sh` で扱う（本 Unit 対象外）。

### consumer 別 API マッピング表（計画 §4.1 の確定版）

| 機能 | 共有 API | validate | next | status |
|------|---------|----------|------|--------|
| 終端ガード | `fm_has_closing_frontmatter` | 使用 | 使用 | 使用 |
| block 抽出 | `fm_extract_block` | 使用 | 使用 | 使用 |
| body 抽出 | `fm_extract_body` | 使用 | 不要 | 不要 |
| スカラー strict | `fm_scalar <fm> <key> <atom>` | status/size/risk/id | 不要 | 不要 |
| スカラー loose | `fm_scalar <fm> <key>` | 不要 | status/size | status（+ 非空 guard） |
| スカラー raw（引用符非剥離） | `fm_scalar_raw <fm> <key>` | assigned | 不要 | 不要 |
| キー count | `fm_key_count` | 必須 6 キー一意性 | 不要 | status 行一意性 |
| dependencies | `fm_deps` | 使用（+実在検証） | 使用 | 不要 |
| enum 妥当性 | （consumer 責務） | status/size/risk | 非検証 | status |
| 依存実在 | （consumer 責務） | 実施 | warning のみ | 不要 |
| status 遷移/write | （consumer 責務） | 不要 | 不要 | 実施 |
| エラー文言/exit | （consumer 責務） | 自身 | 自身 | 自身 |

---

## conformance test の consumer 別期待 RC マトリクス（T2'）

`tests/test-frontmatter-parser.sh`（自己完結ハーネス / 既存 `put_wi` `assert_rc` 形式）。各 fixture を 3 consumer に通し、consumer 別の期待 RC を固定する。`status_read` = `--read`、`status_write` = `<path> <expected> <next>`。

| # | fixture（カテゴリ） | validate | next | status_read | status_write | 種別 |
|---|---------------------|----------|------|-------------|--------------|------|
| 1 | 正常: unquoted id / 全 enum 正 / 空 deps | 0 | 0(選定) | 0 | 0 | 受理 |
| 2 | 正常: quoted id `"001"` / deps 複数要素 | 0 | 0 | 0 | 0 | 受理 |
| 3 | 閉じ `---` 不在 | 1 | 1 | 1 | 1 | 拒否（全 consumer） |
| 4 | status 不正 enum `bogus` | 1 | 0(候補外/読まず非該当) | 1 | 1 | 拒否（validate/status）|
| 5 | size 不正 enum `huge` | 1 | 0(そのまま出力) | 0 | 0 | validate のみ拒否 |
| 6 | risk 不正 enum | 1 | 0(next未読) | 0 | 0 | validate のみ拒否 |
| 7 | id 片側引用符 `"001` | 1 | 0(id=ファイル名由来) | 0 | 0 | validate のみ拒否 |
| 8 | dependencies malformed `[001-002]` | 1 | 1(fail-closed) | 0(deps未読) | 0 | validate/next 拒否 |
| 9 | dependencies 行不在 | 1 | 1(fail-closed) | 0 | 0 | validate/next 拒否 |
| 10 | status 行 2 個（重複キー）| 1 | 0 | 1(曖昧) | 1 | 互換保存（consumer 別） |
| 11 | malformed 配列 `[001 002]`（空白区切り）| 1 | 1 | 0 | 0 | validate/next 拒否 |

**互換保存セット（#1〜#11）の固定契約**:
- 上表 #1〜#11 の期待 RC は **すべて移行前の現行スクリプト実挙動を baseline 観測して確定する固定値**。「移行前実挙動 == 移行後実挙動」を不変条件とし、conformance test はこの恒等性を固定する。
- #10 の next=0: next は重複キーを拒否対象としない（`wi_scalar` が先頭一致で 1 件返す既存挙動 / 重複検出は validate のゲート責務）。fixture コメントに「next は重複検出しない」と明示。
- 実装時（Phase 2）に baseline 観測した RC が本表の予測と食い違う場合は、**実挙動を正とし本表を訂正**する（差分が出たらリファクタが境界を壊した兆候として要調査）。本表の数値は baseline 観測で最終確定する確定値プレースホルダである。

### 意図的拒否強化セット（#733 / Intent 成功基準 intent.md:33）

互換保存セットとは **別枠** の、意図的に拒否側へ倒す deliberate change。Intent「成功基準」が「#733 で検出された既知の malformed / partial-parse クラスは共有 parser の拒否 fixture として固定する（既存に取りこぼしがあった場合はこの範囲で拒否側に倒す）」と明示しており、本 Unit スコープ内（純粋リファクタとは別建ての承認済み仕様）。

**重要（指摘1 反映）**: 拒否強化は **該当 shared API を呼ぶ consumer のみ** に作用させる。consumer が構造上読まない要素まで拒否させると過剰検証（例: status が dependencies malformed を拒否）となり consumer 境界を壊す。よって #733 セットも **consumer 別 RC マトリクス**で表現し、対象 API を併記する。「移行前から読まない consumer」は責務どおり before=after（拒否しない）を維持する。

| # | fixture（#733 既知クラス） | 対象 shared API | validate | next | status_read | status_write | 区分 |
|---|---------------------------|----------------|----------|------|-------------|--------------|------|
| 12 | #733 partial-parse を通していた具体 malformed（Phase 2 で #733 から特定） | Phase 2 で特定（例: `fm_deps` / `fm_scalar` / `fm_extract_block`） | before→1 | before→1（対象 API 使用時のみ） | 対象 API 不使用なら before=after | 対象 API 不使用なら before=after | 意図的拒否強化 |

**手順（Phase 2）**: (1) #733 から具体 malformed 入力と、それを通していた **対象 shared API** を特定 → (2) 各 consumer の移行前 RC を 4 列すべて観測して記録 → (3) **対象 API を呼ぶ consumer のみ** after=1（拒否）に固定。対象 API を呼ばない consumer（その構造を読まない）は before=after を維持（拒否しない）→ (4) fixture コメントに「#733 deliberate strengthening / 対象 API: `fm_xxx` / 対象 consumer: validate(before=N→1), next(...)」を明記し互換保存セットと区別する。移行前から既に全列拒否だったクラスは互換保存セット扱い。**この拒否強化は Intent 承認済みのため削除・別 Unit 化しない**（削除はスコープ縮小に該当）。

---

## 処理フロー概要

### consumer 移行の処理フロー（各 consumer 共通パターン）

1. スクリプト冒頭で `SCRIPT_DIR` を解決し `. "$SCRIPT_DIR/lib/frontmatter.sh"` で source
2. 既存のインラインパース関数定義を削除
3. 呼び出し箇所を `fm_*` 関数呼び出しに置換（引数順・捕捉方法 `$(...)` は既存と同型）
4. consumer 固有の意味検証（enum/一意性解釈/実在/遷移）は残置
5. エラーメッセージ文言・exit code は consumer に残す（`fm_*` の return 1 を受けて従来文言を出力）

**関与するコンポーネント**: lib/frontmatter.sh / 各 consumer

### source パス解決の留意

- 既存スクリプトは `dir="$1"`（work-items ディレクトリ）を引数に取るが、**ライブラリ source パスはスクリプト自身の位置基準**（`SCRIPT_DIR`）で解決する必要がある。`BASH_SOURCE` ベースで `SCRIPT_DIR` を求め `lib/frontmatter.sh` を source する（cwd 非依存）
- bash 3.2 互換の `SCRIPT_DIR` 解決（`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd` 相当）を各 consumer に追加

---

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 共有化で顕著な実行時間増を招かない（Unit NFR）
- **対応策**: 関数は既存実装と同等の grep/sed/awk 1〜数回。source は 1 回のみ。`$()` 捕捉も既存同等のオーダー

### セキュリティ
- **要件**: 特になし（ローカル parser）
- **対応策**: 非破壊・read-only（write は status consumer の atomic mv のみ）。malformed fail-closed で undefined behavior を防ぐ

### スケーラビリティ
- **要件**: 将来 consumer（release / reflect / doctor）が同一ライブラリを source できる拡張性
- **対応策**: `fm_*` 公開 API を安定インターフェースとして文書化。新 consumer は source して呼ぶだけ

### 可用性
- **要件**: 既存テスト緑を維持（回帰なし）
- **対応策**: conformance + 既存テスト（test-work-item-next / test-define-flow / test-develop-flow / test-state-scripts / test-activation）を全て緑に保つ

---

## 技術選定
- **言語**: bash 3.2/4.0+ 互換、`set -euo pipefail`（status は既存どおり `-uo`）
- **ツール**: grep / sed / awk / tr（共有ライブラリ内部使用は許可）
- **テスト**: 自己完結型 bash ハーネス（外部フレームワーク非依存 / mktemp サンドボックス）

---

## 実装上の注意事項

- **dynamic scope shadowing**: stdout 返却方式を基本とし shadowing を原理回避。result-out 関数を導入する場合のみ `_local_fm_<fn>_<name>` namespace 規約を厳守
- **namespace 衝突**: 公開 `fm_` / private `_fm_` / 定数 `FM_`。共有ライブラリは `STATUS_ENUM` 等のグローバル `readonly` を **定義しない**（consumer の `readonly STATUS_ENUM` と二重宣言 → 再代入エラーを回避）
- **`set -e` 差異**: status は `-e` なし。共有関数は return 1 を返すだけで `exit` しない（consumer が受ける）。`-e` 環境でも関数内の非ゼロ return が即 exit を誘発しないよう、内部は `|| return 1` 明示で組む
- **規約文書化**: 共有 parser 境界 + 「個別 consumer での frontmatter 構造解釈に grep/sed/awk/permissive jq を使うことを禁止」+ Unit 完了条件「新たな構造データ読取は共有 parser 使用 + conformance fixture 追加必須」を文書（配置先は設計レビューで確定: `skills/aidlc-v3/` 配下の規約ドキュメント or lib/frontmatter.sh 冒頭の責務コメント + docs）

---

## 不明点と質問（設計中に記録）

[Question] `fm_split_file`（result-out 版）を公開 API に含めるか？
[Answer] **含めない（確定）**。YAGNI / shadowing リスク回避。`fm_extract_block` + `fm_extract_body` の 2 関数で要件充足。コンポーネントツリー・API 一覧からも除外済み。

[Question] `fm_in_list` を共有化するか（enum 値リストは別）？
[Answer] **共有化しない（確定 / 設計レビュー指摘5）**。`in_list` は frontmatter 構造解釈ではなく汎用メンバシップ判定であり、`fm_` namespace に入れると責務が膨らみ false DRY の入口になる。各 consumer（validate / status）に現状どおり残す。enum 値リスト（`STATUS_ENUM` 等）も consumer 保持。汎用 util 共有が将来必要になれば別 `lib/common.sh` で扱う（本 Unit 対象外）。

[Question] 禁止規約の文書配置先は？
[Answer] (1) `lib/frontmatter.sh` 冒頭の責務コメント（SoT）+ (2) v3 規約ドキュメント（既存があれば追記、なければ新設）への参照。Unit 002（T4 CI ガード）が本規約を検出ルールの根拠とするため、機械可読な配置（allowlist: lib/ と tests/）と整合させる。設計レビューで配置を確定。
