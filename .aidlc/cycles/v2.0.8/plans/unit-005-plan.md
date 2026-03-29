# Unit 005 計画: Operations Phase総点検

## 概要
steps/operations/ の全ファイル（01-04 + operations-release.md）と関連スクリプトの記述を実動作と突き合わせ。

## 点検対象
### ステップファイル
- `steps/operations/01-setup.md`
- `steps/operations/02-deploy.md`
- `steps/operations/03-release.md`
- `steps/operations/04-completion.md`
- `steps/operations/operations-release.md`

### 関連スクリプト
- `scripts/pr-ops.sh`
- `scripts/issue-ops.sh`
- `scripts/post-merge-cleanup.sh`
- `scripts/get-default-branch.sh`

## 完了条件チェックリスト
- [ ] steps/operations/ の全5ファイルの点検完了
- [ ] 関連スクリプトの動作確認完了
- [ ] 重大な乖離が全て修正されている
- [ ] 軽微な乖離がGitHub Issueとしてバックログに登録されている
- [ ] 乖離リスト（005-audit-findings.md）が作成されている
