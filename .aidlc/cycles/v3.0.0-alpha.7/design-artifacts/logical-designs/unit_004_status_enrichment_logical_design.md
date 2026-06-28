# 論理設計: Unit 004 status 出力拡充

## 概要

`skills/aidlc-v3/steps/status.md` を skeleton から実行手順に拡充し、各出力フィールドの導出手順・Step 0 前提確認・§3.5 フィールド整合を規定する。あわせて静的検証テスト `test-status.sh` を追加する。status は読み取り専用。

**重要**: 本論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体コードは Phase 2 で作成する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/steps/status.md` | 現状仕様・stale 位置づけ・更新点 |
| `docs/v3/workflow.md §3.5` / `data-model.md §5・§6` | 出力構造正本 / 導出規則 / 未対応 schema |
| `skills/aidlc-v3/scripts/state-validate.sh` / `state-read.sh` / `work-item-status.sh` / `lib/frontmatter.sh` | Step 0・フィールド導出の wrap 契約・委譲先関数 |
| `skills/aidlc-v3/scripts/tests/test-reflect-flow.sh` / `test-doctor.sh` | 静的検証ハーネス方式 |
| `skills/aidlc-v3/scripts/doctor.sh` | cycle パス安全検証の基準 |

### (b) 設計時に意識すべき挙動

- status はスクリプト不在の手順ベース。state-read.sh は schema 非検証 → Step 0 で state-validate.sh の status:valid のみ進行。
- 未対応 schema warn は復帰不可（進めず診断）。current_cycle はパス安全検証（doctor 同基準）。
- frontmatter 生パース禁止 → work-item-status.sh / lib/frontmatter.sh（fm_extract_block + fm_scalar）委譲。
- launch prefix は `/aidlc-v3`（skeleton 統一）。§3.5 の `/aidlc` 差は documented。

### (c) 既存実装に基づく代替案検討

| 方針 | 適合性 | 判定 |
|------|-------|------|
| `enrich-spec`: status.md を実行手順に拡充 + 静的検証テスト | 既存 step 記法統一・手順ベース整合 | **採用** |
| `new-script`: status.sh 新設 | スコープ超過・既存は手順ベース | 却下 |

## アーキテクチャパターン

- **既存手順ファイル方式の拡充**（手順 markdown + 静的検証テスト）。新規スクリプトを導入しない（status は AI 手順実行）。

## コンポーネント構成

```text
skills/aidlc-v3/
├── steps/status.md             [変更] skeleton→実行手順（Step 0 前提 / フィールド導出 / §3.5 整合）
└── scripts/tests/test-status.sh [新規] §3.5 整合の静的検証
```

### コンポーネント詳細

#### `steps/status.md`（変更）

- **責務**: status の出力仕様 + 実行手順（Step 0 前提確認 + 各フィールド導出 + 出力例）。
- **依存**: `state-validate.sh`（schema 検証）/ `state-read.sh`（cycle・state）/ `work-item-status.sh`（status）/ `lib/frontmatter.sh`（size/risk）/ `data-model.md §5`（導出規則 SoT 参照）。
- **副作用**: なし（読み取り専用 / state-write.sh を呼ばない）。

#### `scripts/tests/test-status.sh`（新規）

- **責務**: status.md の §3.5 フィールド整合・No active cycle 案内・委譲・状態非変更・stale 注記なしを静的検証（自己完結 / jq 前提 / ネットワーク非依存）。

## 手順インターフェース設計（status.md）

### Step 0: 前提確認

| 状態 | 出力 | Suggested command |
|------|------|------------------|
| `.aidlc/state.json` 不在 | `No active cycle found.` | `/aidlc-v3 define` |
| 存在 + `state-validate.sh` rc1（破損/schema 不正）/ rc2（読取不能）/ `status:warn:unsupported-schema-version:*`（未対応 schema / 復帰不可） | `state read error` | `/aidlc-v3 doctor` |
| 存在 + `status:valid` + `current_cycle` 空 / 取得失敗 / 不正識別子（`..` 含む or `^[A-Za-z0-9][A-Za-z0-9._-]*$` 不一致） | `state read error` | `/aidlc-v3 doctor` |
| 存在 + `status:valid` + `current_cycle` 正常だが **`.aidlc/cycles/<cycle>` ディレクトリ不在**（指摘#1 / doctor `[cycle]` 同基準） | `state read error`（cycle ディレクトリ未解決） | `/aidlc-v3 doctor` |
| 存在 + `status:valid` + `current_cycle` 正常 + cycle dir 存在 | active cycle status 構成へ | （フェーズ依存） |

### active cycle 時の出力フィールド（§3.5 正本 / 順序固定）

| フィールド | 導出 |
|-----------|------|
| `Cycle` | `state-read.sh current_cycle` |
| `Phase` | `data-model.md §5` の導出規則（再定義せず参照）+ 導出根拠併記 |
| `Current work item` | 進行中 work item（id + size/risk/status）。status は `work-item-status.sh --read`、size/risk は `fm_extract_block` + `fm_scalar` |
| `Completed` | done / withdrawn の件数・内訳 |
| `Blocked` | blocked work item（なければ `none`） |
| `Remaining` | 未完了 work item |
| `Suggested command` | 導出フェーズに対応（`/aidlc-v3 develop` 等） |

出力フォーマットは `workflow.md §3.5` のフィールド構造・順序・`No active cycle found.` 文言を正本一致。launch prefix のみ skeleton 統一の `/aidlc-v3`。

### frontmatter 安全境界（重要）

- work item status → `scripts/work-item-status.sh --read <path>`（status 専用）。**exit 0 の stdout は `status:<value>` 形式**（指摘#2 / 既存 release.md / develop.md / reflect.md と同契約）。表示（`Current work item` の `status: ...`）・集計（Completed / Blocked / Remaining）では **prefix `status:` を剥がした `<value>` のみ**を使用する（stdout 全体を使うと `status: status:in_progress` の §3.5 不一致になる）。
- size / risk → `lib/frontmatter.sh` を source し `fm=$(fm_extract_block <file>)` → `fm_scalar "$fm" size '[A-Za-z_]'` / `fm_scalar "$fm" risk '[A-Za-z_]'`。専用 `fm_size`/`fm_risk` は実在しないため使わない。enum（`tiny|normal|risky` / `low|medium|high`）を表示前に検証。
- status.md に直接 grep/sed/awk の frontmatter パースを書かない（RFC P4）。

## test-status.sh 検証契約（静的）

計画「変更2」の検証項目 1–11 を実装:

1. bash -n + shellcheck / 2. status.md 存在 / 3. 7 フィールドが §3.5 順序で記載 / 4. No active cycle 案内 exact string / 5. §3.5 ブロックとのフィールド構造 exact 比較（prefix 差を除く）/ 6. launch prefix `/aidlc-v3` 統一（`/aidlc ` 単独混在なし）/ 7. frontmatter 委譲（work-item-status.sh / fm_extract_block / fm_scalar 参照・生パースなし / **`status:<value>` から `<value>` のみ使用の契約記載**（指摘#2））/ 8. 状態非変更（コマンド位置の state-write.sh なし）/ 9. Step 0 分離（不在→No active cycle / 読取失敗・schema 不正・**cycle dir 不在**（指摘#1）→診断案内）/ 10. data-model §5 SoT 参照 / 11. stale 注記なし（skeleton / Phase 3）。

## 非機能要件（NFR）への対応

- **パフォーマンス**: 読み取り専用・軽量（手順ベース）。
- **セキュリティ**: current_cycle パス安全検証（doctor 同基準）。出力に機密情報を含めない。
- **スケーラビリティ**: work item 数に比例した表示。
- **可用性**: state.json 不在は No active cycle 案内、破損/未対応 schema は doctor 案内。

## 技術選定

- **言語**: Markdown 手順 + bash（テスト）。
- **テスト**: 自己完結シェル + jq（既存方式）。新規ライブラリなし。

## 実装上の注意事項

- §3.5 出力例のフィールド名・順序・`No active cycle found.` を正本一致。prefix は `/aidlc-v3` 統一（SKILL.md コマンド表記について準拠）。
- フェーズ導出規則を再定義しない（data-model §5）。doctor `[phase]` 導出 code 化は対象外（#741）。
- frontmatter 生パース禁止。current_cycle パス安全検証。
- test-isolation cd-guard / コメント内 `rm -rf` 文字列回避 / コマンド置換禁止（#697）。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 5 指摘0件 / SoT・公開関数を codex 実読検証済み）
[Answer] -
