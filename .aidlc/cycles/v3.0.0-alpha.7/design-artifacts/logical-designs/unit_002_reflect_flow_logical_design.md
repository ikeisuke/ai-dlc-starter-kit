# 論理設計: Unit 002 reflect フロー実装

## 概要

reflect フローを v3 既存ステップ記法（`steps/release.md`）に準拠した手順ファイル + テンプレート + 静的検証テスト + SKILL.md 更新で実装する論理設計。

**重要**: 本論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体コードは Phase 2 で作成する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/SKILL.md` | reflect 予約記述（8-9 / 17-21 / 45 / 117 行）・retrospective エイリアス（68 行）・express（72-81 行）の更新点確定 |
| `skills/aidlc-v3/steps/release.md` | 構成・パス解決・Step 0 cycle 解決・exit code 分岐・journal 追記・gh 分岐の記法参照 |
| `skills/aidlc-v3/templates/release.md` / `templates/journal.md` | テンプレ記法（`# <title>: {{cycle}}` + HTML コメント解説 + プレースホルダ） |
| `skills/aidlc-v3/scripts/tests/test-release-flow.sh` | 静的検証ハーネス雛形（jq 前提 / pass-fail カウンタ / 構造・契約検証） |
| `docs/v3/workflow.md §3.4` / `data-model.md §4・§5.1・§10` | reflect 仕様 / complete 前提 / 成果物保存先 |

### (b) 設計時に意識すべき挙動

- reflect は state を変更しない（`state-write.sh` 不使用）。complete 前提（`release.merge_approved` + PR merged）でのみ実行可。
- journal.md 追記は専用スクリプトなし（直接追記）。work item status は `work-item-status.sh` 経由（frontmatter 生パース禁止）、理由は非構造抽出。
- gh 分岐: complete 判定の PR merged 確認は停止/手動確認、Issue 化は skip-continue。
- SKILL.md は reflect を予約→実装済みに、doctor は予約のまま（混在更新に注意）。express に reflect を加えない。

### (c) 既存実装に基づく代替案検討

| 方針 | 適合性 | 判定 |
|------|-------|------|
| `extend`: release.md 記法準拠の手順 + template + 静的検証テスト | v3 記法統一・最小侵襲・レビュー反復削減 | **採用** |
| `new-script`: reflect 専用重ロジック | core から外す方針に反する | 却下 |

## アーキテクチャパターン

- **既存 v3 手順ファイル方式の踏襲**（手順 markdown + テンプレート + 静的検証テスト）。新規アーキテクチャ・重スクリプトは導入しない。

## コンポーネント構成

```text
skills/aidlc-v3/
├── steps/reflect.md            [新規] Step 0–4 手順本体（release.md 構成踏襲）
├── templates/reflect.md        [新規] Keep/Problem/Try/Issue リンク章立て
├── SKILL.md                    [変更] reflect を予約→実装済みに（doctor は予約維持）
└── scripts/tests/
    └── test-reflect-flow.sh    [新規] 静的構造・契約検証（test-release-flow.sh 方式）
```

### コンポーネント詳細

#### `steps/reflect.md`（新規）

- **責務**: reflect Step 0–4 の手順本体。
- **依存**: `scripts/state-read.sh`（cycle / release.merge_approved / pr_number）、`scripts/work-item-status.sh`（status 読取）、`gh`（Issue 起票 / PR merged 確認）、`templates/reflect.md`、`docs/v3/workflow.md §3.4`（SoT 参照）。
- **公開インターフェース**: `/aidlc-v3 reflect`（および `retrospective` エイリアス）の手順エントリ。

#### `templates/reflect.md`（新規）

- **責務**: reflect.md 成果物のテンプレート。
- **構成**: `# Reflect: {{cycle}}` + HTML コメント（生成タイミング・章立て解説）+ `## Keep` / `## Problem` / `## Try` / `## Issue リンク`。

#### `SKILL.md`（変更）

- **責務**: ルーティング骨組み。reflect を実装済みに反映。
- **変更点**:
  - description（8-9 行）/ 位置づけ（17-21 行）/ コマンド表（45 行）で reflect を `steps/reflect.md` 実在に更新。doctor は予約維持。
  - パス解決の **steps 列挙（117 行）に `reflect.md` 追加**、かつ **templates 列挙（116 行）に `reflect.md` 追加**（指摘#3: テンプレ実体とパス解決の整合）。
  - **フェーズコマンド見出し（38 行「状態を進行させ、承認ゲートを持つ」）の中立化**（指摘#1: reflect は state 非変更・明示ゲートなしで見出しと矛盾）。見出しを「フェーズコマンド」程度に中立化し、reflect が state 非変更・Step 2/3 人間確認である旨は reflect.md 手順側に明記する。
  - retrospective エイリアス整合・express 非包含維持。

#### `scripts/tests/test-reflect-flow.sh`（新規）

- **責務**: reflect 成果物の静的構造・契約検証（自己完結 / jq 前提 / ネットワーク非依存 / pass-fail カウンタ）。

## スクリプト/手順インターフェース設計

### steps/reflect.md の Step 契約

| Step | 入力 | 処理 | 出力 / 副作用 | 異常系 |
|------|------|------|--------------|--------|
| 0 前提確認 | `state.json` | cycle 解決 + complete 確認（`release.merge_approved`=true / `release.pr_number` / PR merged 実態） | （なし / read のみ） | cycle 不在→案内終了。complete でない→案内終了。PR merged 確認用 gh 不可→停止/手動確認分岐 |
| 1 材料収集 | journal.md / release.md / work item | 3 ソース読込。status は `work-item-status.sh`、理由は非構造抽出（unknown フォールバック） | `ReflectMaterial`（メモリ） | **`release.md` 不在→不整合として停止/明示確認**（complete 前提下の必須成果物欠落 / data-model.md §10）。`journal.md` 不在・理由不足→ unknown/空で継続（指摘#2: 不在扱いを成果物の必須性で分離） |
| 2 KPT 抽出 | 材料 | AI が KPT 提案 → 人間編集 | `reflect.md`（Keep/Problem/Try 章記録） | - |
| 3 行動化 | KPT の Try | Issue 化可否確認（承認しない→作らない / 一部→必要分 / gh 不可→skip） | 改善 Issue（任意）+ reflect.md の Issue リンク章 | gh 不可用→Issue 化 skip + `PENDING_MANUAL` 記録、reflect.md 継続。ラベル検証なし |
| 4 完了 | - | journal.md 当日日付見出し配下に追記 | `journal.md` 追記 | 当日見出しなし→追加 |

### test-reflect-flow.sh の検証契約（grep ベース静的検証）

計画「変更4」の検証項目 1–13 を実装（成果物存在 / Step 0–4 見出し / complete 前提記述 / 材料収集対象 / Try Issue 化 3 分岐 / テンプレ章立て / state 非変更（`state-write.sh` 不呼出）/ SKILL.md reflect 実在参照（steps + templates 列挙）・予約 stale なし / retrospective エイリアス整合・express 非包含 / journal 追記形式 / core から外す **workflow.md §3.4 の 4 項目**明示）。

## データモデル概要

- **reflect.md**: `.aidlc/cycles/<cycle>/reflect.md`（Markdown / Keep・Problem・Try・Issue リンク章）。
- **journal.md 追記**: `## YYYY-MM-DD` 見出し配下に `- reflect completed: <cycle>` 相当の箇条書き。
- **新規 frontmatter キー追加なし**（data-model.md §4 不変）。

## 処理フロー概要

### reflect 実行フロー（complete 状態のサイクル）

1. Step 0: cycle 解決 + complete 前提確認（非 complete → 終了）。
2. Step 1: journal/release/未完了 work item から材料収集。
3. Step 2: KPT を AI 提案 → 人間編集 → reflect.md 記録。
4. Step 3: Try ごとに Issue 化判断 → 起票（任意）→ reflect.md に Issue リンク記録。
5. Step 4: journal.md に reflect 完了を追記。

**関与コンポーネント**: `state-read.sh` / `work-item-status.sh` / `gh` / `templates/reflect.md` / `reflect.md` / `journal.md`

## 非機能要件（NFR）への対応

- **パフォーマンス**: 手順ベース（重スクリプトなし）。
- **セキュリティ**: reflect.md / Issue 本文に機密情報を含めない（review-flow マスク方針準用）。Bash ツール経由コマンド置換禁止（#697）遵守。
- **可用性**: gh 不可用時、Issue 化は skip-continue（reflect.md 記録継続）。complete 判定の PR merged 確認不能時は停止/手動確認。

## 技術選定

- **言語**: Markdown 手順 + bash（テスト）。
- **テスト**: 自己完結シェル + jq（`test-release-flow.sh` 方式）。
- **新規ライブラリ**: なし。

## 実装上の注意事項

- SKILL.md は reflect のみ更新し doctor の予約記述を誤って変更しないこと（混在更新の事故防止）。
- complete 判定（SoT 必須前提）と Issue 化 gh 不可用（任意成果物）で gh 不可用時の扱いを区別する（停止 vs skip-continue）。
- frontmatter 生パース禁止（status は `work-item-status.sh`、理由は非構造抽出）。
- ガイド照合: 終了コード規約 `guides/exit-code-convention.md` と整合（reflect は read + 成果物生成のみ、state 非変更）。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 2 で指摘0件 / SoT 整合確認済み）
[Answer] -
