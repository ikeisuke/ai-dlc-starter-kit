# 共通知識ベース

## AI-DLC手法の要約

AI-DLCは、AIを開発の中心に据えた新しい開発手法です。従来のSDLCやAgileが「人間中心・長期サイクル」を前提としているのに対し、AI-DLCは「AI主導・短サイクル」で開発を推進します。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **冪等性の保証**: 各ステップで既存成果物を確認し、差分のみ更新

**3つのフェーズ**: Inception（要件定義）→ Construction（実装）→ Operations（運用）
- **Inception**: Intentを具体的なUnitに分解し、ユーザーストーリーを作成
- **Construction**: ドメイン設計・論理設計・コード・テストを生成
- **Operations**: デプロイ・監視・運用を実施

**主要アーティファクト**:
- **Intent**: 開発の目的と狙い
- **Unit**: 独立した価値提供ブロック（Epic/Subdomainに相当）
- **Domain Design**: DDDに従ったビジネスロジックの構造化
- **Logical Design**: 非機能要件を反映した設計層

## プロジェクト情報

### プロジェクト概要
**AI-DLC Starter Kit**: AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット

このリポジトリには、AWS が提唱する AI-DLC 方法論の日本語リソースとプロンプトテンプレートが含まれています。

- **AI-DLC とは**: AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論
- **3つのフェーズ**: Inception（起動）→ Construction（構築）→ Operations（運用）

### 技術スタック
**開発タイプ**: greenfield

技術スタックは Inception Phase で決定します。

### ディレクトリ構成

#### ドキュメント構成
```
example/
├── prompts/              # 各フェーズのプロンプトと履歴
│   ├── common.md
│   ├── inception.md
│   ├── construction.md
│   ├── operations.md
│   ├── additional-rules.md
│   └── history.md
├── templates/            # テンプレートファイル
├── plans/                # 実行計画
├── requirements/         # 要件定義
├── story-artifacts/      # ユーザーストーリー
│   └── units/           # Unit別
├── design-artifacts/     # 設計成果物
│   ├── domain-models/
│   ├── logical-designs/
│   └── architecture/
├── construction/         # 構築記録
│   └── units/
└── operations/           # 運用関連
```

#### ソースコード構成
Inception Phase で決定します。

### 制約事項

#### 技術的制約
- Inception Phase で決定

#### データライセンス
- MIT License（プロンプトテンプレート等）
- AI-DLC 翻訳文書は学習・参考目的での利用を想定

#### セキュリティ
- セキュリティスキャンの実施
- シークレット情報の適切な管理

#### 開発制約
- なし


## 開発ルール

### コード品質基準
- 言語: Inception Phase で決定
- フレームワーク: Inception Phase で決定
- スタイルガイド: Inception Phase で決定

### Git運用
- ブランチ戦略: main（安定版）、feature/*（機能開発）、releases/*（リリース準備）
- コミット粒度: 1つのコミットは1つの論理的な変更のみ

**原則**:
- コミットメッセージで「〜と〜と〜」となる場合は分割を検討
- ビルドやテストが通る状態で各コミットを作成

**例**:
- Good: `feat: ユーザー認証機能を追加`
- Bad: `feat: 認証追加、バグ修正、リファクタリング`

### プロンプト履歴管理
- すべてのプロンプト実行は `prompts/history.md` に記録
- 記録項目: 日時、フェーズ名、実行内容、プロンプト、成果物、備考
- 日時取得は `date '+%Y-%m-%d %H:%M:%S'` コマンドを使用

## フェーズの責務分離

### Inception Phase
**やること**:
- Intent（開発意図）の明確化
- 既存コード分析（brownfield の場合）
- ユーザーストーリーの作成
- Unit 定義
- PRFAQ 作成
- 技術スタック決定（greenfield の場合）

**やらないこと**:
- 詳細設計
- コード実装
- デプロイ

**成果物**:
- requirements/intent.md
- design-artifacts/existing-system-model.md（brownfield のみ）
- story-artifacts/user_stories.md
- story-artifacts/units/*.md
- requirements/prfaq.md

### Construction Phase
**やること**:
- ドメインモデル設計
- 論理設計
- コード生成
- テスト生成
- ビルド・テスト実行
- 実装記録作成

**やらないこと**:
- 要件定義（Inception で完了済み）
- デプロイ（Operations で実施）

**成果物**:
- design-artifacts/domain-models/<unit>_domain_model.md
- design-artifacts/logical-designs/<unit>_logical_design.md
- ソースコード
- テストコード
- construction/units/<unit>_implementation_record.md

### Operations Phase
**やること**:
- デプロイ準備
- CI/CD 構築
- 監視・ロギング設定
- 配布（該当する場合）
- リリース後の運用

**やらないこと**:
- 要件定義（Inception で完了済み）
- コード実装（Construction で完了済み）

**成果物**:
- operations/deployment_checklist.md
- operations/monitoring_strategy.md
- operations/distribution_feedback.md
- operations/post_release_operations.md

## 進捗管理と冪等性

### チェックリストによる進捗確認
各フェーズの開始時に、以下をチェック：
- [ ] 前フェーズの成果物がすべて作成されているか
- [ ] 既存成果物の内容は最新か
- [ ] 実行履歴が記録されているか

### 既存成果物の確認手順
1. 対象ファイルの存在確認
2. ファイルが存在する場合は内容を読み込み
3. 差分のみ更新（完全に新規作成はしない）
4. 更新内容を history.md に記録

### 差分のみ更新するルール
- ファイルが存在しない場合: 新規作成
- ファイルが存在する場合: 内容を読み込み → 不足部分のみ追記 → 履歴に記録

## テンプレート参照

詳細なテンプレートは `example/templates/` 配下を参照してください：

- `intent_template.md` - Intent（開発意図）
- `user_stories_template.md` - ユーザーストーリー
- `unit_definition_template.md` - Unit 定義
- `prfaq_template.md` - PRFAQ
- `domain_model_template.md` - ドメインモデル
- `logical_design_template.md` - 論理設計
- `implementation_record_template.md` - 実装記録
- `deployment_checklist_template.md` - デプロイチェックリスト
- `monitoring_strategy_template.md` - 監視・ロギング戦略
- `distribution_feedback_template.md` - 配布記録
- `post_release_operations_template.md` - リリース後の運用記録
