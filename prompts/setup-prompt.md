# AI-DLC セットアッププロンプト

このファイルを使用して、AI-DLC開発環境を初期化します。

---

## 変数定義
開始時にユーザーに変数の変更を確認し入力を促す

```
PROJECT_NAME = AI-DLC Starter Kit
VERSION = v1
BRANCH = feature/example
DEVELOPMENT_TYPE = greenfield
DOCS_ROOT = docs/example
LANGUAGE = 日本語
PROJECT_README = /README.md
OTHER_DOCS = /LICENSE

DEVELOPER_EXPERTISE = ソフトウェア開発
ROLE_INCEPTION = プロダクトマネージャー兼ビジネスアナリスト
ROLE_CONSTRUCTION = ソフトウェアアーキテクト兼エンジニア
ROLE_OPERATIONS = DevOpsエンジニア兼SRE

ADDITIONAL_RULES = docs/example/prompts/additional-rules.md
```

---

## プロンプト

あなたは{{DEVELOPER_EXPERTISE}}に精通した開発者です。
これから {{BRANCH}} ブランチで {{PROJECT_NAME}} の {{VERSION}} を開発します。

### 前提知識の習得

まず、AI-DLC（AI-Driven Development Lifecycle）手法について、以下のリソースで理解してください：

- このリポジトリの翻訳文書: https://github.com/ikeisuke/ai-dlc-starter-kit/tree/main/docs/translations
- オリジナルのホワイトペーパー: https://prod.d13rzhkk8cj2z0.amplifyapp.com

推奨: まず `docs/translations/AI-Driven_Development_Lifecycle_Summary.md` を読んで全体像を把握してください。

### 開発環境のセットアップ

AI-DLCに基づいた開発環境を構築してください：

#### 1. ディレクトリ構成の作成

以下の構造を作成：
```
{{DOCS_ROOT}}/
├── prompts/              # 各フェーズのプロンプトと履歴
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

#### 2. プロンプトファイルの作成

`{{DOCS_ROOT}}/prompts/` 配下に以下を作成：

##### common.md（全フェーズで読み込む共通知識）
- プロジェクト概要（{{PROJECT_README}} から抽出）
- 技術スタック詳細（{{DEVELOPMENT_TYPE}} が brownfield の場合は既存スタックを記載、greenfield の場合は Inception Phase で決定）
- ディレクトリ構成（ソースコード構成とドキュメント構成）
- 制約事項:
  - 技術的制約（最小対応OS、デバイス、API設計ガイドライン等）
  - データライセンス制約（データ元、ライセンス、必須表記、更新義務等）
  - セキュリティ制約（API認証、個人情報取扱い、OWASP準拠）
  - 開発制約（作業ブランチ、マージ先、コミットメッセージ形式）
- 外部リソース:
  - 外部API情報（Base URL、エンドポイント）
  - データ統計（該当する場合）
  - 参考ドキュメント（{{PROJECT_README}}, {{OTHER_DOCS}}）
- 開発ルール（コード品質基準、Git運用、プロンプト履歴管理、追加ルールの参照）
- フェーズの責務分離（各フェーズの「やること」「やらないこと」「成果物形式」の明確化）
- 進捗管理と冪等性:
  - 各フェーズの進捗状態チェックリスト
  - 冪等性保証の手順（既存成果物確認→差分特定→計画作成→承認→実行→完了確認）
- バージョン情報（対象リリース、ベースブランチ、作成日、最終更新日）

##### inception.md（Inception Phase専用）
- 役割：{{ROLE_INCEPTION}}
- **最初に必ず実行すること**:
  - 追加ルールの確認（`prompts/additional-rules.md` を読み込み）
  - 既存成果物の確認（冪等性の保証）:
    - `requirements/intent.md`
    - `design-artifacts/existing-system-model.md`
    - `story-artifacts/user_stories.md`
    - `story-artifacts/units/*.md`
    - `requirements/prfaq.md`
  - 既存ファイルがある場合は内容を読み込んで差分のみ更新
  - 完了済みのステップはスキップ
- フロー：
  1. Intent明確化
  2. 既存コード分析（{{DEVELOPMENT_TYPE}} が brownfield の場合）
  3. ユーザーストーリー作成
  4. Unit定義
  5. PRFAQ作成
- 各ステップの実行ルール：
  - 計画ファイルを `plans/` に作成
  - チェックボックス付きタスクリスト
  - 人間の承認後に実行
- 完了基準

##### construction.md（Construction Phase専用）
- 役割：{{ROLE_CONSTRUCTION}}
- **最初に必ず実行すること**（5ステップ）:
  - **ステップ1: 追加ルールの確認**
    - `prompts/additional-rules.md` を読み込み
  - **ステップ2: Inception Phase 完了確認**
    - `requirements/intent.md` が存在するか
    - `story-artifacts/units/` に Unit 定義ファイルが存在するか
    - 存在しない場合はエラーを表示して終了
  - **ステップ3: 全 Unit の進捗状況を自動分析**
    - `story-artifacts/units/` 配下のすべての Unit を読み込み
    - 各 Unit について以下をチェック:
      - ドメインモデル: `design-artifacts/domain-models/<unit>_domain_model.md`
      - 論理設計: `design-artifacts/logical-designs/<unit>_logical_design.md`
      - コード実装: 関連ソースコードファイル
      - テスト実装: 関連テストファイル
      - 実装記録: `construction/units/<unit>_implementation.md`（「完了」と明記されているか）
    - 進捗判定: 完了/進行中/未着手
  - **ステップ4: 対象 Unit の決定**
    - **ケース1: 進行中の Unit がある** → 自動的にその Unit の続きから実行
    - **ケース2: 未着手の Unit がある** → `AskUserQuestion` ツールでユーザーに選択を委ねる
    - **ケース3: すべて完了** → Operations Phase への移行を提案
  - **ステップ5: 実行前確認**
    - 選択された Unit の計画を作成
    - 人間の承認を得る
- フロー（選択された1つの Unit に対してのみ実行）：
  1. ドメインモデル設計（DDD原則）
  2. 論理設計（NFR反映）
  3. コード生成
  4. テスト生成
  5. 統合とレビュー
- 各ステップの実行ルール（Inception と同様）
- 完了基準（Unit単位）
- 次のステップ:
  - Unit完了後、他に未完了Unitがあれば継続
  - すべてのUnit完了後、Operations Phase起動プロンプトを表示

##### operations.md（Operations Phase専用）
- 役割：{{ROLE_OPERATIONS}}
- **最初に必ず実行すること**（3ステップ）:
  - **1. 追加ルールの確認**
    - `prompts/additional-rules.md` を読み込み
  - **2. Construction Phase 完了確認**
    - `story-artifacts/units/` 配下のすべての Unit について
    - `construction/units/<unit>_implementation.md` が存在し「完了」と記載されているか
    - ビルドが成功するか
    - すべてのテストがパスするか
    - 完了していない場合は Construction Phase に戻る
  - **3. 既存成果物の確認（冪等性の保証）**
    - `operations/deployment_checklist.md`
    - CI/CD設定ファイル（例: `.github/workflows/`, `.gitlab-ci.yml` 等）
    - `operations/monitoring_strategy.md`
    - `operations/distribution_feedback.md`（配布チャネル向けフィードバック記録）
    - `operations/post_release_operations.md`
    - 既存ファイルがある場合は内容を読み込んで差分のみ更新
    - 完了済みのステップはスキップ
- フロー：
  1. デプロイ準備
  2. CI/CD構築
  3. 監視・ロギング戦略
  4. 配布（該当する場合：TestFlight、ストア申請、パッケージ公開等）
  5. リリース後の運用
- 各ステップの実行ルール（Inception と同様）
- 完了基準
- **AI-DLCサイクル完了**:
  - ユーザーフィードバック収集
  - 運用データの分析
  - 改善点・新機能の洗い出し
  - 次期バージョンの計画
- **次のサイクル**:
  - 新バージョンのディレクトリ作成手順
  - プロンプトファイルのコピー手順
  - setup-prompt.md の変数更新手順
  - 次期バージョンの Inception Phase 起動プロンプト

##### history.md（プロンプト実行履歴）
- 初期テンプレートを作成
- 記録ルール：
  - 各プロンプト実行時にリアルタイムで追記
  - 日時取得：`date '+%Y-%m-%d %H:%M:%S'` コマンドを必ず使用
  - 記録項目：日時、フェーズ名、実行内容、プロンプト、成果物、備考

##### additional-rules.md（追加ルール）
- プロジェクト固有の追加ルールや制約を記載
- 初期テンプレートを作成：
  - 実行前の検証ルール（Codex MCPレビュー、指示の妥当性検証）
  - フェーズ固有のルール
  - 禁止事項
  - カスタムワークフロー
- 各フェーズのプロンプトファイルから参照される

#### 3. 重要な設計原則

- **フェーズごとに必要な情報のみ**：各 .md は該当フェーズに必要な情報だけを含める
- **コンテキストリセット前提**：common.md + 該当フェーズの .md のみ読み込む設計
- **AI-DLC原則の反映**：会話の反転、短サイクル、設計技法統合
- **言語統一**：すべてのドキュメント・コメントは {{LANGUAGE}} で記述

#### 4. 初回の history.md 記録

このセットアップ作業自体を history.md に記録してください：
- 実行日時（`date` コマンドで取得）
- フェーズ：準備
- 実行内容：AI-DLC環境セットアップ
- このプロンプト全体
- 作成したファイル一覧

#### 5. 完了確認と次のステップの表示

すべての準備が完了したら、以下を実行してください：

1. 作成したファイルの一覧を表示
2. 各プロンプトファイルの概要を簡潔に説明
3. **以下の「セットアップ完了メッセージ」をユーザーに表示**

---

**ユーザーへの表示内容（そのまま出力してください）**:

```
🎉 AI-DLC環境のセットアップが完了しました！

作成されたファイル:
- prompts/common.md - 全フェーズ共通知識
- prompts/inception.md - Inception Phase用プロンプト
- prompts/construction.md - Construction Phase用プロンプト
- prompts/operations.md - Operations Phase用プロンプト
- prompts/additional-rules.md - 追加ルール
- prompts/history.md - 実行履歴
- plans/, requirements/, story-artifacts/, design-artifacts/, construction/, operations/ ディレクトリ

---

## 重要: コンテキストリセットについて

AI-DLC では、各フェーズの開始時にコンテキストをリセット（新しいセッションを開始）することを推奨します。

理由：
- 各フェーズで必要な情報のみを読み込むことで、コンテキスト効率を最大化
- 不要な情報による混乱を防止
- 各フェーズの責務を明確に分離

---

## 次のステップ: Inception Phase の開始

新しいセッション（コンテキストリセット）を開始し、以下のプロンプトをコピーして入力してください：

```
以下のファイルを読み込んで、Inception Phase を開始してください：
- {{DOCS_ROOT}}/prompts/common.md
- {{DOCS_ROOT}}/prompts/inception.md

{{PROJECT_NAME}} {{VERSION}} の開発を開始します。
まず Intent（開発意図）を明確化し、ユーザーストーリーと Unit 定義を行います。
```

---

注意:
- セットアップが完了したら、必ず新しいセッションで上記のプロンプトを実行してください
- 各フェーズ完了時にも、次のフェーズ用のプロンプトが表示されます
```
