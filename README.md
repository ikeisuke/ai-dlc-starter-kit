# AI-DLC Starter Kit

[![Version](https://img.shields.io/badge/version-2.1.8-blue.svg)](./version.txt)

AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット

## 概要

このリポジトリには、AWS が提唱する AI-DLC 方法論の日本語リソースとプロンプトテンプレートが含まれています。

- **AI-DLC とは**: AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論
- **3つのフェーズ**: Inception（起動）→ Construction（構築）→ Operations（運用）

## インストール

### 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済みであること
- Git がインストール済みであること
- （推奨）[dasel](https://github.com/TomWright/dasel) がインストール済みであること（設定ファイル操作に使用）

### インストール手順

1. Claude Codeでマーケットプレイスを追加:

```text
/plugin marketplace add ikeisuke/ai-dlc-starter-kit
```

2. プラグインをインストール:

```text
/plugin install aidlc@ikeisuke-ai-dlc-starter-kit
```

以下のスキルがまとめてインストールされます:

| スキル | 用途 |
|--------|------|
| `aidlc` | AI-DLCオーケストレーター（メインスキル） |
| `aidlc-setup` | 環境セットアップ・アップグレード |
| `aidlc-migrate` | v1→v2マイグレーション |
| `aidlc-feedback` | AI-DLCへのフィードバック送信 |
| `reviewing-inception-intent` | Intent承認前レビュー |
| `reviewing-inception-stories` | ストーリー承認前レビュー |
| `reviewing-inception-units` | Unit定義承認前レビュー |
| `reviewing-construction-plan` | 計画承認前レビュー |
| `reviewing-construction-design` | 設計レビュー |
| `reviewing-construction-code` | コード+セキュリティレビュー |
| `reviewing-construction-integration` | 統合レビュー |
| `reviewing-operations-deploy` | デプロイ計画レビュー |
| `reviewing-operations-premerge` | PRマージ前レビュー |
| `squash-unit` | Unit完了時のコミットスカッシュ |
| `write-history` | 履歴ファイルへの記録 |

3. 対象プロジェクトのルートディレクトリで `/aidlc-setup` を実行:

```text
/aidlc-setup
```

セットアップウィザードがプロジェクト情報の入力を案内し、`.aidlc/config.toml` と必要なディレクトリ構造を自動生成します。

### アップグレード（v1 → v2）

v1 から v2 へのアップグレードは、マイグレーションスキルで自動化されています:

```text
/aidlc-migrate
```

移行では以下が実行されます:
- v1 の `docs/aidlc/` → v2 の `skills/aidlc/` への構成移行
- `.aidlc/config.toml` の設定移行
- 既存サイクルデータの保持

### v1 ブランチについて

v1 系を引き続き使用したい場合は、[v1 ブランチ](https://github.com/ikeisuke/ai-dlc-starter-kit/tree/v1)を参照してください。v1 ブランチはメンテナンスモードであり、新機能の追加は行われません。

## リポジトリ構成

```text
ai-dlc-starter-kit/
├── skills/                    # Claude Codeスキルプラグイン
│   ├── aidlc/                 # メインスキル（オーケストレーター）
│   │   ├── SKILL.md           # スキル定義・引数ルーティング
│   │   ├── AGENTS.md          # マルチツールエントリポイント
│   │   ├── CLAUDE.md          # Claude Code固有設定
│   │   ├── steps/             # フェーズステップファイル
│   │   │   ├── common/        # 共通ルール・ワークフロー
│   │   │   ├── inception/     # Inception Phase（6ステップ）
│   │   │   ├── construction/  # Construction Phase（4ステップ）
│   │   │   ├── operations/    # Operations Phase（4ステップ）
│   │   │   └── setup/         # Setup Phase（3ステップ）
│   │   ├── scripts/           # ユーティリティスクリプト
│   │   ├── templates/         # ドキュメントテンプレート
│   │   └── config/            # デフォルト設定
│   ├── aidlc-setup/           # アップグレードスキル
│   └── squash-unit/           # コミットスカッシュスキル
│
├── .aidlc/                    # プロジェクト設定・サイクル成果物
│   ├── config.toml            # プロジェクト設定
│   ├── rules.md               # プロジェクト固有ルール
│   ├── operations.md          # 運用引き継ぎ情報
│   └── cycles/                # サイクル固有成果物
│       └── {{CYCLE}}/         # サイクル識別子で管理
│
├── docs/
│   └── translations/          # AI-DLC ホワイトペーパーの日本語翻訳
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

対象プロジェクトのルートディレクトリで `/aidlc-setup` を実行します:

```text
/aidlc-setup
```

セットアップウィザードがプロジェクト情報を対話形式で案内します。完了後、以下のディレクトリ構造が作成されます:

```text
.aidlc/
├── config.toml               # プロジェクト設定
├── rules.md                  # プロジェクト固有ルール
└── cycles/                   # サイクル固有成果物

skills/
├── aidlc/                    # メインスキル
├── aidlc-setup/              # アップグレードスキル
└── squash-unit/              # コミットスカッシュスキル
```

**重要**:

- セットアップ完了後、`.aidlc/rules.md` をプロジェクトに合わせてカスタマイズしてください
- 新サイクル開発時は新しい `CYCLE` で `/aidlc inception` を実行します

### 3. 開発を開始

各フェーズは**新しいセッション**で開始してください（コンテキストリセット）。

簡略指示でフェーズを開始できます：

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」 | Inception Phase |
| 「コンストラクション進めて」 | Construction Phase |
| 「オペレーション進めて」 | Operations Phase |

または、スキルコマンドを直接実行：

```text
/aidlc inception
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

**名前付きサイクル**は、複数の機能テーマを並行して管理する場合に便利です。`.aidlc/config.toml` の `[rules.cycle].mode` を `"named"` に設定すると、Inception Phase開始時に名前付きサイクルの作成・継続が案内されます。

```toml
[rules.cycle]
mode = "named"  # "default"（デフォルト）, "named", "ask"
```

名前付きサイクルでは `.aidlc/cycles/{name}/vX.X.X/` のようなディレクトリ構造で成果物が管理されます。

### 4. 次サイクルの開発

Operations Phase 完了後、新しい `CYCLE` で `/aidlc inception` を実行してライフサイクルを継続します。

- `.aidlc/rules.md` は全サイクル共通で引き継がれます
- 前サイクルの `requirements/intent.md` を参照して改善点を反映

## スキル構成

### プラグイン同梱スキル

`/plugin install aidlc@ikeisuke-ai-dlc-starter-kit` で以下のスキルがすべてインストールされます:

| スキル | 用途 |
|--------|------|
| `aidlc` | AI-DLCオーケストレーター（メインスキル） |
| `aidlc-setup` | 環境セットアップ・アップグレード・v1→v2移行 |
| `reviewing-inception-*` | Inception成果物レビュー（intent/stories/units） |
| `reviewing-construction-*` | Construction成果物レビュー（plan/design/code/integration） |
| `reviewing-operations-*` | Operations成果物レビュー（deploy/premerge） |
| `squash-unit` | Unit完了時のコミットスカッシュ |
| `write-history` | 履歴ファイルへの記録 |

### オプションスキル（別途インストール）

以下のスキルは [claude-skills](https://github.com/ikeisuke/claude-skills) リポジトリで提供されています。未インストールでも開発フローに影響はありません。

```text
/plugin marketplace add ikeisuke/claude-skills
/plugin install tools@ikeisuke-skills
```

| スキル | 用途 |
|--------|------|
| `session-title` | ターミナルタブのタイトル・バッジ設定（macOS） |
| `suggest-permissions` | 許可設定の自動提案・監査 |

## 主要な機能

### エクスプレスモード

`start express` コマンドで有効化されるフェーズ連続実行モード。Inception → Construction をコンテキストリセットなしで連続実行し、AIが自律的に最後まで走り切ります。depth_level に依存せず、Unit の複雑度判定（4項目: 受け入れ基準の明確さ、依存関係の複雑さ、技術的リスク、変更影響範囲）に基づいて適用可否を判定します。

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

`skills/aidlc/scripts/` にユーティリティスクリプトを配置。環境情報取得、Issue操作、履歴書き込み、markdownlint実行等をスクリプト化し、AIエージェントの許可リスト運用を改善しています。

### バックトラック機能

フェーズ間を柔軟に行き来可能：

- Inception ← Construction: Unit追加・拡張が必要な場合
- Construction ← Operations: バグ修正が必要な場合

### サンドボックス環境

AIエージェントを隔離環境で安全に実行するには [jailrun](https://github.com/ikeisuke/jailrun) を参照してください。

### コンテキスト効率

各フェーズで必要最小限のファイルのみ読み込み、コンテキスト溢れを防止。長いセッションで中断しても自動再開できます。

### 人間の承認プロセス

計画作成後・設計完了後に必ず承認を要求。承認なしで次のステップに進みません。

### 自動Gitコミット

セットアップ完了時、Inception Phase完了時、各Unit完了時、Operations Phase完了時に自動でGitコミットを作成します。

### カスタマイズ

- `.aidlc/rules.md` にプロジェクト固有のルール（コーディング規約、セキュリティ要件等）を記述可能
- `.aidlc/config.toml` で各種設定（バックログモード、レビューモード、squash等）を制御
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
