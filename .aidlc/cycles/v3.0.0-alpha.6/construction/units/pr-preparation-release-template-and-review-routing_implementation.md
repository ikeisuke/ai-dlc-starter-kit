# 実装記録: Unit 002 PR 整備 + release.md テンプレート + review ルーティング

## 実装日時
2026-06-27 〜 2026-06-27

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/steps/release.md` - Step 2「PR 整備」を実装（Unit 001 プレースホルダを差し替え）。2-0 gh 可用性停止 / 2-1 PR 解決 fail-closed（gh pr view で OPEN+head+base 一致）/ 2-2 release.pr_number 書込 + 検証 / 2-3 review ルーティング / 2-4 release.md 生成 / 2-5 ready 確認ゲート。
- `skills/aidlc-v3/templates/release.md` - 新規作成。PR 概要 / work item 完了一覧 / review 結果サマリ（固定マーカー純 YAML）/ CI 状態 / merge 記録枠。

### テスト
- 新規テストファイルなし（テスト追加は Unit 004）。既存 v3 テスト 7 スイートで回帰 sanity。マーカー間 YAML の parse 健全性は ruby（psych）で検証。

### 設計ドキュメント
- .aidlc/cycles/v3.0.0-alpha.6/design-artifacts/domain-models/unit_002_pr_preparation_release_template_and_review_routing_domain_model.md
- .aidlc/cycles/v3.0.0-alpha.6/design-artifacts/logical-designs/unit_002_pr_preparation_release_template_and_review_routing_logical_design.md

## ビルド結果
成功（Markdown のためビルド対象なし。markdownlint 0 errors）

## テスト結果
成功（既存 v3 テスト回帰）

- 実行テスト数: 7 スイート
- 成功: 7
- 失敗: 0

```text
TOTAL: pass=7 fail=0（回帰ゼロ / worktree clean）
review サマリ YAML: ruby parse OK / merge_blocker_any=false / perspectives=premerge,integration,deploy / 必須フィールド充足
```

## コードレビュー結果
- [x] セキュリティ: OK（Bash 安全規約 / file-based PR body / 機密混入なし）
- [x] コーディング規約: OK（gh 直接 + 既存スクリプト/スキル委譲 / Unit 001 と同系統）
- [x] エラーハンドリング: OK（PR 解決 fail-closed / state-read/write exit 1/2 停止 / gh 不在停止）
- [x] テストカバレッジ: OK（新規テストは Unit 004 / 既存 7 スイート green / YAML parse 検証）
- [x] ドキュメント: OK（写像表・SoT 参照・境界明記）

## 技術的な決定事項
- **PR 解決 fail-closed**: pr_number / open PR から update/adopt/create/conflict_stop を導出。全経路で `gh pr view` の `state==OPEN`（draft 含む / isDraft 別属性）+ `headRefName` 一致 + `baseRefName==<integration-branch>` を確認。create は出力 URL ではなく `gh pr view --json number` で番号再取得。
- **review 結果サマリ = 固定マーカー純 YAML**: Unit 002→003 のデータ契約。マーカー間は純 YAML のみ（コードフェンス不可）。欠損・parse 不能・enum 外は Unit 003 側 fail-closed。
- **review ルーティング**: perspective→caller_context 写像（premerge→PR マージ前 / integration→統合とレビュー / deploy→デプロイ計画承認前）。`routing_review_mode=[rules.reviewing].mode` を渡し perspective 名を `review_mode` に渡さない。
- **境界遵守**: state 書込は `release.pr_number` のみ（schema 不変）。ready 化・`release.ready`/`merge_approved`・merge は Step 3（Unit 003）。SKILL.md の `release` は予約のまま。reviewing 本体非改修（委譲のみ）。

## 課題・改善点
- Step 3–4（merge 承認・実行・post-merge）は Unit 003。SKILL.md 公開フリップ・express 整合・新規テスト本格追加は Unit 004。

## 状態
**完了**

## 備考
レビュー: 計画(3R) / 設計(3R) / コード(3R) / 統合(2R) を codex で実施し全指摘 resolve（unresolved 0 / defer 0）。詳細は 002-review-summary.md 参照。
