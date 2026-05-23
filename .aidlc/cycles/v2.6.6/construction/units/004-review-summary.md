# レビューサマリ: Unit 004 §1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証

## 基本情報

- **サイクル**: v2.6.6
- **フェーズ**: Construction
- **対象**: Unit 004 (004-loop-issue-flow-and-validation / §1.5 Try ループ起票 + predecessor 新動作経路 + dogfooding 検証)

---

## Set 1: 2026-05-19 09:57:48

- **レビュー種別**: 設計レビュー（construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（last_round_clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_004_loop_issue_flow_and_validation_domain_model.md`, `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md` - `SelfReviewVerdict` をループ全体で単数として扱い Try 単位の §1.2.5 セルフレビュー実運用と齟齬 | 修正済み（domain_model L172: 構成要素を `Map<try_id, SelfReviewVerdict>` に変更 / TryLoopCreationStrategy 入力を `verdict_map` 化 / SectionComposer 入力に「caller が verdict_map[try.try_id] で lookup 済の単数 verdict」を明示） | - |
| 2 | 高 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md` - `closedAt` null 安全ソート式 `sort_by((.closedAt // "9999-12-31T23:59:59Z")) \| reverse` が null を先頭に押し上げ「null は末尾」のコメントと矛盾 | 修正済み（L229: `sort_by((.closedAt // "")) \| reverse` に変更 / 検証コメント「null="" → 昇順先頭 → reverse 後末尾」を追加） | - |
| 3 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md` - cap 到達時 `break` と「skip 継続を採用」が併記され制御フローが二義的 | 修正済み（L130-149: cap/dialog 失敗 = `break`（残 Try 一括停止）、section 失敗 = `continue`（当該 1 件のみ skip）に統一 / `creation_summary` を `{ created_count, skipped_count: { cap_reached, dialog_required, section_invalid }, cap_reached: bool }` に拡張 / 制御フロー仕様表を新設） | - |
| 4 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md` - aggregate_issue_enabled=true 時にテンプレ旧ブロック選択条件がインターフェースとして未定義 | 修正済み（L75-76: テンプレ内 HTML コメントマーカー `<!-- BEGIN: try_loop_block -->` / `<!-- BEGIN: aggregate_block -->` で 2 ブロック明示分離 / L243 付近にテンプレ選択ルール新設 / 不変条件 4 項目を明文化） | - |
| 5 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md` - §1.5 Step 4 分岐ロジック INPUT が `selfreview_verdict (SelfReviewVerdict)` の単数のまま、同ファイル内の TryLoopCreationStrategy（`verdict_map` 前提）と契約不整合 | 修正済み（L112: INPUT を `verdict_map (Map<try_id, SelfReviewVerdict>)` に統一 / AggregatedCreationStrategy 呼び出し箇所に「verdict_map を使わない（旧フロー互換のため使用箇所なし）」備考を追加 / TryLoopCreationStrategy 呼び出しに `verdict_map` 引数を明示） | - |

### Round 履歴

- **Round 1**: 4 件指摘（高 2 / 中 2 / 低 0）— 上記 #1〜#4 を反映
- **Round 2**: 1 件指摘（中 1）— 上記 #5 を反映
- **Round 3**: 指摘 0 件（clean）

完了条件: `rounds.size=3 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。

セッション ID: `019e3db9-b9ca-7752-b500-9a6a8a83baf5`

---

## Set 2: 2026-05-19 10:30:00

- **レビュー種別**: コードレビュー（construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件（last_round_clean）

### 指摘一覧

| # | 重要度 | focus | 内容 | 対応 | バックログ |
|---|--------|-------|------|------|-----------|
| 1 | 中 | code | `skills/aidlc/scripts/lib/predecessor-issue.sh` - `t_issue_*` 経路の `candidates` スキーマが既存契約（url/title/closedAt）とずれている（`number` フィールド混入で下流厳密スキーマ前提時に後方互換リスク） | 修正済み（`__pred_gh_query_t_issue` の `gh issue list --json` を `url,title,closedAt` に変更し既存 5 経路と統一） | - |
| 2 | 低 | security | `skills/aidlc/scripts/lib/predecessor-issue.sh` - T Issue 判定 `startswith("[Retrospective: " + $cycle + "]")` が `[Retrospective: v2.6.5]foo` のような cycle id 偽装・ノイズ混入を許容する | 修正済み（jq 絞り込みを「完全一致 `[Retrospective: <cycle>]` または `[Retrospective: <cycle>]<半角スペース>` で始まる」の 2 条件に強化 / 既存 5 経路の `__pred_gh_query` label_fallback と同じ判定形式に揃えた） | - |

### Round 履歴

- **Round 1**: 2 件指摘（高 0 / 中 1 / 低 1）— 上記 #1〜#2 を反映
- **Round 2**: 指摘 0 件（clean）

完了条件: `rounds.size=2 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。

セッション ID: `019e3e1d-0233-7c82-bebf-3b31dacacd21`

---

## Set 3: 2026-05-19 11:00:00

- **レビュー種別**: 統合レビュー（construction-integration / focus: code）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件（last_round_clean）

### 指摘一覧

| # | 重要度 | focus | 内容 | 対応 | バックログ |
|---|--------|-------|------|------|-----------|
| 1 | 中 | code | `.aidlc/cycles/v2.6.6/construction/units/004-review-summary.md` - レビュー実施記録のエビデンス不足（Set 1 のみで Set 2 コードレビュー / Set 3 統合レビューが未記録） | 修正済み（本ファイルに Set 2 コードレビューと Set 3 統合レビューを追記。各 set に round 履歴 / clean 判定 / session id / 対象ファイルを明記） | - |
| 2 | 低 | code | `.aidlc/cycles/v2.6.6/plans/unit-004-plan.md`, `.aidlc/cycles/v2.6.6/story-artifacts/units/004-loop-issue-flow-and-validation.md` - 完了条件チェック (19 項目) が未チェック / Unit 定義「実装状態」が「未着手」のまま | 修正済み（plan.md の 4A: 5 項目 / 4B: 5 項目 / 共通: 4 項目を「完了」に更新 / 4C: 5 項目は Operations Phase §1 retrospective に委譲する旨を項目単位で明記 / Unit 定義の「実装状態」を「完了」に更新） | - |

### Round 履歴

- **Round 1**: 2 件指摘（高 0 / 中 1 / 低 1）— 上記 #1〜#2 を反映
- **Round 2**: 指摘 0 件（clean）

完了条件: `rounds.size=2 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。

セッション ID: `019e3e1f-7bc5-7ca0-a658-d06c8c5661a8`

---
