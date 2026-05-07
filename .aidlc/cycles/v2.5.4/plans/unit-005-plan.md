# Unit 005 計画: AI レビュー完了条件を `last_round_clean` に緩和（hotfix）

## 概要

`skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」（v2.5.2 Unit 001 / #635 で導入）から `last_two_rounds_clean` 規則を削除し、`last_round_clean`（直近 round が clean なら完了）ベースに書き換える。同時に `skills/aidlc/templates/review_summary_template.md` の反復回数表記補注を新ルールと整合させる。

5R 上限 / defer 自動 Issue 起票 / 千日手検出 / Round 4+ 新領域 backlog 化 などの v2.5.2 で導入された他要素は **完全に維持**する。

## 関連 Issue

- なし（v2.5.4 内部 hotfix、Issue 起票なし）
- 関連: v2.5.2 Unit 001 / #635（5R 化導入元）

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 完了条件判定（SoT） | `last_round_clean` ベースの完了規則 | `skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」セクション |
| 整合参照 | パス 2（セルフ）記述「反復上限・完了条件はパス 1 と同一」 | 同上ファイル先頭付近 |
| テンプレート補注 | 反復回数表記の sequential history 補注 | `skills/aidlc/templates/review_summary_template.md` |
| 履歴 | 実装進捗の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit05.md` |

**ドリフト防止策**:

- 形式選択: 既存スタイル踏襲の **形式 B**（`1R clean 特例` を独立規則として残し、`rounds.size >= 2 && last_round_clean → completed` を別規則として明記）を採用
- `last_two_rounds_clean` 文字列を完全削除（grep で確認）
- 5R 上限・千日手検出・defer 自動 Issue 起票・Round 4+ 新領域 backlog 化の各既存記述を grep で再確認し、削除や縮約が起きていないことを検証

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/steps/common/review-flow.md` | 改修 | 「完了条件の判定単一仕様」セクションを `last_round_clean` ベース（形式 B）に書き換え。`last_two_rounds_clean` 言及を完全削除 |
| `skills/aidlc/templates/review_summary_template.md` | 改修 | 反復回数表記補注を v2.5.4 新ルール込みの sequential history に更新 |
| `.aidlc/cycles/v2.5.4/history/construction_unit05.md` | 新規 | Unit 005 進捗履歴（変更ファイル / レビュー round / 検証結果 / 後続 Unit への即時適用証跡） |

## 実装計画

### Phase 1（設計、最小）

`depth_level=standard` だが Unit 005 は **docs only / 0.5 日見積もり** のため Phase 1 は最小限とし、ドメインモデルと論理設計を 1 ファイルに統合する形で実施する:

- `design-artifacts/logical-designs/unit_005_review_flow_last_round_clean_logical_design.md`: 既存「完了条件の判定単一仕様」セクションの現行文言と新文言（形式 B）を対比し、置換手順 + grep 検証クエリ + テンプレート補注の更新方針を確定

`design-artifacts/domain-models/` 配下の独立ドメインモデルファイルは作成しない（規則表現の書き換えのみで新ドメイン語彙の導入なし、現行の `ReviewSession.is_completed()` / `ReviewRound.is_clean()` を維持）。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」セクションを形式 B で書き換え
2. `last_two_rounds_clean` 言及の完全削除を grep で確認（ヒット 0）
3. `skills/aidlc/templates/review_summary_template.md` の補注を v2.5.4 込み sequential history に更新
4. 5R 上限・千日手検出・defer 自動 Issue 起票・Round 4+ 新領域 backlog 化の既存記述が残っていることを grep で検証
5. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
6. markdownlint 実行 / 履歴記録

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `last_two_rounds_clean` の grep ヒットが残る | 該当箇所をすべて削除し再 grep。ヒット 0 になるまで反復 |
| 既存規則の重複・矛盾（同一 round が二重判定される） | 形式 B の独立規則間で適用範囲（`rounds.size == 1` vs `rounds.size >= 2`）が排他的になることを文言で明示 |
| 5R 上限・千日手・defer・Round 4+ の grep が消失 | 書き換え範囲を狭め、対象セクション外の記述を保持 |
| markdownlint 失敗 | 該当ルール（MD013 line-length / MD031 等）を調整 |
| 既存 v2.5.2 Unit 001 のレビュー履歴記述（履歴ファイル等の過去サイクル成果物）への遡及書き換え発生 | 禁止。`git diff --name-only` で `.aidlc/cycles/v2.5.4/history/`（本サイクル分）と `skills/aidlc/{steps,templates}/...` のみ変更対象であることを確認 |

## NFR

- **パフォーマンス**: docs のみ改訂のためランタイム影響なし。新ルール適用後は AI レビュー所要 round が 1〜2 round 削減される見込み
- **セキュリティ**: 機密情報の取り扱いに変更なし
- **後方互換**: `5R 上限`・`defer 自動 Issue 起票`・`千日手検出`・`Round 4+ 新領域 backlog 化` などの v2.5.2 導入要素を維持。`1R clean 特例` の挙動は形式 B の独立規則として明記し維持
- **可用性**: 影響なし

## 完了条件チェックリスト

### 機能要件

- [ ] `skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」セクションが形式 B で書き換えられている（`1R clean 特例` 独立 + `2R 以上 + last_round_clean → completed`）
- [ ] `grep -c "last_two_rounds_clean" skills/aidlc/steps/common/review-flow.md` の結果が **0**
- [ ] パス 2（セルフ）記述の「反復上限・完了条件はパス 1 と同一」が新ルールと整合
- [ ] `skills/aidlc/templates/review_summary_template.md` の反復回数表記補注が v2.5.4 込み sequential history に更新されている

### 既存ガード仕様の維持

`grep -c` をキーワードごとに独立実行し、変更前 HEAD（基準値）と変更後で件数を比較する。基準値取得は `git show HEAD:skills/aidlc/steps/common/review-flow.md | grep -c "<keyword>"` を変更前に 1 度実行して固定。

- [ ] `grep -c "5R" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `grep -c "5 round" skills/aidlc/steps/common/review-flow.md` の値が基準値以上（半角スペース表記）
- [ ] `grep -E -c "5[[:space:]]*round" skills/aidlc/steps/common/review-flow.md` の値が基準値以上（POSIX 文字クラスでスペース有無を吸収、BSD/GNU grep 両対応）
- [ ] `grep -c "千日手" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `grep -c "new-area-from-round4plus" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `grep -c "defer 自動 Issue 起票" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `is_clean()` の定義は変更なし
- [ ] レビュー実行手順（パス 1/2/3）・指摘対応判断フロー・スコープ保護確認・機密情報マスクには変更なし

### 形式 B 排他設計の検証ケース表

形式 B の独立規則（`rounds.size == 1 && last_round_clean → completed` / `rounds.size >= 2 && last_round_clean → completed` / `rounds.size >= 5 && unresolved_count > 0 → decision_required`）が同一 round に対して二重判定されないことを以下のケースで確認する（具体的な文言と判定結果は logical design で確定）:

| ケース | rounds.size | last_round_clean | unresolved_count | 期待結果 |
|--------|-------------|------------------|------------------|---------|
| Round 1 clean | 1 | true | 0 | `completed`（1R clean 特例ルール） |
| Round 2 clean（Round 1 で指摘 → Round 2 resolve） | 2 | true | 0 | `completed`（2R 以上 + last_round_clean ルール、新ルール下で 1R 短縮） |
| Round 2 中（Round 1 で指摘・Round 2 まだ） | 2 | false | >0 | `in_progress` |
| Round 5 unresolved | 5 | false | >0 | `decision_required` |
| Round 5 clean | 5 | true | 0 | `completed`（2R 以上 + last_round_clean ルール、5R 上限まで使い切り） |

各ケースで適用される規則が **1 つだけ** であること（`rounds.size == 1` と `rounds.size >= 2` は排他）を確認する。

### スコープ保護

- [ ] 設定ファイル（`config.toml`）への新規キー追加なし
- [ ] レビューサマリの「指摘一覧」テーブル形式・列ガイダンスは変更なし
- [ ] v2.5.4 サイクル内で **既に完了済み**の AI レビュー成果物（Unit 001 完了時のレビュー履歴等）への遡及書き換えなし
- [ ] `git diff --name-only` で変更対象が `skills/aidlc/steps/common/review-flow.md` / `skills/aidlc/templates/review_summary_template.md` / `.aidlc/cycles/v2.5.4/history/construction_unit05.md` / 計画 + Unit 定義のみであることを確認

### 履歴

- [ ] `.aidlc/cycles/v2.5.4/history/construction_unit05.md` が新規作成され、変更ファイル / レビュー round / 検証 grep 結果 / 後続 Unit への即時適用方針が追記されている

### 品質ゲート

- [ ] markdownlint（`markdown_lint=true` 設定）が変更対象ファイルで pass
- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（**新ルール: 直近 round が clean**、ただし Unit 005 自身のレビューは現行 `last_two_rounds_clean` ルール下で実施するか、ユーザー裁量で `last_round_clean` 相当として早期適用する）を満たす
- [ ] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み

## 見積もり

- 設計フェーズ: 0.25 日（既存規則の置き換え範囲確定 + 形式 B の文言確定 + grep 検証クエリ整備）
- 実装フェーズ: 0.25 日（review-flow.md 該当箇所書き換え + template 補注更新 + grep 検証 + lint）
- 合計: **0.5 日**（Unit 定義の見積もりと一致）
