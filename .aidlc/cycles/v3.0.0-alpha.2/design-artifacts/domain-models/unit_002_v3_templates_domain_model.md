# ドメインモデル: Unit 002 v3 成果物テンプレート

## 概要

v3 の成果物テンプレート 3 種（intent / work-item / journal）が表現するドキュメント構造のドメインを定義する。本 Unit は静的テンプレートファイルの作成であり、ドメインロジックは持たないが、work item の「状態モデル（frontmatter schema）」と「本文の必須セクション構造」を `docs/v3/data-model.md` §4 / §7 に準拠してモデル化する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実テンプレートは Phase 2 で作成する。

## ステップ0: 事前コード読込み（新規テンプレート作成のため参照基盤の確認）

本 Unit は `skills/aidlc-v3/templates/` を新規作成する（改修対象の既存実装なし）。本セクションは設計の根拠となる正本・規約の確認として実施する。

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `docs/v3/data-model.md` §4 | work item frontmatter（必須キー・型・enum）+ 本文必須 6 セクションの正本確認 |
| `docs/v3/data-model.md` §7 | journal 形式（タイトル + 日付見出し + 箇条書き）の正本確認 |
| `docs/v3/data-model.md` §2 | ディレクトリ構造上の各成果物の位置づけ（intent.md / work-items/*.md / journal.md）確認 |
| `skills/aidlc-v3/scripts/state-validate.sh`（Unit 001） | work item state（frontmatter）と cycle state（state.json）の責務分担確認（state は state.json、work item 個別状態は frontmatter） |

### (b) 設計時に意識すべき挙動

- frontmatter の enum 値・キー名は SoT（data-model §4）と**完全一致**させる（表記揺れ・取りこぼし厳禁）
- work item の trace 情報の正本は各 work-item.md に置く（state.json には持たせない / §9）
- テンプレートは「埋める前の雛形」であり、placeholder は自然な形（`{{...}}` / 説明）で統一する
- markdownlint 通過（見出しレベル・空行・リスト記法）

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採用 / 却下 | 根拠 |
|------|------|-----------|------|
| data-model §4 の確定例示を雛形化 | §4.2 の確定例示テンプレートをそのまま雛形に | **採用** | SoT と完全一致が保証され、表記揺れリスク最小 |
| placeholder を `{{...}}` で統一 | 値部分を `{{...}}`、enum は候補をコメント明示 | **採用** | v2 テンプレート（`{{CYCLE}}` 等）と記法整合、検証も容易 |
| 独自構成で再設計 | data-model と別構成のテンプレート | 却下 | SoT 逸脱・整合性破壊のリスク |

## エンティティ（Entity）

### WorkItem（`work-items/*.md`）

work item を表すドキュメント。frontmatter（状態）+ 本文（trace・作業内容）で構成。

- **ID**: `id`（string / 3 桁ゼロ埋め推奨）
- **属性（frontmatter）**:
  - `status`: WorkItemStatus（enum）
  - `size`: WorkItemSize（enum）
  - `risk`: WorkItemRisk（enum）
  - `assigned`: string or null
  - `dependencies`: array（依存 work item ID。空配列可）
- **本文構造（必須 6 セクション）**: `Goal` / `Scope` / `Acceptance Criteria` / `Traceability` / `Size / Risk`（単一見出し）/ `Dependencies`。`Implementation Notes` は任意

### Intent（`intent.md`）

サイクルの開発意図を表すドキュメント。

- **構造**: 目的 / スコープ（含む・含まない）/ 受け入れ基準 等。work item への trace 起点

### Journal（`journal.md`）

追記型の軽量作業証跡。

- **構造**: トップレベルタイトル `# Journal: {{cycle}}` + 日付見出し `## YYYY-MM-DD` 配下に箇条書き

## 値オブジェクト（Value Object）

### WorkItemStatus

- **値域（enum）**: `pending` / `in_progress` / `blocked` / `done` / `withdrawn`
- **不変性**: enum は SoT（data-model §4）固定。テンプレートには既定値 `pending` + 候補一覧をコメントで明示

### WorkItemSize

- **値域（enum）**: `tiny` / `normal` / `risky`
- **意味**: tiny=軽微単一ファイル / normal=通常機能 / risky=release/migration/state model 変更等

### WorkItemRisk

- **値域（enum）**: `low` / `medium` / `high`

## 集約（Aggregate）

### WorkItem 集約

- **集約ルート**: WorkItem
- **境界**: 1 つの work-item.md ファイル（frontmatter + 本文）
- **不変条件**:
  - frontmatter が必須キー（id/status/size/risk/assigned/dependencies）を過不足なく持つ
  - status/size/risk が各 enum の値である
  - 本文が必須 6 セクションを持つ

## ドメインサービス

本 Unit は静的テンプレートのため実行時ドメインサービスは持たない。テンプレートの妥当性（frontmatter キー/enum・本文見出し）は Phase 2 の検証ステップ（構造検証）で担保する。

## ユビキタス言語

- **テンプレート**: 成果物を作成する前の雛形。define フローが値を埋めて実ファイルを生成する（生成実装は Phase 3）
- **frontmatter**: work item 個別状態を保持する YAML ヘッダ（cycle state = state.json とは別レイヤ）
- **必須 6 セクション**: work item 本文の固定見出し（Goal/Scope/Acceptance Criteria/Traceability/Size / Risk/Dependencies）
- **placeholder**: テンプレート内の差し替え対象（`{{...}}` 記法で統一）

## 不明点と質問（設計中に記録）

[Question] intent.md テンプレートの具体構成は data-model に確定例示があるか。
[Answer] data-model §4 は work item 中心で intent の確定例示は持たない。Unit 定義の「目的 / スコープ（含む・含まない）/ 受け入れ基準等」と workflow.md §3.1 の define 手順（intent 定義）に整合する構成を論理設計で確定する（v2 intent_template との整合も意識）。

[Question] placeholder 記法は `{{...}}` とコメントのどちらに統一するか。
[Answer] 値部分は `{{...}}`、enum 候補や記述ガイドは Markdown コメント / 箇条書き注記で明示する（論理設計で確定）。
