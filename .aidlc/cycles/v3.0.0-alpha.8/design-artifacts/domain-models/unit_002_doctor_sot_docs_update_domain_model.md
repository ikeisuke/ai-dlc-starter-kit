# ドメインモデル: Unit 002 doctor 完全診断の SoT ドキュメント反映

## 概要

doctor が 11 領域の完全診断になったことを SoT ドキュメント（`doctor.md` / `workflow.md` / `v3-renewal-plan.md`）へ反映する「ドキュメント整合」ドメイン。コードは変更せず、記述（領域カウント・defer 注記・出力例）を実装の実出力に一致させる。

**重要**: このドメインモデル設計では**コードは書かず**、整合対象の概念と整合ルールのみを定義する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/doctor.sh` | 実装の実出力（11 領域 / 出力順 `... pr → phase → trace → scripts → parse-guard` / report 固定幅整形 / 各 severity 文言）を正本として把握し、ドキュメントの出力例・領域テーブルを一致させる |
| `skills/aidlc-v3/steps/doctor.md` | 反映対象①。冒頭位置づけ（行 4）/ 診断領域見出し（行 26）/ 領域テーブル（行 35-45）/ 出力例（行 88-100）/ 末尾 alpha.8 defer（行 102-110）の現状文言を確認 |
| `docs/v3/workflow.md` | 反映対象②。§3.1（行 31）/ §3.6 段階スコープ（行 160-161）/ チェック項目テーブル（行 176-177）/ 出力例（行 181,195-200）の現状を確認 |
| `docs/v3-renewal-plan.md` | 反映対象③。§doctor 段階スコープ（行 905）/ チェック項目（行 917-918）/ 出力例（行 923,940-945）/ Phase 6 完了条件（行 1092）の現状を確認 |
| `docs/v3/data-model.md` §5 | フェーズ導出規則の正本。SoT 二重定義回避（各ドキュメントは結果参照のみで導出規則を再定義しない）を守る |

### (b) 設計時に意識すべき挙動

- 実出力順は `[phase]` / `[trace]` が `[pr]` と `[scripts]` の**間**。全 SoT は現状これらを末尾に置くため、出力例は実出力順に揃える。
- 実出力文言（`[phase] OK define（state.json 不在 → define フォールバック）` / `[trace] SKIP （state なし）` 等）は、旧 defer 想定文言（`develop (derived: ...)` / `WARN: work_item 003 ...`）と異なる。出力例は実出力に合わせる。
- report は固定幅（ラベル 14 桁左詰 + severity 6 桁）。出力例の整形をこれに合わせる。
- 領域数表記の揺れ（「8 領域 + parse-guard」「9 領域」「shallow scope」）が 3 ファイルに散在。「11 領域」へ統一する。
- markdown_lint=true。テーブル列数・コードスパン・行長に注意（Unit 001 で MD056/MD038 を踏んだ教訓を踏襲）。

### (c) 既存実装に基づく代替案検討

| 論点 | 候補 | 採否 |
|------|------|------|
| 出力例の順序 | (i) 実出力順（pr→phase→trace→scripts）/ (ii) ドキュメント既存の末尾配置維持 | (i) 採用。実装が正本（Unit 定義「出力例を実装の実出力に揃える」）。ドキュメント間の順序統一も達成 |
| 段階メタ（`# alpha.7` コメント / 段階列） | (i) 全撤去 / (ii) phase/trace の defer 表記のみ実装済みへ（最小差分） | (ii) 採用。全撤去はスコープ拡大。Unit 境界は「alpha.8 defer 注記を実装済みへ」 |
| 導出規則の記述 | (i) 各ドキュメントに導出規則を再掲 / (ii) data-model §5 参照のまま | (ii) 採用。SoT 二重定義回避（技術的考慮事項） |

## エンティティ（整合対象の概念）

### SoTDocument（反映対象ドキュメント）

- **ID**: ファイルパス（`doctor.md` / `workflow.md` / `v3-renewal-plan.md`）
- **属性**:
  - area_count_notation: string - 領域数表記（現状「9 領域」等 → 「11 領域」へ）
  - defer_notes: list - 「alpha.8 defer」注記（→ 実装済みへ）
  - output_example: block - doctor 出力例（→ 実出力に一致）
- **振る舞い**: reflect() - 実装の実態に記述を一致させる（コードは変更しない）

## 値オブジェクト（Value Object）

### DiagnosisAreaCount（領域数）

- **属性**: value: 11（固定 / 実装 doctor.sh の領域数）
- **不変性**: 実装の領域数が正本。ドキュメントはこれに追従する

### DoctorOutputExample（出力例）

- **属性**: lines（11 領域 / 実出力順 / 実出力文言 / report 固定幅）
- **不変性**: doctor.sh の実行結果が正本

## 集約（Aggregate）

### DocConsistency 集約

- **集約ルート**: 3 SoT ドキュメントの doctor 記述整合
- **含まれる要素**: 領域数表記 + defer 注記 + 出力例 + 役割分担記述（`[trace]` vs `[work-items]`）
- **不変条件**:
  - 3 ファイルで領域数表記が「11 領域」に統一される
  - 出力例が doctor.sh の実出力（順序・文言・整形）に一致する
  - 導出規則の正本は data-model §5 のみ（他は参照）— SoT 二重定義を作らない

## ユビキタス言語

- **SoT ドキュメント**: doctor の仕様・出力を記述する正本文書（doctor.md / workflow.md / v3-renewal-plan.md）
- **alpha.8 defer**: alpha.7 時点で `[phase]`/`[trace]` を先送りした注記（本 Unit で「実装済み」へ更新）
- **11 領域**: config/state/cycle/work-items/git/gh/pr/phase/trace/scripts/parse-guard
- **役割分担（`[trace]` vs `[work-items]`）**: `[work-items]` は frontmatter schema 検証、`[trace]` は design 必須 work item の design ファイル存在整合（責務が異なる）

## 不明点と質問（設計中に記録）

[Question] 出力例の順序を実出力（pr→phase→trace→scripts）に揃えると、既存ドキュメントの末尾配置から変わるが問題ないか。
[Answer]（設計判断）実装が正本であり Unit 定義が「出力例を実装の実出力に揃える」と明記。順序変更はドキュメント間整合の向上であり許容。論理設計に反映。
