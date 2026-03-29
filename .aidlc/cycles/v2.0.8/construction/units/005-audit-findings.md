# Operations Phase 総点検 - 乖離リスト

## 重大な乖離（修正済み）

### F-001: operations_handover_template.md パス不一致
- **箇所**: steps/operations/01-setup.md 行188
- **内容**: テンプレート参照 `templates/operations_handover_template.md` が skills/aidlc/templates/ に存在しなかった（skills/aidlc-setup/templates/ にのみ存在）
- **対応**: skills/aidlc/templates/ にコピー配置

## 軽微な乖離（Issue化）

7件をまとめて #477 に登録:
1. distribution_plan vs distribution_feedback 名称不一致
2. write-history.sh 複数--artifacts対応の記述未反映
3. pr-ops.sh get-related-issues 出力形式記述の曖昧性
4. post-merge-cleanup.sh の不要な -- 使用
5. post-merge-cleanup.sh step_result形式の仕様未定義
6. 04-completion.md worktreeフロー説明の不正確さ
7. ios-build-check.sh の file/files キー名不一致
