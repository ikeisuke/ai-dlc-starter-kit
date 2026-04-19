# Unit: Inception progress.md 表記の「ステップ1〜N」統一

## 概要

Inception の進捗管理に関する文書群（テンプレート、step ファイル、参照仕様、task-management.md、verify スクリプトのフィクスチャ）で混在する「Part 1 / Part 2 / ステップ1-5 / 完了処理」表記を「ステップ1〜N」で統一する。`phase-recovery-spec.md` の `completion_done` など checkpoint 名称（意味論ラベル）は変更しない。

## 含まれるユーザーストーリー

- ストーリー 2.1: Inception progress.md の進捗テーブル表記が「ステップ1〜N」に統一されている（#565, 表記変更本体）
- ストーリー 2.2: Inception progress.md 命名変更の検証と後方互換が担保される（#565, 検証・互換）

> 注: Story 2.1 と 2.2 は本 Unit の同一 PR 内で一体実装・検証する（差し戻し範囲を限定するため意図的に分割せず、受け入れ基準のみで責務を分離する）。

## 責務

- **進捗モデル確定（DR-003）**: 現行テンプレートの **6 ステップ構造**（Intent明確化 / 既存コード分析 / ユーザーストーリー作成 / Unit定義 / PRFAQ作成 / Construction用progress.md作成）を正本とし、`verify-inception-recovery.sh` のフィクスチャ生成関数（`gen_progress_md_*`）を 6 ステップに追従更新する。
- `skills/aidlc/templates/inception_progress_template.md` の進捗テーブル項目名を「ステップ1〜N」の最終形に整える。
- 以下のファイルで progress.md 進捗テーブル文脈に現れる旧表記を新表記に更新する:
  - `skills/aidlc/steps/inception/index.md`
  - `skills/aidlc/steps/inception/01-setup.md`
  - `skills/aidlc/steps/inception/02-preparation.md`
  - `skills/aidlc/steps/inception/04-stories-units.md`
  - `skills/aidlc/steps/inception/05-completion.md`
  - `skills/aidlc/steps/common/phase-recovery-spec.md`（progress.md 状態参照文脈のみ、checkpoint 名称は対象外）
  - `skills/aidlc/steps/common/task-management.md`
  - `skills/aidlc/scripts/verify-inception-recovery.sh`（フィクスチャ生成関数）
  - `skills/aidlc/scripts/verify-construction-recovery.sh` / `verify-operations-recovery.sh`（Inception 進捗参照分のみ）
- **CHANGELOG 更新（DR-002）**: `CHANGELOG.md` に `[2.3.6] - <リリース日>` エントリを追加し、Unit 001・002・003・004 の変更内容（#583-A / #583-B / #565 / Draft PR Actions スキップ）をまとめて記載する。Unit 001・002・004 のマージ完了を前提に本 Unit を最後に着手する。
- 完了条件: **progress.md 進捗テーブル文脈**で以下の検索パターンがいずれも 0 ヒットになる。
  - `rg "Part [0-9]+"`（Part 1〜Part 99 網羅）
  - `rg "^\|\s*完了処理"`（テーブル行先頭の「完了処理」）
  - `rg "ステップ[0-9]+-[0-9]+"`（旧「ステップ1-5」表記）
  - checkpoint 名称（`completion_done` 等の意味論ラベル）はヒットしてもよい（対象外）。
- `verify-inception-recovery.sh` の既存シナリオが全て合格する。

## 境界

- `phase-recovery-spec.md` の checkpoint 名称（`completion_done` / `setup_done` 等）は変更しない。
- Operations Phase の固定スロット反映手順（Unit 001）や write-history.sh ガード（Unit 002）は扱わない。
- 新しい進捗管理機能の追加（Inception ステップの増減、新規ステップの意味追加）は扱わない。DR-003 に従い 6 ステップ構造の確定はリファクタ範囲と定義する。
- Construction / Operations の progress.md テンプレート（`operations_progress_template.md` 等）は、Inception と独立した命名体系のため本 Unit の対象外。

## 依存関係

### 依存する Unit

- **Unit 001（技術的にはコード非依存、運用上はマージ先行が必要）**: DR-002 により Unit 003 は CHANGELOG に Unit 001 の変更内容（`operations-release.md §7.6` の固定スロット反映ステップ追加）をまとめて記載する。Unit 001 のマージ完了前に Unit 003 に着手した場合、CHANGELOG 記載が暫定的となり追加コミットが必要になる。
- **Unit 002（技術的にはコード非依存、運用上はマージ先行が必要）**: 同様に DR-002 により Unit 002 の変更内容（write-history.sh ガード実装 + 04-completion.md 禁止記述 + SKILL.md exit 3 追記）を CHANGELOG にまとめて記載するため、Unit 002 のマージ完了前に本 Unit に着手した場合は同じ問題が発生する。

> 注: コード編集対象ファイルは Unit 001 / 002 と重複しないため、技術的には並列実装可能。ただし CHANGELOG 集約という運用制約により、**Construction Phase の実行順序としては Unit 001 → Unit 002 → Unit 003** を推奨する。

### 外部依存

- なし

## 非機能要件（NFR）

- **後方互換性**: `v1.x〜v2.3.5` の既存 `inception/progress.md`（旧命名 `Part` 表記を含む）を読んで復帰判定が動作する（スポット検証必須）。
- **整合性**: テンプレートと `verify-inception-recovery.sh` のフィクスチャ項目名を完全一致させる。
- **保守性**: 変更箇所を step ファイル横断で一括確認できるよう、PR 本文で対象ファイル一覧と変更要約を提示する。

## 技術的考慮事項

- 進捗モデルは DR-003 により 6 ステップ構造で確定済み。verify フィクスチャの 5 ステップ構造を 6 ステップへ書き換え、既存シナリオ（1a / 1b / 4a / 4b / 5 等）の期待値・生成関数（`gen_progress_md_*`）を追従更新する。
- 「Part 1 / Part 2」は主に `01-setup.md` のセクション見出しに存在するため、「ステップ N（セットアップ）」等への置換ポリシーを統一する。
- `phase-recovery-spec.md` §5.1 / §9 の「progress.md『完了処理』進行中」などの記述は、テーブル構造参照である場合のみ追従更新する。判定ロジック本文（checkpoint 名）には触れない。
- `session-continuity.md` は旧命名参照を含まないため対象外（ただし `rg` 検出時は追従）。
- CHANGELOG 追記は Unit 001・002 のマージ完了後に、cycle/v2.3.6 ブランチで Unit 001–003 の変更概要をまとめて記載する。フォーマットは `CHANGELOG.md` の既存エントリ（`[2.3.5] - 2026-04-18`）に倣う。

## 関連Issue

- #565

## 実装優先度

Medium

## 見積もり

1 日（DR-002 で CHANGELOG 更新を追加、DR-003 で verify フィクスチャ書き換えが確定したため、当初 0.5〜1 日から 1 日に再評価）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
