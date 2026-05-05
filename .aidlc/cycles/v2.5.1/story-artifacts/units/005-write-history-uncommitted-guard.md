# Unit: #616 マージ前 write-history 追加コミット漏れガード

## 概要

Operations Phase 7.12 PR マージ前レビュー反映後の `/write-history` 追加コミット未実施をフローガードで検出し、マージブロック（exit ≥ 1）する。実装 Option（A: review-flow ガード / B: write-history --commit / C: verify-git 必須化 / D: write-history 1 回限定）の選定は Construction で確定。Option 非依存の観測点（exit code / BATS テスト）は本 Unit で必ず満たす。

## 含まれるユーザーストーリー

- ストーリー 6: #616 マージ前 write-history 追加コミット漏れガード

## 責務

- 7.12 マージ前レビュー反映後の未コミット差分検出ガード（実装 Option は Construction で確定）
- `review-flow.md` L50「レビュー後コミット」の手順明確化
- BATS テスト `tests/operations-uncommitted-detection.bats`（Option 非依存の最小契約 verify）
- 既存 Issue #579（マージ後 write-history 禁止 exit 3）との整合維持

## 境界

- 振り返り Issue 起票・wizard・LLM 下書きは他 Unit が担う（本 Unit は #616 単独）
- マージ後フェーズの動作は本 Unit のスコープ外（既存 #579 ガードと整合させるのみ）

## 依存関係

### 依存する Unit

- なし（論理的依存はなし / 振り返り関連と並列実装可能）

**ファイル競合リスク注記**: 本 Unit が改修対象とする `steps/common/review-flow.md` および `scripts/operations-release.sh` は Unit 002 / Unit 003 も同時期に触る可能性がある。手戻り防止のため、**実装順は Unit 001 / Unit 002 の主要改修完了後を推奨**（並列着手自体は可能だがマージ時のコンフリクト解消コストを下げる狙い）。

### 外部依存

- 既存 `scripts/operations-release.sh verify-git`
- 既存 `scripts/write-history.sh`
- 既存 `steps/common/review-flow.md`

## 非機能要件（NFR）

- **回帰防止**: v2.4.3 で発生した未コミット差分破棄事故が再発しない
- **観測性**: ガード発火時のエラーメッセージで対処方法を明示
- **互換性**: 既存マージ後 write-history 禁止 exit 3 動作を破壊しない

## 技術的考慮事項

- 実装 Option（A/B/C/D）の trade-off を Construction Phase Phase 1（設計）で評価し、1 つに確定
- 確定後は受け入れ基準の暫定項目を確定値に置換
- `review-flow.md` L50 の文言は Option 確定後に明確化

## 関連Issue

- #616（[Backlog] Operations 7.12 PRマージ前レビュー後の write-history が追加コミット漏れする運用バグ）

## 実装優先度

Medium

## 見積もり

小規模。Option 選定 + ガード実装 + review-flow.md 改修 + BATS テスト。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-05
- **完了日**: 2026-05-05
- **担当**: Construction Phase Unit 005
- **エクスプレス適格性**: -
- **適格性理由**: -
