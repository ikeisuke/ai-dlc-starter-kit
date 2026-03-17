# AI-DLC Starter Kit

[![Version](https://img.shields.io/badge/version-1.23.0-blue.svg)](./version.txt)

AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット

## 概要

このリポジトリには、AWS が提唱する AI-DLC 方法論の日本語リソースとプロンプトテンプレートが含まれています。

- **AI-DLC とは**: AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論
- **3つのフェーズ**: Inception（起動）→ Construction（構築）→ Operations（運用）

## リポジトリ構成

```text
ai-dlc-starter-kit/
├── docs/
│   ├── translations/          # AI-DLC ホワイトペーパーの日本語翻訳
│   ├── aidlc.toml             # プロジェクト設定
│   ├── aidlc/                 # 全サイクル共通ファイル
│   │   ├── bin/               # ユーティリティスクリプト
│   │   ├── config/            # デフォルト設定
│   │   ├── guides/            # 各種ガイドドキュメント
│   │   ├── lib/               # 共通ライブラリ
│   │   ├── prompts/           # フェーズプロンプト（inception/construction/operations）
│   │   ├── skills/            # AIエージェントスキル定義
│   │   ├── templates/         # ドキュメントテンプレート
│   │   └── tests/             # シェルスクリプトテスト
│   │
│   └── cycles/                # サイクル固有成果物
│       ├── rules.md           # プロジェクト固有ルール
│       ├── operations.md      # サイクル横断の運用引き継ぎ情報
│       └── {{CYCLE}}/         # サイクル識別子で管理（例: v1.0.0, 2024-12）
│           ├── inception/     # Inception進捗管理
│           ├── requirements/  # 要件定義成果物
│           ├── story-artifacts/  # ユーザーストーリー、Unit定義
│           ├── design-artifacts/ # ドメインモデル、論理設計
│           ├── construction/  # Construction進捗・実装記録
│           ├── operations/    # Operations進捗管理
│           ├── plans/         # 実装計画
│           └── history/       # 開発履歴
│
└── prompts/
    └── setup-prompt.md        # セットアッププロンプト（エントリーポイント）
```

## クイックスタート

### 1. AI-DLC について学ぶ

まず、AI-DLC の概要を理解しましょう：

- [要約版](docs/translations/AI-Driven_Development_Lifecycle_Summary.md)（10分）
- [詳細版](docs/translations/README.md)（30分〜1時間）

### 2. プロジェクトをセットアップ

別プロジェクトのルートディレクトリで、このスターターキットの `prompts/setup-prompt.md` を利用中のAIエージェントに読み込ませます：

```markdown
以下のファイルを読み込んで、AI-DLC 開発環境をセットアップしてください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md
```

セットアップ時に以下の変数を確認されます：

| 変数 | 説明 | 例 |
|------|------|-----|
| `PROJECT_NAME` | プロジェクト名 | `my-app` |
| `CYCLE` | サイクル識別子 | `v1.0.0`, `2024-12`, `feature-x` |
| `PROJECT_TYPE` | プロジェクト種別 | `ios` / `android` / `web` / `backend` / `general` |
| `DEVELOPMENT_TYPE` | 開発種別 | `greenfield`（新規）/ `brownfield`（既存） |
| `DOCS_ROOT` | ドキュメントルート | `docs` |

セットアップ完了後、以下のディレクトリ構造が作成されます：

```text
docs/
├── aidlc.toml                # プロジェクト設定
├── aidlc/                    # 全サイクル共通（初回セットアップ時のみ作成、主要部分のみ抜粋）
│   ├── bin/                  # ユーティリティスクリプト
│   ├── prompts/              # 各フェーズのプロンプトファイル
│   ├── templates/            # ドキュメントテンプレート
│   └── ...                   # guides/, skills/, config/ 等
│
└── cycles/
    ├── rules.md              # プロジェクト固有ルール
    ├── operations.md         # サイクル横断の運用引き継ぎ情報
    └── {{CYCLE}}/            # サイクル固有成果物
```

**重要**:

- セットアップ完了後、`docs/cycles/rules.md` をプロジェクトに合わせてカスタマイズしてください
- 新サイクル開発時は新しい `CYCLE` で `setup-prompt.md` を再実行します

### 3. 開発を開始

各フェーズは**新しいセッション**で開始してください（コンテキストリセット）。

簡略指示でフェーズを開始できます：

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」 | Inception Phase |
| 「コンストラクション進めて」 | Construction Phase |
| 「オペレーション進めて」 | Operations Phase |

または、プロンプトファイルを直接指定：

```markdown
docs/aidlc/prompts/inception.md を読み込んでください
```

#### Inception Phase（要件定義）

- 進捗管理ファイルで6ステップの進捗を管理
- 対話形式でIntentを作成（不明点は質問）
- ユーザーストーリー・Unit定義を作成
- コンテキストリセット時は未完了ステップから自動再開

#### Construction Phase（実装）

- Unit依存関係に基づいて実行順を自動判断
- Phase 1（設計）: コードは書かず、構造・責務・インターフェースを定義
- Phase 2（実装）: 設計を参照してコード生成・テスト
- 各Unit完了後に自動Gitコミット

#### Operations Phase（デプロイ・運用）

- デプロイ準備、CI/CD構築、監視設定
- リリース後の運用
- 完了後に自動Gitコミット

### サイクル識別子について

サイクル識別子（`CYCLE`）には2つの形式があります：

| 形式 | 例 | 用途 |
|------|-----|------|
| バージョン番号 | `v1.0.0`, `v2.1.3` | 一般的なリリースサイクル |
| 名前付きサイクル | `waf/v1.0.0`, `auth/v1.0.0` | 機能テーマごとにサイクルを分類したい場合 |

**名前付きサイクル**は、複数の機能テーマを並行して管理する場合に便利です。`docs/aidlc.toml` の `[rules.cycle].mode` を `"named"` に設定すると、Inception Phase開始時に名前付きサイクルの作成・継続が案内されます。

```toml
[rules.cycle]
mode = "named"  # "default"（デフォルト）, "named", "ask"
```

名前付きサイクルでは `docs/cycles/{name}/vX.X.X/` のようなディレクトリ構造で成果物が管理されます。

### 4. 次サイクルの開発

Operations Phase 完了後、新しい `CYCLE` で `setup-prompt.md` を再実行してライフサイクルを継続します。

- `docs/cycles/rules.md` と `docs/cycles/operations.md` は全サイクル共通で引き継がれます
- 前サイクルの `requirements/intent.md` を参照して改善点を反映

## 主要な機能

### 対話形式による開発

AIが独自判断をせず、不明点は質問して明確化。ユーザーとの対話を通じて要件や設計を策定します。

### 進捗管理の一元化

全フェーズで `progress.md` を自動管理。コンテキストオーバーフロー時も未完了ステップから自動再開できます。

### Unit依存関係の自動管理

Inception Phase で定義した依存関係を解析し、実行可能な Unit を自動判断。複数候補がある場合は優先度と見積もりを提示します。

### 設計と実装の分離

Phase 1（設計）ではコードを書かず構造・責務・インターフェースを定義。Phase 2（実装）で設計を参照してコード生成。レビューしやすい設計書を作成します。

### AIレビュー統合

外部AIツール（Codex、Claude CLI、Gemini CLI）によるコード・アーキテクチャ・セキュリティレビューを統合。レビュー種別ごとの専門スキルで品質を確保します。

### スクリプト化基盤

`docs/aidlc/bin/` にユーティリティスクリプトを配置。環境情報取得、Issue操作、履歴書き込み、markdownlint実行等をスクリプト化し、AIエージェントの許可リスト運用を改善しています。

### バックトラック機能

フェーズ間を柔軟に行き来可能：

- Inception ← Construction: Unit追加・拡張が必要な場合
- Construction ← Operations: バグ修正が必要な場合

### コンテキスト効率

各フェーズで必要最小限のファイルのみ読み込み、コンテキスト溢れを防止。長いセッションで中断しても自動再開できます。

### 人間の承認プロセス

計画作成後・設計完了後に必ず承認を要求。承認なしで次のステップに進みません。

### 自動Gitコミット

セットアップ完了時、Inception Phase完了時、各Unit完了時、Operations Phase完了時に自動でGitコミットを作成します。

### カスタマイズ

- `docs/cycles/rules.md` にプロジェクト固有のルール（コーディング規約、セキュリティ要件等）を記述可能
- `docs/aidlc.toml` で各種設定（バックログモード、レビューモード、squash等）を制御
- `PROJECT_TYPE` でプラットフォーム固有の注意事項を自動表示

## ドキュメント

### AI-DLC 翻訳文書

| ドキュメント | 内容 |
|------------|------|
| [要約版](docs/translations/AI-Driven_Development_Lifecycle_Summary.md) | 全体の概要（最初に読むことを推奨） |
| [背景](docs/translations/AI-DLC_I_CONTEXT_Translation.md) | なぜ AI-DLC が必要か |
| [主要原則](docs/translations/AI-DLC_II_KEY_PRINCIPLES_Translation.md) | AI-DLC を支える 10 の原則 |
| [コアフレームワーク](docs/translations/AI-DLC_III_CORE_FRAMEWORK_Translation.md) | 3つのフェーズの詳細 |
| [実践例（新規）](docs/translations/AI-DLC_IV_IN_ACTION_Translation.md) | Green-Field プロジェクト |
| [実践例（既存）](docs/translations/AI-DLC_V_IN_ACTION_BrownField_Translation.md) | Brown-Field プロジェクト |
| [導入方法](docs/translations/AI-DLC_VI_Adopting_Translation.md) | 組織への導入戦略 |
| [付録A](docs/translations/AI-DLC_AppendixA_ja.md) | プロンプトテンプレート集 |

詳細な読み方ガイドは [docs/translations/README.md](docs/translations/README.md) を参照してください。

### その他

- [セットアッププロンプト](prompts/setup-prompt.md) - 環境セットアップ用（エントリーポイント）
- [CHANGELOG.md](CHANGELOG.md) - バージョンごとの変更履歴

## 設計原則

1. **会話の反転** - AIが作業計画を提示し、人間が承認・判断する
2. **対話による明確化** - AIが独自判断をせず、不明点は質問
3. **設計技法の統合** - DDD・BDD・TDDをAIが自動適用
4. **短サイクル反復** - 各フェーズを短いサイクルで反復
5. **人間との共創** - リスク管理や重要判断は人間が担当
6. **冪等性の保証** - 各ステップで既存成果物を確認し、差分のみ更新
7. **コンテキスト効率** - 必要最小限のファイルのみ読み込み
8. **自動コミット** - 重要なタイミングで自動的にGitコミットを作成

## 関連リンク

- [オリジナルのホワイトペーパー](https://prod.d13rzhkk8cj2z0.amplifyapp.com) - AWS による AI-DLC 公式ドキュメント

## ライセンス

このリポジトリのオリジナルコンテンツ（プロンプトテンプレート等）は MIT License で提供されています。

AI-DLC 翻訳文書については、オリジナルのホワイトペーパーは AWS (Amazon Web Services) により公開されており、著者は Raju SP です。オリジナルドキュメントには明示的なライセンス情報が記載されていないため、このリポジトリの翻訳文書は学習・参考目的での利用を想定しています。商用利用や再配布については、AWS または著者に直接確認することを推奨します。

## コントリビューション

問題や改善提案がありましたら、Issue や Pull Request をお気軽にお送りください。

## フィードバック

このスターターキットについてのフィードバックや質問は、GitHub Issues でお願いします。

- [フィードバック・改善提案](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feedback.yml)
- [バグ報告](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=bug.yml)
- [機能要望](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feature.yml)

**AIで作業中の場合**: 「AIDLCフィードバック」と入力すると、AIがフィードバック送信を案内します。
