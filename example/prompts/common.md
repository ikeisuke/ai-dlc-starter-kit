# 共通知識（全フェーズ共通）

このファイルは、AI-DLC の全フェーズで読み込まれる共通知識です。

---

## プロジェクト概要

**プロジェクト名**: AI-DLC Starter Kit

**概要**: AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット。AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論を実践する。

**主要な特徴**:
- AI-DLC ホワイトペーパーの日本語翻訳を提供
- 3つのフェーズ（Inception → Construction → Operations）に対応したプロンプトテンプレート
- テンプレートファイルによる効率的なドキュメント作成

---

## 技術スタック詳細

このプロジェクトは **greenfield（新規開発）** です。

**技術スタックは Inception Phase で決定します。**

決定後、このセクションを更新してください。

---

## ディレクトリ構成

### ドキュメント構成

```
example/
├── prompts/              # プロンプトと履歴
├── templates/            # テンプレートファイル
├── plans/                # 実行計画
├── requirements/         # 要件定義
├── story-artifacts/      # ユーザーストーリー
│   └── units/
├── design-artifacts/     # 設計成果物
│   ├── domain-models/
│   ├── logical-designs/
│   └── architecture/
├── construction/         # 構築記録
│   └── units/
└── operations/           # 運用関連
```

### ソースコード構成

Inception Phase で決定します。

---

## 制約事項

### 技術的制約

- **開発環境**: macOS (Darwin 25.0.0)
- **Git リポジトリ**: https://github.com/ikeisuke/ai-dlc-starter-kit
- **その他**: Inception Phase で決定

### データライセンス制約

- AI-DLC 翻訳文書はオリジナルのホワイトペーパー（AWS, 著者: Raju SP）の翻訳
- 学習・参考目的での利用を想定

### セキュリティ制約

- OWASP Top 10 脆弱性を防止
- 機密情報（.env, credentials.json等）をコミットしない
- 詳細は Inception Phase で定義

### 開発制約

- **作業ブランチ**: feature/example
- **マージ先**: main
- **コミットメッセージ形式**: 1行目に要約、詳細説明、フッター

---

## 外部リソース

### 参考ドキュメント

- **README.md**: `/README.md`
- **LICENSE**: `/LICENSE` - MIT License
- **AI-DLC 翻訳文書**: `docs/translations/`
- **オリジナルホワイトペーパー**: https://prod.d13rzhkk8cj2z0.amplifyapp.com

---

## 開発ルール

### コード品質基準

- **言語統一**: すべてのドキュメント・コメントは日本語で記述
- **セキュリティ**: OWASP Top 10 脆弱性を防止
- **テスト**: 各 Unit に対してテストを作成

### Git運用

- **ブランチ戦略**: feature ブランチから main へマージ
- **コミット粒度**:
  - 1つのコミットは1つの論理的な変更のみ
  - 機能追加、リファクタリング、バグ修正は別々のコミット
  - 関連する変更はまとめる
  - ビルドが成功する状態でコミット
  - コミットメッセージで「何を」「なぜ」変更したか明確に説明
- **プッシュ**: 人間の明示的な承認後のみ

### プロンプト履歴管理

- すべてのフェーズ実行時に `example/prompts/history.md` へ記録
- 記録項目: 日時、フェーズ名、実行内容、プロンプト、成果物、備考

### 追加ルール

詳細は `example/prompts/additional-rules.md` を参照してください。

---

## フェーズの責務分離

### Inception Phase

- **役割**: プロダクトマネージャー兼ビジネスアナリスト
- **やること**: Intent明確化、ユーザーストーリー作成、Unit定義、PRFAQ作成、技術スタック決定
- **やらないこと**: 詳細な設計、コード実装、デプロイ・運用設定
- **成果物**: `requirements/intent.md`, `story-artifacts/user_stories.md`, `story-artifacts/units/*.md`, `requirements/prfaq.md`

### Construction Phase

- **役割**: ソフトウェアアーキテクト兼エンジニア
- **やること**: ドメインモデル設計、論理設計、コード生成、テスト生成、統合とレビュー
- **やらないこと**: 要件定義、デプロイ・運用設定
- **成果物**: `design-artifacts/domain-models/*.md`, `design-artifacts/logical-designs/*.md`, ソースコード、テスト、`construction/units/*_implementation.md`

### Operations Phase

- **役割**: DevOps エンジニア兼 SRE
- **やること**: デプロイ準備、CI/CD構築、監視・ロギング戦略、配布、リリース後の運用
- **やらないこと**: 要件定義、コード実装
- **成果物**: `operations/deployment_checklist.md`, CI/CD設定、`operations/monitoring_strategy.md`, `operations/post_release_operations.md`

---

## 進捗管理と冪等性

### 進捗状態チェックリスト

各フェーズの進捗を管理します。

### 冪等性保証の手順

1. 既存成果物確認
2. 差分特定
3. 計画作成
4. 承認
5. 実行
6. 完了確認

---

## バージョン情報

- **対象リリース**: v1
- **ベースブランチ**: main
- **作業ブランチ**: feature/example
- **作成日**: 2025-11-08
- **最終更新日**: 2025-11-08

---

## テンプレートファイル

詳細なテンプレートは `example/templates/` 配下を参照してください：

- `intent_template.md` - Intent（開発意図）
- `user_stories_template.md` - ユーザーストーリー
- `unit_definition_template.md` - Unit定義
- `prfaq_template.md` - PRFAQ
- `domain_model_template.md` - ドメインモデル
- `logical_design_template.md` - 論理設計
- `implementation_record_template.md` - 実装記録
- `deployment_checklist_template.md` - デプロイチェックリスト
- `monitoring_strategy_template.md` - 監視戦略
- `distribution_feedback_template.md` - 配布記録
- `post_release_operations_template.md` - リリース後の運用記録
