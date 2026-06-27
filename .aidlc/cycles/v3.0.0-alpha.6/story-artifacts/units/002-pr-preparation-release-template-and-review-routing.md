# Unit: PR 整備 + release.md テンプレート + review ルーティング

## 概要

release フェーズ Step 2「PR 整備」を実装する。PR の作成（既存時は更新）、`release.pr_number` の state.json 書き込み、`templates/release.md` 新規作成と release.md 成果物の生成、release-level review（premerge / integration / deploy）の perspective ルーティングを担う。

## 含まれるユーザーストーリー

- ストーリー 2: PR 整備と release.md 作成
- ストーリー 3: release-level review ルーティング

## 責務

- Step 2「PR 整備」を `steps/release.md` に実装。
- PR 未作成時は作成、`early_pr: true`（define 時 Draft PR 済み）時は本文更新のみ、の分岐。
- PR 作成時に `release.pr_number` を `state-write.sh` で書き込み、`state-validate.sh` で検証。
- `templates/release.md` を新規作成（PR 概要 / work item 完了一覧 / review 結果サマリ / CI 状態 / merge 記録）。release.md 成果物をテンプレートから生成。
  - **review 結果サマリは Unit 003 の semi_auto merge ゲートの入力契約となる**ため、perspective ごと（premerge / integration / deploy）の結果・**未解決指摘数**・**最高重要度**・**merge blocker 有無**を機械可読に記録するセクションを含める（Unit 002→003 データ契約）。
- release-level review ルーティング: `premerge` 常時 / `integration`（`status:done` 2件以上）/ `deploy`（`size:risky` の done 1件以上）。既存 reviewing スキルへ `review-routing` 経由で委譲。
- review 結果は `release.md` に集約し `reviews/*.md` を生成しない（`data-model.md §8`）。
- Step 2 のゲートは「PR ready 確認」（ready 化操作は Unit 003 / Step 3）。

## 境界

- PR の ready 化操作・`release.ready` 書き込み・merge は扱わない（Unit 003）。
- state.json schema 変更は行わない（既存 `release.pr_number` のみ使用）。
- reviewing スキル本体の改修（9→1 統合）は行わない（既存スキルへ委譲のみ）。

## 依存関係

### 依存する Unit

- 001 release フロー骨格 + リリース準備ゲート（依存理由: `steps/release.md` の骨格と Step 1 ゲート通過後に Step 2 が動作するため）

### 外部依存

- 既存 `state-write.sh` / `state-read.sh` / `state-validate.sh`
- 既存 reviewing スキル: `reviewing-operations-premerge` / `reviewing-construction-integration` / `reviewing-operations-deploy`、`review-routing.md`
- `gh`（PR create / edit）
- 設計 SoT: `docs/v3/workflow.md §3.3`（Step 2）/ `§6`（review perspective）/ `docs/v3/data-model.md §3・§8`

## 非機能要件（NFR）

- **互換性**: state.json schema 不変。書き込みは `release.pr_number` のみ。
- **保守性**: PR 操作は `gh` 直接呼び出しを基本とし、ラッパは最小限（設計時判断）。
- **セキュリティ**: PR 本文・release.md に機密情報を含めない（review-flow のマスク方針準用）。

## 技術的考慮事項

- review perspective マッピングの正本は `workflow.md §6` / `review-routing.md §3`。release.md は再定義せず参照。
- PR 作成補助スクリプトを設ける場合は exit code 規約（0/1/2）に準拠し、result-out 関数の local 命名規約を遵守。

## 関連Issue

- #736（部分対応 / Relates）

## 実装優先度

High

## 見積もり

1 日（PR 整備 + template + review ルーティング）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
