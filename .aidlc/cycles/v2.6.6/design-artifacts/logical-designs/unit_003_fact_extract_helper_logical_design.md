# 論理設計: Unit 003 一次情報三層検証 helper (3 source MVP + jsonl 引数 opt-in)

## 概要

Unit 003 ドメインモデル（`FactExtractionSessionAggregate` / `FactExtractorService` / `FactTableRenderer` / `FactExtractionOrchestrator`）の論理実装。**公開シンボルは `retrospective_api_extract_facts` 1 本のみ**（Facade 一本化）、internal 実装は `retrospective-fact-extract.sh`（private 実装層）に閉じ、Facade `retrospective-api.sh` から source される構造とする。役割は **L1 extractors / L2 renderer / L3 orchestrator** の 3 層に物理分離する。

**重要**: 本論理設計では **コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。

---

## ステップ0 事前コード読込み

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc/scripts/lib/retrospective-api.sh`（1〜80 行） | (i) 多重 source ガード `RETROSPECTIVE_API_SOURCED` (ii) `_RETROSPECTIVE_API_BASE` 解決ロジック (iii) 既存 internal lib（`retrospective-llm-draft.sh` 等）の source パターン を踏襲するため |
| `skills/aidlc/scripts/lib/retrospective-api.sh`（140〜185 行 / `retrospective_api_aggregate_enabled`） | Type B 公開関数の (i) stdout 1 行契約 (ii) exit 0 fail-safe (iii) `_local_<fnshort>_<name>` 命名規約 (iv) `read-config.sh` 終了コード 0/1/2+ ハンドリング を踏襲するため |
| `skills/aidlc-retrospective/steps/retrospective.md` §1.1.5（106〜128 行） | 既定 markdown 表の列構成（`項目 / 値 / 出典`）と 5 行構成（DR 件数 / review round 数 / 指摘件数 / defer 件数 / 時系列イベント）を完全踏襲するため |
| `skills/aidlc/scripts/read-config.sh` | helper 内部で読みうる config 値（jsonl 機密フィルタの拡張余地）の終了コード規約参照 |
| `.aidlc/cycles/v2.6.5/inception/decisions.md` | 実 fixture 用に DR 見出しの canonical 形式（`^## DR-NNN` 等）を確認 |
| `.aidlc/cycles/v2.6.5/construction/units/*-review-summary.md` | Round 見出し / 指摘テーブル / defer 列の canonical 構造を確認 |
| `.aidlc/cycles/v2.6.5/history/*.md` | H2 見出し（ISO8601 timestamp）+ 直後 1 行の時系列構造を確認 |
| `tests/retrospective-aggregate-enabled.bats` 等 | bats fixture / Facade source / dynamic scope shadowing 回避パターン参照 |
| `CLAUDE.md` 「AI エージェント Bash ツール経由の安全パターン」 | コマンド置換禁止規約遵守 |

### (b) 設計時に意識すべき挙動

- Facade `retrospective-api.sh` は本 Unit が追加する `retrospective-fact-extract.sh` も同じ source 順序（既存 `retrospective-llm-draft.sh` 等と同列）で取り込む前提
- 既存 Type B 関数は **stdout 1 行 / exit 0 固定**。本 Unit の `retrospective_api_extract_facts` は出力が複数行 markdown 表となるが、stdout の純粋性（warn なし / 表本体のみ）と exit 0 fail-safe（cycle 不在のみ exit 2）の方針を取る
- `_local_<fnshort>_<name>` 命名規約は dynamic scope shadowing 対策の主防御線
- §1.1.5 手動経路の markdown 表は LF 終端 / 列セパレータ `|` の前後に半角スペース 1 個 / 空セルは `-` という空白規則がある（既存 §1.1.5 引用箇所の文字列観察から）
- shellcheck 系（SC2086 / SC2034 / SC2155 等）を pass させるため、quoting / local separator は明示する
- bats 統合テストでは「実 fixture」（`.aidlc/cycles/v2.6.5/`）と「手動 §1.1.5 経路の期待 markdown ファイル」を組で用意し `diff` で 0 を確認する方式とする

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `single-file` 公開関数 + extractor / renderer を 1 ファイルに同居 | `retrospective-fact-extract.sh` に L1/L2/L3 すべて同居 | **却下** | 計画レビュー R1 指摘 #2「責務過密」を構造で吸収できない。L3 orchestrator は Facade に置き、L1/L2 のみを private 実装に閉じる |
| `multi-file` extractors / renderer / orchestrator を別ファイルに分離 | 3 ファイル新規追加 | **却下** | 物理分離過剰。1 unit 1 機能の helper 規模では 1 file + 関数分離で十分。3 ファイル分割は Facade source 行も増えて bootstrap 負荷が上がる |
| `private-lib + facade` extractors / renderer を `retrospective-fact-extract.sh` に、orchestrator を Facade に | 1 ファイル新規 + Facade に公開関数 | **採用** | (i) 公開シンボルが Facade に集中する既存パターンと整合 (ii) L1/L2 が物理ファイルで内包される (iii) shellcheck / lint 上 1 ファイルの肥大化を避けられる |

---

## アーキテクチャパターン

- **Facade Pattern**: `retrospective-api.sh` を唯一の公開境界（Facade）として固定。caller は Facade のみを source / 呼出
- **Layered Architecture（3 層）**:
  - **L1 Extractors**: 入力 source ごとに構造化データ（pipe-separated 中間形式）を生成
  - **L2 Renderer**: 構造化データを §1.1.5 互換 markdown 表に整形
  - **L3 Orchestrator**: L1 を順次起動 → L2 で整形 → stdout 出力（公開 API）
- **Dependency Direction**: L3 → L1 / L3 → L2 / L1 ⊥ L2（相互独立）。逆方向依存禁止
- **Separation of Concerns**: 抽出ロジック（L1）/ 表示整形ロジック（L2）/ orchestration（L3）が互いに知らない構造

選定理由: 計画 R1 で指摘された「責務過密 / モジュール凝集低下」を構造で予防し、将来の source 追加（L1 拡張）と表示形式変更（L2 改修）が独立に進化可能とする。

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/lib/
├── retrospective-api.sh                     (Facade / 公開境界)
│   └── retrospective_api_extract_facts       (L3 orchestrator / 新規公開関数)
└── retrospective-fact-extract.sh            (private 実装層 / 新規ファイル)
    ├── _retrospective_fact_extract_decisions          (L1 extractor)
    ├── _retrospective_fact_extract_review_summary     (L1 extractor)
    ├── _retrospective_fact_extract_history            (L1 extractor)
    ├── _retrospective_fact_extract_jsonl_optional     (L1 extractor)
    ├── _retrospective_fact_extract_mask_secrets       (L1 共通 / 機密フィルタ)
    └── _retrospective_fact_extract_render_markdown    (L2 renderer)
```

### コンポーネント詳細

#### `retrospective-api.sh` への追記分

- **責務**: L3 orchestrator として公開 API `retrospective_api_extract_facts` を提供。`retrospective-fact-extract.sh` を多重 source ガード付きで source し、L1 extractors を順次起動して L2 renderer に渡す
- **依存**: `retrospective-fact-extract.sh`（同階層から source）
- **公開インターフェース**: `retrospective_api_extract_facts`（後述「インターフェース設計」参照）
- **internal シンボル**: なし（既存 `_retrospective_api_resolve_base` 等の internal 関数を再利用、本 Unit 由来の internal は L1/L2 へ）

#### `retrospective-fact-extract.sh`（新規）

- **責務**: L1 extractors（4 source 抽出 + 機密フィルタ）と L2 renderer（markdown 整形）を internal 関数として提供
- **依存**: なし（read-config.sh は Facade 側で必要時に呼び出す。本 Unit では config 直接読込なし / Phase 2 のスコープ確定で再検討）
- **公開インターフェース**: なし（全関数 `_retrospective_fact_extract_*` プレフィックスで internal 専用を表明）
- **多重 source ガード**: `RETROSPECTIVE_FACT_EXTRACT_SOURCED=1` を立てる（Facade と同パターン）

#### L1 Extractors（internal）

| 関数名 | 責務 | 入力 | 出力 |
|-------|------|-----|-----|
| `_retrospective_fact_extract_decisions` | DR 件数集計 | `<cycle_dir>` | pipe-separated FactRow 行群（stdout） |
| `_retrospective_fact_extract_review_summary` | review round / 指摘 / defer 件数集計 | `<cycle_dir>` | pipe-separated FactRow 行群（stdout） |
| `_retrospective_fact_extract_history` | 時系列イベント抽出（最大 N 件） | `<cycle_dir> <max_events>` | pipe-separated FactRow 行群（stdout） |
| `_retrospective_fact_extract_jsonl_optional` | jsonl 構造化エントリ抽出 + 機密フィルタ | `<jsonl_path>` | pipe-separated FactRow 行群（stdout、引数空時は空出力） |
| `_retrospective_fact_extract_mask_secrets` | 機密パターンマスク（共通 helper） | `<text>`（stdin or 引数） | マスク済み text（stdout） |

各 extractor は **副作用なし / stdout に pipe-separated 行を流す / 警告は stderr** の契約を守る。exit code は 0 固定（source 不在等は出力行で表現）。

#### L2 Renderer（internal）

| 関数名 | 責務 | 入力 | 出力 |
|-------|------|-----|-----|
| `_retrospective_fact_extract_render_markdown` | pipe-separated FactRow 行群を §1.1.5 互換 markdown 表に整形 | `<table_intermediate_stdin>`（stdin） | markdown 表（stdout） |

renderer は L1 から受け取った行群を §1.1.5 既定列構成（`| 項目 | 値 | 出典 |`）に変換するのみ。集計ロジックは持たない。

#### L3 Orchestrator（Facade 公開関数）

| 関数名 | 責務 | 入力 | 出力 |
|-------|------|-----|-----|
| `retrospective_api_extract_facts` | L1 extractors を順次起動 → 中間結果を集約 → L2 renderer に渡す → stdout 出力 | `<cycle_id> [<jsonl_path>]` | markdown 表（stdout） / warn（stderr） |

---

## インターフェース設計

### 公開 API（Facade）

#### `retrospective_api_extract_facts <cycle_id> [<jsonl_path>]`

- **説明**: 1 cycle 分の事実テーブルを §1.1.5 互換 markdown 表として stdout に出力する。jsonl_path 引数指定時のみ jsonl source を追加抽出する
- **引数**:
  - `cycle_id`: string（必須）- `v{major}.{minor}.{patch}` 形式。`.aidlc/cycles/{cycle_id}/` を base とする
  - `jsonl_path`: filesystem path（任意）- 指定時は jsonl source を追加抽出。空文字列は引数未指定と等価
- **stdout**: §1.1.5 互換 markdown 表（複数行 / `| 項目 | 値 | 出典 |` ヘッダ + 区切り行 + データ行 / LF 終端）
- **stderr**: warn メッセージ（source 不在 / jsonl 不在 / 機密フィルタ動作 等）
- **exit code**:
  - `0`: 正常完了（少なくとも cycle_dir が存在）
  - `2`: fatal（cycle_dir 不在 / 引数不正）
- **副作用**: なし（read-only）
- **多重呼出安全**: Facade の多重 source ガード経由で source される。public 関数の複数回呼び出しは新規セッションを毎回構築するため idempotent

### L1 Extractors（internal / 中間形式契約）

各 extractor は以下の **pipe-separated 中間形式** で stdout に行を流す:

```text
{kind}|{item_id}|{value}|{source_path}
```

| フィールド | 例 | 制約 |
|----------|-----|------|
| `kind` | `decisions` / `review_summary` / `history` / `jsonl` | SourceKind 値オブジェクトと同一の 4 値 |
| `item_id` | `dr_count` / `dr_titles` / `dr_root_cause_class` / `review_round_total` / `review_finding_total` / `defer_count` / `history_event` / `jsonl_event` | **安定 ID（snake_case）**。L1→L2 の安定契約として L1 から L2 への語彙伝搬を切る。renderer 側で表示ラベルに変換する |
| `value` | `5` / `2026-05-18T23:00 - Unit 001 完了` 等 | パイプ `\|` を含む場合は `\|`（バックスラッシュ + パイプ）でエスケープ。改行を含めない |
| `source_path` | `inception/decisions.md` / `construction/units/001-review-summary.md` 等 | repo-relative（cycle_dir 起点）。glob はそのまま記録（例: `construction/units/*-review-summary.md`） |

**Note**: 中間形式は **internal の SoT** であり、caller / 外部 lib に露出しない。L1 → L2 間のデータ受け渡しに使う pipe transport が標準入出力のため、エスケープ規約を明示する。L2 renderer 側で `item_id → 表示ラベル` のマッピングを所有することで、**L1 が知るのは `item_id` のみ / L2 が知るのは「`item_id` から §1.1.5 表示ラベルへの変換規則」のみ** という双方向独立性を担保する（指摘 #2 への対応 / 内部プロトコル安定化）。

#### item_id ↔ §1.1.5 表示ラベル マッピング（L2 専有 SoT）

| item_id | §1.1.5 表示ラベル | §1.1.5 互換モード出力 | §1.1.5 互換モード扱い |
|---------|------------------|---------------------|---------------------|
| `dr_count` | `DR 件数` | 1 行 | 既定 5 行に含む |
| `dr_titles` | （非表示） | - | **内部集計のみ**（§1.1.5 互換モード非表示 / 将来別 API 経由で公開検討） |
| `dr_root_cause_class` | （非表示） | - | **内部集計のみ**（§1.1.5 互換モード非表示 / 将来別 API 経由で公開検討） |
| `review_round_total` | `review round 数（合計）` | 1 行 | 既定 5 行に含む |
| `review_finding_total` | `指摘件数（合計）` | 1 行 | 既定 5 行に含む |
| `defer_count` | `defer 件数` | 1 行 | 既定 5 行に含む |
| `history_event` | `時系列イベント（主要なもの）` | 1 行（集約） | 既定 5 行に含む。複数 event は value 内で改行ではなく `; ` 区切りで結合する（renderer の集約責務） |
| `jsonl_event` | `時系列イベント（jsonl）` | 1 行（jsonl 引数指定時のみ） | jsonl 引数指定時のみ §1.1.5 既定 5 行 + 1 行（合計 6 行） |

**§1.1.5 互換モード公開契約（固定 / 指摘 #1 への対応）**:

- L3 公開 API `retrospective_api_extract_facts` は **§1.1.5 互換モード** のみを提供する
- §1.1.5 互換モード出力は **既定 5 行**（jsonl 引数指定時は 6 行）に厳密に限定する
- `dr_titles` / `dr_root_cause_class` は **内部集計のみで stdout 表に表示しない**。これらは Unit 003 内で抽出は行うが、§1.1.5 互換モードでは出力しない（将来的に別 API `retrospective_api_extract_facts_extended` 等を v2.7.0+ で導入する余地を残す）
- これにより「5 行厳守」と「追加抽出」の不整合を構造で解消し、公開契約を 1 つに固定する

### L2 Renderer

#### `_retrospective_fact_extract_render_markdown` (stdin: 中間形式行群)

- **入力**: stdin から L1 中間形式行群を 1 行 1 FactRow で受け取る（`{kind}|{item_id}|{value}|{source_path}` 形式）
- **処理**:
  1. ヘッダ行 `| 項目 | 値 | 出典 |` と区切り行 `|------|-----|------|` を出力
  2. 入力行を `item_id` で分類し、§1.1.5 互換モードでは「§1.1.5 互換モード出力」列が `1 行` の item_id のみを採択（`dr_titles` / `dr_root_cause_class` 等の内部集計値は除外）
  3. 採択した item_id を §1.1.5 既定順（`dr_count` → `review_round_total` → `review_finding_total` → `defer_count` → `history_event` → `jsonl_event`）に並べ替え
  4. 各 item_id を「item_id ↔ §1.1.5 表示ラベル マッピング」表で表示ラベルに変換
  5. `history_event` が複数行の場合は value を `; ` 区切りで結合し 1 行に集約する（5 行厳守のため）
  6. 各データ行を `| {表示ラベル} | {value} | {source_path} |` 形式に変換して stdout に出力
- **出力**: markdown 表（stdout）

**ソート規則**: 既定行の出現順は item_id ベースの固定リテラル順（上表の順序）。`history_event` 複数行のソートは Phase 2 で確定（タイムスタンプ昇順 or 出現順）。`LC_ALL=C sort` 強制でロケール差を排除。

**表示ラベル変換の責務局在化**: 表示ラベルへの変換は **renderer のみが知る規則** とし、extractors は item_id だけを知っていれば良い。これにより L1 名前変更が L2 を破壊しない構造（指摘 #2 への対応 / 内部プロトコル安定化）。

---

## スクリプトインターフェース設計

本 Unit はライブラリ関数のみで、独立した CLI スクリプト entry point は持たない（既存 `bin/` 配下に専用 CLI は新設しない）。caller は `retrospective-api.sh` を source して `retrospective_api_extract_facts` を呼ぶ。

### 想定 caller 経路（参考）

```text
aidlc-retrospective skill (steps/retrospective.md §1.1.5)
  ↓ (将来の opt-in 経路 / 本 Unit では SoT 化のみ)
source skills/aidlc/scripts/lib/retrospective-api.sh
  ↓
retrospective_api_extract_facts v2.6.5
  ↓ (内部)
source skills/aidlc/scripts/lib/retrospective-fact-extract.sh (Facade 内で多重 source ガード)
  ↓
L1 extractors → L2 renderer → stdout markdown table
```

caller 側の §1.1.5 への組み込みは **本 Unit のスコープ外**（Intent §1.4 / Unit 定義「境界」参照）。

---

## エラーハンドリング設計

### エラー区分と対応

| エラー区分 | 検出箇所 | 対応 | exit code |
|----------|---------|------|----------|
| `cycle_dir 不在` | L3 orchestrator | stderr に「[error] cycle ディレクトリ不在: {path}」/ 即時 return | 2 |
| `引数不正（cycle_id 空 / 形式不正）` | L3 orchestrator | stderr に「[error] cycle_id 不正: {value}」/ 即時 return | 2 |
| `source ファイル不在（decisions / review_summary / history）` | L1 extractor | stderr に warn / 当該 FactRow を `value="-（source 不在）"` で生成 | 0（継続） |
| `jsonl_path 指定 + ファイル不在` | L1 jsonl extractor | stderr に warn / jsonl 行を生成しない | 0（継続） |
| `jsonl 内 機密情報検出` | L1 mask helper | stderr に warn（マスク件数のみ）/ 値をマスクして FactRow 生成 | 0（継続） |
| `内部処理エラー（grep / awk 失敗 等）` | L1 extractor | stderr に warn / 該当 source 行を `value="-（抽出失敗）"` | 0（継続） |

fail-safe 原則: cycle_dir 不在のみ fatal。それ以外は warn + 部分結果で stdout を必ず返す（既存 `retrospective_api_*` の fail-safe 契約と整合）。

### 機密フィルタ

#### 採用正規表現エンジン

**ERE（Extended Regular Expression）** を採用し、実装は `grep -E` または bash 組込 `=~`（ERE 準拠）で行う。`sed -E`（macOS BSD sed 互換）/ `awk`（ERE 準拠）も併用可。**BRE（Basic）/ POSIX class の `\| `（OR エスケープ）/ Perl 拡張（`\d` 等）は使わない**（指摘 #3 への対応）。

#### 検出パターン（ERE 準拠 / `_retrospective_fact_extract_mask_secrets` 内）

| パターン名 | ERE 正規表現 | マスク後表現 | 検出例 |
|----------|-----------|------------|--------|
| `api_key` | `(api[_-]?key)["':= ]+[A-Za-z0-9_\-]{16,}` | `{api_key}=****` | `api_key="sk-1234567890abcdef"` |
| `bearer_token` | `[Bb]earer[ \t]+[A-Za-z0-9_\-.]{16,}` | `Bearer ****` | `Authorization: Bearer eyJhbGc...` |
| `secret_kv` | `(secret|password|token)["':= ]+[A-Za-z0-9_\-]{8,}` | `{key}=****` | `password="hunter22"` / `token=abc12345` |
| `conn_string` | `(://)[^:@/ ]+:[^@/ ]+@` | `://****@` | `postgresql://user:pass@host/db` |

**重要（ERE 構文）**:
- ERE では `|`（OR）はバックスラッシュ不要で機能する（`secret|password|token`）。`secret\|password\|token` のような BRE 風記法を **使わない**
- 文字クラス内のハイフン `-` は末尾配置（`[A-Za-z0-9_\-]`）でリテラル扱い。安全のためバックスラッシュエスケープも併用
- `\s` は POSIX ERE では非対応のため `[ \t]` で代替

false positive 許容（漏洩リスクを優先）。

#### 必須テストケース（指摘 #3 への対応 / 検出漏れ防止優先）

bats 機密フィルタテスト（`tests/retrospective-fact-extract-jsonl.bats` 内）に以下のテストケースを **必須** とする:

| ID | 入力例 | 期待マスク後 | 検証目的 |
|----|--------|------------|---------|
| MASK-01 | `api_key="sk-proj-abc123def456ghi"` | `api_key=****` | api_key パターン |
| MASK-02 | `API_KEY=ABCDEFGHIJ1234567890` | `API_KEY=****` | 大文字 / 等号 / クォートなし |
| MASK-03 | `apikey: 'live_xxxxxxxxxxxxxxxx'` | `apikey=****` | コロン / シングルクォート |
| MASK-04 | `Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.abc.def` | `Authorization: Bearer ****` | bearer_token パターン |
| MASK-05 | `password="hunter22xx"` | `password=****` | secret_kv パターン |
| MASK-06 | `token=abc12345defgh` | `token=****` | secret_kv パターン（クォートなし） |
| MASK-07 | `secret: ghp_xxxxxxxxxxxxxxxx` | `secret=****` | secret_kv パターン（コロン） |
| MASK-08 | `postgresql://user:pass@host:5432/db` | `postgresql://****@host:5432/db` | conn_string パターン |
| MASK-09 | `https://admin:secret123@example.com/path` | `https://****@example.com/path` | conn_string パターン（https） |
| MASK-10 | （false positive 確認）`secretary_name=Tanaka` | `secretary_name=Tanaka`（マスクされない） | キー名先頭一致での誤検出回避 |

MASK-10 を除き、検出漏れがあれば **テスト fail とする**（漏洩リスク優先）。false positive（MASK-10）は許容するが、明らかな英単語境界違反のみ最低限抑止する正規表現を Phase 2 で確定。

---

## 後方互換性設計

### §1.1.5 手動経路との diff 0 保証

- **bats 統合テスト**で実 fixture（`.aidlc/cycles/v2.6.5/`）に対する手動 §1.1.5 期待 markdown ファイルを用意し、helper 経路出力との `diff` が 0 であることを必須化
- 期待 markdown ファイルは bats テスト内で fixture として bundle（`tests/fixtures/unit003_v265_facts_expected.md` 等、Phase 2 で path 確定）
- 行順序 / 列順序 / 空白（`|` 前後の半角スペース / セル空時の `-`）/ 末尾改行を完全一致

### `retrospective-api.sh` 既存 API の不変

- 既存 13 関数（`retrospective_api_resolve_feedback_mode` 〜 `retrospective_api_record_selfreview`）のシグネチャは不変
- 本 Unit が追加するのは `retrospective_api_extract_facts` 1 本のみ

---

## テスト設計

### bats テスト構成

| テストファイル | 内容 |
|--------------|------|
| `tests/retrospective-fact-extract-decisions.bats` | L1 decisions extractor: 正常系 / 空ファイル / ファイル不在 |
| `tests/retrospective-fact-extract-review-summary.bats` | L1 review_summary extractor: 正常系 / 空ファイル / ファイル不在 |
| `tests/retrospective-fact-extract-history.bats` | L1 history extractor: 正常系 / 空ファイル / ファイル不在 / N 件超過時の打切 |
| `tests/retrospective-fact-extract-jsonl.bats` | L1 jsonl extractor: 引数なし / 引数あり + 存在 / 引数あり + 不在 / 機密フィルタ MASK-01〜MASK-10 必須網羅 |
| `tests/retrospective-fact-extract-integration.bats` | L3 公開 API: §1.1.5 手動経路との diff 0 / パフォーマンス NFR（5 秒以内）/ cycle 不在 fatal |

テストファイル粒度は Phase 2 着手時に再調整可（1 ファイル 5 テスト程度を目安）。

### fixture

| fixture | 目的 |
|---------|------|
| `tests/fixtures/unit003_v265_cycle/` | 実 fixture（v2.6.5 サイクルの decisions / review-summary / history のコピー） |
| `tests/fixtures/unit003_v265_facts_expected.md` | 手動 §1.1.5 経路で得られる期待 markdown 表 |
| `tests/fixtures/unit003_sample.jsonl` | jsonl 正常系 |
| `tests/fixtures/unit003_sample_secrets.jsonl` | 機密情報含む jsonl（マスク検証用） |

---

## 公開シンボル一覧（SoT）

本 Unit が追加する **公開シンボルは以下 1 件のみ**:

| シンボル | 種別 | 場所 |
|---------|------|-----|
| `retrospective_api_extract_facts` | function | `skills/aidlc/scripts/lib/retrospective-api.sh` |

それ以外（`_retrospective_fact_extract_*` プレフィックスの全関数 / `RETROSPECTIVE_FACT_EXTRACT_SOURCED` 変数）は **internal 専用** とし、caller / 外部 lib からの参照を禁止する（規約レベル / 構造的強制は多重 source ガードと命名規約で実現）。

---

## 設計判定マトリクス

| 設計判定 | 採否 | 根拠 |
|---------|------|------|
| 公開 API は Facade に集中 | 採用 | 計画 R1 指摘 #1 / Facade Pattern |
| L1/L2/L3 3 層分離 | 採用 | 計画 R1 指摘 #2 / Separation of Concerns |
| L1/L2 を `retrospective-fact-extract.sh` に閉じる | 採用 | shellcheck / lint 上の責務分離 + 物理ファイル分離 |
| L3 を Facade 公開関数に置く | 採用 | 既存 Facade 一本化パターンと整合 |
| 中間形式は pipe-separated | 採用 | bash stdin/stdout 経路で軽量 / 既存パターン整合 |
| 機密フィルタは安全側 | 採用 | 漏洩リスク優先 / false positive 許容 |
| jsonl 自動検出 | 不採用 | Intent / Unit 定義「境界」で v2.7.0+ defer 明示 |
| §1.1.5 手動経路置換 | 不採用 | 後方互換 / Intent §「明示的に除外するもの」 |

---

## 想定リスク・留意点（論理設計レベル）

- **中間形式エスケープ**: pipe `|` を value に含むケース（時系列イベントのタイムスタンプ + 概要 結合等）でエスケープ規約が崩れると renderer 出力が壊れる。Phase 2 でエスケープ規約を確定し bats で encode/decode 対称性をテスト
- **renderer ソート安定性**: 既定行の固定リテラル順 + 時系列複数行のタイムスタンプ昇順を `sort` で実装する場合、locale 差が出る。`LC_ALL=C sort` 強制を Phase 2 で fix
- **shellcheck**: SC2086（quoting）/ SC2155（local + assignment）/ SC1091（source path）を pass させる quoting 規約を Phase 2 で固定
- **多重 source ガード**: `RETROSPECTIVE_FACT_EXTRACT_SOURCED` を立て忘れると Facade re-source 時に関数再定義 warning が出る
- **bats fixture サイズ**: 実 v2.6.5 fixture を全コピーすると tests/ が膨張するため、必要最小限のファイル抜粋 + 期待 markdown を bundle する
