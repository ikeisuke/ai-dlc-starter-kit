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
│   ├── translations/          # AI-DLC ホワイトペーパーの日本語翻訳
│   │   ├── README.md
│   │   ├── AI-DLC_I_CONTEXT_Translation.md
│   │   ├── AI-DLC_II_KEY_PRINCIPLES_Translation.md
│   │   ├── AI-DLC_III_CORE_FRAMEWORK_Translation.md
│   │   ├── AI-DLC_IV_IN_ACTION_Translation.md
│   │   ├── AI-DLC_V_IN_ACTION_BrownField_Translation.md
│   │   ├── AI-DLC_VI_Adopting_Translation.md
│   │   ├── AI-DLC_AppendixA_ja.md
│   │   └── AI-Driven_Development_Lifecycle_Summary.md
│   │
│   └── example/               # セットアップ後に生成される例（参考用）
│       ├── prompts/           # 各フェーズのプロンプト
│       └── templates/         # ドキュメントテンプレート
│
└── prompts/
    └── setup-prompt.md        # セットアッププロンプト（これだけ使います）
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

別プロジェクトのルートディレクトリで、`prompts/setup-prompt.md` を Claude に読み込ませます：

```markdown
以下のファイルを読み込んで、AI-DLC 開発環境をセットアップしてください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md
```

セットアップ時に変数の確認があるので、プロジェクトに合わせて変更してください：
- `PROJECT_NAME`: プロジェクト名
- `PROJECT_TYPE`: `ios` / `android` / `web` / `backend` / `general`
- `DEVELOPMENT_TYPE`: `greenfield`（新規） / `brownfield`（既存）
- `DOCS_ROOT`: プロンプトとテンプレートを配置するディレクトリ（例: `docs`）

セットアップが完了すると、以下が作成されます：
- `prompts/` - 各フェーズのプロンプトファイル
- `templates/` - ドキュメントテンプレート（11ファイル）
- 各成果物用のディレクトリ（plans/, requirements/, story-artifacts/, 等）

**重要**: セットアップ完了後、`prompts/additional-rules.md` をプロジェクトに合わせてカスタマイズしてください（コーディング規約、セキュリティ要件等）。

### 3. 開発を開始

**各フェーズは新しいセッションで開始**してください（コンテキストリセット）：

#### Inception Phase（要件定義）
```markdown
以下のファイルを読み込んで、Inception Phase を開始してください：
prompts/common.md
prompts/inception.md
```

AIが以下を実施します：
- **対話形式でIntentを作成**: 不明点は `[Question]`/`[Answer]` タグで記録し、質問してきます
- ユーザーストーリー作成
- Unit定義
- PRFAQ作成

**完了後**: 自動的にGitコミットが作成されます

#### Construction Phase（実装）
```markdown
以下のファイルを読み込んで、Construction Phase を開始してください：
prompts/common.md
prompts/construction.md
```

AIが以下を実施します：
- 全Unit進捗を自動分析（コンテキスト溢れ防止のため、最小限のファイルのみ読み込み）
- 対象Unitを選択
- **対話形式でドメインモデル設計・論理設計**: 不明点を質問してきます
- コード生成、テスト生成
- ビルド、テスト実行

**各Unit完了後**: 自動的にGitコミットが作成されます
**重要**: 1つのUnit完了後、新しいセッションで次のUnitを実施してください

#### Operations Phase（デプロイ・運用）
```markdown
以下のファイルを読み込んで、Operations Phase を開始してください：
prompts/common.md
prompts/operations.md
```

AIが以下を実施します：
- Construction完了確認（コンテキスト溢れ防止のため、最小限のファイルのみ読み込み）
- **対話形式でデプロイ準備、CI/CD構築、監視設定**: 不明点を質問してきます
- リリース後の運用

**完了後**: 自動的にGitコミットが作成されます

## ✨ 主要な機能

### 1. 対話形式による開発
- AIが独自判断をせず、不明点は `[Question]`/`[Answer]` タグで質問
- ユーザーとの対話を通じて要件や設計を明確化

### 2. コンテキスト溢れ防止
- 各フェーズで必要最小限のファイルのみ読み込み
- `ls` / `grep` コマンドで効率的に情報取得
- 指定されたDOCS_ROOT配下のファイルのみ読み込む制限

### 3. 人間の承認プロセス
- 計画作成後、必ず「進めてよろしいですか？」と質問
- 承認なしで次のステップに進まない

### 4. 自動Gitコミット
- セットアップ完了時
- Inception Phase完了時
- 各Unit完了時
- Operations Phase完了時

### 5. プラットフォーム対応
- `PROJECT_TYPE` 変数でプラットフォームを指定
- iOS/Android固有の注意事項（ローカライゼーション等）を自動表示

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

### セットアッププロンプト

- [setup-prompt.md](prompts/setup-prompt.md) - 環境セットアップ用プロンプト（これだけ読み込めば、プロジェクトに合わせたプロンプトとテンプレートが自動生成されます）

## 🎯 このスターターキットの設計原則

1. **会話の反転（Reverse the Conversation）** - AIが作業計画を提示し、人間が承認・判断する
2. **対話による明確化** - AIが独自判断をせず、不明点は質問して明確化する
3. **設計技法の統合** - DDD・BDD・TDDをAIが自動適用
4. **短サイクル反復** - 各フェーズを短いサイクルで反復し、継続的に価値を提供
5. **人間との共創** - リスク管理や重要判断は人間が担当
6. **冪等性の保証** - 各ステップで既存成果物を確認し、差分のみ更新
7. **コンテキスト効率** - 必要最小限のファイルのみ読み込み、コンテキスト溢れを防止
8. **自動コミット** - 重要なタイミングで自動的にGitコミットを作成し、進捗を記録
9. **プラットフォーム対応** - iOS/Android等の固有要件を自動で含める
10. **カスタマイズ可能** - プロジェクト固有のルールを additional-rules.md に記述可能

## 🔗 関連リンク

- [オリジナルのホワイトペーパー](https://prod.d13rzhkk8cj2z0.amplifyapp.com) - AWS による AI-DLC 公式ドキュメント

## 📄 ライセンス

このリポジトリのオリジナルコンテンツ（プロンプトテンプレート等）は MIT License で提供されています。

AI-DLC 翻訳文書については、オリジナルのホワイトペーパーは AWS (Amazon Web Services) により公開されており、著者は Raju SP です。オリジナルドキュメントには明示的なライセンス情報が記載されていないため、このリポジトリの翻訳文書は学習・参考目的での利用を想定しています。商用利用や再配布については、AWS または著者に直接確認することを推奨します。

## 🤝 コントリビューション

問題や改善提案がありましたら、Issue や Pull Request をお気軽にお送りください。

## 📮 フィードバック

このスターターキットについてのフィードバックや質問は、GitHub Issues でお願いします。
