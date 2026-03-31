# Unit 003 計画: 400行超えMarkdownファイルの分割

## 概要

`skills/aidlc/` 配下の400行超えMarkdownファイル9つを分割し、各ファイルを400行以内に収める。

## 設計方針

- セクション単位で自然な分割点を選定
- 分割後のファイル名は `{親ファイル名}-{機能名}.md` 形式
- 親ファイルに `**【次のアクション】** 今すぐ {分割先ファイル} を読み込んで` パターンで参照追加
- ファイル内容の論理的変更は行わない（構造的分割のみ）

## 対象ファイルと分割方針

| # | ファイル | 行数 | 分割方針 |
|---|---------|------|---------|
| 1 | steps/inception/01-setup.md | 692 | プリフライト・セットアップ部分と本体を分離 |
| 2 | steps/operations/operations-release.md | 628 | リリース前半（PR作成〜マージ）と後半（ポストマージ）を分離 |
| 3 | guides/sandbox-environment.md | 583 | プラットフォーム別セクションを分離 |
| 4 | guides/ai-agent-allowlist.md | 578 | ツール別セクションを分離 |
| 5 | steps/common/rules.md | 546 | セミオートゲート仕様を別ファイルに分離 |
| 6 | steps/construction/01-setup.md | 478 | セットアップ部分と本体を分離 |
| 7 | steps/common/review-flow.md | 433 | セルフレビューフロー部分を分離 |
| 8 | steps/common/commit-flow.md | 438 | Squash統合フローを分離 |
| 9 | steps/construction/04-completion.md | 416 | Unit完了時の必須作業を分離（既に独立セクション） |

## 完了条件チェックリスト

- [ ] 対象9ファイルが全て400行以内
- [ ] 分割後のファイル間参照の整合性維持
- [ ] 既存の読み込み順序指示が正しく更新されている
