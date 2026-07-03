# ドメインモデル: Unit 004 status 出力拡充

## 概要

`/aidlc-v3 status` の出力（現在地表示）を `docs/v3/workflow.md §3.5` のフィールド構造に揃え、各フィールドの導出手順を明記する手順ベース仕様としてモデル化する。status は読み取り専用（状態変更なし）。

**重要**: 本ドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/steps/status.md` | 現状の出力仕様（§3.5 と一致）・stale な skeleton 位置づけ・更新点の把握 |
| `docs/v3/workflow.md §3.5` | 出力フィールド構造（7 フィールド + No active cycle 案内）の正本 |
| `docs/v3/data-model.md §5・§6` | フェーズ導出規則（再定義しない参照先）/ 未対応 schema（復帰不可 WARN）の扱い |
| `skills/aidlc-v3/scripts/state-validate.sh` | Step 0 schema 検証の wrap 契約（status:valid / warn:* / exit 1/2） |
| `skills/aidlc-v3/scripts/state-read.sh` | cycle / state フィールド読取（schema 妥当性は検証しない点） |
| `skills/aidlc-v3/scripts/work-item-status.sh` | work item status 読取（frontmatter 生パース禁止の委譲先） |
| `skills/aidlc-v3/scripts/lib/frontmatter.sh` | size/risk 読取の公開関数（`fm_extract_block` / `fm_scalar`。専用 `fm_size`/`fm_risk` は不在） |
| `skills/aidlc-v3/scripts/doctor.sh` | cycle 識別子パス安全検証の基準（Step 0 で同基準を適用） |

### (b) 設計時に意識すべき挙動

- status はスクリプトを持たず、AI エージェントが state-read + frontmatter を読んで出力を構成する手順ベース。
- `state-read.sh` は schema 妥当性を検証しない（型不正でもキー存在で exit 0 になり得る）→ Step 0 で `state-validate.sh` の `status:valid` のみ進行。
- 未対応 schema（`status:warn:unsupported-schema-version:*`）は復帰不可 WARN（data-model §6）→ 進めず診断案内。
- `current_cycle` はパス安全検証（doctor と同基準 `^[A-Za-z0-9][A-Za-z0-9._-]*$` + `..` 禁止）が必要（`.aidlc/cycles/<cycle>` 境界外参照防止）。
- frontmatter 生パース禁止 → status は `work-item-status.sh`（status）/ `lib/frontmatter.sh`（size/risk）委譲。
- launch prefix は `/aidlc-v3`（skeleton 統一 / SKILL.md「コマンド表記について」/ 既存 step と整合 / Phase 7 で `/aidlc` 統一）。§3.5 の `/aidlc` 表記との差は documented skeleton↔end-state 差。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 判定 |
|------|------------------|------|
| `enrich-spec`: status.md を skeleton→実行手順に拡充 + 静的検証テスト追加 | release.md/reflect.md/doctor.md と記法統一・手順ベース（status はスクリプトなし）に整合 | **採用** |
| `new-script`: status.sh を新設して出力生成 | 既存 status は手順ベース・スクリプト不在。新規スクリプトは Unit スコープ超過 | 却下 |

## エンティティ / 値オブジェクト

### StatusReport（現在地レポート / 集約）

- **集約ルート**: StatusReport
- **含まれる要素**: `Cycle` / `Phase`（導出根拠付き）/ `CurrentWorkItem` / `Completed` / `Blocked` / `Remaining` / `SuggestedCommand`
- **不変条件**: status は読み取り専用（state を変更しない）。出力フィールドの構造・順序は `workflow.md §3.5` を正本とする。
- **生成前提**: `complete` 等のフェーズ導出は `data-model.md §5` の規則に従う（再定義しない）。

### WorkItemView（work item 表示 / 値オブジェクト）

- **属性**: `id` / `status`（work-item-status.sh 経由）/ `size`・`risk`（lib/frontmatter.sh 経由）
- **不変性**: 読取時点のスナップショット。frontmatter 生パースをしない。

## ドメインサービス

### PhaseDeriver（フェーズ導出 / 参照のみ）

- **責務**: `data-model.md §5` の規則に従い state.json + work item frontmatter からフェーズを導出し、導出根拠を併記する。**導出規則を再定義しない**（SoT 参照）。

### StatusPrecondition（Step 0 前提確認）

- **責務**: state.json 存在判定 → schema 検証（state-validate.sh）→ current_cycle 取得 + 非空 string + パス安全検証。
- **分岐**:
  - state.json 不在 → `No active cycle found.` + `Suggested command: /aidlc-v3 define`
  - 存在 + schema 不正 / 未対応 schema / 読取失敗 / current_cycle 不正（空・パストラバーサル）/ **`.aidlc/cycles/<cycle>` ディレクトリ不在**（doctor `[cycle]` 同基準 / 指摘#1） → `state read error` + `Suggested command: /aidlc-v3 doctor`
  - `status:valid` + current_cycle 正常 + cycle dir 存在 → active cycle status 構成へ

### WorkItemReader（work item 読取 / 安全境界委譲）

- **責務**: work item status は `work-item-status.sh --read`、size/risk は `fm_extract_block` + `fm_scalar` で読む。enum 妥当性（`tiny|normal|risky` / `low|medium|high`）を表示前に検証。

## ユビキタス言語

- **No active cycle**: state.json 不在（未開始）。`/aidlc-v3 define` 案内。
- **state read error**: state.json 存在するが schema 不正 / 未対応 schema / 読取失敗 / current_cycle 不正。`/aidlc-v3 doctor` 案内（No active cycle とは区別）。
- **導出根拠**: Phase 表示に併記する導出理由（例: `define_completed=true, 2/4 items remaining`）。
- **skeleton 統一 prefix**: `/aidlc-v3`（現状の v2 共存表面 / Phase 7 で `/aidlc` 統一）。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 5 で指摘0件 / SoT・公開関数を codex 実読検証）
[Answer] -
