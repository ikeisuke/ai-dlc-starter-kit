# Inception Phase 実行計画

## 概要

AI-DLC Starter Kit v1.0.0 のInception Phaseを実行します。
開発Intentに基づき、プロンプトファイルとバージョンごとの成果物を分離する新しいディレクトリ構造への移行を計画します。

## 実行ステップ

### 1. Intent明確化

- 既存の `docs/v1.0.0-intent.md` を参照
- 不明点をユーザーに質問（一問一答形式）
- `docs/versions/v1.0.0/requirements/intent.md` を作成

### 2. 既存コード分析（brownfield開発）

以下のファイル・ディレクトリを分析：
- `prompts/setup-prompt.md`（現在のセットアップスクリプト）
- `docs/example/`（既存のv0.1.0構造）
- `README.md`（現在のドキュメント）
- `scripts/`（既存のスクリプト）

分析結果を `docs/versions/v1.0.0/requirements/existing_analysis.md` に記録

### 3. ユーザーストーリー作成

Intent に基づいてユーザーストーリーを作成：
- スターターキットの利用者視点
- メンテナンス担当者視点
- プロンプトファイル利用者視点

成果物: `docs/versions/v1.0.0/story-artifacts/user_stories.md`

### 4. Unit定義

ユーザーストーリーを独立した価値提供ブロックに分解：
- setup-prompt.md の変更
- 各フェーズプロンプトの変更
- README.md の更新
- docs/example の移行
- バージョン管理の更新

各Unitの依存関係を明確化し、個別ファイルとして作成
成果物: `docs/versions/v1.0.0/story-artifacts/units/[unit_name]_definition.md`

### 5. PRFAQ作成

プレスリリース形式で v1.0.0 の価値を記述
成果物: `docs/versions/v1.0.0/requirements/prfaq.md`

### 6. 進捗管理ファイル作成

全Unit定義完了後、Construction Phaseで使用する進捗管理ファイルを作成
成果物: `docs/versions/v1.0.0/construction/progress.md`

### 7. 履歴記録

実行内容を `docs/versions/v1.0.0/prompts/history.md` に追記（heredoc使用）

### 8. Gitコミット

Inception Phase完了時、すべての成果物をコミット

## 参照テンプレート

- `docs/versions/v1.0.0/templates/intent_template.md`
- `docs/versions/v1.0.0/templates/user_stories_template.md`
- `docs/versions/v1.0.0/templates/unit_definition_template.md`
- `docs/versions/v1.0.0/templates/prfaq_template.md`

## 制約事項

- 既存のv0.1.0ドキュメントを削除・変更しない
- 一問一答形式で質問し、複数の質問をまとめて提示しない
- 独自の判断をせず、不明点は質問で明確化する
- 承認なしで次のステップを開始しない

## 完了基準

- すべての成果物が作成されている
- 進捗管理ファイル（progress.md）が作成されている
- Gitコミットが作成されている

## 推定作業時間

- Intent明確化: 質問と回答のラウンド数に依存
- 既存コード分析: 1セッション
- ユーザーストーリー作成: 1セッション
- Unit定義: 1セッション
- PRFAQ作成: 1セッション
- 進捗管理ファイル作成: 1セッション
- 履歴記録・Gitコミット: 1セッション

合計: 対話を含めて複数セッション想定
