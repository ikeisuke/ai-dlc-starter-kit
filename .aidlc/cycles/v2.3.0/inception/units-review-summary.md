# レビューサマリ: Unit 定義

## 基本情報

- **サイクル**: v2.3.0
- **フェーズ**: Inception
- **対象**: Unit 定義 6件（story-artifacts/units/001〜006）+ decisions.md

---

## Set 1: 2026-04-09

- **レビュー種別**: reviewing-inception-units
- **使用ツール**: codex
- **反復回数**: 3（指摘4件→1件→0件）
- **結論**: 指摘対応判断完了

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | Unit 002 - 責務「各フェーズのインデックスに判定セクション実装」と依存関係（Unit 001 のみ）が矛盾。Construction/Operations インデックスは Unit 003/004 で作成されるため順序不整合 | 修正済み（Unit 002 を「共通判定仕様策定 + Inception 先行適用」に責務縮小。Unit 003/004 が各フェーズインデックスへの組み込みを担当。依存関係は 001→002→003/004 と一直線化） | - |
| 2 | 高 | ストーリー 6/7 が Should-have、Unit 005 が Medium。Intent「#519 Tier 2/3 完遂」と優先度がねじれている | 修正済み（ストーリー 6/7 を Must-have、Unit 005 を High/Must-have に引き上げ。DR-008 として決定を記録） | - |
| 3 | 中 | Unit 005 - review-flow.md 移管先が「共通参照ファイル or 各フェーズインデックス」と両論併記。依存先も Unit 001/004 のみで Construction 側との関係が欠落 | 修正済み（移管先を `steps/common/review-routing.md` に確定。依存先に Unit 003 を追加し、全フェーズインデックスから参照する構造を明文化） | - |
| 4 | 中 | decisions.md - Tier 2 必達度、boilerplate 扱い、Unit 002 実装順序、Unit 分割方針の判断根拠が未記録 | 修正済み（DR-008: Tier 2 必達度 / DR-009: boilerplate 自動解消扱い / DR-010: Unit 002 責務範囲と段階導入順 / DR-011: 6 Unit 分割方針 の4件を追加記録） | - |
| 5 | 中 | ストーリー9 が Should-have のまま一方 Unit 006 は High 扱いで優先度不一致。DR-008「サイクル完了＝#519 クローズ」と衝突 | 修正済み（ストーリー9 を Must-have に引き上げ） | - |
