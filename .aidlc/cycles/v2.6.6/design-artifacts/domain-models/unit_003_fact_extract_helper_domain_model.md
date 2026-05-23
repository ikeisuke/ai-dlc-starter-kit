# ドメインモデル: Unit 003 一次情報三層検証 helper (3 source MVP + jsonl 引数 opt-in)

## 概要

`retrospective` 振り返り skill の §1.1.5「事実テーブル先抽出ステップ」を支える、3 source（decisions.md / construction review-summary / history）＋ jsonl 引数 opt-in の事実構造化抽出 helper のドメインモデル。本モデルは **「構造化 FactRow を生成する extractors」「§1.1.5 互換 markdown 表に整形する renderer」「両者を順次起動する orchestrator」の 3 層分離** を中核とし、§1.1.5 手動経路との後方互換（diff 0）と将来の source 追加余地を構造で担保する。

**重要**: 本ドメインモデル設計では **コードは書かず**、構造と責務の定義のみを行う。

---

## ステップ0 事前コード読込み

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc/scripts/lib/retrospective-api.sh` | 既存 Facade の (i) 多重 source ガード規約 / (ii) `_RETROSPECTIVE_API_BASE` 解決経路 / (iii) Type B 関数の出力契約 / (iv) `_local_<関数省略名>_<名>` 命名規約 を踏襲するため |
| `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` | 同名ファイルが既存しないこと（新規追加対象であること）を確認する |
| `skills/aidlc-retrospective/steps/retrospective.md` §1.1.5 | (i) 既定 markdown 表の列・行構造 / (ii) `source` パスの canonical 形式 / (iii) 「実際に Read した結果のみ」の運用規約 を踏襲するため |
| `skills/aidlc/scripts/read-config.sh` | `aggregate_issue_enabled` helper と同様に終了コード（0/1/2+）の解釈規約を再利用するため |
| `.aidlc/cycles/v2.6.5/inception/decisions.md`, `.aidlc/cycles/v2.6.5/construction/units/*-review-summary.md`, `.aidlc/cycles/v2.6.5/history/*.md` | 実 fixture として後方互換 diff 0 統合テストで使う実データ source の構造（DR 見出し / Round 別指摘テーブル / 時系列見出し）を確認するため |
| `tests/retrospective-*.bats`（既存） | bats fixture 作成パターン / Facade source パターン / dynamic scope shadowing 回避パターン を踏襲するため |
| `CLAUDE.md`（本リポジトリ）「AI エージェント Bash ツール経由の安全パターン」 | helper 内部実装で `$(...)` / backtick を Bash ツール引数文字列に直書きしない規約遵守のため |

### (b) 設計時に意識すべき挙動

- Facade `retrospective-api.sh` は **多重 source ガード**（`RETROSPECTIVE_API_SOURCED=1`）と `_RETROSPECTIVE_API_BASE` 環境（自己解決）に依存しており、本 Unit が追加する `retrospective-fact-extract.sh` も同じパスで source される前提で動作する
- 既存 Type B 公開関数（例: `retrospective_api_aggregate_enabled` / `retrospective_api_check_cap`）は **stdout 1 行 + exit 0 固定** の fail-safe 契約。本 Unit の `retrospective_api_extract_facts` は出力が複数行 markdown 表となるが、**stderr に warn を流す前提で stdout はあくまで markdown 表本体** に限定する（Type B 拡張）
- 既存 `_local_<関数省略名>_<名>` 命名規約は `printf -v "$var"` を使う result-out 関数の dynamic scope shadowing 対策。本 Unit は `printf -v` 経路を取らず、関数戻り値はすべて **stdout 経由（pipe-separated 中間形式 → markdown 表）** に統一するため、必須適用ではないが、internal 関数の local 変数は同規約に準じた `_local_<fnshort>_<name>` プレフィックスで揃え、将来の result-out 化に備える
- §1.1.5 手動経路は markdown 表の列「項目 / 値 / 出典」を 5 行（DR 件数 / review round 数 / 指摘件数 / defer 件数 / 時系列イベント）で固定しており、helper 経路でも **行順序・列順序・空白を完全一致** させる必要がある
- source ファイル不在（例: 過去サイクルに decisions.md がない）は warn 出力 + 当該行「-（source 不在）」で他 source 処理継続。cycle ディレクトリ自体不在は fatal（exit 2）
- jsonl source は **file path 引数指定時のみ** opt-in 処理。引数なし時は jsonl 行を表に出さない（既存 §1.1.5 互換）
- jsonl 内には API キー / トークン等の機密情報が含まれうる。**機密フィルタ正規表現** で値マスクが必須（漏洩リスク優先 / false positive は安全側）

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `refactor` 既存 §1.1.5 を helper 化 | 既存手動 Read 経路を廃止して helper のみに統一 | **却下** | Intent §「明示的に除外するもの」で「§1.1.5 のデフォルト経路化は v2.7.0+ defer」と明示。後方互換を破壊しない |
| `extend` 既存関数群への内蔵 | `retrospective-api.sh` 内に extractor / renderer 関数を直接追加 | **却下** | (i) Facade 責務が抽出ロジックで肥大 (ii) shellcheck / lint 上 1 ファイル 1000 行近くなる (iii) 役割 3 層分離（L1/L2/L3）が単一ファイルで凝集低下 |
| `add` 新規 private lib + Facade source | `retrospective-fact-extract.sh`（private 実装）を新規追加し Facade から source、公開 API は Facade のみ | **採用** | (i) Facade 一本化（呼出側 namespace 汚染なし）(ii) 3 層分離が物理ファイルでも表現される (iii) 既存パターン（`retrospective-llm-draft.sh` 等が Facade に source される構造）と整合 |

---

## エンティティ（Entity）

### `Cycle`

- **ID**: `cycle_id`: string（`v{major}.{minor}.{patch}` 形式 / 識別子）
- **属性**:
  - `cycle_dir`: filesystem path - `.aidlc/cycles/{cycle_id}/` の絶対パス
- **振る舞い**:
  - `resolveSourcePath(kind)` - SourceKind に応じた既定 source ファイルパス（または glob）を導出する
  - `existsCycleDir()` - cycle_dir の存在チェック（不在時は orchestrator 側で fatal）

### `FactSource`

- **ID**: `(cycle_id, kind)` の複合キー
- **属性**:
  - `kind`: SourceKind - `decisions` / `review_summary` / `history` / `jsonl` のいずれか
  - `paths`: filesystem path のリスト - decisions は単一ファイル / review_summary は glob / history は glob / jsonl は引数指定の単一ファイル
  - `availability`: enum - `present` / `absent` / `skipped`（jsonl で引数未指定時は `skipped`）
- **振る舞い**:
  - `extractRows()` - source 種別に応じた抽出ロジックを起動し FactRow 集合を返す（domain-level の責務、実装は L1 extractors）
  - `markAbsent()` - source 不在を表現する FactRow（値「-（source 不在）」/ 出典「{paths}」）を返す

### `FactExtractionSession`

- **ID**: `(cycle_id, started_at)`
- **属性**:
  - `cycle`: Cycle
  - `requested_sources`: List<SourceKind> - 3 source MVP では常に `[decisions, review_summary, history]`、jsonl 引数指定時は末尾に `jsonl` を追加
  - `warns`: List<string> - 抽出中に発生した警告メッセージ集（stderr へ流す）
  - `result`: ExtractionResult
- **振る舞い**:
  - `addWarn(message)` - warn メッセージを追記する
  - `complete()` - 全 source の抽出を完了状態にする

---

## 値オブジェクト（Value Object）

### `SourceKind`

- **属性**: `kind`: enum - `decisions` / `review_summary` / `history` / `jsonl`
- **不変性**: 列挙値が事前定義された 4 種から外れない
- **等価性**: 列挙値の完全一致

### `FactRow`

- **属性**:
  - `kind`: SourceKind - この行を生成した source 種別
  - `item`: string - markdown 表「項目」列の値（例: `DR 件数` / `review round 数（合計）` / `時系列イベント（主要なもの）`）
  - `value`: string - markdown 表「値」列の値（実数値、リスト表現、または `-（source 不在）`）
  - `source_path`: string - markdown 表「出典」列の値（canonical な repo-relative path / glob）
- **不変性**: 3 列が常に揃う。`value` に機密情報が含まれる場合は **生成時にマスク済み** であること
- **等価性**: `(kind, item, value, source_path)` の完全一致

### `FactTable`

- **属性**: `rows`: List<FactRow> - 表全体の行集合
- **不変性**:
  - `rows` の順序は **§1.1.5 既定順** に固定（DR 件数 → review round 数 → 指摘件数 → defer 件数 → 時系列イベント → jsonl 由来イベント の順、jsonl は opt-in 時のみ）
  - 同一 `(kind, item)` の重複は許容しない（時系列イベントは複数行となるが `item` を `時系列イベント #N` 形式で一意化、または合計行を 1 行に集約する設計を logical_design.md で確定）
- **等価性**: rows 全体の順序付き完全一致

### `ExtractionContext`

- **属性**:
  - `cycle_id`: string
  - `jsonl_path`: optional<filesystem path> - 引数指定された場合のみ非空
  - `max_history_events`: integer - 時系列イベントの最大行数（既定 5）
- **不変性**: `cycle_id` は必須・非空。`jsonl_path` 空時は jsonl source を `skipped` とする

### `ExtractionResult`

- **属性**:
  - `table`: FactTable - 整形前の構造化結果
  - `warns`: List<string> - 抽出中の警告
  - `outcome`: enum - `ok`（少なくとも 1 source が `present`）/ `partial`（一部 absent / skipped）/ `empty`（全 source absent + 不在のみ）
- **不変性**: `outcome=empty` でも table は最低 5 行（既定項目 + `-（source 不在）`）を含む。0 行になる場合は fatal とする

### `RenderedTable`

- **属性**:
  - `markdown`: string - markdown 表本体（複数行）
- **不変性**: §1.1.5 既定列構成（`| 項目 | 値 | 出典 |`）と完全一致 / 末尾は LF 終端

---

## 集約（Aggregate）

### `FactExtractionSessionAggregate`

- **集約ルート**: `FactExtractionSession`
- **含まれる要素**: `Cycle` / `FactSource`（複数）/ `ExtractionResult`（`FactTable` を内包）/ warns
- **境界**: 1 回の helper 呼び出しに対応する単位（cycle_id + jsonl_path 引数の組）。複数 cycle の混在は許容しない
- **不変条件**:
  - cycle_id に対応する `cycle_dir` が存在する場合のみセッションが成立する（不在時は fatal）
  - `result.table.rows` は §1.1.5 既定順序を保持する
  - jsonl source の availability は `(jsonl_path 非空 ∧ ファイル存在)` のとき `present`、`(jsonl_path 空)` のとき `skipped`、`(jsonl_path 非空 ∧ 不在)` のとき `absent`

---

## ドメインサービス

### `FactExtractorService`

- **責務**: SourceKind ごとの抽出規則（DR 件数の集計、review round 数の集計、history 見出し抽出、jsonl 構造化エントリ抽出 + 機密フィルタ）を定義し、`FactSource` の `extractRows()` 呼び出しに対する応答を生成する。**実装層では L1 internal 関数群** として表現される
- **操作**:
  - `extractDecisions(cycle)` - decisions.md から DR 件数 / DR タイトル / 主因 3 分類カウントを集計
  - `extractReviewSummary(cycle)` - review-summary 群から review round 数合計 / 指摘件数合計 / defer 件数合計を集計
  - `extractHistory(cycle, max_events)` - history/*.md の見出し（H2+）+ 直後 1 行を時系列イベントとして抽出（最大 `max_events` 件）
  - `extractJsonlOptional(jsonl_path)` - 引数指定時のみ jsonl line-by-line で構造化エントリを抽出、機密フィルタ適用後にタイムスタンプ + summary に正規化

### `FactTableRenderer`

- **責務**: `FactTable`（構造化された FactRow 集合）を §1.1.5 既定列構成と diff 0 の markdown 表に整形する。表示互換契約（列順序・行順序・空白）を **このサービス単独で保持** し、extractors と orchestrator はこの責務を持たない。**実装層では L2 internal 関数** として表現される
- **操作**:
  - `render(table)` - FactTable を markdown 表（`| 項目 | 値 | 出典 |` ヘッダ + 区切り行 + データ行）に整形して RenderedTable を返す

### `FactExtractionOrchestrator`

- **責務**: ExtractionContext を受け取り、Cycle / FactSource 群を構築し、`FactExtractorService` を順次起動して `FactTable` を構築し、`FactTableRenderer` に渡して stdout に出力する。warn 集積と stderr 出力もここで担う。**実装層では L3 公開 API 関数** `retrospective_api_extract_facts` として表現される
- **操作**:
  - `execute(context)` - 全 source の抽出 → renderer 起動 → stdout 出力までを 1 トランザクションで実行

---

## リポジトリインターフェース

本 Unit はファイルシステム上の markdown / jsonl 読み取り専用で、永続化は伴わない（永続化先は呼び出し側の標準出力のみ）。よって伝統的 Repository は不要。代わりに **read-only な source accessor** を `FactExtractorService` の操作内で間接利用する想定。

---

## ファクトリ

不要（FactRow / FactTable / ExtractionContext は値オブジェクトとして直接構築可）。

---

## ドメインモデル図

```text
ExtractionContext (VO)
  └─ build → FactExtractionSession (Entity, Aggregate Root)
       ├─ Cycle (Entity)
       ├─ requested_sources: List<FactSource (Entity)>
       │    └─ kind: SourceKind (VO)
       ├─ FactExtractorService (Domain Service / L1)
       │    └─ extractRows() per FactSource
       │         └─ produces List<FactRow (VO)>
       ├─ FactTableRenderer (Domain Service / L2)
       │    └─ render(table) → RenderedTable (VO)
       └─ FactExtractionOrchestrator (Domain Service / L3)
            └─ execute(context) → stdout(markdown) + stderr(warns)
```

---

## 公開 API（実装層への投影）

| 公開シンボル | ドメイン責務 | 実装層 |
|------------|------------|--------|
| `retrospective_api_extract_facts` | `FactExtractionOrchestrator.execute()` | L3 / `retrospective-api.sh` |

internal 関数（`_retrospective_fact_extract_*` プレフィックス、`retrospective-fact-extract.sh` 内）は `FactExtractorService` / `FactTableRenderer` の各操作に 1:1 対応する。

---

## ビジネスルール / 不変条件まとめ

1. **後方互換不変**: `FactTable.rows` は §1.1.5 既定 5 行（jsonl 引数指定時は 6 行）の順序・構造を保持する。`dr_titles` / `dr_root_cause_class` の内部集計結果は **§1.1.5 互換モードの stdout には出力しない**（renderer による採択フィルタで除外、将来別 API で公開検討）
2. **公開境界不変**: `retrospective_api_extract_facts` 以外を caller から呼ばれない構造（Facade 一本化）を保証する
3. **機密保護不変**: jsonl 由来の値は **生成時マスク済み** で `FactRow` に格納される
4. **fail-safe 不変**: source 不在は warn + 「-（source 不在）」行で他 source 処理継続。cycle 不在のみ fatal（exit 2）
5. **stdout 純粋性不変**: stdout には markdown 表本体のみ流す。warn / 進捗 / debug は stderr
