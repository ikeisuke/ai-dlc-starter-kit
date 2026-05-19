# Construction Phase 履歴: Unit 04

## 2026-05-19T09:58:49+09:00

- **フェーズ**: Construction Phase
- **Unit**: 04-loop-issue-flow-and-validation（§1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証）
- **ステップ**: 計画 AI レビュー完了
- **実行内容**: 計画 AI レビュー（codex）完了 2R clean。

- セッション ID: `019e3db3-123f-7d43-b0a7-e0989ec2dfb1`
- Round 1: 3 件（高 0 / 中 2 / 低 1）→ ①完了ゲート総数不整合（13 → 15 項目）②依存関係の自己矛盾（実装依存 = Unit 001/002 / 運用上の着手前提 = Unit 003 完了確認に分離）③patch 条件とのトレーサビリティ強化（4C 完了ゲートの「CI green」を「既定動作系 SC-02/03 + opt-in 復元系 SC-04 の両テスト群を含む」と明示確認）
- Round 2: 指摘 0 件 → clean

完了条件: `rounds.size=2 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。
- **成果物**:
  - `.aidlc/cycles/v2.6.6/plans/unit-004-plan.md`

---
## 2026-05-19T09:58:59+09:00

- **フェーズ**: Construction Phase
- **Unit**: 04-loop-issue-flow-and-validation（§1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証）
- **ステップ**: 設計 + 設計 AI レビュー完了
- **実行内容**: 設計（ドメインモデル + 論理設計）完成 + 設計 AI レビュー（codex）完了 3R clean。

- セッション ID: `019e3db9-b9ca-7752-b500-9a6a8a83baf5`
- Round 1: 4 件（高 2 / 中 2 / 低 0）→ ①SelfReviewVerdict を Try 単位 `Map<try_id, SelfReviewVerdict>` に変更 ②closedAt null 安全ソート式を `sort_by((.closedAt // "")) | reverse` に修正 ③cap/dialog 失敗 = `break`、section 失敗 = `continue` で制御フロー仕様統一 + creation_summary 拡張 ④テンプレ選択ルール新設（HTML コメントマーカー `try_loop_block` / `aggregate_block` の 2 ブロック明示分離）
- Round 2: 1 件（中）→ ⑤§1.5 Step 4 分岐ロジック INPUT を `verdict_map` に統一（TryLoopCreationStrategy と整合）
- Round 3: 指摘 0 件 → clean

完了条件: `rounds.size=3 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。
- **成果物**:
  - `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_004_loop_issue_flow_and_validation_domain_model.md`
  - `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md`
  - `.aidlc/cycles/v2.6.6/construction/units/004-review-summary.md`

---
## 2026-05-19T11:49:30+09:00

- **フェーズ**: Construction Phase
- **Unit**: 04-loop-issue-flow-and-validation（§1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証）
- **ステップ**: Phase 2 実装完了 + コード/統合 AI レビュー完了 / Unit 完了
- **実行内容**: Phase 2（実装）完了 + コード AI レビュー（codex）2R clean + 統合 AI レビュー（codex）2R clean。

**実装**:

- 4A: `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 4 を `aggregate_issue_enabled` で Step 4-A TryLoopCreationStrategy（既定 / T ループ起票）と Step 4-B AggregatedCreationStrategy（opt-in / 集約 Issue）に分岐。Step 4-A は 5 必須見出し（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）非空保証 + cap/dialog 失敗 break / section invalid continue の制御フロー仕様確定。
- 4A: `skills/aidlc/templates/retrospective_template.md` の Try セクションを `try_loop_block` / `aggregate_block` HTML コメントマーカーで明示分離（設計レビュー R1 指摘 #4 対応）。
- 4B: `skills/aidlc/scripts/lib/predecessor-issue.sh` の `_pure_classify_resolution_path` 引数 6/7 を optional 末尾追加（既存呼出は 0 デフォルトで warn_continue にフォール / 既存 5 経路完全不変）。warn_continue 直前に新動作経路 2 サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback` を追加。`__pred_gh_query_t_issue`（T Issue 用 gh CLI 呼出 / canonical title `[Retrospective: <cycle>]` 完全一致 + ` ` 区切り prefix の 2 条件絞り込み）+ `_pure_sort_by_closed_at_desc_null_safe`（closedAt null 末尾安全ソート）を新規追加。
- 4B: 既存 `__pred_gh_query` の milestone_enabled=true 経路にも T Issue prefix 除外フィルタを追加（label_fallback と同じ canonical title 判定形式に統一）。

**テスト**:

- 新規 `tests/predecessor-issue-t-loop.bats`: 8 件（T1〜T8 / 新動作経路 2 サブ分岐 + 旧サイクル維持 + null 安全ソート + T Issue prefix 除外）
- 新規 `tests/retrospective-issue-loop-create.bats`: 13 件（T-LOOP-1〜T-LOOP-13 / テンプレ整合性 + Step 4-A 構造ガード）
- 既存 `tests/predecessor-issue-handoff.bats` P2 fixture を canonical title (`Retrospective: v2.5.0`) に更新（milestone_and_label 経路の T Issue prefix 除外フィルタ追加に伴う調整）
- bats 248/248 pass（既存 retrospective_* + predecessor_* 全件 + 新規 21 件 / regression なし）
- shellcheck: warning は既存と同型のみ（本 Unit 追加分由来なし）
- markdownlint: 0 error
- bash 構文チェック: pass

**レビュー**:

- コード AI レビュー: codex 2R clean（auto_approved）
  - Round 1: 2 件（中 1 / 低 1）→ ①candidates スキーマ統一（number 除外）②T Issue 判定 prefix 厳密化
  - セッション ID: `019e3e1d-0233-7c82-bebf-3b31dacacd21`
- 統合 AI レビュー: codex 2R clean（auto_approved）
  - Round 1: 2 件（中 1 / 低 1）→ ①review-summary に Set 2/Set 3 追記 ②plan.md チェックリスト + Unit 定義実装状態を完了に更新
  - セッション ID: `019e3e1f-7bc5-7ca0-a658-d06c8c5661a8`

**完了条件**: 4A: 5/5 / 4B: 5/5 / 共通: 4/4 → 14 項目達成。4C: 5 項目は Operations Phase §1 retrospective / release PR / 完了処理に委譲（plan.md 4C 完了ゲートに委譲先明記）。

**意思決定記録**: 重要な意思決定なし（既存実装規約に沿った改修のみ）。

**4C 検証フェーズ委譲**: dogfooding (a)(b)(c) / CI green + 後方互換 fixture / PR Closes・Comment / CHANGELOG 3 項目は Operations Phase で実施。
- **成果物**:
  - `skills/aidlc/scripts/lib/predecessor-issue.sh`
  - `skills/aidlc-retrospective/steps/retrospective.md`
  - `skills/aidlc/templates/retrospective_template.md`
  - `tests/predecessor-issue-handoff.bats`
  - `tests/predecessor-issue-t-loop.bats`
  - `tests/retrospective-issue-loop-create.bats`
  - `.aidlc/cycles/v2.6.6/construction/units/004-review-summary.md`
  - `.aidlc/cycles/v2.6.6/story-artifacts/units/004-loop-issue-flow-and-validation.md`

---
