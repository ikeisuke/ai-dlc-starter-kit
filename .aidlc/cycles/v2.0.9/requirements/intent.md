# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
v2.0.8総点検で検出・登録されたバックログIssue（#471〜#480）を一括対応し、ステップファイル・スクリプト・テンプレートの記述と実動作の乖離を解消する。加えて、agents-rules.mdからMCPレビュー推奨を削除し、レビューフローをreview-flow.mdに統一する。

## ターゲットユーザー
AI-DLCスターターキットを利用する開発者およびAIエージェント

## ビジネス価値
- ステップファイルの記述と実動作の一致により、AIエージェントの実行精度が向上する
- レビューフローの一元化により、レビュー手順の混乱を防止する
- スクリプト設計ガイドラインへの準拠により、保守性と移植性が向上する

## 成功基準
- 各Issueで指摘された記述と実動作の不一致が解消され、対象ファイル/スクリプト単位で差分確認済みである。検証方法: 各Issue対象ファイルの変更前後のdiffレビューと、関連ステップファイルとの記述突合
- agents-rules.mdからMCPレビュー推奨が削除され、review-flow.mdへの統一後に関連ドキュメント間で矛盾がない。検証方法: agents-rules.md、review-flow.md、各フェーズステップファイルのレビューフロー参照箇所のリンク・記述整合確認
- 変更後のスクリプトがscript-design-guideline.mdに準拠している。検証方法: script-design-guideline.mdのチェック項目（パス解決、終了コード、出力形式）に対する準拠確認
- 既存のテスト・CIが通過する。検証方法: `git push` 後のCI結果確認
- 既存CLIの引数体系は変更しない。出力形式の変更はドキュメント不一致解消に必要な範囲に限定する
- #471〜#480の全Issueがクローズされている。検証方法: `gh issue list` での状態確認

## 期限とマイルストーン
- 1サイクル（v2.0.9）で完了

## 制約事項
- スキル間の内部実装依存は禁止（インターフェイスでの依存は許可）
- #480はIssue提案（環境変数注入パターン）をそのまま適用しない。script-design-guideline.mdに従い、`git rev-parse --show-toplevel` による自己完結的なパス解決を維持し、標準機能に寄せる
- 独自のパス解決に頼りすぎず、できる限り標準機能を利用する
- 既存CLIの引数体系・出力形式の互換性を維持する。Issue解消に必要な範囲でスクリプト実装とドキュメントの双方を修正可能とするが、スクリプトの実動作を変える場合はドキュメント側も必ず同期する
- review-flow.md統一に伴い、参照元ドキュメントのリンク切れ・手順欠落を発生させない

## スコープ

### 含まれるもの

変更種別: [D]=ドキュメントのみ、[S]=スクリプト実装修正、[D+S]=双方修正

- #471: [D] check-open-issues.sh 出力形式とステップファイルの記述不一致の修正。影響確認: inception/01-setup.md（ステップ10コンテキスト表示）
- #472: [D] init-cycle-dir.sh バックログディレクトリ記述の実態合わせ。影響確認: inception/01-setup.md
- #473: [D] worktree_path の名前付きサイクル形式の記載追加。影響確認: inception/01-setup.md
- #474: [D] issue-ops.sh の出力形式をconstruction 01-setup.mdに追記。影響確認: construction/01-setup.md
- #475: [D] implementation_record_template.md のプレースホルダ形式統一。影響確認: templates/implementation_record_template.md
- #476: [D+S] run-markdownlint.sh の出力フォーマット標準化。影響確認: operations/03-release.md、script-design-guideline.md
- #477: [D+S] Operations Phase軽微な乖離一括修正（7項目: distribution_plan/feedback名称不一致、write-history.sh複数artifacts記述未反映、pr-ops.sh出力形式記述曖昧、post-merge-cleanup.shの不要な`--`使用、post-merge-cleanup.shのskipped-branch-not-found仕様未定義、04-completion.mdのworktreeフロー説明不正確、ios-build-check.shのfile/filesキー名不一致）。影響確認: operations/*.md、対象スクリプト
- #478: [D+S] aidlc-setup 軽微な乖離一括修正（4項目: 初回/移行モード分岐フロー明確化、setup-ai-tools.shの存在しないテンプレート参照、config.toml生成時のTOML配列フォーマット明記、migrate-config.shのbootstrap.sh非依存コメント詳細化）。影響確認: aidlc-setupスキルのステップファイル
- #479: [S] update-version.sh がスキル内 version.txt を更新しない問題の修正。影響確認: bin/update-version.sh、skills/aidlc/version.txt、skills/aidlc-setup/version.txt
- #480: [S] migrate-*.sh のパス解決をscript-design-guideline.md準拠で確認・修正（パス解決、スクリプト冒頭の定型パターン含む）。影響確認: skills/aidlc-migrate/scripts/migrate-*.sh、script-design-guideline.md
- [D] agents-rules.md からMCPレビュー推奨の削除（review-flow.mdへの統一）。影響確認: agents-rules.md、review-flow.md
- [D] review-flow.md の外部入力検証ルールに「AIレビュワー指摘のAI自己判断による却下禁止」を明記し、「AIレビュー応答の検証」をコンテキスト外のサブエージェントに委譲する方式に変更。影響確認: review-flow.md

### 含まれないもの
- 新機能の追加
- アーキテクチャの大規模変更
- v2.0.8以前のバックログで今回のスコープ外のもの

## 不明点と質問（Inception Phase中に記録）

[Question] #480の対応方針: 環境変数注入パターンではなく、script-design-guideline.mdのガイドラインに従い標準機能（git rev-parse）に寄せる方向で対応するか？
[Answer] はい。独自のパス解決に頼りすぎず標準機能に寄せる。スクリプト内部では環境変数注入は参照できない可能性がある。

[Question] agents-rules.mdのMCPレビュー推奨を削除し、review-flow.mdに沿った外部ツール/サブエージェントでのレビューに統一するか？
[Answer] はい、そのとおり。
