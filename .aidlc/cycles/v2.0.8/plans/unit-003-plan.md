# Unit 003 計画: Inception Phase総点検

## 概要
steps/inception/ の全ファイル（01-06）と関連スクリプトの記述を実動作と突き合わせ、乖離を検出・修正する。

## 点検対象ファイル
### ステップファイル
- `steps/inception/01-setup.md`
- `steps/inception/02-preparation.md`
- `steps/inception/03-intent.md`
- `steps/inception/04-stories-units.md`
- `steps/inception/05-completion.md`
- `steps/inception/06-backtrack.md`

### 関連スクリプト
- `scripts/check-open-issues.sh`
- `scripts/suggest-version.sh`
- `scripts/init-cycle-dir.sh`
- `scripts/setup-branch.sh`
- `scripts/cycle-label.sh`
- `scripts/label-cycle-issues.sh`

## 点検方法
1. 各ステップファイルを順に読み、記述されたコマンド・条件分岐・出力フォーマットを抽出
2. 関連スクリプトの実引数・出力形式・終了コードとステップファイルの記述を比較
3. 乖離を重大度判定（重大: フロー中断・誤結果 / 軽微: 表記揺れ・動作影響なし）
4. 結果を .aidlc/cycles/v2.0.8/construction/units/003-audit-findings.md に記録

## 完了条件チェックリスト
- [ ] steps/inception/ の全6ファイルの点検完了
- [ ] 関連スクリプト6件の動作確認完了
- [ ] 重大な乖離が全て修正されている
- [ ] 軽微な乖離がGitHub Issueとしてバックログに登録されている
- [ ] 乖離リスト（003-audit-findings.md）が作成されている
