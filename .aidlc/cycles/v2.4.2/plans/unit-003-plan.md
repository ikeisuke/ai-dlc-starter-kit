# Unit 003 実装計画: Operations 手順書 / template 明文化

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.2/story-artifacts/units/003-operations-doc-template.md`
- 対象 Issue: #591（Closes 対象、empirical-prompt-tuning で検出された 8 件中の本 Unit 該当分）+ #585（Closes 対象、#591 [P2] と統合）
- 関連 DR: DR-005（#591/#585 統合実装の決定）/ DR-009（v2.4.2 サイクルの 3 Unit 構成）/ DR-010（AI レビューフォールバック方針）
- 主対象ファイル:
  - `skills/aidlc/steps/operations/operations-release.md`（§7.2-§7.6 / §7.7 / §7.2 CHANGELOG 設定値確認の文章補強）
  - `skills/aidlc/steps/operations/02-deploy.md`（§7 状態ラベル列挙 / §7.7 誘導注記）
  - `skills/aidlc/templates/operations_progress_template.md`（固定スロットセクション新設）
- 整合確認のみ:
  - `skills/aidlc/steps/common/phase-recovery-spec.md`（§5.3.5 grammar 仕様 v1 を参照、改訂しない）
  - `skills/aidlc/steps/common/session-continuity.md` / 復帰判定ロジック（改訂しない）
  - `bin/setup-aidlc.sh` / `aidlc-setup` スキルのテンプレート展開ロジック（既存ファイル存在時にスキップする実装である旨を Phase 1 で確認、本 Unit では改訂しない）

> **Unit 定義との表記整合（指摘 #3 対応）**: Unit 定義 §責務「§7.5 等の文章補強」と本計画書 §完了条件「§7.6 に既存 progress.md セクション有無判定の手順が明示されている（補強2）」の表記揺れは、現行 `operations-release.md` の構造（§7.2〜§7.6 が line 23-36 に集約、§7.5 = lint、§7.6 = progress.md 反映）に基づき **§7.6 に確定** とする。Phase 1 設計成果物で行範囲を最終確定。

## 現状確認（Phase 1 着手前）

### `skills/aidlc/steps/operations/operations-release.md`（288 行）

- **§7.2〜§7.6**: line 23-36 に集約。固定スロット 3 行（`release_gate_ready` / `completion_gate_ready` / `pr_number`）について line 29-36 で文章説明されているが、**追記先セクション名や具体的なコードブロック例が不在**。利用者は他の手順書を読まないと実際の Markdown 形式で何を書くべきか分からない
- **§7.7**: line 38-40 で `commit-flow.md` を参照する旨のみ記述。コミット対象ファイルが列挙されていない
- **§7.2 CHANGELOG 設定値確認**: line 25 で `rules.release.changelog = true` の場合のみ更新する旨を記述しているが、設定値確認の手順（`scripts/read-config.sh rules.release.changelog`）は未明示

### `skills/aidlc/steps/operations/02-deploy.md`（188 行）

- **§7（ステップ7: リリース準備）**: line 156-186。状態ラベル（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）の使用例は散在しているが、**冒頭に列挙が不在**
- **§7.7 誘導注記**: line 175 でサブステップ一覧の中に「7.7 Gitコミット」が含まれるが、`operations-release.md §7.7` への誘導注記が独立した形では記述されていない（line 168 の包括的な「各サブステップの詳細手順は `operations-release.md` を参照」のみ）

### `skills/aidlc/templates/operations_progress_template.md`（37 行）

- **固定スロットセクション**: 未存在。`<!-- fixed-slot-grammar: v1 -->` コメントもなく、`release_gate_ready=` / `completion_gate_ready=` / `pr_number=` の 3 スロットも記載されていない
- **既存構造**: ステップ一覧表（line 5-13）/ 現在のステップ（line 15-17）/ 完了済みステップ（line 19-21）/ 次回実行時の指示（line 23-25）/ プロジェクト種別（line 27-31）/ 再開時に読み込むファイル（line 33-37）

## スコープ

empirical-prompt-tuning で検出された 8 件のうち、本 Unit で対応する明文化項目:

| # | 優先度 | 対応箇所 | 内容 |
|---|--------|---------|------|
| 1 | [P1] | operations-release.md §7.2-§7.6 | 固定スロット 3 行の具体例コードブロックを inline 記載 + セクション名の明示 |
| 2 | [P2] | operations_progress_template.md | 固定スロットセクション新設（`## 固定スロット（Operations 復帰判定用）`）。#585 と統合実装 |
| 3 | [P3] | 02-deploy.md §7 | 状態ラベル 5 値の冒頭列挙 |
| 4 | [P4] | operations-release.md §7.7 | コミット対象ファイル列挙 |
| 5 | （補強1） | operations-release.md §7.2 | CHANGELOG 設定値確認手順 (`scripts/read-config.sh rules.release.changelog`) |
| 6 | （補強2） | operations-release.md §7.6 | 既存 progress.md セクション有無判定の手順明示 |
| 7 | （補強3） | operations-release.md §7.2 | CHANGELOG 該当なし判定（`changelog=false`）の動作明示 |
| 8 | （補強4） | operations-release.md §7.7 | 設定依存判定（`rules.release.changelog` / `bin/update-version.sh` 利用有無）の判定基準明示 |

すべて「文章 / 例 / 列挙」の追加。**既存のロジック・スクリプト・スキーマには変更を加えない**（後方互換性最大）。

### 実行順序（並列可、ファイル単位で独立）

```text
[Phase 2 実装]
  ├─ operations-release.md 改訂（[P1] / [P4] / 補強1〜4）
  ├─ 02-deploy.md 改訂（[P3] + §7.7 誘導注記）
  └─ operations_progress_template.md 改訂（[P2] / #585）
       ↓
[Phase 2b 検証]
  ├─ markdownlint 実行
  ├─ 手順書 walkthrough（empirical-prompt-tuning 8 件チェック）
  └─ progress.md テンプレートと既存サイクル形式の後方互換確認
```

## 実装方針

### Phase 1（設計）

#### Phase 1 設計成果物（必須）

1. **挿入位置の最終確定**: 各ファイルの追記箇所（行範囲）を確定
2. **追記文面の構造設計**: 固定スロット 3 行の Markdown 表現（コードフェンス / 表形式）の選定
3. **テンプレート同梱の後方互換戦略**: 既存サイクルの `operations/progress.md` を上書きしない（テンプレート展開はサイクル初期化時のみ）の構造的保証。**確認対象**: `bin/setup-aidlc.sh` および `aidlc-setup` スキル（`skills/aidlc-setup/steps/`）のテンプレート展開ロジックを Phase 1 で読み取り、既存ファイル存在時にスキップする実装である旨を計画書または設計ドキュメントの該当箇所に明記する（指摘 #2 対応）

#### ドメインモデル設計（軽量版）

本 Unit はコード追加ではなく Markdown 手順書 / テンプレート改訂のため、ソフトウェアエンティティは存在しない。代わりに対象ワークフロー（Operations Phase 復帰判定）のドメイン用語と固定スロット grammar を「ドメイン」として記述する。

- **エンティティ**:
  - `FixedSlotGrammarV1`（既存 v1 仕様、改訂しない）: `key=value` 形式 / カンマ区切り併記許容 / 値前後の空白許容 / 重複キー時は最初の出現値を採用
  - `OperationsProgress`（既存 `operations/progress.md` のドキュメント形式、改訂しない）: 既存セクション群 + 新規追加固定スロットセクション
  - `OperationsProgressTemplate`（テンプレートエンティティ、本 Unit で改訂）: サイクル初期化時のみ展開
- **状態遷移**: なし（本 Unit は手順書 / テンプレートの文書改訂のみ）
- **不変条件**:
  - **INV-V1（v1 grammar 互換）**: 追記する固定スロット 3 行は既存 `phase-recovery-spec.md §5.3.5` の v1 grammar に厳密に準拠する
  - **INV-T1（テンプレート後方互換）**: 既存サイクルの `operations/progress.md` は上書きしない（テンプレート展開はサイクル初期化時のみ）
  - **INV-D1（ロジック非変更）**: 復帰判定ロジック / `RecoveryJudgmentService.judge()` / `DecisionCategoryClassifier` には触れない

#### 論理設計（軽量版）

- **operations-release.md の改訂方針**:
  - §7.2-§7.6 の line 29-36 範囲に、現行記述を保持しつつ「具体例コードブロック」を inline 追加
  - §7.7（line 38-40）に「コミット対象ファイル列挙」と「行区切り規約」を追加
  - §7.2 末尾に CHANGELOG 設定値確認手順を追加
  - §7.6 / §7.7 に補強3 / 補強4 の判定基準を追加
- **02-deploy.md の改訂方針**:
  - §7（line 156-186）の冒頭注記または最初のサブステップ説明に状態ラベル 5 値を表形式で追加
  - §7.7 への誘導注記を独立記述として追加（[必読] operations-release.md §7.7）
- **operations_progress_template.md の改訂方針**:
  - line 13 と line 14 の間（ステップ一覧の後、現在のステップの前）に新規セクション `## 固定スロット（Operations 復帰判定用）` を追加
  - セクション内容: `<!-- fixed-slot-grammar: v1 -->` コメント + 3 スロット（`release_gate_ready=` / `completion_gate_ready=` / `pr_number=`）

### Phase 2（実装）

- 改訂対象: 上記 3 ファイル
- 実装内容: Phase 1 で確定した文面・配置を反映
- 各ファイルは独立して並列実装可能

### Phase 2b（検証）

- markdownlint 実行（`markdown_lint=true`、3 ファイルすべて 0 error 確認）
- 手順書 walkthrough（empirical-prompt-tuning 8 件すべての明文化確認）
- progress.md テンプレートと既存 v2.4.1 以前サイクルの形式整合確認（テンプレート差分が既存サイクルに波及しないこと）

### Phase 3（完了処理）

- 設計 / コード / 統合 AI レビュー（Unit 001 / Unit 002 と同様、`review_mode=required` のためスキップ不可）
- Unit 定義状態を「完了」に更新、履歴記録、Markdownlint、Squash、Git コミット

## 完了条件チェックリスト

> **観測条件の境界**: 本 Unit は手順書 / テンプレート文書改訂が主体で、実走行検証はスコープ外。完了条件は **「手順書・テンプレート内に該当記述が存在すること」** を基準とする。

### Phase 1 設計成果物

- [ ] 各ファイルの追記箇所（行範囲）が確定し、設計ドキュメントまたは計画書に記録されている
- [ ] 固定スロット 3 行の Markdown 表現が選定されている（コードフェンス / 表形式）
- [ ] テンプレート同梱の後方互換戦略（既存サイクル非上書き）が記述されている

### 機能要件（Unit 定義「責務」由来）

#### `operations-release.md`

- [ ] inline 記載する具体例コードブロックは `phase-recovery-spec.md §5.3.5` v1 grammar（boolean 小文字固定 `true`/`false` / integer は `^[1-9][0-9]*$` 形式 / HTML コメント `<!-- fixed-slot-grammar: v1 -->` 同梱）に準拠している（指摘 #4 対応）
- [ ] §7.2-§7.6 に固定スロット 3 行（`release_gate_ready` / `completion_gate_ready` / `pr_number`）を `## 固定スロット（Operations 復帰判定用）` セクションへ追記する具体例コードブロックが inline 記載されている [P1]
- [ ] §7.7 にコミット対象ファイルが列挙されている（`operations/progress.md` / `history/operations.md` / `README.md` / `CHANGELOG.md`（条件付き）/ `version.txt` / `.aidlc/config.toml`（条件付き）/ markdownlint で修正したその他ファイル）[P4]
- [ ] §7.7 のコミット対象ファイル列挙に条件付き記述（`CHANGELOG.md` は `rules.release.changelog=true` 時、`version.txt` / `.aidlc/config.toml` は `bin/update-version.sh` 利用時）が明示されている（指摘 #1 対応）
- [ ] §7.7 に行区切り規約（改行区切り、独立行）が明示されている
- [ ] §7.2 に CHANGELOG 設定値確認手順（`scripts/read-config.sh rules.release.changelog`）が追加されている（補強1）
- [ ] §7.6 に既存 progress.md セクション有無判定の手順が明示されている（補強2）
- [ ] §7.2 に CHANGELOG 該当なし判定（`changelog=false`）の動作が明示されている（補強3）
- [ ] §7.7 に設定依存判定（`rules.release.changelog` / `bin/update-version.sh` 利用有無）の判定基準が明示されている（補強4）

#### `02-deploy.md`

- [ ] §7 冒頭または最初のサブステップ説明に状態ラベル 5 値（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）が列挙されている [P3]
- [ ] §7.7 への誘導注記（[必読] operations-release.md §7.7）が独立記述として追加されている

#### `operations_progress_template.md`

- [ ] `## 固定スロット（Operations 復帰判定用）` セクションが新設されている [P2] / [#585]
- [ ] セクション内に `<!-- fixed-slot-grammar: v1 -->` コメントが含まれている
- [ ] 3 スロット（`release_gate_ready=` / `completion_gate_ready=` / `pr_number=`）が記載されている
- [ ] 既存サイクルへの強制移行は行われない（サイクル初期化時のみテンプレート展開）旨が記述または既存実装で構造的に保証されている

### Issue / Decision 整合

- [ ] #591（Closes 対象）に明示された 8 件のうち本 Unit 該当分すべてに対応している
- [ ] #585（Closes 対象、#591 [P2] と統合）の `operations_progress_template.md` 同梱が完了している

### プロセス要件

- [ ] 設計 AI レビュー承認（`review_mode=required`）
- [ ] コード AI レビュー承認（同上）
- [ ] 統合 AI レビュー承認（同上）
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit03.md`）
- [ ] Markdownlint 実行（`markdown_lint=true`、3 ファイル 0 error）
- [ ] markdownlint 違反予防（`|` を含むコードスパン回避、Unit 001/002 で発生した MD038/MD056 への対策）を Phase 2 実装時に確認している（指摘 #5 対応）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット

## 依存関係

- **依存する Unit**: なし（Unit 001 / Unit 002 と完全独立、並列実装可能）
- **外部依存**: なし（Markdown ファイル更新のみ、外部ライブラリ依存なし）

## 見積もり

- Phase 1（設計）: 0.25 日（軽量設計、3 ファイルの追記位置確定 + テンプレート展開ロジック確認）
- Phase 2（実装）: 0.5 日（3 ファイルの並列改訂）
- Phase 2b（検証）: 0.25 日（markdownlint + walkthrough）
- Phase 3（完了処理）: 0.25 日（DR-010 採用のセルフレビューパス前提、3 種 AI レビュー（設計 / コード / 統合）逐次実施）

合計: 1.25 日規模（Unit 定義の見積もり「小〜中規模」と整合、3 ファイル並列改訂で短縮）

> **見積もり前提（指摘 #7 対応）**: Phase 3 の 0.25 日圧縮は DR-010（codex CLI usage limit に対する general-purpose subagent でのセルフレビューパス）採用前提。codex CLI 復活時は 3 種 AI レビューが各々 codex 経由となるため Phase 3 は 0.5 日に拡大する想定。本 Unit 着手時点では codex usage limit 継続中（v2.4.2 サイクル全体の Unit 001/002 と同じ条件）。

## リスク・留意点

- **テンプレート上書きの誤動作**: テンプレート（`operations_progress_template.md`）の改訂は新規サイクル初期化時のみ展開され、既存サイクル（v2.4.1 以前）の `operations/progress.md` には影響しない構造的保証を本 Unit 着手時に再確認する。`bin/setup-aidlc.sh` 系の展開ロジックを念のため Phase 1 で確認
- **grammar v1 仕様の微妙な不整合**: 固定スロット 3 行を新規追記する際、既存 `phase-recovery-spec.md §5.3.5` の grammar に厳密に従う必要がある。具体的には `key=value` 形式 / 値前後の空白許容 / カンマ区切り併記許容。Phase 2 実装時に正規表現での検証パターンを参照
- **手順書間の参照ドリフト**: operations-release.md と 02-deploy.md の §7.7 参照関係（02-deploy.md → operations-release.md）が双方の改訂後に整合しているか Phase 2b で確認
- **markdownlint 設定との整合**: 改訂後ファイルのコードフェンス / 表形式 / 見出しレベルが `.markdownlint.yaml` の既存ルール（MD038/MD056 等）に違反しないか Phase 2b で確認。Unit 001 / Unit 002 で発生した `|` を含むコードスパンエラー（MD038/MD056）に注意
- **8 件すべての観測可能性**: 完了条件チェックリストで 8 件すべてが「観測可能」（テキスト検索で発見可能）になるよう Phase 2 実装時に明示的なキーワードを含める
- **将来の grammar v2 への影響**: 本 Unit は v1 grammar 完全互換のため v2 への移行（将来導入される可能性）には影響しない。v2 移行時は `phase-recovery-spec.md` 改訂と同時に本 Unit の追記内容も改訂する想定（v2.5.0 以降の検討事項）
