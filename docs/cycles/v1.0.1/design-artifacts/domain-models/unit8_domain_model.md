# ドメインモデル: セットアップファイル最適化

## 概要
セットアップファイル（1746行）をフェーズ別に分割し、可読性・保守性を向上させる。各ファイルの責務と境界を明確化する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

---

## エンティティ（Entity）

### SetupMain（メインファイル）
- **識別子**: `prompts/setup-prompt.md`
- **属性**:
  - mode: String - 実行モード（list/template/setup）
  - variables: Map - 変数定義（PROJECT_NAME, CYCLE, AIDLC_ROOT等）
  - flowControl: Enum - セットアップフロー制御
- **責務**:
  - MODEに応じた処理分岐
  - 変数の定義と初期化
  - 各フェーズセットアップファイルへの参照
- **目安行数**: 300行

### InceptionSetup（Inceptionセットアップ）
- **識別子**: `prompts/setup/inception.md`
- **属性**:
  - promptContent: Text - inception.mdプロンプト生成内容
  - templates: List - Inception用テンプレート群
- **責務**:
  - inception.mdプロンプトファイルの生成
  - Inception関連テンプレートの保持（intent, user_stories, unit_definition, prfaq, progress）
- **目安行数**: 500行

### ConstructionSetup（Constructionセットアップ）
- **識別子**: `prompts/setup/construction.md`
- **属性**:
  - promptContent: Text - construction.mdプロンプト生成内容
  - templates: List - Construction用テンプレート群
- **責務**:
  - construction.mdプロンプトファイルの生成
  - Construction関連テンプレートの保持（domain_model, logical_design, implementation_record）
- **目安行数**: 500行

### OperationsSetup（Operationsセットアップ）
- **識別子**: `prompts/setup/operations.md`
- **属性**:
  - promptContent: Text - operations.mdプロンプト生成内容
  - templates: List - Operations用テンプレート群
- **責務**:
  - operations.mdプロンプトファイルの生成
  - Operations関連テンプレートの保持（deployment_checklist, monitoring_strategy, distribution_feedback, post_release_operations, progress）
- **目安行数**: 500行

### CommonSetup（共通処理）
- **識別子**: `prompts/setup/common.md`
- **属性**:
  - directoryStructure: List - 作成するディレクトリ一覧
  - commonFiles: List - 共通ファイル（history.md, additional-rules.md, index.md, backlog関連）
  - completionSteps: List - 完了処理手順
- **責務**:
  - ディレクトリ構成の作成
  - 共通ファイルの生成
  - 完了確認と次ステップの表示
- **目安行数**: 200行

---

## 値オブジェクト（Value Object）

### PromptSection
- **属性**:
  - header: String - セクションタイトル
  - content: Text - セクション内容
- **不変性**: 生成後は変更されない（新バージョンで再生成）
- **等価性**: headerが同一であれば同一セクション

### Template
- **属性**:
  - name: String - テンプレート名
  - content: Text - テンプレート内容
  - targetPhase: Enum - 対象フェーズ（Inception/Construction/Operations）
- **不変性**: テンプレート定義は不変
- **等価性**: nameが同一であれば同一テンプレート

### DirectoryPath
- **属性**: path: String - ディレクトリパス
- **不変性**: パスは不変
- **等価性**: path文字列の一致

---

## 集約（Aggregate）

### SetupSystem
- **集約ルート**: SetupMain
- **含まれる要素**:
  - SetupMain（1）
  - InceptionSetup（1）
  - ConstructionSetup（1）
  - OperationsSetup（1）
  - CommonSetup（1）
- **境界**: セットアップファイル群全体
- **不変条件**:
  - 全ファイルの合計が元の機能を完全にカバー
  - 各ファイルは独立して読み込み可能
  - ファイル間の参照は一方向（Main→各フェーズ→Common）

---

## ドメインサービス

### SetupExecutor
- **責務**: セットアップ実行フローの制御
- **操作**:
  - executeSetup() - セットアップ全体の実行
  - dispatchToPhase(phase) - フェーズ別処理への分岐
  - validateCompletion() - 完了確認

### TemplateGenerator
- **責務**: テンプレートファイルの生成
- **操作**:
  - generateFromEmbedded(templateName) - 埋め込みテンプレートからファイル生成
  - validateTemplate(content) - テンプレート形式の検証

---

## ファイル間の参照関係

```
SetupMain (prompts/setup-prompt.md)
├── MODE判定
├── 変数定義
├── AI-DLC概要（圧縮版）
└── フェーズ別処理への分岐
    ├── InceptionSetup (prompts/setup/inception.md)
    │   ├── inception.mdプロンプト生成
    │   └── Inception用テンプレート
    ├── ConstructionSetup (prompts/setup/construction.md)
    │   ├── construction.mdプロンプト生成
    │   └── Construction用テンプレート
    ├── OperationsSetup (prompts/setup/operations.md)
    │   ├── operations.mdプロンプト生成
    │   └── Operations用テンプレート
    └── CommonSetup (prompts/setup/common.md)
        ├── ディレクトリ作成
        ├── 共通ファイル生成
        └── 完了処理
```

---

## ユビキタス言語

- **セットアップ**: AI-DLC環境の初期構築プロセス
- **プロンプトファイル**: AIへの指示を記載したMarkdownファイル
- **テンプレート**: 成果物の雛形（ドメインモデル、論理設計等）
- **フェーズ**: AI-DLCの3段階（Inception/Construction/Operations）
- **MODE**: セットアップの動作モード（list/template/setup）

---

## 不明点と質問（設計中に記録）

（現時点で不明点なし - Unit定義が明確なため）

---

## 作成日時
2025-11-28
