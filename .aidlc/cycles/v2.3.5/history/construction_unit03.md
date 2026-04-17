# Construction Phase 履歴: Unit 03

## 2026-04-17T23:59:12+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-merge-pr-skip-checks（merge-pr --skip-checks オプション追加）
- **ステップ**: 計画承認
- **実行内容**: Unit 003 計画承認: Codex 3ラウンドレビュー（Round1=3件 高1中2、Round2=1件 中1、Round3=0件）で auto_approved。主要強化: (1) gh pr checks の unknown バケットを no-checks-configured / checks-query-failed に分離し安全性を確保、(2) --skip-checks は no-checks-configured のみバイパス許可（failed/pending/checks-query-failed は指定の有無に関わらず拒否）、(3) 機械可読な pr:<N>:reason:<code> 補助行と人間向け pr:<N>:hint:<text> 行を後方互換で追加、出力順序契約（error→reason→hint）を固定、(4) ドキュメント正本を operations-release.md 7.13 節に固定（03-release.md は完了基準サマリのため更新なし）、(5) no-checks-configured 経路も pass と同じ即時マージ実装（--match-head-commit 付与）を共用し race condition を防止。Phase 1（設計）へ遷移。
- **成果物**:
  - `.aidlc/cycles/v2.3.5/plans/unit-003-plan.md`

---
## 2026-04-18T00:16:10+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-merge-pr-skip-checks（merge-pr --skip-checks オプション追加）
- **ステップ**: 設計承認
- **実行内容**: Codex 設計レビュー 5 Round: Round1=3件(高1/中2)、Round2=3件(高1/中2)、Round3=2件(中2)、Round4=2件(中2)、Round5=0件で auto_approved。主要強化: (1) resolve_check_status() の Bash 実装パターンを if/else 形式で固定（|| true + $? 禁止を明示、OK/NG 例併記）、(2) exit code 規約で既存 pr-ops.sh 互換のため exit 1 を例外的に維持する旨を明示、(3) head_sha を遅延解決に変更（action=merge-now/set-auto-merge の場合のみ gh pr view 呼出）、(4) シーケンス図で merge-now と set-auto-merge の出力行を分離、(5) 責務境界を判定/決定/実行の 3 ドメインに明確化し merge-pr ドメイン層全体に統一、(6) PullRequest.buildMergeCommand() を削除し MergeExecutor にコマンド構築責務を一本化、(7) trap EXIT を関数内で使わず明示的 rm -f クリーンアップに変更。Phase 2（実装）へ遷移。
- **成果物**:
  - `.aidlc/cycles/v2.3.5/design-artifacts/domain-models/unit_003_merge_pr_skip_checks_domain_model.md`
  - `.aidlc/cycles/v2.3.5/design-artifacts/logical-designs/unit_003_merge_pr_skip_checks_logical_design.md`

---
## 2026-04-18T00:29:39+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-merge-pr-skip-checks（merge-pr --skip-checks オプション追加）
- **ステップ**: Unit完了
- **実行内容**: Unit 003（merge-pr --skip-checks オプション追加）実装完了。

## 変更サマリ
- skills/aidlc/scripts/pr-ops.sh
  - resolve_check_status() 新規: gh pr checks 生出力を CheckStatus 5 分類に写像（pass/fail/pending/no-checks-configured/checks-query-failed）。stdout が確定値を返した場合は exit code に関わらず優先（pending exit 8 公式仕様対応）
  - emit_checks_status_unknown_error() 新規: error:checks-status-unknown エラー時の 3 行順序固定出力（error → reason → hint）
  - cmd_merge() 改修: skip_checks 引数追加、head_sha を action 確定後に遅延解決、no-checks-configured のみバイパス許可、fail/pending/checks-query-failed は skip_checks を無視
  - main() merge サブコマンドパーサに --skip-checks 追加
- skills/aidlc/scripts/operations-release.sh
  - cmd_merge_pr() に --skip-checks 引数パースを追加し pr-ops.sh merge に透過
  - print_help_merge_pr() を更新
- skills/aidlc/steps/operations/operations-release.md
  - 7.13 節に error:checks-status-unknown の reason 分岐（AskUserQuestion）と適用マトリクスを追加
- skills/aidlc/guides/merge-pr-usage.md 新規
  - 5 分類の判定条件、挙動マトリクス、使い分けガイダンス、エラーコード一覧、出力契約

## レビュー実績
- 計画レビュー: Codex 3 Round（Round1=3件 高1中2、Round2=1件 中1、Round3=0件、auto_approved）
- 設計レビュー: Codex 5 Round（Round1=3件 高1中2、Round2=3件 高1中2、Round3=2件 中2、Round4=2件 中2、Round5=0件、auto_approved）
- コードレビュー: Codex 3 Round（Round1=1件 高1 [pending exit 8 regression]、Round2=1件 低1 [FAQ 旧仕様残存]、Round3=0件、auto_approved）
- 統合レビュー: Codex 1 Round（指摘0件、auto_approved。Unit 定義・Intent・Issue #575 要件の完全充足、21 件テスト全 PASS を確認）

## テスト実績
- skills/aidlc/scripts/tests/test_pr_ops_merge_skip_checks.sh を新規作成（21 件、PASS=21/FAIL=0）
  - 5 状態 × 2 フラグ有無 = 10 マトリクスセル
  - 出力順序契約（error → reason → hint）
  - merge/rebase サブコマンドでの --skip-checks 透過
  - pending regression 防止（exit 8 対応）
  - checks-query-failed + --skip-checks のバイパス禁止

## 主要な安全性契約
- fail / pending / checks-query-failed では --skip-checks を無視（バイパス禁止）
- no-checks-configured のみで --skip-checks による CI バイパスを許可
- --match-head-commit を pass / no-checks-configured の両経路で必ず付与（race condition 防止）

## 機械可読な外部契約
- error:checks-status-unknown 出力時に reason:<code> 行（機械可読）と hint:<text> 行（人間向け）を順序固定で出力
- reason_code の有効値: no-checks-configured（--skip-checks 可） / checks-query-failed（バイパス不可）

## 既存テストの状況
- 本 Unit 追加テスト: 21 件全 PASS
- Unit 002 のテスト (test_validate_git_remote_sync.sh): PASS 維持
- 既存テスト失敗 (test_detect_phase, test_wildcard_detection, test_parse_gh_error, test_kiro_merge, test_resolve_remote, test_root_commit_helpers): 本 Unit 変更前から存在する pre-existing な失敗で、スコープ外として記録

## 残課題
- なし（Unit 003 のスコープ内で完了）
- 将来の改善候補（バックログ化検討）: gh pr checks の構造化 error code 提供後の文言マッチ廃止、exit-code-convention.md への exit 2 寄せ（pr-ops.sh 全体の見直し）
- **成果物**:
  - `.aidlc/cycles/v2.3.5/plans/unit-003-plan.md`
  - `.aidlc/cycles/v2.3.5/design-artifacts/domain-models/unit_003_merge_pr_skip_checks_domain_model.md`
  - `.aidlc/cycles/v2.3.5/design-artifacts/logical-designs/unit_003_merge_pr_skip_checks_logical_design.md`
  - `skills/aidlc/scripts/pr-ops.sh`
  - `skills/aidlc/scripts/operations-release.sh`
  - `skills/aidlc/steps/operations/operations-release.md`
  - `skills/aidlc/guides/merge-pr-usage.md`
  - `skills/aidlc/scripts/tests/test_pr_ops_merge_skip_checks.sh`
  - `.aidlc/cycles/v2.3.5/construction/units/003-review-summary.md`

---
