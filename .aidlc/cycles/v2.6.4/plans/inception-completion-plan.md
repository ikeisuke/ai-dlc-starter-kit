# Inception Phase 完了処理 計画 - v2.6.4

## 実行ステップ

1. **Milestone 作成・Issue 紐付け** (`milestone_enabled=true` / `gh available`)
   - `scripts/milestone-ops.sh ensure-create v2.6.4` で v2.6.4 Milestone 作成
   - `scripts/milestone-ops.sh link-issues-from-units v2.6.4 --milestone-number <N> --mode inception`
   - 対象 Issue: #694 / #708 / #709 / #710（既に `inception` step 16 で early-link 試行済み = `defer-to-05-completion`）
2. **iOSバージョン更新**: スキップ（project.type != ios）
3. **履歴記録**: `/write-history` で「Inception Phase 完了」を追記
4. **意思決定記録**: 完了済み（`inception/decisions.md` 作成済み、DR-001〜DR-006）
5. **ドラフト PR 作成** (`draft_pr=always` / `gh available`)
   - 既存 PR なしを確認
   - `templates/inception_pr_body_template.md` 参照、PR 本文作成（`Closes #694 #708 #709 #710`）
   - `gh pr create --draft --title "サイクル v2.6.4" --body-file <tmp>`
6. **Squash** (`squash_enabled=true`)
   - `commit-flow.md` の Squash 統合フロー
7. **Gitコミット**: Squash 結果による
8. **完了サマリ出力**
9. **コンテキストリセット提示**: `semi_auto` の仕様では「スキップして Construction 自動開始」だが、本セッションはユーザーが `/aidlc i` で Inception のみ起動しており、明示的に Construction 連続実行の指示はないため、**Inception 完了時点でセッションを区切り、Construction は別セッションで `/aidlc c` 起動を案内**する（CLAUDE.md「AI 自発のコンテキストリセット推奨を出さない」プロジェクトルールに従い、区切り情報の提示までで終了し、続行可否はユーザーに委ねる）
