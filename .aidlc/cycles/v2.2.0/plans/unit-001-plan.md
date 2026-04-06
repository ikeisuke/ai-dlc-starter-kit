# Unit 001 計画: 先読み指示廃止・テンプレート外部化

## 概要

全ステップファイルから冗長な先読み指示パターン（25箇所）を削除し、05-completion.mdのPR本文テンプレート・コンテキストリセットテンプレート、review-flow.mdのレビューサマリSetフォーマットをtemplates/に外部化する。

## 作業内容

### タスク A: 先読み指示パターン削除（23箇所）

以下のファイルから「【次のアクション】」で始まり、特定ステップファイルの事前読込を要求する先読み指示を削除する。削除対象は「...確認してください」系と「...手順に従ってください」系の両方を含む。

| ファイル | 削除行数 |
|---------|---------|
| construction/01-setup.md | 10行 |
| inception/01-setup.md | 5行 |
| operations/01-setup.md | 9行 |
| operations/02-deploy.md | 1行（operations-release.md読み込み指示） |

**維持対象（削除しない）**:
- タスクリスト作成指示（construction/01-setup.md, inception/01-setup.md, operations/01-setup.md）
- Squashフロー実行指示（construction/04-completion.md, inception/05-completion.md）

### タスク B: インラインテンプレート外部化

#### B-1: PR本文テンプレート（05-completion.md → Inception専用テンプレート新規作成）

05-completion.md L176-187のインラインPR本文テンプレートを`templates/inception_pr_body_template.md`として新規作成する。既存の`pr_body_template.md`（Operations Phase用: Summary/受け入れ基準/変更概要/Test plan/Closes構成）とは構成が異なるため（サイクル概要/含まれるUnit/複数IssueのCloses列挙）、Inception専用テンプレートとして分離する。

#### B-2: コンテキストリセットテンプレート（05-completion.md → 新規作成）

05-completion.md L252-277のコンテキストリセットテンプレートを`templates/context_reset_template.md`として外部化する。元の箇所にはテンプレート参照指示を残す。

#### B-3: レビューサマリSetフォーマット（review-flow.md → フォーマット例のみテンプレートに移動）

review-flow.md L173-188のSetフォーマット例（マークダウンコードブロック部分）のみを`templates/review_summary_template.md`に移動する。バックログ列有効値テーブル（L190-199）と検証条件（OUT_OF_SCOPE時必須ルール等）はreview-flow.mdに残す（業務ルールの責務分離を維持）。

## 完了条件チェックリスト

- [ ] 全ステップファイルから先読み指示パターン（25箇所）が削除されている
- [ ] ワークフロー制御指示（7箇所）が維持されている
- [ ] `templates/context_reset_template.md` が作成されている
- [ ] `templates/review_summary_template.md` にSetフォーマット例が追加されている（業務ルールはreview-flow.mdに残存）
- [ ] `templates/inception_pr_body_template.md` が作成されている（Inception専用PR本文）
- [ ] 05-completion.md のPR本文テンプレートが `inception_pr_body_template.md` 参照に置換されている
- [ ] 05-completion.md のコンテキストリセットテンプレートが `context_reset_template.md` 参照に置換されている
- [ ] review-flow.md のSetフォーマットが `review_summary_template.md` 参照に置換されている
- [ ] 移動後の各参照指示が正しいパスを示している

## 影響範囲

- 変更対象: 6ステップファイル + 1テンプレート更新 + 2テンプレート新規作成
- ステップファイルの内容ロジック自体は変更しない
- preflight.mdの条件分岐圧縮はUnit 002のスコープ
