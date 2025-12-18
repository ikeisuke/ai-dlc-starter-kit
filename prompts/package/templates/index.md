# AI-DLC テンプレート一覧

このディレクトリには、AI-DLC開発で使用するドキュメントテンプレートが格納されます。

## テンプレート生成方法（JIT: Just-In-Time）

テンプレートは必要な時に自動生成されます：

### 自動生成（推奨）
各フェーズ開始時、AIが自動的に必要なテンプレートをチェックします。不足している場合は自動生成し、「再度プロンプトを読み込んでください」と通知します。

### 手動生成（オプション）
テンプレートを事前に生成したい場合：

```
以下のファイルを読み込んでテンプレートを生成してください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md

変数設定：
MODE = template
TEMPLATE_NAME = (生成したいテンプレート名)
DOCS_ROOT = (あなたのDOCS_ROOT)
```

## 利用可能なテンプレート

### Inception Phase

#### intent_template
- **説明**: 開発の目的、ターゲットユーザー、ビジネス価値を記録
- **使用タイミング**: Intent明確化ステップ
- **生成コマンド**: `TEMPLATE_NAME = intent_template`

#### user_stories_template
- **説明**: ユーザーストーリーとEpic、受け入れ基準を記録
- **使用タイミング**: ユーザーストーリー作成ステップ
- **生成コマンド**: `TEMPLATE_NAME = user_stories_template`

#### unit_definition_template
- **説明**: Unit（独立した価値提供ブロック）の定義を記録
- **使用タイミング**: Unit定義ステップ
- **生成コマンド**: `TEMPLATE_NAME = unit_definition_template`

#### prfaq_template
- **説明**: プレスリリース形式での製品説明とFAQ
- **使用タイミング**: PRFAQ作成ステップ
- **生成コマンド**: `TEMPLATE_NAME = prfaq_template`

#### inception_progress_template
- **説明**: Inception Phaseの進捗管理（6ステップの状態管理）
- **使用タイミング**: Inception Phase開始時に自動作成
- **生成コマンド**: `TEMPLATE_NAME = inception_progress_template`

### Construction Phase

#### domain_model_template
- **説明**: DDDに基づくドメインモデル設計（エンティティ、値オブジェクト、集約等）
- **使用タイミング**: ドメインモデル設計ステップ
- **生成コマンド**: `TEMPLATE_NAME = domain_model_template`

#### logical_design_template
- **説明**: 非機能要件を反映した論理設計（アーキテクチャ、API設計等）
- **使用タイミング**: 論理設計ステップ
- **生成コマンド**: `TEMPLATE_NAME = logical_design_template`

#### implementation_record_template
- **説明**: 実装記録（変更内容、テスト結果、レビュー等）
- **使用タイミング**: 統合とレビューステップ
- **生成コマンド**: `TEMPLATE_NAME = implementation_record_template`

### Operations Phase

#### deployment_checklist_template
- **説明**: デプロイ前チェックリストと手順
- **使用タイミング**: デプロイ準備ステップ
- **生成コマンド**: `TEMPLATE_NAME = deployment_checklist_template`

#### monitoring_strategy_template
- **説明**: 監視とロギングの戦略
- **使用タイミング**: 監視・ロギング戦略ステップ
- **生成コマンド**: `TEMPLATE_NAME = monitoring_strategy_template`

#### distribution_feedback_template
- **説明**: 配布とフィードバック収集の記録
- **使用タイミング**: 配布ステップ
- **生成コマンド**: `TEMPLATE_NAME = distribution_feedback_template`

#### post_release_operations_template
- **説明**: リリース後の運用とフィードバック分析
- **使用タイミング**: リリース後の運用ステップ
- **生成コマンド**: `TEMPLATE_NAME = post_release_operations_template`

#### operations_progress_template
- **説明**: Operations Phaseの進捗管理（6ステップの状態管理）
- **使用タイミング**: Operations Phase開始時に自動作成
- **生成コマンド**: `TEMPLATE_NAME = operations_progress_template`

#### operations_handover_template
- **説明**: サイクル間で引き継ぐ運用設定・方針（バージョン確認設定、デプロイ環境等）
- **使用タイミング**: 運用引き継ぎファイル作成時
- **生成コマンド**: `TEMPLATE_NAME = operations_handover_template`

## テンプレート生成の仕組み

### 自動生成（推奨）

各フェーズの開始時、AIが自動的に必要なテンプレートの有無を確認します。テンプレートが不足している場合は：

1. AIが自動的にテンプレートを生成
2. 生成完了後、ユーザーに「再度プロンプトを読み込んでください」と通知
3. ユーザーが同じセッションでプロンプトを再読み込み
4. フェーズ処理を継続

この方法により、初回セットアップが軽量化され、必要なテンプレートのみを必要な時に生成できます。

### 手動生成（オプション）

テンプレートを事前に生成したい場合は、以下を実行：

```
MODE = template
TEMPLATE_NAME = intent_template  # 生成したいテンプレート名
DOCS_ROOT = (あなたのDOCS_ROOT)
```
