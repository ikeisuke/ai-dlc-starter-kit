# Unit 003 計画: Issueクローズタイミング変更

## 概要

IssueクローズのタイミングをConstruction PhaseのUnit完了時からPRマージ時（GitHubの `Closes #XX` 構文による自動クローズ）に統一する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/construction.md` | Unit完了時の「1.5 Issueステータス更新」セクションを削除 |
| `prompts/package/prompts/operations.md` | PR本文に `Closes #XX` が未記載の場合の警告表示をプロンプト指示として追加 |

## 実装計画

### Phase 1: 設計

プロンプトの変更のみのため、ドメインモデル・論理設計は省略（Unit定義の「技術的考慮事項」に基づく）。

### Phase 2: 実装

#### 変更1: construction.md からIssueステータス更新を削除

- `prompts/package/prompts/construction.md` の「### 1.5 Issueステータス更新【Issue管理】」セクション（Unit完了時の必須作業内）を削除
- 対象: Unit完了時に `issue-ops.sh set-status <issue_number> waiting-for-review` を呼び出す部分

#### 変更2: operations.md にClosesチェック警告を追加

- `prompts/package/prompts/operations.md` の「6.6 ドラフトPR Ready化」セクション内の「Closes記載の確認」部分に、記載漏れ時の警告表示をより明確にするプロンプト指示を追加
- 既存の「記載漏れがある場合は `gh pr view {PR番号} --web` でブラウザから編集してください」を警告形式に強化

#### 変更3: docs/aidlc/ への反映はOperations Phaseで実施

- `docs/aidlc/` は `prompts/package/` の rsync コピーであるため、直接編集しない（rules.md のメタ開発ルールに従う）

## 完了条件チェックリスト

- [ ] `construction.md` のUnit完了時必須作業からIssueステータス更新処理を削除
- [ ] `operations.md` のPRマージ前チェックで、PR本文に `Closes #XX` が記載されていない場合の警告表示をプロンプト指示として追加
- [ ] Operations Phaseの既存実装との一貫性確認
