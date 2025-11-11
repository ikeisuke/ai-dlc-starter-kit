# AI-DLC テンプレート一覧

このディレクトリには、AI-DLC開発で使用するドキュメントテンプレートが格納されます。

## テンプレート生成方法（JIT: Just-In-Time）

テンプレートは必要な時に生成します。新しいセッションで以下を実行してください：

```
以下のファイルを読み込んでテンプレートを生成してください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md

変数設定：
MODE = template
TEMPLATE_NAME = (生成したいテンプレート名)
DOCS_ROOT = docs/example
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

## よくある使い方

### 例1: Inception開始前に必要なテンプレートをまとめて生成

Intent、ユーザーストーリー、Unit定義、PRFAQのテンプレートを生成：

```
# 新しいセッションで以下を4回実行（TEMPLATE_NAMEを変更して）
MODE = template
TEMPLATE_NAME = intent_template  # 1回目
# TEMPLATE_NAME = user_stories_template  # 2回目
# TEMPLATE_NAME = unit_definition_template  # 3回目
# TEMPLATE_NAME = prfaq_template  # 4回目
DOCS_ROOT = docs/example
```

### 例2: 必要になった時点で1つずつ生成（推奨）

各ステップ開始時に、必要なテンプレートのみを生成します。これにより初回セットアップが軽量化されます。
