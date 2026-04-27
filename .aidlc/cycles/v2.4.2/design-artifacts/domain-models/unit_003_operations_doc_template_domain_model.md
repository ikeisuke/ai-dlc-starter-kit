# ドメインモデル: Unit 003 - Operations 手順書 / template 明文化

## 概要

本 Unit は **3 ファイル（`operations-release.md` / `02-deploy.md` / `operations_progress_template.md`）の文書改訂のみ** を対象とし、ロジック・スクリプト・スキーマには変更を加えない。ソフトウェアエンティティは存在しないため、本ドメインモデルでは対象ワークフロー（Operations Phase 復帰判定）のドメイン用語と固定スロット grammar、および既存のテンプレート展開動作を「ドメイン」として記述する。

**重要**: このドメインモデル設計ではコードは書かず、手順書改訂で実現する明文化のドメイン仕様のみを行う。実装（Markdown 追記）は Phase 2 で行う。

## ドメインとは（本 Unit における定義）

- **対象ドメイン**: Operations Phase の復帰判定 / リリース手順の明文化（empirical-prompt-tuning で検出された 8 件の不明瞭点解消）
- **アクター**: AI-DLC 利用者（外部プロジェクトでの Operations Phase 実行者、メタ開発者）
- **観測対象リソース**: `operations/progress.md`（既存のサイクル固有ファイル、本 Unit では改訂しない）/ `operations_progress_template.md`（テンプレートエンティティ、本 Unit で改訂）/ `operations-release.md` / `02-deploy.md`（手順書ファイル、本 Unit で改訂）

## 対象 8 件の明文化マッピング（empirical-prompt-tuning 由来）

| # | 優先度 | 対応箇所 | 内容 | 観測キーワード |
|---|--------|---------|------|--------------|
| 1 | [P1] | operations-release.md §7.2-§7.6 | 固定スロット 3 行の具体例コードブロック inline | `## 固定スロット（Operations 復帰判定用）` セクション名 + `<!-- fixed-slot-grammar: v1 -->` |
| 2 | [P2]/[#585] | operations_progress_template.md | 固定スロットセクション新設 | `## 固定スロット（Operations 復帰判定用）` セクション + 3 スロット |
| 3 | [P3] | 02-deploy.md §7 | 状態ラベル 5 値の冒頭列挙 | `未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了` |
| 4 | [P4] | operations-release.md §7.7 | コミット対象ファイル列挙 + 行区切り規約 | `operations/progress.md` / `history/operations.md` / `README.md` / `CHANGELOG.md` 等の列挙 |
| 5 | 補強1 | operations-release.md §7.2 | CHANGELOG 設定値確認手順 | `scripts/read-config.sh rules.release.changelog` |
| 6 | 補強2 | operations-release.md §7.6 | 既存 progress.md セクション有無判定 | `## 固定スロット` セクションの存在確認手順 |
| 7 | 補強3 | operations-release.md §7.2 | CHANGELOG 該当なし判定 | `changelog=false` 時の動作 |
| 8 | 補強4 | operations-release.md §7.7 | 設定依存判定基準 | `rules.release.changelog` / `bin/update-version.sh` 利用有無の条件分岐 |

## エンティティ

### `FixedSlotGrammarV1`（既存仕様、本 Unit で改訂しない）

`phase-recovery-spec.md §5.3.5` で定義される `key=value` 形式の grammar。本 Unit が追記する具体例コードブロックはこの v1 仕様に厳密に準拠する。

| 規則 | 仕様 |
|------|------|
| 形式 | `key=value` 形式（独立行、改行区切り） |
| 値の前後の空白 | 許容（パース時にトリム） |
| カンマ区切り併記 | 許容（複数値可、本 Unit のスロットは単一値のみ使用） |
| 重複キー | 最初の出現値を採用 |
| boolean | 小文字固定 `true` / `false` |
| integer（`pr_number`） | `^[1-9][0-9]*$` 形式（先頭ゼロ禁止、空文字禁止） |
| HTML コメント | `<!-- fixed-slot-grammar: v1 -->` 必須（パーサーがバージョン判定に使用） |

### `OperationsProgress`（既存ドキュメント形式、本 Unit で改訂しない）

サイクル固有の `operations/progress.md` ファイル。既存セクション（ステップ一覧 / 現在のステップ / 完了済みステップ / 次回実行時の指示 / プロジェクト種別による差異 / 再開時に読み込むファイル）に加えて、本 Unit のテンプレート改訂後は `## 固定スロット（Operations 復帰判定用）` セクションが新規サイクルで自動展開される。

### `OperationsProgressTemplate`（テンプレートエンティティ、本 Unit で改訂）

`skills/aidlc/templates/operations_progress_template.md`。Operations Phase 開始時（`steps/operations/01-setup.md` §6）に **`operations/progress.md` が存在しない場合のみ** 初回作成のためのソースとして使用される。

**改訂内容**: 既存セクション群を保持しつつ、ステップ一覧（line 5-13）と現在のステップ（line 15-17）の間に新規セクション `## 固定スロット（Operations 復帰判定用）` を挿入する。

### `ReleaseProcedureDoc`（手順書エンティティ、本 Unit で改訂）

- `operations-release.md`（288 行）: §7.2-§7.6 / §7.7 の文章補強
- `02-deploy.md`（188 行）: §7 状態ラベル列挙 + §7.7 誘導注記

## 状態遷移（既存、本 Unit では改訂しない）

本 Unit は文書改訂のみのため、状態遷移を持たない。Operations Phase の既存状態遷移（`progress.md` の `release_gate_ready` / `completion_gate_ready` / `pr_number` の 3 スロット更新）は `operations-release.md` の既存記述に既に存在し、本 Unit はその記述を「より明示的に」するのみ。

## 不変条件

- **INV-V1（v1 grammar 互換）**: 追記する固定スロット 3 行は既存 `phase-recovery-spec.md §5.3.5` の v1 grammar に厳密に準拠する。具体的には:
  - `<!-- fixed-slot-grammar: v1 -->` HTML コメントを同梱
  - `release_gate_ready` / `completion_gate_ready` の値は `true` / `false` の小文字固定
  - `pr_number` の値は `^[1-9][0-9]*$` 形式（または初期値の空文字 = 未記録状態）
  - 各スロットは独立行、改行区切り
- **INV-T1（テンプレート後方互換）**: 既存サイクル（v2.4.1 以前）の `operations/progress.md` は **絶対に上書きしない**。
  - **構造的保証 1**: テンプレート展開は `01-setup.md` §6 の「存在しない場合: 初回実行として作成」分岐でのみ発生する。既存サイクルは `progress.md` 既存のため当該分岐に到達しない
  - **構造的保証 2**: `OperationsProgressTemplate` は新規サイクル（=`v2.4.2` 以降）の Operations Phase 初回開始時にのみソースとして使用される
- **INV-D1（ロジック非変更）**: 復帰判定ロジック / `RecoveryJudgmentService.judge()` / `DecisionCategoryClassifier` / `PhaseResolver` には触れない。本 Unit は手順書 / テンプレートの**文書改訂のみ**
- **INV-S1（スコープ境界）**: 本 Unit のスコープは empirical-prompt-tuning 検出 8 件中の本 Unit 該当分（Unit 定義 §責務記載のもの）に限定される。8 件のうち追加分は `phase-recovery-spec.md` 自体の改訂を含む可能性があるが、それは Unit 定義 §境界で「スコープ外」と明示されている

## 観測条件（本 Unit の完了判定基準）

各完了条件は **テキスト検索（grep / Read）で発見可能なキーワードを含む** ことを観測条件とする:

| 観測対象 | 観測キーワード（grep 用） |
|---------|------------------------|
| operations-release.md §7.2-§7.6 [P1] | `## 固定スロット（Operations 復帰判定用）` + `<!-- fixed-slot-grammar: v1 -->` を含むコードブロック |
| operations-release.md §7.7 [P4] | `operations/progress.md` / `history/operations.md` / `README.md` / `CHANGELOG.md` の列挙 + `rules.release.changelog=true` 条件付き記述 |
| operations-release.md §7.2 補強1 | `scripts/read-config.sh rules.release.changelog` |
| operations-release.md §7.6 補強2 | `## 固定スロット` セクションの存在確認文言 |
| operations-release.md §7.2 補強3 | `changelog=false` または「スキップ」文言 |
| operations-release.md §7.7 補強4 | `bin/update-version.sh` + 「利用有無」の条件分岐文言 |
| 02-deploy.md §7 [P3] | `未着手` `進行中` `完了` `スキップ` `PR準備完了` の 5 値列挙 |
| 02-deploy.md §7.7 誘導注記 | `[必読] operations-release.md §7.7` または同等表現 |
| operations_progress_template.md [P2] | `## 固定スロット（Operations 復帰判定用）` セクション見出し + `<!-- fixed-slot-grammar: v1 -->` + `release_gate_ready=` + `completion_gate_ready=` + `pr_number=` |

## ユビキタス言語

- **固定スロット**: `operations/progress.md` 内の `key=value` 形式の構造化シグナル 3 行（`release_gate_ready` / `completion_gate_ready` / `pr_number`）。`phase-recovery-spec.md §5.3.5` で grammar v1 が定義されている
- **マージ前完結契約**: `release_gate_ready=true` / `completion_gate_ready=true` を予約的に §7.6 時点で書き込み、§7.7 最終コミットで main に反映する原則
- **後方互換**: 既存サイクル（v2.4.1 以前）の `operations/progress.md` は本 Unit のテンプレート改訂後も上書きされない。テンプレート展開は新規サイクルの初回 Operations Phase 開始時のみ発生
- **明文化（empirical-prompt-tuning 由来）**: AI エージェントが手順書を解釈して実行する際の「どう書けばよいか / どの設定値を確認すべきか」の具体例 / 列挙 / 確認手順を inline 記載すること

## 外部エンティティ（参照のみ、改訂なし）

- `phase-recovery-spec.md §5.3.5`: 固定スロット grammar v1 の規範仕様。本 Unit で改訂しない
- `RecoveryJudgmentService.judge()` / `DecisionCategoryClassifier`: 復帰判定ロジック。本 Unit で改訂しない（v2.3.6 Unit 005 で実装済み）
- `bin/setup-aidlc.sh` / `aidlc-setup` スキル: テンプレート展開ロジック。本 Unit で改訂しない（既存ファイル存在時にスキップする実装である旨は `01-setup.md` §6「存在する場合 / 存在しない場合」で文書的に保証されている）

## 不明点と質問（設計中に記録）

[Question] テンプレート改訂の後方互換性は、既存サイクル（v2.4.1 以前）にも反映されるか？
[Answer] **反映されない**。`01-setup.md` §6 の動作により、既存サイクルは `operations/progress.md` 既存のため初回作成分岐に到達せず、テンプレート差分の影響を受けない。テンプレート改訂は **新規サイクル（v2.4.2 以降）の Operations Phase 初回開始時** にのみ展開される。

[Question] 既存サイクルでの v2.4.2 リリース後の Operations Phase 実行は、固定スロットセクションが progress.md に存在しないが問題ないか？
[Answer] 既存仕様で対応済み。`RecoveryJudgmentService.judge()` および `DecisionCategoryClassifier` は new_format / legacy_format 自動切替（v2.3.6 Unit 005 改訂）により、固定スロット不在時は legacy_format で `history/operations.md` をフォールバック判定源とする。本 Unit はこの既存仕様に依存し、追加実装は不要。

[Question] テンプレートに固定スロットセクションを追加することで、新規サイクル初回 Operations Phase 開始時の `operations/progress.md` がどう変わるか？
[Answer] 新規サイクルの `operations/progress.md` には `## 固定スロット（Operations 復帰判定用）` セクションが**初期値 = 空 / false** で展開される。`release_gate_ready=` / `completion_gate_ready=` の初期値は手順書 §7.6 で `true` に更新される（既存仕様）。`pr_number=` は §7.6 通常系または §7.8 エッジケースで PR 番号が確定した時点で更新される（既存仕様）。

[Question] 補強2「既存 progress.md セクション有無判定」の挿入箇所は §7.5 か §7.6 か？
[Answer] **§7.6 に確定**（計画書 §対象セクション末尾の表記整合注記参照、指摘 #3 対応）。`operations-release.md` の現行構造（§7.5 = lint、§7.6 = progress.md 反映）に基づき、「既存 progress.md セクション有無判定」は progress.md を更新する §7.6 の文脈に置く方が自然。

[Question] AskUserQuestion の使用は本 Unit に該当するか？
[Answer] **該当しない**。本 Unit は手順書 / テンプレート文書改訂のみで、対話 UI を新規追加しない。Unit 001 / Unit 002 と異なり、本 Unit には MergeConfirmGuard / HeadDetachGuard / BranchDeleteFlow のようなガードコンポーネントは存在しない。
