# ドメインモデル: Unit 003 事実テーブル先抽出ステップ + 推定値検出ガード

## 概要

振り返り作業時の推測値混入を構造的に予防するドメインモデル。事実テーブル（Fact Table）と推定値検出ガード（Estimate Guard）の 2 要素を中心とする。

**重要**: コードは書かず、構造と責務の定義のみを行う。

## エンティティ

### FactTable（事実テーブル）

- **ID**: 振り返り対象 cycle 識別子
- **属性**:
  - `sources`: `Set<FactSource>` - 読み込み対象の source 集合（最低 3 種別必須）
  - `entries`: `List<FactEntry>` - 構造化された事実項目（DR 件数 / review round 数 / 指摘件数 / defer 件数 / 時系列イベント等）
  - `extraction_timestamp`: 抽出時刻
- **振る舞い**:
  - `extract_from_sources()` - 各 source を Read し、事実項目を markdown 表形式で構造化
  - `validate_minimum_sources()` - sources 集合に最低 3 種別が含まれることを保証

### FactSource（事実 source）

- **ID**: source パスパターン
- **属性**:
  - `kind`: `decisions` | `review_summary` | `history`
  - `path_pattern`: glob パターン（例: `.aidlc/cycles/{{CYCLE}}/inception/decisions.md`）
- **振る舞い**:
  - `read_content()` - source 内容を Read

### EstimateGuardFinding（推定値検出指摘）

- **ID**: 段落単位の通番
- **属性**:
  - `excerpt`: 該当箇所の引用
  - `marker`: 検出されたマーカー語（`約` / `およそ` / `approximately` / `推定` 等）
  - `adjacent_number`: 隣接した数値表現
  - `paragraph_evidence_links`: 段落内に存在する根拠リンク（PR/Commit/Issue/file path）
  - `disposition`: `flagged` | `allowed`
- **振る舞い**:
  - `evaluate()` - **判定原則（固定 / 差し替え不能）** に従って disposition を決定。判定原則は `JudgmentPrinciple` 値オブジェクトとして固定化されており、外部注入は不可（設計レビュー Round 1 指摘 #1 反映）
  - `format_finding_message()` - 「指摘 #N - 推定値混入: `<該当箇所>`」形式で出力

## 値オブジェクト

### EstimateMarker（推定値マーカー）

- **属性**: `marker_text`: 列挙値 `約` / `およそ` / `approximately` / `approx.` / `推定` / `〜くらい` / `〜程度`
- **不変性**: 文字列固定
- **等価性**: 文字列一致

### NumberAdjacencyWindow（数値隣接窓）

- **属性**: `radius`: 5 文字（直前/直後）
- **不変性**: 5 文字固定
- **等価性**: radius 値の一致

### EvidenceLink（根拠リンク）

- **属性**: `kind`: `issue_link` | `commit_sha` | `pr_link` | `file_path_reference`
- **不変性**: 種別固定

### ApplicationScope（適用スコープ）

- **属性**: `scope_kind`: 振り返り文脈のみ
- **不変性**: 振り返り文脈以外は適用対象外
- **SoT**: 適用スコープの正準定義は **論理設計（`unit_003_fact_table_and_estimate_guard_logical_design.md`）** に固定。本ドメインモデル / 計画ファイルは論理設計を参照する形で記述（設計レビュー Round 1 指摘 #2 反映 / SoT 集約）

### JudgmentPrinciple（判定原則 / 値オブジェクト / 固定）

- **属性**: 「**一次情報を Read 済みでも、根拠リンクや出典参照が併記されていない近似語付き数値は flag する**」（Intent v2.5.3 §「推定値検出ガードの境界条件」直接引用）
- **不変性**: 値固定 / 差し替え不能。外部注入は許容しない（`EstimateGuardFinding.evaluate()` は本値オブジェクトを内部参照する）
- **等価性**: 内容文字列の一致（基本は単一インスタンス）

## 集約

### EstimateGuardEvaluation（推定値ガード評価）集約

- **集約ルート**: `EstimateGuardFinding`
- **含まれる要素**: `EstimateGuardFinding` + `Set<EvidenceLink>` + `EstimateMarker`
- **境界**: 単一段落単位の判定スコープ
- **不変条件**: 判定原則「一次情報 Read 済みでも根拠リンク併記なしなら flag」が常に適用される

## ドメインサービス

### FactTableExtractionService

- **責務**: 振り返り対象 cycle の sources から事実項目を抽出して FactTable を構築
- **操作**: `extract(cycle)` - 04-completion.md §1.x 手順に従い AI エージェントが手動抽出

### EstimateGuardEvaluationService

- **責務**: 振り返り Issue 本文 / KPT / 主因 / Try / mirror 候補本文を入力として推定値検出を実行
- **操作**: `evaluate(text, application_scope)` - 適用スコープを判定 → スコープ内なら判定原則に従って flag/allowed を出力

## ユビキタス言語

- **事実テーブル（Fact Table）**: 振り返り作業の起点として、3 source 以上から構造化抽出した事実項目集合（KPT 記入後・主因切り分け前に作成）
- **推定値マーカー**: 数値の不確実性を示唆する語（約 / およそ / approximately / approx. / 推定 / 〜くらい / 〜程度）
- **数値隣接判定**: マーカーから 5 文字以内の算用数字 / 日本語数字との隣接で判定
- **根拠リンク併記の例外**: 同一段落に PR/Commit/Issue リンクまたはファイルパス参照があれば許容
- **判定原則**: 一次情報 Read 済みでも根拠リンク併記がなければ flag（Intent v2.5.3 SoT）
- **適用スコープ**: 振り返り文脈のみ（コードレビュー / Plan / Design 等は対象外）

## 不明点と質問

[Question] 事実テーブルの粒度

[Answer] markdown 表形式で 5-10 行程度を目安とする（DR 件数 / review round 数 / 指摘件数 / defer 件数 / 時系列イベント等）。AI 手順としての記述に留め、自動抽出ツール化は #652 として OUT_OF_SCOPE。
