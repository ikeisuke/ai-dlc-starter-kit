# 実装記録: Unit 001 Inception フェーズインデックスのパイロット実装

## 実装日時

2026-04-09（single session）

## 作成ファイル

### 新規作成

- `skills/aidlc/steps/inception/index.md` — Inception フェーズインデックスファイル。目次・分岐ロジック・判定チェックポイント骨格・ステップ読み込み契約を集約（4,484 tok）

### 更新

- `skills/aidlc/SKILL.md` — 不変ルール「ステップファイル読み込みは省略不可」にフェーズインデックス併用時の注記追加。「フェーズステップ読み込み」テーブルの inception 行を `index.md` のみに更新（+243 tok）
- `skills/aidlc/steps/inception/03-intent.md` — ステップ1 末尾の「セミオートゲート判定」記述を `index.md` の「2.4 automation_mode 分岐」への参照に置換（-111 tok）
- `skills/aidlc/steps/inception/04-stories-units.md` — ステップ3 / ステップ4 末尾の「セミオートゲート判定」記述を同参照に置換（-222 tok）
- `skills/aidlc/steps/common/compaction.md` — フェーズごとの再読み込みパス表の Inception 行を `index.md` + `progress.md` 未完了ステップ特定に更新。「フェーズの特定」表に #553 相当の誤判定を防ぐ Inception 優先ガード（判定順2）を追加。非正本・暫定・Unit 002 削除予定注記を追加

### 設計ドキュメント

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_001_inception_index_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_001_inception_index_logical_design.md`

### 計画・レビュー

- `.aidlc/cycles/v2.3.0/plans/unit-001-plan.md`（5回反復レビュー済み）
- `.aidlc/cycles/v2.3.0/construction/units/001-review-summary.md`（設計4回 + コード2回 + 統合4回）

## ビルド結果

**成功**（ドキュメント変更のみ、ビルド対象なし）

## テスト結果

**成功**（全DoD検証項目通過）

### tok 計測結果

```text
v2.2.3 ベースライン（9 ファイル）:
  4685 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   181 tok  skills/aidlc/steps/common/session-continuity.md
  3353 tok  skills/aidlc/steps/inception/01-setup.md
  2053 tok  skills/aidlc/steps/inception/02-preparation.md
  2536 tok  skills/aidlc/steps/inception/03-intent.md
  3076 tok  skills/aidlc/steps/inception/04-stories-units.md
  3238 tok  skills/aidlc/steps/inception/05-completion.md
 22972 tok  TOTAL

v2.3.0 Unit 001 実装後（5 ファイル）:
  4928 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   181 tok  skills/aidlc/steps/common/session-continuity.md
  4484 tok  skills/aidlc/steps/inception/index.md
 13443 tok  TOTAL

削減量: 9,529 tok (-41.5%)
目標: 15,000 tok 以下 → ✅ 達成（余裕 1,557 tok）
```

### 静的構造回帰検証結果

- ✅ テンプレート完全一致（6ファイル）: intent / user_stories / unit_definition / prfaq / decision_record / inception_progress
- ✅ 成果物パス一覧一致（8パス）: history/inception.md / decisions.md / progress.md / existing_analysis.md / intent.md / prfaq.md / units/*.md / user_stories.md
- ✅ `/write-history` 呼び出しステップ名集合一致
- ✅ progress.md 更新指示一致

### 契約ルーティング検証結果

- ✅ 全5 `step_id` 解決成功（`inception.01-setup` 〜 `inception.05-completion`）
- ✅ 全5 `detail_file` が Read 可能
- ✅ StepLoadingContract 列構造固定（`step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`）
- ✅ RecoveryCheckpoint 列構造固定・全5行・全 TBD セル固定
- ✅ load_timing 全5行 `on_demand`
- ✅ 既定ルート（新規開始時は `inception.01-setup`、復帰時は `progress.md` 未完了ステップ特定）明記

## コードレビュー結果

- [x] セキュリティ: OK（機密情報なし、ドキュメントのみ）
- [x] コーディング規約: OK（Markdown 記述、リンク切れなし）
- [x] エラーハンドリング: OK（該当なし、ドキュメント）
- [x] テストカバレッジ: OK（静的構造検証・契約ルーティング検証・tok 計測すべて通過）
- [x] ドキュメント: OK（Source of Truth 宣言、汎用構造仕様、Unit 001/002 責務境界すべて明記）

**レビュー履歴**: 計画（codex ×5）→ 設計（codex ×4）→ コード（codex ×2）→ 統合（codex ×4）、計15反復。全指摘計19件を解消。

## 技術的な決定事項

1. **契約スキーマの固定化**: `StepLoadingContract` と `RecoveryCheckpoint` の列構造・行構造を「予算都合でも変更不可」と明記。Unit 002 が機械的に流し込めるよう契約不変領域として保護
2. **load_timing ポリシー**: Unit 001 では全 `detail_file` を `on_demand` に固定。計測対象と契約を一致させ、15,000 tok 判定の偽陽性を排除
3. **既定ルートの文脈分離**: 新規開始時は `inception.01-setup`、コンパクション復帰時は `inception/progress.md` から未完了ステップ特定、という2種類の開始点を明示
4. **Inception 優先ガード（#553 暫定対処）**: `compaction.md` の判定表に `inception/progress.md` 未完了ステップ存在チェックを Construction 判定より優先する判定順2を追加。本格的な解決は Unit 002（`phase-recovery-spec.md`）に委ねる
5. **`セミオートゲート判定` 契約語の維持**: SKILL.md が `セミオートゲート判定` を semi_auto 対象識別の契約語として参照しているため、詳細ステップファイルの見出し語は維持し、内容のみ `index.md` 参照に置換
6. **Source of Truth 宣言**: `index.md` 冒頭コメントで「Inception の現在位置判定の正本は本インデックス」と明示。`compaction.md` の旧判定テーブルは非正本・Unit 002 削除予定と宣言
7. **汎用構造仕様コメント**: `<!-- phase-index-schema: v1 -->` でスキーマ世代を識別。Unit 003/004 が本構造をそのまま流用する前提を固定

## 課題・改善点

### Unit 002 への引き継ぎ項目

- `index.md` の判定チェックポイント骨格（5行 × 5列 × TBDセル）に実値を流し込む
- `steps/common/phase-recovery-spec.md` を新規作成し、`CurrentStepDetermination.determine` の内部判定規則を定義（4系統の reason_code: `missing_file` / `conflict` / `format_error` / `legacy_structure`）
- `compaction.md` の「フェーズの特定」表を完全削除し、Inception 優先ガード（判定順2）を共通判定仕様に置き換え
- Construction/Operations も `index.md` の判定チェックポイント骨格を参照できるよう Unit 003/004 側でインデックスに判定セクションを実装

### Unit 001 での残課題

- 特になし。全 DoD 検証項目が通過

## 状態

**完了**

## 備考

- 本 Unit は v2.3.0 サイクル全体の基盤 Unit であり、Unit 002-006 のすべてが本 Unit の成果物に依存する
- 計画・設計・実装・テスト・レビューの全フェーズで合計15回のレビュー反復を実施。全19件の指摘を解消し、指摘0件で承認可に到達
- 初回ロード削減量 -41.5% は Intent 目標 -35% を超過達成
