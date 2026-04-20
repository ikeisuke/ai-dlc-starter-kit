# ドメインモデル: Unit 003 - Inception Part ラベル修正 + CHANGELOG 集約【DR-005 選択肢 C 確定版】

## 位置づけ（重要）

本ドキュメントは DR-005 選択肢 C 決定後の縮小スコープに基づく軽量なドメインモデルである。本 Unit は**表現層の限定的な書き換え**と **CHANGELOG 集約**に責務を絞り、テンプレート・fixture・判定仕様の 3 層整合化は次サイクル以降の別 Unit/Issue で実施する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## スコープ図

```
┌─────────────────────────────────────────────────────────────────┐
│ 本 Unit（v2.3.6）のスコープ                                    │
│   ├─ PartMarker 書き換え（4 ファイル）                        │
│   └─ ChangelogEntry 集約追加（Unit 001/002/003/004）          │
└─────────────────────────────────────────────────────────────────┘
                             ↓ 先送り（次サイクル）
┌─────────────────────────────────────────────────────────────────┐
│ 次サイクル以降の別 Unit/Issue スコープ                          │
│   ├─ InceptionProgressModel の 3 層整合化                      │
│   │   ├─ ProgressTemplate（6 ステップ）                        │
│   │   ├─ ProgressFixture（5 ステップ）                         │
│   │   └─ SpecTextualReference（判定仕様 §5.1 の progress 参照）│
│   ├─ DR-003 の再検討（6 ステップ or 5 ステップ）              │
│   └─ 判定仕様リファクタ（成果物存在ベースへ、選択肢 B 推奨）  │
└─────────────────────────────────────────────────────────────────┘
```

## エンティティ（Entity）

本ドメインは静的な表現更新と集約エントリ追加であり、永続化エンティティは持たない。

## 値オブジェクト（Value Object）

### PartMarker

- **属性**:
  - `source_file: string`（対象ファイルの相対パス）
  - `original_label: string`（例: `Part 1: セットアップ` / `Part 2`）
  - `replacement_label: string`（例: `ステップ1: セットアップ` / `ステップ2以降`）
  - `semantic_role: PartSemanticRole`（`setup_phase` / `inception_body` / `reference`）
- **不変性**: 置換前後で手順・成果物・意味論は変更しない（表現層のみの書き換え）
- **等価性**: source_file + original_label の組で等価
- **意味**: `Part 1` / `Part 2` という章立て表現を、既存 step ファイル名（`01-setup` / `02-preparation`）と整合するステップ表記に置換する単位

### PartSemanticRole

- `setup_phase`: `01-setup` に相当する「セットアップ」段階
- `inception_body`: `02-preparation` 以降に相当する「インセプション本体」段階
- `reference`: 他ファイルの Part 表記を参照している文脈（例: `02-preparation.md` で「Part 1 ステップ1のプリフライト」）

### ReplacementRule

- **属性**:
  - `file_path: string`
  - `locations: List<PartMarker>`
  - `preservation_check: List<string>`（置換後も維持されるべき手順・参照・成果物リスト）
- **意味**: ファイル単位での置換ルール。置換後に既存手順が破綻しないことを検証する

### ChangelogEntry

- **属性**:
  - `version: string`（`[2.3.6]`）
  - `date: string`（`2026-04-20`）
  - `sections: Map<CategoryType, List<UnitChangeRecord>>`（Added / Changed / Fixed / Removed）
  - `footnote: string`（DR-005 経緯・バックログ Issue 番号参照）
- **不変性**: 既存 `[2.3.5]` エントリのフォーマットに従う

### UnitChangeRecord

- **属性**:
  - `unit_number: string`（`001` / `002` / `003` / `004`）
  - `summary: string`（1 行要約）
  - `related_issues: List<string>`（例: `#583-A` / `#583-B` / `#565` / `（サイクル追加要件）`）
  - `section: CategoryType`（Added / Changed / Fixed / Removed のいずれか）
- **意味**: CHANGELOG エントリ内の Unit ごとの記載単位

### BacklogIssue

- **属性**:
  - `title: string`（Inception progress.md テンプレート 6 ステップと判定仕様 §5.1（5 checkpoint）の 3 層整合化リファクタ）
  - `body: string`（DR-003 / DR-005 経緯、現状、推奨方針（選択肢 B）、影響範囲）
  - `labels: List<string>`（`backlog` / `type:refactor` / `priority:medium`）
  - `related_issues: List<string>`（#565 関連）
- **意味**: 先送りされた残課題を次サイクルで追跡するための GitHub Issue

## 集約境界

1. **PartRefactorAggregate**: `ReplacementRule` を集約ルートとし、4 ファイルの `PartMarker` を配下に持つ。置換の一貫性（意味論保持）を保証する
2. **ChangelogAggregate**: `ChangelogEntry` を集約ルートとし、4 つの `UnitChangeRecord` を配下に持つ。CHANGELOG の分類正規性（Added/Changed/Fixed/Removed の適切な振り分け）を保証する
3. **BacklogAggregate**: `BacklogIssue` 単独。残課題の外部化を担当

## ドメインルール

### Part ラベル置換ルール

1. **意味論保持**: 置換前後で、Part に紐づいた手順・タスクリスト・成果物・参照関係は不変
2. **既存 step ファイル名との整合**: 置換後の表現は `01-setup` / `02-preparation` 等の既存 step ファイル名と意味が一致する
3. **6 ステップテンプレートとの整合は追求しない**: DR-005 選択肢 C により、本 Unit では `inception_progress_template.md` の 6 ステップ構造（Intent明確化 / 既存コード分析 等）との整合は次サイクル以降
4. **置換は冪等**: 再実行しても結果が変わらない（同一文字列に 2 回目の置換は発生しない）

### CHANGELOG 集約ルール（DR-002）

1. **単一エントリ**: `[2.3.6] - 2026-04-20` の 1 エントリとして追加
2. **4 Unit 統合**: Unit 001/002/003/004 の変更を分類して記載
3. **フォーマット整合**: 既存 `[2.3.5]` エントリに倣う
4. **残課題参照**: Unit 003 記述に DR-005 経緯とバックログ Issue 番号を含める

### バックログ Issue 登録ルール

1. **先送り理由の明示**: DR-003 / DR-005 の経緯を本文に含める
2. **推奨方針の明示**: 選択肢 B（判定仕様の成果物存在ベースへのリファクタ）を推奨として記載
3. **次サイクル対応**: minor リリース（v2.4.0）以降での対応を示唆
4. **既存 Issue との関連**: #565 を `relates` として参照

## 境界

- テンプレート（`inception_progress_template.md`）は変更しない
- fixture（`verify-inception-recovery.sh`）は変更しない
- 判定仕様（`phase-recovery-spec.md §5.1`）は変更しない
- verify-construction / operations-recovery.sh の Inception 部分は変更しない
- `04-stories-units.md` / `05-completion.md` の「ステップ N-M」表記は変更しない
- `guides/error-handling.md` の Part ラベルは変更しない（Unit 境界外）
- Operations 関連ファイルの「ステップ N-M」表記は変更しない（Operations progress 文脈）
- DR-003 の再検討は本 Unit では行わない

## 参考資料

- DR-002 / DR-003 / DR-005（`inception/decisions.md`）
- Unit 定義: `story-artifacts/units/003-inception-progress-naming-unification.md`（スコープ縮小版）
- 既存 CHANGELOG: `CHANGELOG.md` `[2.3.5]` エントリ
