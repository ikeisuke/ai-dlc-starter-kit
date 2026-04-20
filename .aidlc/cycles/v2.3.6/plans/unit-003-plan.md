# Unit 003 実装計画 - Inception Part ラベル修正 + CHANGELOG 集約【DR-005 選択肢 C 確定版】

## Unit 概要

DR-005 選択肢 C 決定（2026-04-20）に基づき、Unit 003 のスコープを以下に縮小する:

1. **Part ラベル修正**: `inception/index.md` / `01-setup.md` / `02-preparation.md` / `common/task-management.md` の `Part 1` / `Part 2` 章立て表現を、既存 step ファイル名（`01-setup` / `02-preparation`）と整合する「ステップ1（セットアップ）」「ステップ2以降（インセプション本体）」等に修正する
2. **CHANGELOG 集約（DR-002）**: `CHANGELOG.md` に `[2.3.6] - 2026-04-20` エントリを追加し、Unit 001/002/003/004 の変更内容をまとめて記載する
3. **バックログ Issue 登録**: 先送りされた残課題（テンプレート 6 ステップ・fixture 5 ステップ・判定仕様 5 checkpoint の整合、DR-003 再検討）を GitHub Issue で登録する

## スコープ改訂の経緯

**当初計画（Phase 1 設計着手前）**: テンプレート・fixture・判定仕様・step ファイルの全層で 6 ステップ表記に統一する大規模リファクタ。

**Phase 1 設計検討時の発見**: 6 ステップ progress.md（DR-003 正本）と判定仕様 §5.1 の 5 checkpoint 構造（`setup_done`〜`completion_done` が step ファイル `01-setup`〜`05-completion` と 1:1 対応）との構造ズレが顕在化。

- 6 ステップ progress にはサイクル作成（`01-setup`）・インセプション準備（`02-preparation`）に対応する行がない
- §5.1.1「progress.md のステップ1完了マーク」は 5 ステップ構造前提で書かれている（6 ステップではステップ1＝Intent明確化 ≠ 01-setup のサイクル作成）
- §5.1.4「progress.md『完了処理』未着手」は 6 ステップ progress に該当行がない

**最終決定（DR-005 選択肢 C）**: Unit 003 を軽量なリファクタに縮小し、3 層整合化は次サイクルで DR-003 再検討含めて再設計する。将来方針は選択肢 B（判定仕様を成果物存在ベースへリファクタ）を推奨。

## 完了条件チェックリスト

**Part ラベル修正**:

- [ ] `skills/aidlc/steps/inception/index.md` で `rg "Part [0-9]+"` が 0 ヒット。`Part 1（セットアップ）` / `Part 2（インセプション本体）` を「ステップ1（セットアップ）」「ステップ2以降（インセプション本体）」等に修正
- [ ] `skills/aidlc/steps/inception/01-setup.md` で `rg "Part [0-9]+"` が 0 ヒット。`Part 1: セットアップ` / `Part 1タスクリスト作成` / `Part 2` 参照を、対応する step ファイル名表記に修正
- [ ] `skills/aidlc/steps/inception/02-preparation.md` で `rg "Part [0-9]+"` が 0 ヒット。`Part 2: インセプション準備` / `Part 1 ステップ1` 参照を適切なステップ表現に修正
- [ ] `skills/aidlc/steps/common/task-management.md` で `rg "Part [0-9]+"` が 0 ヒット。`Part 1: セットアップ` / `Part 2以降` 見出しを修正
- [ ] `guides/error-handling.md` は対象外（Unit 責務リスト非該当）
- [ ] 上記 4 ファイルの Part 修正により、既存の内容・手順・意味論は維持されている（新たな混乱を招かない）

**CHANGELOG 集約（DR-002）**:

- [ ] `CHANGELOG.md` の先頭（`## [2.3.5] - 2026-04-18` の前）に `## [2.3.6] - 2026-04-20` エントリが追加されている
- [ ] エントリに以下の 4 Unit の成果が分類記載されている（Added / Changed / Fixed / Removed 等、既存 2.3.5 のフォーマットに倣う）:
  - Unit 001: `operations-release.md §7.6` 固定スロット反映ステップ追加（#583-A）
  - Unit 002: `write-history.sh` マージ後ガード + `04-completion.md` 禁止記述 + SKILL.md exit 3 追記（#583-B）
  - Unit 003: Inception Part ラベル修正（DR-005 により当初スコープから縮小、#565 一部対応）
  - Unit 004: Draft PR 時の GitHub Actions スキップ（DR-004、二段ガード）
- [ ] Unit 003 の CHANGELOG 記述に「テンプレート・fixture・判定仕様の 3 層整合化は次サイクル対応」と明記（追跡可能性）
- [ ] バックログ Issue 番号が記載されている（CHANGELOG から Issue へのリンク可能性）

**バックログ Issue 登録**:

- [ ] GitHub Issue が作成され、以下を含む:
  - タイトル: 「Inception progress.md テンプレート 6 ステップと判定仕様 §5.1（5 checkpoint）の 3 層整合化リファクタ」
  - 本文: DR-003 / DR-005 の経緯、3 層構造の現状、推奨方針（選択肢 B、成果物存在ベースへのリファクタ）、影響範囲（`phase-recovery-spec.md §5.1` / fixture / テンプレート / step ファイル / task-management.md）、patch サイクル予算超え・minor リリース（v2.4.0）以降対応の注記
  - ラベル: `backlog` / `type:refactor` / `priority:medium`
  - 参照 Issue: #565（関連、完全対応ではない）

## 実装方針

### Phase 1（設計）の扱い

本 Unit はスコープ縮小により**軽量な表現層修正**に留まるため、Phase 1 はドメインモデル（既作成、縮小版に更新）と軽量な論理設計（ファイル別の置換ルール + CHANGELOG 骨子）で完結する。

- **ドメインモデル**: 既作成の `unit_003_inception_progress_naming_unification_domain_model.md` を DR-005 選択肢 C スコープに合わせて縮小改訂
- **論理設計**: `unit_003_inception_progress_naming_unification_logical_design.md` を作成。Part ラベルの具体的な置換パターン + CHANGELOG エントリ骨子のみ
- **設計レビュー**: `reviewing-construction-design` スキル（codex）
- **設計承認**: ゲート承認（`automation_mode=semi_auto`）

### Phase 2（実装）の作業内容

1. **Part ラベル修正**:
   - `inception/index.md`: L47-48 の `Part 1（セットアップ）` / `Part 2（インセプション本体）` を「ステップ1（セットアップ）」「ステップ2以降（インセプション本体）」に置換。`phase` 構成表の意味は維持
   - `inception/01-setup.md`: L47「Part 1: セットアップ」 → 「ステップ1: セットアップ」、L58「Part 1タスクリスト作成」 → 「ステップ1タスクリスト作成」、L60「Inception Phase: Part 1」 → 「Inception Phase: ステップ1（セットアップ）」、L206・L226 の「Part 2」参照を「ステップ2以降」に
   - `inception/02-preparation.md`: L3「Part 2: インセプション準備」 → 「ステップ2: インセプション準備」、L7・L23「Part 1 ステップ1のプリフライトチェック」 → 「ステップ1のプリフライトチェック」
   - `common/task-management.md`: L55「Part 1: セットアップ」 → 「ステップ1: セットアップ（プリフライト完了後...）」、L63「Part 2以降」 → 「ステップ2以降」
   - いずれも、Part に紐づいた**手順・成果物の意味**は変更しない（表現層のみの変更）
2. **CHANGELOG 集約**:
   - 既存 `[2.3.5] - 2026-04-18` エントリの前に `[2.3.6] - 2026-04-20` エントリを挿入
   - 4 Unit の変更を Added / Changed / Fixed / Removed の分類で記載（既存フォーマット準拠）
   - Unit 003 エントリに「DR-005 によりスコープ縮小、残課題は #<issue_number> で追跡」と注記
3. **バックログ Issue 作成**:
   - `gh issue create --title "Inception progress.md テンプレート 6 ステップと判定仕様 §5.1（5 checkpoint）の 3 層整合化リファクタ" --label "backlog,type:refactor,priority:medium" --body-file <一時ファイル>`
   - 本文は DR-003 / DR-005 の経緯と推奨方針（選択肢 B）を含む
   - CHANGELOG から Issue 番号を参照できるようにする
4. **0 ヒット確認**: 4 ファイルで `rg "Part [0-9]+"` が 0 ヒットであることを確認
5. **コードレビュー**: `reviewing-construction-code` スキル（codex）
6. **統合レビュー**: 全置換 + CHANGELOG 追記 + Issue 登録後に `reviewing-construction-integration` スキル

### 境界外（本 Unit では扱わない、次サイクル対応）

- テンプレート（`inception_progress_template.md`）の 6 ステップ構造（現状維持）
- fixture（`verify-inception-recovery.sh`）の 5 ステップ構造（現状維持）
- 判定仕様（`phase-recovery-spec.md §5.1`）の 5 checkpoint + progress.md 参照文言
- `verify-construction-recovery.sh` / `verify-operations-recovery.sh` の Inception fixture 部分
- `04-stories-units.md` / `05-completion.md` の「ステップ N-M」表記
- `guides/error-handling.md` の Part ラベル（Unit 責務リスト非該当）
- Operations 関連ファイルの「ステップ N-M」表記（Operations progress 文脈、Unit 境界外）
- DR-003 の再検討（次サイクル対応）

## 影響範囲

- 変更ファイル:
  - `skills/aidlc/steps/inception/index.md`
  - `skills/aidlc/steps/inception/01-setup.md`
  - `skills/aidlc/steps/inception/02-preparation.md`
  - `skills/aidlc/steps/common/task-management.md`
  - `CHANGELOG.md`
- 設計ファイル:
  - `design-artifacts/domain-models/unit_003_inception_progress_naming_unification_domain_model.md`（既存、縮小改訂）
  - `design-artifacts/logical-designs/unit_003_inception_progress_naming_unification_logical_design.md`（新規）
- 追加成果物:
  - GitHub Issue（バックログ、Issue 番号は作成後に確定）
- 下流影響: 微小。Part ラベルが「ステップ1」等に変わるだけで、手順・意味論・判定ロジック・fixture・テンプレートへの波及なし

## 見積もり

**改訂後**: 0.5 日（当初 1 日 → 縮小により半減）
**内訳**: 設計更新 + 4 ファイル編集 + CHANGELOG 追記 + Issue 作成 + レビュー 3 回（設計 / コード / 統合）

## 依存関係

- **依存する Unit**: Unit 001 / 002 / 004（cycle ブランチ上でコミット先行、CHANGELOG 集約のため）。既に満たされている
- **CHANGELOG 集約順序**: `Unit 001 → Unit 002 → Unit 004 → Unit 003`
- **外部依存**: なし

## 参考資料

- DR-002 / DR-003 / DR-005（`inception/decisions.md`）
- Unit 定義: `story-artifacts/units/003-inception-progress-naming-unification.md`（スコープ縮小版）
- Issue #565（関連、本 Unit では一部対応のみ）
- 既存 CHANGELOG フォーマット: `CHANGELOG.md` `[2.3.5] - 2026-04-18`
