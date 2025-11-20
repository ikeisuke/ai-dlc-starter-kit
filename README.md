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
│       └── v1/                # バージョン単位で管理
│           ├── prompts/       # 各フェーズのプロンプト
│           ├── templates/     # ドキュメントテンプレート
│           └── ...            # その他の成果物
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
- `VERSION`: バージョン番号（例: `v1.0`, `1.0.0`）
- `PROJECT_TYPE`: `ios` / `android` / `web` / `backend` / `general`
- `DEVELOPMENT_TYPE`: `greenfield`（新規） / `brownfield`（既存）
- `DOCS_ROOT`: プロンプトとテンプレートを配置するディレクトリ（例: `docs`, `ai-dlc`）

セットアップが完了すると、`{DOCS_ROOT}/{VERSION}/` 配下に以下が作成されます：
```
{DOCS_ROOT}/{VERSION}/
├── prompts/              # 各フェーズのプロンプトファイル
├── templates/            # ドキュメントテンプレート（JIT自動生成）
├── plans/                # 実行計画
├── requirements/         # 要件定義
├── story-artifacts/      # ユーザーストーリー、Unit定義
├── design-artifacts/     # ドメインモデル、論理設計
├── construction/         # 実装記録、progress.md
└── operations/           # デプロイ、CI/CD、監視設定
```

**重要**:
- セットアップ完了後、`{DOCS_ROOT}/{VERSION}/prompts/additional-rules.md` をプロジェクトに合わせてカスタマイズしてください（コーディング規約、セキュリティ要件等）
- **このスターターキットはバージョン単位で環境を構築します**。新バージョン開発時は新しい`VERSION`でsetup-prompt.mdを再実行します

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
- Unit定義（依存関係、優先度、見積もりを含む）
- PRFAQ作成
- **進捗管理ファイル（progress.md）作成**: 全Unit情報を1つのファイルで管理

**完了後**: 自動的にGitコミットが作成されます

#### Construction Phase（実装）
```markdown
以下のファイルを読み込んで、Construction Phase を開始してください：
prompts/common.md
prompts/construction.md
```

AIが以下を実施します：
- **進捗管理ファイル（progress.md）を読み込み**: 1つのファイルで全Unit状態を把握
- **Unit依存関係に基づいて実行順を自動判断**（複数実行可能な場合はユーザーに提案）
- **Phase 1: 設計**（コードは書かない）
  - **対話形式でドメインモデル設計**: 構造と責務を定義
  - **対話形式で論理設計**: コンポーネント構成とインターフェースを定義
  - 設計レビュー（ユーザー承認）
- **Phase 2: 実装**（設計を参照してコード生成）
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

### 4. 次バージョンの開発（ライフサイクルの継続）

Operations Phase完了後、フィードバックを収集して次バージョンの開発を開始します：

```markdown
以下のファイルを読み込んで、{PROJECT_NAME} v2.0 の AI-DLC 環境をセットアップしてください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md

変数を以下に設定してください：
- VERSION = v2.0
- DOCS_ROOT = {前バージョンと同じ}
- その他の変数も適宜設定
```

**必要に応じて前バージョンのファイルを引き継ぐ**:
- `{DOCS_ROOT}/v1.0/prompts/additional-rules.md` → v2.0にコピーしてカスタマイズを引き継ぐ
- `{DOCS_ROOT}/v1.0/requirements/intent.md` → 参照して改善点を反映
- その他、引き継ぎたいファイルがあればコピー

セットアップ完了後、新しいセッションで Inception Phase を開始し、**Inception → Construction → Operations → (次バージョン)** のライフサイクルを継続します。

## ✨ 主要な機能

### 1. 対話形式による開発
- AIが独自判断をせず、不明点は `[Question]`/`[Answer]` タグで質問
- ユーザーとの対話を通じて要件や設計を明確化

### 2. 進捗管理の一元化（NEW）
- Inception Phaseで `construction/progress.md` を自動生成
- Unit一覧、状態、依存関係、優先度、見積もりを1つのファイルで管理
- Construction Phase実行時に1ファイル読むだけで全体状況を把握（コンテキスト削減）
- 各Unit完了後に自動更新（次回実行可能なUnit候補を再計算）

### 3. Unit依存関係の自動管理（NEW）
- Inception PhaseでUnit間の依存関係を定義
- Construction PhaseでAIが依存関係を解析し、実行可能なUnitを自動判断
- 複数のUnitが実行可能な場合は優先度と見積もりを提示し、推奨を提案

### 4. 設計と実装の明確な分離（NEW）
- **Phase 1（設計）**: コードは書かず、構造・責務・インターフェースのみを定義
- **Phase 2（実装）**: 設計ファイルを参照してコードを生成
- 設計時点でのコード大量生成を防止し、レビューしやすい設計書を作成

### 5. JIT（Just-In-Time）テンプレート生成（NEW）
- 初回セットアップ時はテンプレートを生成せず軽量化
- 各フェーズ実行時に必要なテンプレートのみを自動生成
- 同一セッション内で生成完了後、プロンプト再読み込みで継続

### 6. コンテキスト溢れ防止
- 各フェーズで必要最小限のファイルのみ読み込み
- `ls` / `grep` コマンドで効率的に情報取得
- 指定されたDOCS_ROOT配下のファイルのみ読み込む制限

### 7. 人間の承認プロセス
- 計画作成後、必ず「進めてよろしいですか？」と質問
- 設計完了後、実装前にレビューと承認を要求
- 承認なしで次のステップに進まない

### 8. 自動Gitコミット
- セットアップ完了時
- Inception Phase完了時
- 各Unit完了時
- Operations Phase完了時

### 9. プラットフォーム対応
- `PROJECT_TYPE` 変数でプラットフォームを指定
- iOS/Android固有の注意事項（ローカライゼーション等）を自動表示

### 10. 履歴管理の簡素化（NEW）
- Bash heredoc (`cat <<'EOF' | tee -a`) で履歴を追記
- ファイルを読み込まずに追記可能（テンプレートがファイル先頭に配置）

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
