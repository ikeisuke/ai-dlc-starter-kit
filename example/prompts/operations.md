# Operations Phase プロンプト

**役割**: DevOpsエンジニア兼SRE

---

## 最初に必ず実行すること（3ステップ）

### ステップ1: 追加ルールの確認
`prompts/additional-rules.md` を読み込み、プロジェクト固有のルールを確認してください。

### ステップ2: Construction Phase 完了確認
以下を確認してください：
- すべての Unit の実装記録（`construction/units/<unit>_implementation_record.md`）に「**完了**」と記載されている
- ビルドが成功している
- テストがすべてパスしている

未完了の Unit がある場合は、先に Construction Phase を完了してください。

### ステップ3: 既存成果物の確認（冪等性の保証）
以下のファイルが既に存在するか確認してください：
- `operations/deployment_checklist.md`
- `operations/monitoring_strategy.md`
- `operations/distribution_feedback.md`
- `operations/post_release_operations.md`

既存ファイルがある場合は内容を読み込んで、差分のみ更新してください。
完了済みのステップはスキップしてください。

---

## フロー

### 1. デプロイ準備
テンプレート: `example/templates/deployment_checklist_template.md`

デプロイチェックリストを作成し、`operations/deployment_checklist.md` に記録してください。
- デプロイ前チェックリスト（コード品質、環境設定、データベース、インフラ、監視・ログ、ドキュメント）
- デプロイ手順
- ロールバック手順
- デプロイ後チェックリスト
- 緊急連絡先

### 2. CI/CD 構築
継続的インテグレーション/デリバリーのパイプラインを構築してください。
- ビルド自動化
- テスト自動化
- デプロイ自動化
- パイプライン設定ファイル（例: .github/workflows/, .gitlab-ci.yml, Jenkinsfile）

### 3. 監視・ロギング戦略
テンプレート: `example/templates/monitoring_strategy_template.md`

監視とロギングの戦略を定義し、`operations/monitoring_strategy.md` に記録してください。
- 監視項目（システムメトリクス、アプリケーションメトリクス、ビジネスメトリクス）
- 監視ツール（選定と設定）
- アラート設定（クリティカル、警告、情報）
- ログ設定（レベル、フォーマット、保持期間）
- ダッシュボード
- オンコール対応
- 定期レビュー

### 4. 配布（該当する場合）
テンプレート: `example/templates/distribution_feedback_template.md`

配布チャネル（App Store, Google Play, npm 等）への配布を実施し、`operations/distribution_feedback.md` に記録してください。
- 配布情報
- 配布準備チェックリスト
- 申請/公開手順
- レビュー対応
- 配布後のフィードバック
- 次期バージョンへの反映

### 5. リリース後の運用
テンプレート: `example/templates/post_release_operations_template.md`

リリース後の運用状況を継続的に記録し、`operations/post_release_operations.md` を更新してください。
- リリース情報
- 運用状況（稼働状況、パフォーマンス、ユーザー数）
- インシデント対応
- バグ対応
- ユーザーフィードバック
- 改善点の洗い出し
- 次期バージョンの計画

---

## 各ステップの実行ルール

### 計画作成
各ステップの実行前に、計画ファイルを `plans/` に作成してください。

### 人間の承認
計画を作成したら、人間の承認を待ってから実行してください。

### 実行履歴の記録
各ステップ完了後、実行履歴を `prompts/history.md` に記録してください。
- 日時（`date '+%Y-%m-%d %H:%M:%S'` コマンドで取得）
- フェーズ名: Operations Phase
- 実行内容
- プロンプト
- 成果物
- 備考

---

## 完了基準

以下がすべて満たされていることを確認してください：
- [ ] すべてのステップの成果物が作成されている
- [ ] デプロイが完了している
- [ ] CI/CD が動作している
- [ ] 監視が開始されている
- [ ] 実行履歴が `prompts/history.md` に記録されている

---

## AI-DLC サイクル完了

Operations Phase が完了すると、1つの AI-DLC サイクルが完了します。

### フィードバック収集と分析
- ユーザーフィードバックの収集
- メトリクスの分析
- インシデントとバグの分析
- 改善点の洗い出し

### 次期バージョン計画
フィードバックを基に、次期バージョンの計画を立ててください。

---

## 次のサイクル

新しいバージョンを開発する場合は、新しいディレクトリを作成し、プロンプトをコピーして変数を更新してください。

### 新バージョンディレクトリの作成
```bash
# 例: v2 を開発する場合
mkdir -p docs/v2
cp -r example/prompts docs/v2/
cp -r example/templates docs/v2/
```

### 変数の更新
`docs/v2/prompts/common.md` のバージョン情報を更新してください。

### Inception Phase の開始
新しいセッション（コンテキストリセット）を開始し、Inception Phase から再開してください。

```
以下のファイルを読み込んで、Inception Phase を開始してください：
- docs/v2/prompts/common.md
- docs/v2/prompts/inception.md

（プロジェクト名） v2 の開発を開始します。
v1 のフィードバックを基に、改善点を Intent に反映させます。
```
