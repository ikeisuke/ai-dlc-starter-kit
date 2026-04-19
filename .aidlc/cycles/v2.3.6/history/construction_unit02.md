# Construction Phase 履歴: Unit 02

## 2026-04-19T23:12:33+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-write-history-post-merge-guard（write-history.sh マージ後呼び出しガード + 04-completion.md 禁止記述）
- **ステップ**: Unit 完了
- **実行内容**: Unit 002 完了 - write-history.sh マージ後呼び出しガード + 04-completion.md 禁止記述（#583-B / DR-001）

## 実装内容

1. **write-history.sh 拡張**（skills/aidlc/scripts/write-history.sh）
   - 新引数 --operations-stage（pre-merge|post-merge、未定義値は exit 1）
   - ガード関数群追加: validate_operations_stage / read_progress_slot / query_pr_state / emit_post_merge_rejection / evaluate_post_merge_guard
   - 第一条件（--operations-stage post-merge）→ 第二条件（completion_gate_ready=true AND gh pr view で state=MERGED ∧ mergedAt!=null ∧ number 一致）→ それ以外は従来動作、の 3 段評価
   - 拒否時は exit 3 + 機械可読メッセージ error:post-merge-history-write-forbidden:<reason_code>:<diagnostics> を stdout と stderr の両方に重複出力
   - gh 呼び出し最大 1 回保証（GUARD_PR_QUERY_DONE キャッシュ）
   - inline comment（# 以降）除去で §5.3.5 grammar 準拠

2. **/write-history スキル SKILL.md 更新**（skills/write-history/SKILL.md）
   - 引数表に --operations-stage 追記
   - 出力セクションに終了コード表追加（exit 3 の意味記載）
   - Operations Phase 呼び出し例に pre-merge 明示版と 04-completion.md への参照を追加

3. **04-completion.md 禁止記述追加**（skills/aidlc/steps/operations/04-completion.md §5 冒頭）
   - 【重要】マージ前完結ルール: post-merge-sync.sh 実行前の history / progress.md 改変禁止
   - /write-history 呼び出し禁止と exit 3 ガードの説明
   - pre-merge 明示呼び出しの案内（後方互換）

4. **テスト整備**（skills/aidlc/scripts/tests/test_write_history_post_merge_guard.sh）
   - Story 1.2 受け入れ基準 5 ケース + 境界異常系 8 ケース = 全 13 テスト、PASS 26 件
   - fake gh による PATH hijacking + argv 契約検証（subcommand / pr_number 正整数 / --json フィールド一致）
   - 拒否系ケースは stdout / stderr 分離取得で両チャネル出力を個別検証
   - gh 呼び出し回数カウンタで実装最適化（1 回限定）を回帰検証

## レビュー実施結果

- 計画 AI レビュー: 3 反復、指摘 4→2→0 件
- 設計 AI レビュー: 3 反復、指摘 3→2→0 件（エラー出力契約 / §5.3.5 parser 範囲 / 層分離）
- コード AI レビュー: 2 反復、指摘 4→0 件（両チャネル検証 / fake gh argv / 未使用ヘルパー削除 / SKILL.md 表記）
- 統合 AI レビュー: 2 反復、指摘 2→0 件（inline comment 対応 / 契約文書同期 + 実装状態更新）

## 成果物

- skills/aidlc/scripts/write-history.sh（引数・ガード・エラー出力・コメント更新）
- skills/aidlc/scripts/tests/test_write_history_post_merge_guard.sh（新規、26 PASS）
- skills/write-history/SKILL.md（引数表 / 出力表 / 例）
- skills/aidlc/steps/operations/04-completion.md（禁止記述）
- .aidlc/cycles/v2.3.6/design-artifacts/domain-models/unit_002_write_history_post_merge_guard_domain_model.md
- .aidlc/cycles/v2.3.6/design-artifacts/logical-designs/unit_002_write_history_post_merge_guard_logical_design.md
- .aidlc/cycles/v2.3.6/plans/unit-002-plan.md
- .aidlc/cycles/v2.3.6/construction/units/002-review-summary.md

## テスト実行

bash skills/aidlc/scripts/tests/test_write_history_post_merge_guard.sh → PASS=26, FAIL=0

## 関連

- Issue #583（#583-B Pattern B、マージ後 write-history 追記防止）
- DR-001（AND 条件評価、undecidable 扱い）
- phase-recovery-spec.md §5.3.5 / §5.3.6（固定スロット grammar / GitHubPullRequestGateway 信頼境界）
- Unit 001（operations-release.md §7.6 固定スロット反映）は独立に完了済み
- Unit 003（CHANGELOG 集約）は本 Unit マージ後に着手予定
- **成果物**:
  - `skills/aidlc/scripts/write-history.sh`
  - `skills/aidlc/scripts/tests/test_write_history_post_merge_guard.sh`
  - `skills/write-history/SKILL.md`
  - `skills/aidlc/steps/operations/04-completion.md`
  - `.aidlc/cycles/v2.3.6/construction/units/002-review-summary.md`

---
