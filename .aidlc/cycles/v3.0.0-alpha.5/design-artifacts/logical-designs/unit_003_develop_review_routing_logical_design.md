# 論理設計: Unit 003 develop Step 5（レビュー）+ review routing

## 概要

develop.md Step 5（レビュー）の手順実装、Step 2.3 review 境界ガード解除、reviews_path への perspective 別
セクション冪等記録、review-flow.md/review-routing.md への委譲アダプタ境界、workflow.md §6.1 文言整合、および
test-develop-flow.sh の `decide_review_routing` 拡張のコンポーネント構成・インターフェースを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な
手順記述・テストコードは Phase 2 で作成する。

## アーキテクチャパターン

**委譲レイヤード（Delegation Layered）**: develop.md（実行手順オーケストレーション層）が判定ロジックを
review-routing.md（ルーティング判定層）/ review-flow.md（反復・Defer 手順層）へ委譲し、自身は「matrix_review_mode→
caller_context 変換」「成果物配置」「commit 集約」のみを担う。SoT 二重定義回避（§8 / routing / flow を単一正本に保つ）
を選定理由とする。

## コンポーネント構成

### レイヤー / モジュール構成

```text
develop.md（実行手順オーケストレーション）
├── Step 1: MatrixDecision 構築（Unit 001 / 既存）
├── Step 2: design 生成 + Design 承認ゲート（Unit 002 / 既存）
│   └── Step 2.3: review 境界ガード【本 Unit で解除】
├── Step 3: 実装（既存 / 境界解除で到達可能化）
├── Step 4: 検証（既存 / 同上）
├── Step 5: レビュー【本 Unit で実装】
│   ├── ReviewRoutingResolver（matrix_review_mode → PerspectiveRoute 群 / review-routing.md §3 写像）
│   ├── ReviewExecutionDelegate（review-flow.md へ 5R/Defer/マスク/パス選択を委譲）
│   └── ReviewArtifactRecorder（reviews_path に perspective 別セクション upsert）
└── Step 6: 完了（status done + journal + 単一 commit / 既存）

docs/v3/workflow.md §6.1【本 Unit で文言整合】
skills/aidlc-v3/scripts/tests/test-develop-flow.sh
└── decide_review_routing（純粋関数 / 本 Unit で追加）+ run_develop 拡張（境界解除 + Step 5 模擬）
```

### コンポーネント詳細

#### ReviewRoutingResolver（develop.md Step 5 内の判定記述）

- **責務**: `MatrixDecision` の `matrix_review_mode` から実行する PerspectiveRoute 群を導出
- **依存**: Unit 001 `MatrixDecision`（`review_required` / `matrix_review_mode` / `reviews_path` / `designs_path`）、
  review-routing.md §3（caller_context→skill/focus 写像）
- **公開インターフェース**: `matrix_review_mode` → route 群（下表「matrix_review_mode 写像」）

#### ReviewExecutionDelegate（develop.md Step 5 内の委譲記述）

- **責務**: 各 route について review-flow.md の実行手順（パス選択・反復・完了判定・Defer）を呼び出す
- **依存**: review-routing.md §4/§5/§6/§7、review-flow.md（5R 完了判定 / Defer 自動 Issue 起票 / マスク）
- **公開インターフェース**: route → レビュー結果（resolved / deferred の集計 + 記録本文）。
  **委譲限定**: commit / 成果物保存は呼ばず、develop 側の ReviewArtifactRecorder / Step 6 が担う（§委譲境界）

#### ReviewArtifactRecorder（develop.md Step 5 内の記録記述）

- **責務**: レビュー結果を `reviews_path` の perspective 別セクションに冪等記録
- **依存**: Unit 001 配線の `reviews_path`、`designs_path`（design review 対象）
- **公開インターフェース**: `upsert_section(perspective, body, completion_status)`（マーカー区間 upsert）

#### decide_review_routing（test-develop-flow.sh の純粋関数）

- **責務**: `decide_matrix` と同様の単一の真実として、`matrix_review_mode` → route 記述子（perspective + focus +
  記録セクション）を deterministic に出力。テストが routing を検証する基盤
- **依存**: なし（純粋関数）
- **公開インターフェース**: 下記「スクリプトインターフェース設計」参照

## インターフェース設計

### matrix_review_mode 写像（ReviewRoutingResolver の正準テーブル）

| matrix_review_mode | caller_context | skill_name | focus | 対象ファイル | 記録セクション |
|--------------------|----------------|------------|-------|------------|---------------|
| `none` | （なし） | （なし / Step 5 スキップ） | - | - | - |
| `code` | コード生成後 | `reviewing-construction-code` | code, security | 実装差分 | `## Code Review` |
| `code_security` | コード生成後 | `reviewing-construction-code` | code, security（security 重点） | 実装差分 | `## Code Review` |
| `code_security_design` | コード生成後 + 設計レビュー | `reviewing-construction-code` + `reviewing-construction-design` | code, security（重点）/ architecture | 実装差分 / `designs_path` | `## Code Review` + `## Design Review` |

> `routing_review_mode`（config `[rules.reviewing].mode`）は review-routing.md の `ReviewRoutingInput.review_mode`
> 引数として別途渡す。`matrix_review_mode` 値をこの引数に渡さない（不正 enum 混入防止 / 計画 §1.1）。

### Step 5 入力契約（2 系統 / 指摘 #3）

Step 5 は **実行対象決定**と**処理パス選択**の 2 系統入力を取り、依存方向を固定する:

| 入力 | フィールド | 取得元 | 役割 |
|------|----------|--------|------|
| `MatrixDecision`（Unit 001） | `review_required` / `matrix_review_mode` / `reviews_path` / `designs_path` | Step 1 構築済み | **実行対象決定**（どの perspective/focus/対象を実行するか） |
| `ReviewRuntimeConfig`（本 Unit で明示） | `routing_review_mode`（= `[rules.reviewing].mode`）/ `automation_mode` / `configured_tools[]`（= `[rules.reviewing].tools`）/ `available_tools[]`（`command -v` 等の検出結果）/ `tools_runtime_status`（CLI 実行時の `ok`/`cli_runtime_error`/`cli_output_parse_error`） | `config.toml`（`read-config.sh` 経由）+ ツール検出 + 実行時 | **処理パス選択**（外部CLI/セルフ/ユーザーのどのパスでレビューするか / review-routing.md `ReviewRoutingInput`） |

> 依存方向: `MatrixDecision`（実行対象）→ ReviewRoutingResolver、`ReviewRuntimeConfig`（処理パス）→ review-routing.md。
> 両者は独立入力であり、`matrix_review_mode`（§8 値）を `routing_review_mode`（config 値）に混入させない（計画 §1.1）。
> `ReviewRuntimeConfig` の取得・正規化は既存 `read-config.sh` / review-routing.md §2/§4 に委譲し develop に再定義しない。

#### Step 5 レビュー実行

- **パラメータ**: `MatrixDecision` + `ReviewRuntimeConfig`（上表）
- **戻り値**: レビュー完了状態（`resolved_count` / `deferred_count` / `unresolved_count`）
- **副作用**: `reviews_path` への perspective 別セクション生成・upsert（Defer 時の自動 Issue 起票は review-flow.md）
- **分岐**: `review_required=false` → Step 5 スキップ → Step 6。`review_required=true` → route 群を実行 → Step 6

### 委譲境界（ReviewExecutionDelegate / 指摘 #1）

review-flow.md は実体としてパス 1/3 の冒頭・完了処理に commit / review-summary / `history/*.md` 更新を**組み込んで**
いる。これらを丸ごと実行すると v3 develop の「Step 6 単一 commit」「`reviews/<id>-<slug>.md` 成果物」契約を破る。
したがって委譲を**サブ手順粒度**で許可/禁止に分解する:

| review-flow.md のサブ手順 | develop Step 5 での扱い |
|--------------------------|------------------------|
| パス選択（外部CLI/セルフ/ユーザー直行 / review-routing.md §4-§7 経由） | **利用（呼び出し可）** |
| 反復レビュー実行 + 5R 完了判定（`is_completed()` / 1R clean 特例） | **利用（呼び出し可）** |
| 指摘対応判断フロー（千日手検出 / スコープ保護確認）+ 設計レビュー早期 defer ガイド | **利用（呼び出し可）** |
| Defer 自動 Issue 起票（OUT_OF_SCOPE / TECHNICAL_BLOCKER） | **利用（呼び出し可）** |
| 機密マスク（focus=security 特例含む） | **利用（呼び出し可）** |
| **レビュー前コミット / レビュー後コミット三段階（2a/2b/2c）** | **呼び出し禁止**: v3 develop は Step 6 で work item 単位 1 commit に集約 |
| **review-summary 更新（`construction/units/{NNN}-review-summary.md`）** | **呼び出し禁止**: v3 develop は `reviews/<id>-<slug>.md` の perspective 別セクションに記録 |
| **`history/*.md` 配置（write-history）** | **呼び出し禁止（develop フロー内）**: v3 develop の journal.md（Step 6）が記録正本 |

> develop.md Step 5 には上記許可サブ手順のみを使う **v3 用疑似フロー**（後述「Step 5 レビューの処理フロー」）を置き、
> 禁止サブ手順（commit / review-summary / history）は呼ばないことを明記する。review-flow.md 本体は改変しない
> （SoT 二重定義回避）。

## スクリプトインターフェース設計

### decide_review_routing（test-develop-flow.sh 内純粋関数）

#### 概要

`matrix_review_mode` から実行 route 記述子を deterministic に出力する純粋関数（`decide_matrix` と同じ模擬境界方針）。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `matrix_review_mode` | 必須 | `none` / `code` / `code_security` / `code_security_design` |

#### 成功時出力

```text
# perspective:focus:section を `;` 区切りで列挙（route なしは空行 or "none"）
# 例（code_security_design）:
code:code,security:## Code Review;design:architecture:## Design Review
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
unknown
```

- 終了コード: `0`（純粋写像 / `decide_matrix` と同様に未知値は `unknown` トークンで返し停止しない）
- 出力先: stdout

#### 使用コマンド

```bash
# テストハーネス内の assert で呼び出し
decide_review_routing code_security_design
```

### run_develop 拡張（既存ドライバ / 本 Unit で改修）

| 改修点 | 内容 |
|-------|------|
| Step 2.3 境界ガード解除 | `review_required=1` で `exit 26` していた箇所を撤去し Step 3 へ fall-through |
| Step 5 模擬 | `review_required=1` で `decide_review_routing` の route に従い `reviews_path` に perspective 別セクションを生成（AI レビュー実行・反復は非模擬 / approved 前提） |
| 完走化 | design 必須セルが Step 3（src 生成）→ Step 4 → Step 5（reviews 生成）→ Step 6（done + journal + commit）まで到達（旧 rc=26 テストは rc=0 + done + reviews 生成へ更新） |

## データモデル概要

### ファイル形式: reviews/<id>-<slug>.md（マーカー仕様 / 指摘 #2）

- **形式**: Markdown（frontmatter なし / design.md と同様）
- **主要フィールド**:
  - 見出し: `## Code Review` / `## Design Review`（perspective 別）
  - **区間マーカー（状態を含む）**: 開始マーカーに `status=` 属性を持たせ、resume 時の complete/incomplete 判定の
    永続化根拠とする:

    ```text
    <!-- aidlc-review:code:start status=complete -->
    ## Code Review

    （レビュー結果本文 / 機密マスク済み）

    <!-- aidlc-review:code:end -->
    ```

  - `status=` の値域: `complete`（反復完了 = `unresolved_count=0` または全 defer 化）/ `in_progress`（反復未完了）
  - セクション本文: レビュー結果（機密マスク済み / focus=security は要約のみ）
- **異常系の扱い（upsert 前検証）**:
  - **status 欠落 / 不正値**: 当該区間を `in_progress` 扱いとし置換対象とする（部分書き込みの取りこぼし防止 / 安全側）
  - **duplicate marker**（同一 perspective の start が複数）: 最初の start〜対応 end を正規区間とし、余剰区間は警告して
    置換時に統合（重複を残さない）
  - **start/end 不整合**（end 欠落 / 順序逆転）: 当該 perspective を破損とみなし、警告して区間を再生成（incomplete 扱い）
  - **markdownlint 整合**: マーカー HTML コメントの前後に空行を 1 行入れ、見出し（`## ...`）前後の空行規約（MD022 等）を
    満たす。マーカーは見出しの直前・セクション末尾の直後に配置

## 処理フロー概要

### Step 5 レビューの処理フロー（v3 用疑似フロー / 許可サブ手順のみ使用）

**ステップ**:
1. `MatrixDecision.review_required` を確認。`false` → Step 6 へ（Step 5 スキップ）
2. `matrix_review_mode` を「matrix_review_mode 写像」テーブルで route 群へ変換（ReviewRoutingResolver）
3. `ReviewRuntimeConfig` を取得（`read-config.sh` で `routing_review_mode` / `configured_tools` / `automation_mode`、
   ツール検出で `available_tools`）
4. 各 route について review-flow.md の**許可サブ手順のみ**を実行（ReviewExecutionDelegate / 委譲境界表）:
   パス選択（review-routing.md）→ 反復レビュー（最大 5R）→ 完了判定 → 指摘対応判断 / Defer 自動 Issue 起票 → マスク。
   **レビュー前/後コミット・review-summary・history 書込みは呼ばない**
5. route 結果を `reviews_path` の perspective 別セクションに upsert（ReviewArtifactRecorder / 下記冪等フロー）
6. 全 route 完了（`unresolved_count=0` または全 defer）→ Step 6 へ（commit は Step 6 の単一 commit に集約）

**関与するコンポーネント**: ReviewRoutingResolver, ReviewExecutionDelegate, ReviewArtifactRecorder

### reviews_path 冪等 upsert の処理フロー

**ステップ**:
1. 対象 perspective のマーカー区間（`<!-- aidlc-review:<perspective>:start status=... -->` … `:end`）を検出・検証
   （duplicate / 欠落 / 不整合は「マーカー仕様」異常系に従う）
2. 区間あり + `status=complete` → スキップ（再追記・上書きしない / resume 冪等）
3. 区間あり + `status=in_progress`（または status 欠落/不正） → 同一区間を置換（区間まるごと再生成）
4. 区間なし → 末尾に新規セクション追加（マーカー + 見出し + 本文）

**関与するコンポーネント**: ReviewArtifactRecorder

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: レビュー反復は 5R 上限で打ち切る（無限ループ防止 / Unit NFR）
- **対応策**: review-flow.md の `is_completed()`（5R 上限 + 1R clean 特例）を委譲利用

### セキュリティ
- **要件**: security focus レビューの公開記録はマスク方針に従う（Unit NFR）
- **対応策**: review-flow.md の機密マスク + focus=security 特例（要約のみ記録）を委譲利用。`reviews_path` に機密を残さない

### スケーラビリティ
- **要件**: 該当なし（Unit NFR）
- **対応策**: -

### 可用性
- **要件**: レビュー CLI 不在時はフォールバック（self / ユーザー）に従う（Unit NFR）
- **対応策**: review-routing.md §4-§6 の SelfBackcompatShim / fallback_policy を委譲利用（develop に再定義しない）

## 技術選定
- **言語**: Markdown（skill steps）+ Bash（test-develop-flow.sh）
- **フレームワーク**: AI-DLC v3 skill（aidlc-v3）
- **ライブラリ**: 既存 `reviewing-construction-code` / `reviewing-construction-design` スキル、review-routing.md /
  review-flow.md（既存 SoT）

## 実装上の注意事項
- **ドッグフーディング特殊処理の禁止**: スキル呼び出しに自リポジトリ判定を埋め込まない（リポジトリ規約）
- **SoT 二重定義回避**: ルーティング/反復ロジックは review-routing.md / review-flow.md に委譲し、develop.md に再定義しない。
  workflow.md §6.1 は文言整合のみ（review 実行マトリクスの正本は §6.2/§8）
- **局所パース禁止**: `reviews_path` / `designs_path` は Unit 001/002 配線を利用し、develop.md に新規 grep/sed を足さない
- **委譲範囲限定**: review-flow.md の commit / 成果物配置規約を流用せず、v3 develop の Step 6 単一 commit /
  `reviews/<id>-<slug>.md` を正本とする
- **ガイド照合（v1.27.3）**: 終了コード規約（`guides/exit-code-convention.md`）と整合。`decide_review_routing` は
  純粋写像のため未知値も exit 0 + `unknown` トークン（`decide_matrix` 前例と一貫）

## SoT §6.1 不整合の確定（設計判断）

- **不整合**: workflow.md §6.1 は `plan` perspective 実行条件を「develop 開始時（normal/risky）」と列挙するが、
  §6.2 / data-model.md §8 の develop review マトリクスは code review のみ（`matrix_review_mode` に plan を含まない）
- **確定**: §6.2/§8 を正本とし、develop の size×depth review マトリクスに plan review を materialized しない。
  §6.1 の `plan` 行は「将来 `aidlc-review` 統合時の perspective カタログ」であり §8 由来の develop 自動 review 実行
  マトリクスとは別レイヤである旨を文言で明記する。
- **plan capability の所在明確化（指摘 #4）**: **Unit 003 が develop Step 5 で materialize するのは code / design の
  2 perspective のみ**。`plan` は既存 review-routing.md に `caller_context`（「計画承認前」）として存在するが、
  **本 Unit では実行・テスト対象外**（develop の §8 マトリクスが plan review を出力しないため）。Unit 003 は plan
  perspective のルーティング先テーブル（review-routing.md §3）を新規実装せず、既存定義を参照するに留める。
  したがって「3 perspective のルーティング能力」とは「review-routing.md に plan/design/code が存在する」ことを指し、
  Unit 003 の実装・テスト範囲は code/design に限定される（capability は既存資産 / execution は §8 制御で code/design のみ）

## 不明点と質問（設計中に記録）

[Question] design review の `reviewing-construction-design` 呼び出しで対象を `designs_path` とするが、code review の
対象「実装差分」は具体的に何を渡すか。
[Answer] review-routing.md §7 の呼び出し形式「[対象ファイル]」に work item の実装差分（Step 3 で変更したファイル）を
渡す。develop.md Step 5 では「work item の実装変更ファイル群」を対象とし、design review のみ `designs_path` を対象と
する旨を手順に明記する（実装で確定）。

[Question] reviews マーカー区間の置換（incomplete）はどの粒度で行うか。
[Answer] perspective 単位（`## Code Review` セクション全体 = start〜end 区間）で置換する。部分行置換はしない
（区間まるごと再生成で冪等性を単純化）。実装で markdownlint 整合を確認する。

[Question] resume 時の complete/incomplete 判定をファイル上でどう永続化するか（設計レビュー指摘 #2）。
[Answer] 開始マーカーに `status=complete` / `status=in_progress` 属性を持たせて永続化する（「マーカー仕様」参照）。
status 欠落/不正は安全側で incomplete 扱い（置換対象）とし、duplicate / start-end 不整合は警告して区間再生成する。

[Question] Step 5 の処理パス選択に必要な config / ツール検出値はどこから取得するか（設計レビュー指摘 #3）。
[Answer] `ReviewRuntimeConfig`（`routing_review_mode` / `automation_mode` / `configured_tools` / `available_tools` /
`tools_runtime_status`）として明示し、`read-config.sh` + ツール検出 + 実行時から取得する。MatrixDecision（実行対象）と
独立した処理パス選択入力とし、依存方向を固定する（「Step 5 入力契約」参照）。
