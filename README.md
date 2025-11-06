# AI-DLC Starter Kit

AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット

## 概要

このリポジトリには、AWS が提唱する AI-DLC 方法論の日本語リソースとプロンプトテンプレートが含まれています。

- **AI-DLC とは**: AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論
- **3つのフェーズ**: Inception（起動）→ Construction（構築）→ Operations（運用）

## 📂 リポジトリ構成

```
ai-dlc-starter-kit/
├── docs/
│   └── translations/          # AI-DLC ホワイトペーパーの日本語翻訳
│       ├── README.md
│       ├── AI-DLC_I_CONTEXT_Translation.md
│       ├── AI-DLC_II_KEY_PRINCIPLES_Translation.md
│       ├── AI-DLC_III_CORE_FRAMEWORK_Translation.md
│       ├── AI-DLC_IV_IN_ACTION_Translation.md
│       ├── AI-DLC_V_IN_ACTION_BrownField_Translation.md
│       ├── AI-DLC_VI_Adopting_Translation.md
│       ├── AI-DLC_AppendixA_ja.md
│       └── AI-Driven_Development_Lifecycle_Summary.md
│
└── prompts/                   # プロンプトテンプレート
    ├── setup-prompt.md        # セットアッププロンプト
    ├── common.md              # 全フェーズ共通
    ├── inception.md           # Inception Phase
    ├── construction.md        # Construction Phase
    ├── operations.md          # Operations Phase
    ├── additional-rules.md    # 追加ルール
    └── history.md             # 実行履歴テンプレート
```

## 🚀 クイックスタート

### 1. AI-DLC について学ぶ

まず、AI-DLC の概要を理解しましょう：

```bash
# 要約版を読む（10分）
cat docs/translations/AI-Driven_Development_Lifecycle_Summary.md

# 詳細を読む（30分〜1時間）
cat docs/translations/AI-DLC_I_CONTEXT_Translation.md
cat docs/translations/AI-DLC_II_KEY_PRINCIPLES_Translation.md
cat docs/translations/AI-DLC_III_CORE_FRAMEWORK_Translation.md
```

推奨する読み方は [docs/translations/README.md](docs/translations/README.md) を参照してください。

### 2. プロジェクトをセットアップ

`prompts/setup-prompt.md` を Claude に読み込ませて、プロジェクトのセットアップを実行します：

```markdown
以下のファイルを読み込んで、AI-DLC 開発環境をセットアップしてください：
- prompts/setup-prompt.md

変数は以下の通りです：
- PROJECT_NAME = あなたのプロジェクト名
- VERSION = v1.0
- BRANCH = main（または releases/v1.0）
- DEVELOPMENT_TYPE = greenfield（または brownfield）
- DOCS_ROOT = docs
```

### 3. 開発を開始

セットアップが完了したら、各フェーズのプロンプトを使用して開発を進めます：

#### Inception Phase
```markdown
以下のファイルを読み込んで、Inception Phase を開始してください：
- docs/prompts/common.md
- docs/prompts/inception.md

（プロジェクト名） （バージョン） の開発を開始します。
まず Intent（開発意図）を明確化し、ユーザーストーリーと Unit 定義を行います。
```

#### Construction Phase
```markdown
以下のファイルを読み込んで、Construction Phase を開始してください：
- docs/prompts/common.md
- docs/prompts/construction.md

進捗状況を自動的に分析し、次に実装すべき Unit を決定してください。
```

#### Operations Phase
```markdown
以下のファイルを読み込んで、Operations Phase を開始してください：
- docs/prompts/common.md
- docs/prompts/operations.md

すべての Unit の Construction が完了しました。
デプロイ準備、CI/CD構築、監視設定、リリースを実施します。
```

## 📚 ドキュメント

### AI-DLC 翻訳文書

- [README](docs/translations/README.md) - 翻訳文書の読み方ガイド
- [要約版](docs/translations/AI-Driven_Development_Lifecycle_Summary.md) - 全体の概要（最初に読むことを推奨）
- [背景](docs/translations/AI-DLC_I_CONTEXT_Translation.md) - なぜ AI-DLC が必要か
- [主要原則](docs/translations/AI-DLC_II_KEY_PRINCIPLES_Translation.md) - AI-DLC を支える 10 の原則
- [コアフレームワーク](docs/translations/AI-DLC_III_CORE_FRAMEWORK_Translation.md) - 3つのフェーズの詳細
- [実践例（新規開発）](docs/translations/AI-DLC_IV_IN_ACTION_Translation.md) - Green-Field プロジェクト
- [実践例（既存システム）](docs/translations/AI-DLC_V_IN_ACTION_BrownField_Translation.md) - Brown-Field プロジェクト
- [導入方法](docs/translations/AI-DLC_VI_Adopting_Translation.md) - 組織への導入戦略
- [付録A](docs/translations/AI-DLC_AppendixA_ja.md) - プロンプトテンプレート集

### プロンプトテンプレート

- [setup-prompt.md](prompts/setup-prompt.md) - 環境セットアップ用プロンプト
- [common.md](prompts/common.md) - 全フェーズ共通の知識ベース
- [inception.md](prompts/inception.md) - Inception Phase 用プロンプト
- [construction.md](prompts/construction.md) - Construction Phase 用プロンプト
- [operations.md](prompts/operations.md) - Operations Phase 用プロンプト

## 🎯 AI-DLC の主要原則

1. **再構築（Reimagine not Retrofit）** - 既存手法の改良ではなく、AI時代に合わせた根本的な再設計
2. **会話の反転（Reverse the Conversation）** - AI が計画を提示し、人間が承認・判断
3. **設計技法の統合（Integrate Design Techniques）** - DDD・BDD・TDD を AI が自動適用
4. **AI の現実的な能力に合わせる** - AI の強みと限界を理解した設計
5. **複雑なシステム開発を対象とする** - 大規模・複雑なシステムに適用
6. **人間との共創を維持する** - AI が提案、人間が検証・承認
7. **学習容易性** - 既存の知識を活用し、段階的に学習可能
8. **役割の集約** - 専門特化された役割を最小限に
9. **ステージを最小化してフローを最大化** - 短サイクルで高速イテレーション
10. **固定プロセスを廃止** - AI が状況に応じて最適なプロセスを提案

## 🔗 関連リンク

- [オリジナルのホワイトペーパー](https://prod.d13rzhkk8cj2z0.amplifyapp.com) - AWS による AI-DLC 公式ドキュメント

## 📄 ライセンス

このリポジトリのオリジナルコンテンツ（プロンプトテンプレート等）は MIT License で提供されています。

AI-DLC 翻訳文書については、オリジナルのホワイトペーパーは AWS (Amazon Web Services) により公開されており、著者は Raju SP です。オリジナルドキュメントには明示的なライセンス情報が記載されていないため、このリポジトリの翻訳文書は学習・参考目的での利用を想定しています。商用利用や再配布については、AWS または著者に直接確認することを推奨します。

## 🤝 コントリビューション

問題や改善提案がありましたら、Issue や Pull Request をお気軽にお送りください。

## 📮 フィードバック

このスターターキットについてのフィードバックや質問は、GitHub Issues でお願いします。
