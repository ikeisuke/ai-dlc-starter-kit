# Unit: Inception progress.md 表記の「ステップ1〜N」統一

## 概要

Inception の進捗管理に関する文書群で混在する「Part 1 / Part 2」章立て表記を、意味の通るステップ表現に修正する。併せて `CHANGELOG.md` に `[2.3.6]` エントリを追加して Unit 001/002/003/004 の変更内容を集約記載する（DR-002）。

## スコープ改訂履歴【重要】

**当初スコープ**（Phase 1 設計着手前）: テンプレート / fixture / 判定仕様 §5.1 の progress.md 参照文言 / step ファイル / task-management.md の全層で「ステップ1〜N」表記に統一。

**現行スコープ**（DR-005 最終決定、2026-04-20）: Phase 1 設計検討時に、DR-003 が指定する 6 ステップ progress.md と判定仕様 §5.1 の 5 checkpoint 構造（step ファイル `01-setup`〜`05-completion` と 1:1 対応）の間に構造ズレが顕在化。patch サイクル（v2.3.6）の予算内では根本整理できないため、本 Unit のスコープを以下に縮小する:

- **実施**: CHANGELOG 集約（DR-002）+ Part ラベル修正（`01-setup.md` / `02-preparation.md` / `index.md` / `task-management.md`）
- **先送り**（次サイクル以降）: テンプレート・fixture・判定仕様の 3 層整合化（DR-003 の再検討を含む）。Unit 003 完了時に GitHub Issue として登録し、minor リリース（v2.4.0）以降で対応

詳細は DR-005（`inception/decisions.md`）を参照。

## 含まれるユーザーストーリー

- ストーリー 2.1: Inception progress.md の進捗テーブル表記が「ステップ1〜N」に統一されている（#565, 表記変更本体）
- ストーリー 2.2: Inception progress.md 命名変更の検証と後方互換が担保される（#565, 検証・互換）

> 注: Story 2.1 と 2.2 は本 Unit の同一 PR 内で一体実装・検証する（差し戻し範囲を限定するため意図的に分割せず、受け入れ基準のみで責務を分離する）。

## 責務（DR-005 選択肢 C 確定版）

- **Part ラベル修正**: 以下のファイルで `Part 1` / `Part 2` 等の章立て表記を適切なステップ表現に修正する:
  - `skills/aidlc/steps/inception/index.md`
  - `skills/aidlc/steps/inception/01-setup.md`
  - `skills/aidlc/steps/inception/02-preparation.md`
  - `skills/aidlc/steps/common/task-management.md`
  - 置換方針: 「Part 1（セットアップ）」→「ステップ1（セットアップ）」等、既存の step ファイル名（`01-setup` / `02-preparation`）と整合する名称へ変更。テンプレートの 6 ステップとの整合は本 Unit では追求しない（DR-005 選択肢 C）
- **CHANGELOG 更新（DR-002）**: `CHANGELOG.md` に `[2.3.6] - <リリース日>` エントリを追加し、Unit 001・002・003・004 の変更内容（#583-A / #583-B / #565 / Draft PR Actions スキップ）をまとめて記載する。Unit 001・002・004 のマージ完了を前提に本 Unit を最後に着手する。
- **バックログ Issue 登録**: 先送りされた残課題（テンプレート 6 ステップ・fixture 5 ステップ・判定仕様 5 checkpoint の 3 層整合化 + DR-003 再検討）を GitHub Issue として登録し、次サイクル以降のバックログに反映する。
- **完了条件**:
  - Part 修正対象 4 ファイル（`index.md` / `01-setup.md` / `02-preparation.md` / `task-management.md`）から `rg "Part [0-9]+"` が 0 ヒット（Unit 境界内のみ、`guides/error-handling.md` は対象外）
  - `CHANGELOG.md` 先頭に `[2.3.6]` エントリが追加され、Unit 001/002/003/004 の変更内容が Added/Changed/Fixed/Removed で記載されている
  - バックログ Issue が作成され、DR-003/DR-005 の参照が含まれている

**本 Unit では変更しない（先送り）**:

- テンプレート（`inception_progress_template.md`）の 6 ステップ構造
- fixture（`verify-inception-recovery.sh`）の 5 ステップ構造
- 判定仕様（`phase-recovery-spec.md §5.1`）の 5 checkpoint + progress.md 参照文言
- `verify-construction-recovery.sh` / `verify-operations-recovery.sh` の Inception fixture 部分
- `04-stories-units.md` / `05-completion.md` の「ステップ N-M」表記（手順書内参照、progress 進捗テーブル文脈ではない）

## 境界

- `phase-recovery-spec.md` の checkpoint 名称（`completion_done` / `setup_done` 等）は変更しない。
- Operations Phase の固定スロット反映手順（Unit 001）や write-history.sh ガード（Unit 002）は扱わない。
- 新しい進捗管理機能の追加（Inception ステップの増減、新規ステップの意味追加）は扱わない。DR-003 に従い 6 ステップ構造の確定はリファクタ範囲と定義する。
- Construction / Operations の progress.md テンプレート（`operations_progress_template.md` 等）は、Inception と独立した命名体系のため本 Unit の対象外。

## 依存関係

### 依存する Unit

- **Unit 001 / 002 / 004（技術的にはコード非依存、運用上は cycle ブランチ上でのコミット先行が必要）**: DR-002 により Unit 003 は CHANGELOG に Unit 001/002/004 の変更内容をまとめて記載する。Unit 001/002/004 が cycle/v2.3.6 ブランチ上でコミット済みでないと、CHANGELOG 記載が暫定的となる。
- **CHANGELOG 集約の既定実行順序（DR-005 最終スコープ反映）**: `Unit 001 → Unit 002 → Unit 004 → Unit 003`。Unit 003 を最後に実施し、先行 3 Unit の変更内容を集約記載する。

> 注: コード編集対象ファイルは Unit 001/002/004 と重複しないため、技術的には並列実装可能。ただし CHANGELOG 集約という運用制約により、上記実行順序を推奨する。

### 外部依存

- なし

## 非機能要件（NFR）【DR-005 最終スコープ反映済み】

- **既存機能非破壊**: Part ラベル置換後も、各 step ファイルの手順・タスクリスト・成果物参照・フェーズ遷移ロジックは不変であること
- **表現一貫性**: 4 ファイル（`index.md` / `01-setup.md` / `02-preparation.md` / `task-management.md`）の置換後表現は、既存 step ファイル名（`01-setup` / `02-preparation`）と意味的に整合していること
- **CHANGELOG フォーマット準拠**: `CHANGELOG.md` の `[2.3.6]` エントリは既存 `[2.3.5]` エントリ（Keep a Changelog 形式）に倣う
- **追跡可能性**: 先送りされた 3 層整合化（テンプレート・fixture・判定仕様）の課題が GitHub Issue としてバックログに登録され、CHANGELOG から Issue へ参照できる
- **後方互換性の扱い**: 既存サイクル（v1.x〜v2.3.5）の `inception/progress.md` を読んでの復帰判定は、本 Unit で判定仕様を変更しないため影響なし（現状維持）

> 注: 当初 NFR の「テンプレートと verify-inception-recovery.sh のフィクスチャ項目名完全一致」は DR-005 により先送り（次サイクル対応）。現行スコープでは両者は現状維持のまま。

## 技術的考慮事項【DR-005 最終スコープ反映済み】

- **本 Unit のスコープ**（実施する）:
  - 「Part 1 / Part 2」章立て表現を、既存 step ファイル名と整合する「ステップ1（セットアップ）」「ステップ2以降（インセプション本体）」等に置換する
  - `CHANGELOG.md` に `[2.3.6]` エントリを追加し、Unit 001/002/003/004 の変更内容を集約記載する（DR-002）
  - 先送り課題を GitHub Issue でバックログ登録する
- **本 Unit のスコープ外**（実施しない、次サイクル対応）:
  - `templates/inception_progress_template.md` の 6 ステップ構造の変更（現状維持）
  - `verify-inception-recovery.sh` の 5 ステップ fixture の 6 ステップ化（現状維持）
  - `phase-recovery-spec.md §5.1` の 5 checkpoint 判定仕様・progress.md 参照文言の更新（現状維持）
  - `verify-construction-recovery.sh` / `verify-operations-recovery.sh` の Inception fixture 部分（現状維持）
  - `04-stories-units.md` / `05-completion.md` の「ステップ N-M」表記（progress 進捗テーブル文脈ではないため現状維持）
  - `session-continuity.md` の旧命名参照（対象記述なし、現状維持）
- **CHANGELOG 追記タイミング**: Unit 001 / 002 / 004 が cycle/v2.3.6 ブランチ上でコミット済みの状態で、Unit 003 の最終作業として実施。フォーマットは既存 `[2.3.5] - 2026-04-18` に倣う

## 関連Issue

- #565

## 実装優先度

Medium

## 見積もり

1 日（DR-002 で CHANGELOG 更新を追加、DR-003 で verify フィクスチャ書き換えが確定したため、当初 0.5〜1 日から 1 日に再評価）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-20
- **完了日**: 2026-04-20
- **担当**: Claude Code (v2.3.6 cycle)
- **エクスプレス適格性**: -
- **適格性理由**: -
- **スコープ履歴**: DR-005 最終決定で選択肢 C（スコープ縮小）を採用。Part ラベル修正 + CHANGELOG 集約 + バックログ Issue #586 登録に限定。テンプレート / fixture / 判定仕様の 3 層整合化は #586 で次サイクル以降対応。
