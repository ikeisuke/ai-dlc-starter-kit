# Unit: Cycle Phase Completion Check の draft PR skip

## 概要

`cycle/*` ブランチの draft PR で Cycle Phase Completion Check（v2.5.6 / Unit 001 / #672 で導入）が `synchronize` イベントごとに実行され、Construction 中の中間状態で CI が fail する問題を解消する。job レベルの `if` 条件で draft PR を除外し、`ready_for_review` 遷移時には通常実行される構造に変更する。

## 含まれるユーザーストーリー

- ストーリー 2: `cycle/*` の draft PR で Cycle Phase Completion Check を skip

## 責務

- `.github/workflows/cycle-phase-completion-check.yml` の `cycle-phase-completion` ジョブに draft PR 除外の `if` 条件を追加する
- 既存の `startsWith(github.head_ref, 'cycle/')` 条件を維持しつつ、`github.event.pull_request.draft == false` の併用条件にする
- Repository Ruleset 互換挙動を CHANGELOG / 関連ドキュメントで案内する

## 境界

- workflow 自体のロジック（cycle 完了判定スクリプト本体 `bin/check-cycle-phase-completion.sh` 等）は変更しない
- 他の workflow（shellcheck / markdownlint / bats 等）への波及修正は本 Unit の対象外
- Ruleset 設定そのものの変更は本 Unit の対象外（ドキュメント上の案内のみ）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- GitHub Actions runtime（`if` 式評価）

## 非機能要件（NFR）

- **パフォーマンス**: skip 時のジョブ起動コストは 0（GitHub Actions のスケジューリング段階で skip）
- **セキュリティ**: 既存ジョブ範囲の権限変更なし
- **スケーラビリティ**: N/A
- **可用性**: 既存 cycle PR フローで動作互換性維持

## 技術的考慮事項

- Issue #686 推奨案 A を採用: `if: startsWith(github.head_ref, 'cycle/') && github.event.pull_request.draft == false`
- `pull_request` トリガで `draft` プロパティが安定して取得できることを workflow 検証で確認
- `ready_for_review` イベントで draft → ready 遷移時に正しくジョブが起動することを確認

## 関連Issue

- #686

## 実装優先度

High（CI ノイズ即時解消、影響範囲小）

## 見積もり

0.25 day（workflow 1 行修正 + 動作検証 + ドキュメント追記）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-10
- **完了日**: 2026-05-10
- **担当**: AI-DLC（Claude Code）
- **エクスプレス適格性**: -
- **適格性理由**: -
