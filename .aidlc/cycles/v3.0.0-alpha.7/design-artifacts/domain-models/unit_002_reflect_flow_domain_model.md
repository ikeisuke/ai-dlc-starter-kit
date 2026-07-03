# ドメインモデル: Unit 002 reflect フロー実装

## 概要

v3 の reflect（振り返り）ドメインをモデル化する。サイクル完了後の材料から KPT を抽出し、Try を改善 Issue 化、`reflect.md` 記録と `journal.md` 追記を行う手順ベースフロー。

**重要**: 本ドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/SKILL.md` | reflect の「予約」記述箇所（description 8-9 行 / 位置づけ 17-21 行 / コマンド表 45 行 / パス解決 117 行）、retrospective エイリアス（68 行）、express ラッパ（72-81 行）の実態を把握し更新点を確定 |
| `skills/aidlc-v3/steps/release.md` | reflect.md が踏襲すべき記法（位置づけ前文 / 目的 / フロー全体 / パス解決 / Step 0 cycle 解決 / 各 Step の exit code 分岐 / journal 追記 / gh 分岐）の参照 |
| `docs/v3/workflow.md §3.4` | reflect Step 1–4 の正本仕様、core から外す項目 |
| `docs/v3/data-model.md §4・§5.1・§10` | frontmatter 必須キー（reason 専用キーなし）/ complete 状態定義（reflect 前提）/ 成果物保存先（reflect.md + Issue） |
| `skills/aidlc-v3/scripts/work-item-status.sh` | work item status 読取（frontmatter 生パース委譲先 / status 専用、理由は読めない） |

### (b) 設計時に意識すべき挙動

- reflect は **任意実行**で、`complete` 状態（`release.merge_approved=true` + PR merged）でのみ実行可（`data-model.md §5.1`）。Step 0 で前提確認が必要。
- reflect は **state を変更しない**（`state-write.sh` を呼ばない / read + 成果物生成のみ）。明示の承認ゲートを持たない（Step 2 人間編集 / Step 3 Issue 化確認）。
- frontmatter に withdrawn/blocked の **理由専用キーは存在しない**（`data-model.md §4`）。理由は非構造データとして本文/journal/release から抽出。
- work item status 読取は `work-item-status.sh` 経由（frontmatter 生パース禁止）。
- reflect Issue の **必須ラベルは SoT 未定義**（ラベル検証を導入しない）。
- gh 不可用時: complete 判定（PR merged 確認）は停止/手動確認分岐、Issue 化は skip-continue（reflect.md 記録は継続）。
- journal.md 追記は専用スクリプトなし（当日日付見出し配下に直接箇条書き追記 / release.md・develop.md パターン）。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 判定 |
|------|------------------|------|
| `extend`（release.md の手順記法を踏襲した新規 steps/reflect.md + template + 静的検証テスト） | v3 既存ステップと記法統一、レビュー反復削減。重スクリプトなしで手順ベース | **採用** |
| `new-script`（reflect 専用の重ロジックスクリプトを新設） | core から外す方針（重い補助ロジック不採用）に反する。NFR「手順ベース」逸脱 | 却下 |
| `reuse-v2`（v2 retrospective スキルを流用） | v3 は v2 と分離（別サブシステム）。upstream mirror 等 v2 固有機能を持ち込むと core 肥大 | 却下 |

## エンティティ / 値オブジェクト

### ReflectMaterial（振り返り材料 / 値オブジェクト）

- **属性**:
  - `journal_entries`: `journal.md` の当該サイクル記録
  - `release_result`: `release.md` の結果
  - `incomplete_items`: work item のうち `withdrawn` / `blocked` のもの（status は `work-item-status.sh`、理由は本文/journal/release から非構造抽出、なければ `unknown`）
- **不変性**: 収集時点のスナップショット（read-only）。

### KPT（値オブジェクト）

- **属性**: `keep`: string[] / `problem`: string[] / `try`: string[]
- **生成規則**: AI が材料から提案 → 人間が確認・編集（Step 2）。reflect.md テンプレートの章に対応。

### TryAction（Try 項目 / 値オブジェクト）

- **属性**: `description`: string / `issue_decision`: `create` | `skip` / `issue_ref`: URL/番号 | `PENDING_MANUAL` | `none`
- **振る舞い**: Step 3 で人間が Issue 化可否を判断。`create` かつ gh 可用 → Issue 起票し `issue_ref` 確定。`skip` → `none`。gh 不可用 → `PENDING_MANUAL`。

## ドメインサービス

### ReflectMaterialCollector（材料収集 / Step 1）

- **責務**: journal.md / release.md / 未完了 work item を読み込み `ReflectMaterial` を構築。status は `work-item-status.sh` 委譲、理由は非構造抽出。

### KptExtractor（KPT 抽出 / Step 2）

- **責務**: `ReflectMaterial` から KPT を AI 提案 → 人間編集 → `reflect.md` に記録。

### TryActioner（行動化 / Step 3）

- **責務**: 各 Try について Issue 化可否を確認。**承認しない→Issue 作らない / 一部承認→必要分のみ / gh 不可→skip + reflect.md 継続**。Issue 起票は `gh issue create --body-file`（機密マスク）、URL から番号確定、reflect.md の Issue リンク章に記録。必須ラベル検証は行わない。

### ReflectCompleter（完了 / Step 4）

- **責務**: `journal.md` の当日日付見出し配下に `reflect completed: <cycle>` 相当を追記（直接追記）。state は変更しない。

## 成果物保存先契約（data-model.md §10）

- **必須成果物**: `.aidlc/cycles/<cycle>/reflect.md`
- **任意成果物**: 改善 Issue（Try の Issue 化分）
- trace chain: `... → release.md → reflect.md → 次サイクル define input`

## core から外す（実装しない）項目

**workflow.md §3.4 末尾「core から外す（廃止）」= 4 項目**（SoT 準拠 / Unit 責務 002-reflect-flow.md:14 と一致）。reflect.md 手順 / テンプレートに「実装しない」と明示する:

- upstream mirror（starter kit 固有）
- cap 管理
- dialog token
- aggregate retrospective issue（集約振り返り Issue）

**Unit 境界による追加スコープ外**（002-reflect-flow.md:19 / §3.4 の 4 項目とは帰属が異なる）:

- 推定値検出ガード等の重い振り返り補助ロジック（core 外として実装しない。§3.4「core から外す」とは別根拠）

## ユビキタス言語

- **KPT**: Keep（続けること）/ Problem（課題）/ Try（次に試すこと）。
- **complete 状態**: `release.merge_approved=true` かつ PR merged。reflect 実行の前提（data-model.md §5.1）。
- **行動化**: Try を改善 Issue として起票し次サイクルの入力にすること。
- **skip-continue**: gh 不可用時に Issue 化のみ skip し reflect.md 記録は継続する挙動（complete 判定の取得不能とは区別）。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 2 で指摘0件 / SoT 整合確認済み）
[Answer] -
