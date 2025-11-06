# Appendix A（AI-DLC 付録）
AI-DLC を実践するためのプロンプトテンプレート集です。  
各セクションは「Role（役割）」「Task（タスク）」を中心に構成され、AIとの対話を通じて開発を進める手順を示します。  
以下の構文をそのまま使用することで、AI-Driven Development Lifecycle の運用を再現できます。

---

## セットアッププロンプト（Setup Prompt）

私たちは今日、アプリケーションを構築します。  
フロントエンドおよびバックエンドの各コンポーネントごとにプロジェクトフォルダを作成します。  
すべてのドキュメントは `aidlc-docs` フォルダに保存します。  

セッション全体を通して、AIには次のルールで作業を指示します：

- 各作業の前に「計画（plan）」を作成し、`aidlc-docs/plans` フォルダ内に `.md` ファイルとして保存すること。
- 計画は必ず人間の承認後に実行すること。
- 要件・変更ドキュメントは `aidlc-docs/requirements` フォルダに保存。
- ユーザーストーリーは `aidlc-docs/story-artifacts` フォルダに保存。
- アーキテクチャと設計文書は `aidlc-docs/design-artifacts` フォルダに保存。
- すべてのプロンプト履歴は `aidlc-docs/prompts.md` に記録。

---

## インセプション（Inception）

### ユーザーストーリー（User Stories）

**あなたの役割（Your Role）**：  
経験豊富なプロダクトマネージャーとして、システム開発のための明確なユーザーストーリーを作成する。  

**タスク（Your Task）**：  
- 高レベル要件を基に、ユーザーストーリーを策定する。  
- まず `user_stories_plan.md` にチェックボックス付きの計画を作成する。  
- 確認が必要な箇所には注記を追加し、人間の承認を得る。  
- 承認後に各ステップを1つずつ実行し、完了時にチェックを付ける。  

---

## ユニット定義（Units）

**あなたの役割**：  
経験豊富なソフトウェアアーキテクト。ユーザーストーリーをグループ化して独立したユニットを設計する。  

**タスク**：  
- `mvp_user_stories.md` を参照し、密結合を避けつつ高凝集な単位に分割。  
- 各ユニットごとにストーリーと受け入れ基準を個別の `.md` ファイルに記録（`design/`フォルダ内）。  

---

## コンストラクション（Construction）

### ドメインモデル作成（Domain / Component Model）

**あなたの役割**：  
経験豊富なソフトウェアエンジニア。  

**タスク**：  
- `design/seo_optimization_unit.md` に基づき、コンポーネントモデルを設計する。  
- 各コンポーネントの属性・振る舞い・相互作用を定義。  
- コード生成はまだ行わず、設計結果を `/design` フォルダに `.md` で保存。  

---

### コード生成（Code Generation）

**あなたの役割**：  
経験豊富なソフトウェアエンジニア。  

**タスク**：  
- `search_discovery/nlp_component.md` に基づき、NLP コンポーネントを Python で実装。  
- `amazon bedrock` API を使用してクエリテキストからエンティティを抽出。  
- 生成されたコードは `vocabMapper/` ディレクトリに配置。  
- 既存の `EntityExtractor` 実装を解析し、GenAI によるエンティティ抽出・インテント抽出計画を提案する。  

---

## アーキテクチャ（Architecture）

**あなたの役割**：  
経験豊富なクラウドアーキテクト。  

**タスク**：  
- 以下のフォルダを参照してデプロイ計画を策定。  
  - `design/core_component_model.md`  
  - `UNITS/`  
  - `ARCHITECTURE/`  
  - `BACKEND/`  
- AWS クラウドへのデプロイプランを [CloudFormation / CDK / Terraform] で作成。  
- 前提条件を文書化し、承認後にクリーンなコードを生成。  
- 出力はすべて `DEPLOYMENT/` フォルダに格納。  
- バリデーション計画とレポートを作成・修正し、最終確認を行う。  

---

## IaC / REST API 構築（Build IaC / REST APIs）

**あなたの役割**：  
経験豊富なソフトウェアエンジニア。  

**タスク**：  
- `construction/<ユニット名>/services.py` を参照。  
- 各サービスに対応する Python Flask API を作成。  
- ステップごとに計画を立て、承認後に順次実施する。  

---

© Amazon Web Services — AI-Driven Development Lifecycle Appendix A（翻訳構造保持版）
