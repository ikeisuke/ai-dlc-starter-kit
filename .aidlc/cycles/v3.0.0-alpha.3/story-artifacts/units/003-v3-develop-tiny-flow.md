# Unit: v3 develop tiny フロー実行実装

## 概要

`skills/aidlc-v3/steps/develop.md` を新規作成し、tiny サイズの work item を design / review なしで完了する develop フローを実装する。frontmatter status の遷移（`pending → in_progress → done`）と work item 単位 commit、journal 追記を含む。

## 含まれるユーザーストーリー

- ストーリー 3: develop tiny フローで tiny work item を完了する

## 責務

- `steps/develop.md` 新規作成（tiny フローのみ）
- Step 1 work item 選定（`work-item-next.sh` 利用）。**status を `in_progress` 更新する前に `size: tiny` を確認し、次候補が `size: normal` / `risky` の場合は未サポート案内のみで停止する（frontmatter / journal / commit を一切変更しない＝副作用なし）**
- Step 1（tiny 確定後）status を `in_progress` 更新
- Step 3 実装 + work item 単位 commit
- Step 4 検証（acceptance criteria チェック）
- Step 6 完了（status を `done` 更新、journal 追記、次 item / release 案内）
- develop 完了後の state がフェーズ導出可能な状態（`develop` 継続 / `release 可能`）になることの検証、および normal / risky 選定時の副作用なし停止の検証

## 境界

- normal / risky 分岐（design / risk analysis / review ルーティング）は Phase 4
- aidlc-review 統合スキルの実装（Phase 4 以降）
- release フロー（Phase 5）
- `status` 実行実装（Phase 6 / 本 Unit は「導出できる状態」の確認まで）

## 依存関係

### 依存する Unit

- 001-v3-define-flow（依存理由: develop は define が生成した `state.json` / `work-items/*.md` を入力とするため）
- 002-work-item-next（依存理由: Step 1 の work item 選定で `work-item-next.sh` を使用するため）

### 外部依存

- git / `state-write.sh` / `work-item-next.sh`

## 非機能要件（NFR）

- **パフォーマンス**: tiny work item 1 件を軽量に完了
- **セキュリティ**: status 更新は frontmatter 操作の最小範囲、state は `state-write.sh` 経由
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

フロー手順は `docs/v3/workflow.md` §3.2 を正本とする。tiny は design / review をスキップする（size × review マトリクス）。検証はサンドボックス／テストハーネスで行い v2 `.aidlc/` を破壊しない。

## 関連Issue

- なし

## 実装優先度

High

## 見積もり

0.5〜1 サイクル相当

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-14
- **完了日**: 2026-06-14
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
