# Unit: Operations Phase マージ前 CI 通過確認フローの SoT 化

## 概要

`skills/aidlc/steps/operations/` 配下のマージ前ステップに「CI 通過確認 + 失敗時の修復経路」フローを Single Source of Truth として明文化し、これまで属人的に対応していた CI 修復をサイクル横断で再現可能な手順にする（#694）。

## 含まれるユーザーストーリー

- ストーリー 4: Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化（#694）

## 責務

- マージ前ステップに「CI 通過確認ステップ」を追加（`gh pr checks <PR>` または `gh run list --branch <branch>` で全 CI ジョブ通過を確認）
- CI 失敗時の修復経路を 3 分岐で SoT 化:
  - 修復可能: 修正コミット → 再 push → CI 再確認
  - 修復不能（環境依存・flaky）: マージブロック解除前にユーザー承認を必須化（AskUserQuestion）
  - 構造的不整合（Unit 跨ぎ）: サイクル内修正として扱い新規 Issue 化しない
- マージ前ステップで `check-cycle-phase-completion` を明示的に呼び出すよう SoT 化
- 既存 `reviewing-operations-premerge` スキルとの重複観点・補完関係を明示する記述を追加

## 境界

- `check-cycle-phase-completion` スクリプト自体のロジック変更は行わない（呼び出しの SoT 化のみ）
- `reviewing-operations-premerge` スキルの評価軸自体の変更は行わない
- マージ前ステップ以外（PR 作成 / マージ後 cleanup）の改修は行わない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `gh` CLI（`gh pr checks` / `gh run list`）
- `check-cycle-phase-completion` スクリプト
- 既存スキル `aidlc:reviewing-operations-premerge`

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: SoT 化により全 consumer プロジェクトのマージ前フローが標準化される
- **可用性**: 該当なし

## 技術的考慮事項

- マージ前 CI 通過確認の記述が `operations-release.md` / `03-release.md` 等に分散・粒度不揃いのため、どのステップファイルを SoT とするかを設計時に確定する
- `reviewing-operations-premerge` の重複・補完関係の記載構造の細目は設計時に確定する

## 関連Issue

- #694

## 実装優先度

Medium

## 見積もり

中（steps/operations/ のステップファイル特定 + SoT セクション追加 + 既存記述との整合）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-15
- **完了日**: 2026-05-16
- **担当**: AI Agent (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
