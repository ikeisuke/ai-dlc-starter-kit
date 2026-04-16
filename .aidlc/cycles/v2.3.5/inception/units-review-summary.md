# レビューサマリ: Unit 定義

## 基本情報

- **サイクル**: v2.3.5
- **フェーズ**: Inception
- **対象**: story-artifacts/units/*.md（001-004）

---

## Set 1: 2026-04-17

- **レビュー種別**: Inception Unit 定義 承認前
- **使用ツール**: codex
- **反復回数**: 3（初回 + 2回修正確認）
- **結論**: 指摘0件（全件解消）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | Unit 002/003 が共通で `scripts/operations-release.sh` を更新対象にしているのに依存関係が両方「なし」。並行実装で競合リスク | 修正済み（Unit 002 に「Unit 003 は後続」明記、Unit 003 の依存関係に Unit 002 を追加） | - |
| 2 | 中 | Unit 002 が「runtime 判定修正」と「Construction 側の squash 後案内」を同居させており INVEST 違反 | 修正済み（Unit 004 を新規作成し Construction 側案内を分離、Unit 002 は runtime 修正に限定） | - |
| 3 | 中 | Unit 001 の責務に「7.7 時点で判定ソース確定を肯定形で明記する」が欠落しストーリー1 AC取りこぼしリスク | 修正済み（Unit 001 責務に「index.md または該当 step に肯定形で明記」を追加、技術的考慮事項でも補足） | - |
| 4 | 低 | 見積もりが全 Unit「1 Unit」で相対比較不能 | 修正済み（S/M/L 表記に統一。Unit 001=L、002=M、003=S、004=S） | - |
| 5 | 低 | Unit 004 の編集対象が `steps/construction/**` と広く責務境界が緩い | 修正済み（編集対象の第一候補を `04-completion.md` と明示、他ファイル波及は設計フェーズ判断に限定） | - |

### シグナル

- review_detected: true
- deferred_count: 0
- resolved_count: 5
- unresolved_count: 0
- セミオートゲート判定: auto_approved

### Unit 一覧（最終）

| # | Unit 名 | 対応Issue | 見積 | 依存 |
|---|---------|-----------|------|------|
| 001 | Operations 復帰判定の進捗源移行 | #579 | L | なし |
| 002 | リモート同期チェックの squash 後 divergence 対応（runtime 判定修正） | #574 (1)(2) | M | なし |
| 003 | merge-pr `--skip-checks` オプション追加 | #575 | S | Unit 002（ファイル共有） |
| 004 | Construction 側の squash 完了後の force-push 案内追加 | #574 (3) | S | Unit 002（論理依存） |
