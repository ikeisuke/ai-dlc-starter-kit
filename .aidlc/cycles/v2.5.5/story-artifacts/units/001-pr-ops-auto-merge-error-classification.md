# Unit: pr-ops.sh の auto-merge エラー判別精度向上

## 概要

`scripts/lib/pr-ops.sh` の `auto_error` grep パターンを拡張し、auto-merge 無効リポジトリ + CI pending 状態での `error:unknown` 返却を解消する。GitHub CLI 実エラー文言（`Auto merge is not allowed`、`enablePullRequestAutoMerge`）にマッチするパターンを追加し、`pr:<N>:error:auto-merge-not-enabled` を返す。bats テストにエラー分類シナリオを追加。

## 含まれるユーザーストーリー

- ストーリー 1: pr-ops.sh の auto-merge エラー判別精度向上（#665）

## 責務

- `skills/aidlc/scripts/lib/pr-ops.sh:449` 付近の `auto_error` grep パターン拡張（`auto[- ]merge is not allowed` / `enablePullRequestAutoMerge` を含む形）
- `tests/operations-release.bats`（または相当する bats ファイル）に GitHub CLI 実エラー文言を fixture として与えるエラー分類シナリオを 1 件以上追加
- 既存パターン `auto-merge is not allowed`（ハイフン付き）の後方互換テスト維持

## 境界

- `pr-ops.sh` の他のエラーパターン（`merge conflict` / `branch protection` 等）の再設計は行わない（OUT_OF_SCOPE）
- `operations-release.md §7.13` のエラー対処案内本文の修正は行わない（既存案内が起動するように grep 側を改善するだけ）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- `gh` CLI 実エラー文言（v2.42.0+ で確認、将来バージョン更新時は fixture 更新で気付ける）

## 非機能要件（NFR）

- **パフォーマンス**: grep 1 行追加のため計測対象外
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: bats テストでパターン拡張の後方互換性を保証

## 技術的考慮事項

- 推奨パターン: `grep -qiE "auto[- ]merge is not allowed|enablePullRequestAutoMerge|not enabled|auto_merge"`（case-insensitive、camelCase / snake_case 両対応）
- **fixture 更新トリガーの記録先（DR-001）**: Unit 001 完了履歴 `.aidlc/cycles/v2.5.5/history/construction_unit01.md` に「fixture 更新トリガー: gh CLI バージョン更新で auto-merge 実エラー文言が変わった場合、bats fixture が失敗することで気付ける」を 1 行以上記録（Unit 005 と保守方針統一）

## 関連Issue

- #665（[Feedback] pr-ops.sh merge: auto-merge 無効リポジトリで error:unknown が返る）

## 実装優先度

High

## 見積もり

1〜2 時間（grep 1 行 + bats テスト 1 件 + 後方互換テスト確認）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-08
- **完了日**: 2026-05-08
- **担当**: AI-DLC エージェント
- **エクスプレス適格性**: -
- **適格性理由**: -
