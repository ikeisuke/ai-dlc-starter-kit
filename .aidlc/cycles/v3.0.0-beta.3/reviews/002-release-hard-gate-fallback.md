# Review 002: release hard gate の required CI 0 件フォールバック（#745）

- trace: work item 002-release-hard-gate-fallback
- matrix_case: normal_standard / matrix_review_mode: code

<!-- aidlc-review:code:start status=complete -->

## Code Review

- 実行パス: 外部 CLI（codex / `rules.reviewing.mode = required` / tools `["codex"]`）
- focus: code, security
- 対象: skills/aidlc-v3/steps/release.md（Step 3-4 フォールバック追加）/ designs/002-release-hard-gate-fallback.md
- 反復: 2 rounds / 完了条件: last_round_clean（unresolved_count = 0）

### Round 1

- 指摘 1 件（高: 0 / 中: 1 / 低: 0）
- 指摘 #1（中 / security）: 検証資産が 0 件の場合に「代替根拠なし」を明示してユーザー承認へ進める当初案は、required CI 0 件 + ローカル検証 0 件でも merge 可能な無検証 merge 経路になる
- 対応: 「少なくとも 1 件の検証が実行・記録され pass」をフォールバック成立の必須条件に変更し、検証資産 0 件は停止（fail-closed）へ修正。CI トリガー追加 / Traceability への manual check 追記を案内する形に変更（resolved / release.md + design 双方へ反映）

### Round 2

- 指摘 0 件（Round 1 対応の再レビュー / clean）

### 結果

- unresolved: 0 / deferred: 0 / セキュリティ指摘: 1 件 → resolved（無検証 merge 経路の閉鎖）
- セミオートゲート判定: auto_approved（`unresolved_count == 0` / フォールバック非該当）

<!-- aidlc-review:code:end -->
