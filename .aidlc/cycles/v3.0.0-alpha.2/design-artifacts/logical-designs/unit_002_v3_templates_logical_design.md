# 論理設計: Unit 002 v3 成果物テンプレート

## 概要

`skills/aidlc-v3/templates/` に置く 3 テンプレート（intent.md / work-item.md / journal.md）のファイル構造・placeholder 記法・必須要素を定義する。設計正本は `docs/v3/data-model.md` §4（work item）・§7（journal）。

**重要**: この論理設計では**コードは書かず**、ファイル構造と必須要素の定義のみを行う。実テンプレートは Phase 2 で作成する。

## ステップ0: 事前コード読込み（新規テンプレート作成のため参照基盤の確認）

本 Unit は新規テンプレートを作成し改修対象の既存実装が無いため、本セクションは正本・規約の確認として実施する（3 観点の詳細はドメインモデル `design-artifacts/domain-models/unit_002_v3_templates_domain_model.md` のステップ0 に記載）。

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `docs/v3/data-model.md` §4 | work item frontmatter（必須キー・enum）+ 本文必須 6 セクションの正本確認 |
| `docs/v3/data-model.md` §7 | journal 形式の正本確認 |
| 既存 v2 `templates/`（intent_template 等） | placeholder 記法（`{{CYCLE}}` 等）の整合確認 |

### (b) 設計時に意識すべき挙動

- frontmatter の enum・キー名は SoT（data-model §4）と完全一致
- placeholder は `{{...}}` で統一、enum 候補はコメントで明示
- markdownlint 通過（見出し階層・空行・リスト）
- `skills/**` 配下で `skills/aidlc/` プロジェクトルート相対参照を含めない（CI 構造チェック）

### (c) 既存実装に基づく代替案検討

- **雛形ソース**: data-model §4.2 確定例示を雛形化（採用） vs 独自構成（却下: SoT 逸脱）
- **placeholder**: `{{...}}` 統一（採用 / v2 整合） vs 角括弧 `[...]`（却下: v2 と不整合）

## アーキテクチャパターン

**静的ドキュメントテンプレート**（実行ロジックなし）。3 ファイルは独立し、相互依存はない。各ファイルは data-model の対応セクションの「確定例示」を雛形化したもの。

## コンポーネント構成

```text
skills/aidlc-v3/templates/
├── intent.md       (Intent 雛形: 目的/スコープ/受け入れ基準)
├── work-item.md    (work item 雛形: frontmatter + 本文6セクション)
└── journal.md      (journal 雛形: タイトル + 日付見出し + 箇条書き)
```

## ファイル形式（テンプレート構造定義）

### work-item.md

#### frontmatter（YAML / data-model §4.1 準拠）

| キー | 型 | 既定値（テンプレート） | enum 候補（コメント明示） |
|------|---|----------------------|--------------------------|
| `id` | string | `"{{id}}"`（**引用符付き**） | 3 桁ゼロ埋め推奨。SoT は `id: "001"`（quoted string）のため placeholder も引用符で囲み、未引用展開で YAML 数値化・parse 不整合になるのを防ぐ |
| `status` | enum | `pending` | `pending` / `in_progress` / `blocked` / `done` / `withdrawn` |
| `size` | enum | `normal` | `tiny` / `normal` / `risky` |
| `risk` | enum | `medium` | `low` / `medium` / `high` |
| `assigned` | string or null | `null` | 担当者 / 未割当は `null` |
| `dependencies` | array | `[]` | 依存 work item ID のリスト（空配列可） |

#### 本文必須セクション（見出し / data-model §4.2 準拠）

固定見出し（順序固定）:

1. `## Goal` — 何を達成するか
2. `## Scope` — 含むもの / 含まないもの
3. `## Acceptance Criteria` — チェックボックス形式の条件
4. `## Traceability` — Intent refs / Acceptance refs / Verification / Release note required
5. `## Size / Risk` — Size / Risk / Reason（**単一見出し**。`Size`/`Risk` を別見出しにしない）
6. `## Dependencies` — 依存 work item（なければ `none`）

任意セクション: `## Implementation Notes`

### journal.md（data-model §7 準拠）

```text
# Journal: {{cycle}}

## {{YYYY-MM-DD}}

- 作業証跡を箇条書きで追記
```

- トップレベルタイトル `# Journal: {{cycle}}`
- 日付見出し `## YYYY-MM-DD`（追記時に追加）
- 配下に箇条書き

### intent.md

v3 Intent 構成（workflow.md §3.1 define / Unit 定義に整合）:

- `# Intent: {{cycle}}`
- `## 目的` — なぜこのサイクルが必要か
- `## スコープ` — `### 含むもの` / `### 含まないもの`
- `## 受け入れ基準` — チェックボックス形式
- `## 制約・前提`（任意）

## 処理フロー概要

本 Unit に実行フローはない（静的テンプレート）。テンプレートの妥当性は Phase 2 の構造検証で担保する:

### テンプレート構造検証フロー（Phase 2）

1. work-item.md の frontmatter を YAML として解釈し（`id` 等の placeholder は引用符付き文字列のため安全に parse 可能）、必須キー集合が `id/status/size/risk/assigned/dependencies` と過不足なく一致
2. frontmatter の status/size/risk の値または候補列挙が SoT の enum と一致
3. 本文に必須 6 見出し（`## Goal` 〜 `## Dependencies`）が存在
4. journal.md にタイトル `# Journal:` + 日付見出し（`##` レベル）の形式が存在
5. intent.md に 目的 / スコープ（含む・含まない）/ 受け入れ基準 の見出しが存在
6. 3 ファイルが markdownlint を通過

## 非機能要件（NFR）への対応

### 整合性

- **要件**: frontmatter キー・enum 値が SoT と一致（Unit NFR）
- **対応策**: data-model §4.2 確定例示を雛形化し、enum 候補をコメントで明示。Phase 2 構造検証で一致を確認

### 共存（v2 非影響）

- **要件**: 成果物は `skills/aidlc-v3/templates/` に限定（Unit NFR）
- **対応策**: 新規ディレクトリのみ。`skills/aidlc/` 不変

### lint

- **要件**: markdownlint 通過（Unit NFR）
- **対応策**: 見出し階層・空行・リスト記法を markdownlint 準拠で記述

## 技術選定

- **形式**: Markdown（work-item.md は YAML frontmatter + Markdown 本文）
- **placeholder**: `{{...}}` 記法（v2 テンプレートと整合）

## 実装上の注意事項

- enum 値の表記揺れ（大小文字・送り仮名）を避け SoT と完全一致
- `Size / Risk` は単一見出し（`Size` と `Risk` を分割しない）
- `skills/**` で `skills/aidlc/` プロジェクトルート相対参照を書かない（CI 構造チェック）

## 不明点と質問（設計中に記録）

[Question] intent.md の見出し構成は確定例示があるか。
[Answer] data-model に intent 確定例示はないため、Unit 定義（目的/スコープ含む・含まない/受け入れ基準）と workflow.md §3.1 に整合する構成で確定（上記「intent.md」節）。

[Question] work item の frontmatter の既定値はどうするか。
[Answer] テンプレートとして自然な既定（status=pending / size=normal / risk=medium / assigned=null / dependencies=[]）を置き、enum 候補をコメント明示する（data-model §4.2 例示に整合）。
