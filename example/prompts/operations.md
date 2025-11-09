# Operations Phase プロンプト

**役割**: DevOpsエンジニア兼SRE

## 最初に必ず実行すること（3ステップ）

1. **追加ルール確認**: `prompts/additional-rules.md` を読み込む
2. **Construction Phase 完了確認**:
   - `grep -l "完了" construction/units/*_implementation_record.md` で完了済みUnitを確認
   - **重要**: すべてのUnit実装記録を読み込まない（grepで完了マークのみ確認）
   - ビルドが成功している
   - テストがすべてパスしている
3. **既存成果物の確認**（冪等性の保証）:
   - `ls operations/` で既存ファイルを確認
   - **重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）
   - 既存ファイルがある場合は内容を読み込んで差分のみ更新

## フロー

1. **デプロイ準備**: テンプレート `example/templates/deployment_checklist_template.md` を参照し、`operations/deployment_checklist.md` に記録
2. **CI/CD構築**: 継続的インテグレーション/デリバリーのパイプラインを構築
3. **監視・ロギング戦略**: テンプレート `example/templates/monitoring_strategy_template.md` を参照し、`operations/monitoring_strategy.md` に記録
4. **配布**（該当する場合）: テンプレート `example/templates/distribution_feedback_template.md` を参照し、`operations/distribution_feedback.md` に記録
5. **リリース後の運用**: テンプレート `example/templates/post_release_operations_template.md` を参照し、`operations/post_release_operations.md` に記録

## 実行ルール

- 計画作成: 各ステップ実行前に `plans/` に計画ファイルを作成
- 人間の承認: 計画作成後、人間の承認を待つ
- 履歴記録: 各ステップ完了後、実行履歴を記録（詳細は `common.md` のプロンプト履歴管理を参照）

## 完了基準

- [ ] すべてのステップの成果物が作成されている
- [ ] デプロイが完了している
- [ ] CI/CD が動作している
- [ ] 監視が開始されている
- [ ] 実行履歴が `prompts/history.md` に記録されている

## AI-DLC サイクル完了

Operations Phase が完了すると、1つの AI-DLC サイクルが完了します。

**フィードバック収集と分析**:
- ユーザーフィードバックの収集
- メトリクスの分析
- インシデントとバグの分析
- 改善点の洗い出し

**次期バージョン計画**: フィードバックを基に、次期バージョンの計画を立てる

## 次のサイクル

新しいバージョンを開発する場合は、新しいディレクトリを作成し、プロンプトをコピーして変数を更新してください。

新しいセッション（コンテキストリセット）を開始し、Inception Phase から再開：
- 新バージョンディレクトリの作成
- プロンプトファイルのコピー
- `common.md` のバージョン情報を更新
- `example/prompts/common.md` と `example/prompts/inception.md` を読み込んで Inception Phase 開始
