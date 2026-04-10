# レビューサマリ: Unit 002 汎用復帰判定仕様

## 基本情報

- **サイクル**: v2.3.0
- **フェーズ**: Construction
- **対象**: Unit 002 - 汎用復帰判定仕様の策定と Inception への先行適用

---

## Set 1: 設計レビュー（ドメインモデル + 論理設計）

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex (gpt-5.4)
- **反復回数**: 5（初回 + 修正反映4回）
- **結論**: 指摘0件（auto_approved）
- **セッションID**: 019d6fb2-4010-7151-b5f0-07912a5afd1c

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | domain-model - PhaseResolver が存在判定ベースに偏重しており完了状態・競合状態を取り込めていない。#553 以外の誤判定を phase 層に残すリスク | 修正済み（判定順を conflict→Operations(incomplete)→Construction(Inception完了条件必須)→Inception→新規開始フォールバックの5段階に整理。PhaseProgressStatus 値オブジェクトを追加、ArtifactsState に phaseProgressStatus フィールドを追加） | - |
| 2 | 中 | logical-design - 公開 API が `determine_current_step` と `judge` で混在、呼び出し層の境界が曖昧 | 修正済み（RecoveryJudgmentService.judge() を唯一の公開 API として固定、determine_current_step() は非公開下位契約としてリネーム・統合。依存図・ユースケース記述を統一） | - |
| 3 | 中 | domain-model/logical-design - RecoveryCheckpoint の `priority_order=spec§4` が phase ロジックへ不要結合 | 修正済み（checkpoint は自身の step 判定規則への参照 `spec§5.<checkpoint_id>` のみ持つよう再定義。phase 全体優先順位は PhaseResolver の固定責務に寄せる） | - |
| 4 | 低 | logical-design - spec_version と binding_schema_version の境界が混在 | 修正済み（独立管理ルールを明記、互換性ルール=minor/major/schema 更新の3分類を定義。spec §1 に記載予定） | - |
| 5 | 中 | domain-model - 本文修正がクラス図・集約不変条件・用語集に未反映（priorityOrderRef 残存、ArtifactsState 図に phaseProgressStatus 未反映、resolveStep() 残存） | 修正済み（Mermaid 図全面更新、集約名・不変条件・下位契約名をすべて最新仕様に同期） | - |
| 6 | 中 | logical-design - 依存方向の「直接参照しない」表現とユースケースの実際の参照先が矛盾 | 修正済み（境界を「契約層 vs 内部実装データ」として再整理。「judge() 契約を介して扱い、内部では index/spec を実装データとして読む」に統一） | - |
| 7 | 低 | domain-model/logical-design - PhaseResolver 判定順の `unknown` ラベルが入力状態と戻り値型で混在 | 修正済み（判定順5段目を「新規開始フォールバック」に改名、unknown は PhaseProgressStatus の入力状態ラベルのみで使用。Diagnostic に `new_cycle_start` (severity=info) を追加） | - |
| 8 | 中 | domain-model - 内部手順で PhaseLocalStepResolver.resolveStep() 残存、logical-design の判定順末尾で `unknown (新規開始)` 残存 | 修正済み（resolveStep → determine_current_step に統一、判定順末尾を「新規開始フォールバック」に置換、diagnostics を warning/info 両対応に記述） | - |
| 9 | 低 | logical-design - spec 参照トークン形式が「`spec§N.M` は将来拡張、本 Unit ではトップレベルのみ」という古い記述と `spec§5.setup_done` の現行使用で矛盾 | 修正済み（正式文法を `spec§N` と `spec§N.<checkpoint_id>` の2形式として確定、正規化ルールを明記、Unit 003/004 拡張形式 `spec§5.<phase>.<checkpoint_id>` も明記） | - |
| 10 | 低 | logical-design - スケーラビリティ節に旧方針「将来の拡張は `spec§N.M` 形式のみ」が残存 | 修正済み（参照トークン形式節に一本化、スケーラビリティ節は `spec§N` / `spec§N.<checkpoint_id>` / `spec§5.<phase>.<checkpoint_id>` の3形式を明示） | - |
