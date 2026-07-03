# 実装記録: Unit 003 Merge 承認・実行 + Post-merge cleanup

## 実装日時
2026-06-27 〜 2026-06-27

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/steps/release.md` - Step 3「Merge 承認 + 実行」と Step 4「Post-merge」を実装（Unit 001 プレースホルダを差し替え）。冒頭の実装範囲注記も Step 1–4 実装済みに更新。

### テスト
- 新規テストファイルなし（テスト追加は Unit 004）。既存 v3 テスト 7 スイートで回帰 sanity。

### 設計ドキュメント
- .aidlc/cycles/v3.0.0-alpha.6/design-artifacts/domain-models/unit_003_merge_approval_execution_and_post_merge_domain_model.md
- .aidlc/cycles/v3.0.0-alpha.6/design-artifacts/logical-designs/unit_003_merge_approval_execution_and_post_merge_logical_design.md

## ビルド結果
成功（Markdown のためビルド対象なし。markdownlint 0 errors / skill 参照チェック pass）

## テスト結果
成功（既存 v3 テスト回帰）

- 実行テスト数: 7 スイート
- 成功: 7 / 失敗: 0

```text
TOTAL: pass=7 fail=0（回帰ゼロ / worktree clean）
```

## コードレビュー結果
- [x] セキュリティ: OK（merge ゲート迂回防止 / TOCTOU 防止 / 機密混入なし / Bash 安全規約）
- [x] コーディング規約: OK（gh/git 直接 + 既存 state-write 委譲 / Unit 001/002 と同系統）
- [x] エラーハンドリング: OK（二層ゲート / 再開経路 / state-write exit 1/2 停止 / fail-closed）
- [x] テストカバレッジ: OK（新規テストは Unit 004 / 既存 7 スイート green）
- [x] ドキュメント: OK（SoT 参照・境界明記・写像）

## 技術的な決定事項
- **二層ゲート分離**: approval gate（3-2 / 承認判断 / ユーザー確認可）と hard gate（3-4 / CI・PR identity / bypass 不可）を分離。
- **再開経路（idempotency）**: `merge_approved` 既存 true は承認 commit（merge_approved:true を保持する最新 state.json commit）と PR head の一致で 3-3 再実行を回避。不一致（stale approval）は false に戻さず新 head に再アンカー。
- **CI 確認の SHA 固定**: hard gate は headRefOid 同一 SHA の required check を `gh pr checks --required`（count>0 & 全 pass / 0 件 fail-closed）で確認。
- **TOCTOU 防止**: merge は `gh pr merge --match-head-commit <final_head_sha>`。
- **merge_approved の監査記録**: merge 前に PR head branch へ記録・push（base 直 push しない）。
- **Step 4**: fetch+pull --ff-only で remote merge commit を同期後に branch 削除・journal/changelog（commit+push / 保護時 follow-up PR）・tag（merge commit SHA 明示）。
- **境界遵守**: state 書込は `release.ready`/`release.merge_approved` のみ（schema 不変）。PR 作成・release.md 作成は Unit 002。SKILL.md の `release` 予約のまま（公開フリップは Unit 004）。

## 課題・改善点
- SKILL.md 公開フリップ・express 整合・新規テスト本格追加・全 Step 通し検証は Unit 004。

## 状態
**完了**

## 備考
レビュー: 計画(2R) / 設計(3R) / コード(5R) / 統合(1R) を codex で実施し全指摘 resolve（unresolved 0 / defer 0）。コードレビューは merge ロジックの安全性（TOCTOU / push 先 / required check / post-merge 同期 / tag SHA）を 7 指摘にわたり精査。詳細は 003-review-summary.md 参照。
