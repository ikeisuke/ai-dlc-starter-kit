# AI-DLC Starter Kit

[![Version](https://img.shields.io/badge/version-1.5.3-blue.svg)](./version.txt)

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
│   ├── aidlc.toml             # プロジェクト設定（v1.2.2から位置変更）
│   ├── aidlc/                 # 全サイクル共通の共通ファイル（v1.0.0から）
│   │   ├── prompts/           # 共通プロンプト（inception.md, construction.md, operations.md等）
│   │   └── templates/         # 全テンプレートファイル（セットアップ時に事前作成）
│   │
│   ├── cycles/                # サイクル固有成果物（v1.0.0から）
│   │   ├── rules.md           # プロジェクト固有ルール（v1.2.2から位置変更）
│   │   ├── operations.md      # サイクル横断の運用引き継ぎ情報（v1.2.1から）
│   │   └── {{CYCLE}}/         # サイクル識別子で管理（例: v1.0.0, 2024-12, feature-x）
│   │       ├── inception/
│   │       │   └── progress.md       # Inception進捗管理（v1.0.0新機能）
│   │       ├── requirements/         # 要件定義成果物
│   │       ├── story-artifacts/      # ユーザーストーリー、Unit定義
│   │       ├── design-artifacts/     # ドメインモデル、論理設計
│   │       ├── construction/
│   │       │   ├── progress.md       # Construction進捗管理
│   │       │   └── units/            # Unit実装記録
│   │       ├── operations/
│   │       │   └── progress.md       # Operations進捗管理（v1.0.0新機能）
│   │       └── history.md            # 開発履歴
│   │
│   └── versions/              # このプロジェクト自体の開発記録（参考資料）
│       └── v1.0.0/            # v0.1.0を使ってv1.0.0を開発した記録
│
└── prompts/
    └── setup-prompt.md        # セットアッププロンプト（v1.0.0）
```

**注**: 現在のバージョンは **v1.0.0** です。`docs/versions/v1.0.0/` は v0.1.0 を使ってこのプロジェクト自体（v1.0.0）を開発した記録で、参考資料として残してあります。v1.0.0 を使ってセットアップすると `docs/aidlc/` に共通プロンプトが配置され、`docs/cycles/{{CYCLE}}/` にサイクル固有の成果物が作成されます。

## 🚀 クイックスタート (v1.0.0)

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

別プロジェクトのルートディレクトリで、このスターターキットの `prompts/setup-prompt.md` を Claude に読み込ませます：

```markdown
以下のファイルを読み込んで、AI-DLC 開発環境をセットアップしてください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md
```

セットアップ時に変数の確認があるので、プロジェクトに合わせて変更してください：
- `PROJECT_NAME`: プロジェクト名
- `CYCLE`: **サイクル識別子**（例: `v1.0.0`, `2024-12`, `feature-x` など自由に命名可能）
- `PROJECT_TYPE`: `ios` / `android` / `web` / `backend` / `general`
- `DEVELOPMENT_TYPE`: `greenfield`（新規） / `brownfield`（既存）
- `DOCS_ROOT`: ドキュメントルート（例: `docs`）
  - `docs/aidlc/` に共通プロンプト・テンプレート
  - `docs/cycles/` にサイクル固有成果物

セットアップが完了すると、以下のディレクトリ構造が作成されます：
```
docs/
├── aidlc.toml                # プロジェクト設定
├── aidlc/                    # 全サイクル共通（初回セットアップ時のみ作成）
│   ├── prompts/              # 各フェーズのプロンプトファイル
│   │   ├── inception.md      # Inception Phase用
│   │   ├── construction.md   # Construction Phase用
│   │   └── operations.md     # Operations Phase用
│   └── templates/            # ドキュメントテンプレート（セットアップ時に事前作成）
│
└── cycles/
    ├── rules.md              # プロジェクト固有ルール
    ├── operations.md         # サイクル横断の運用引き継ぎ情報
    └── {{CYCLE}}/            # サイクル固有成果物
        ├── inception/
        │   └── progress.md   # Inception進捗管理
        ├── requirements/     # 要件定義
        ├── story-artifacts/  # ユーザーストーリー、Unit定義
        ├── design-artifacts/ # ドメインモデル、論理設計
        ├── construction/
        │   ├── progress.md   # Construction進捗管理
        │   └── units/        # Unit実装記録
        ├── operations/
        │   └── progress.md   # Operations進捗管理
        └── history.md        # 開発履歴
```

**重要**:
- セットアップ完了後、`docs/cycles/rules.md` をプロジェクトに合わせてカスタマイズしてください（コーディング規約、セキュリティ要件等）
- **このスターターキットはサイクル単位で環境を構築します**。新サイクル開発時は新しい`CYCLE`でsetup-prompt.mdを再実行します

### 3. 開発を開始

**各フェーズは新しいセッションで開始**してください（コンテキストリセット）：

#### Inception Phase（要件定義）
```markdown
以下のファイルを読み込んで、Inception Phase を開始してください：
docs/aidlc/prompts/inception.md
```

AIが以下を実施します：
- **進捗管理ファイル（inception/progress.md）を確認**: 6ステップの進捗を管理、コンテキストリセット時は未完了ステップから再開
- **対話形式でIntentを作成**: 不明点は `[Question]`/`[Answer]` タグで記録し、質問してきます
- ユーザーストーリー作成
- Unit定義（依存関係、優先度、見積もりを含む）
- PRFAQ作成
- **Construction用進捗管理ファイル（construction/progress.md）作成**: 全Unit情報を1つのファイルで管理

**完了後**: 自動的にGitコミットが作成されます

#### Construction Phase（実装）
```markdown
以下のファイルを読み込んで、Construction Phase を開始してください：
docs/aidlc/prompts/construction.md
```

AIが以下を実施します：
- **進捗管理ファイル（construction/progress.md）を読み込み**: 1つのファイルで全Unit状態を把握
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

**バックトラック**: Unit追加が必要になった場合は、Inception Phaseに戻ってUnit定義を追加できます

#### Operations Phase（デプロイ・運用）
```markdown
以下のファイルを読み込んで、Operations Phase を開始してください：
docs/aidlc/prompts/operations.md
```

AIが以下を実施します：
- **進捗管理ファイル（operations/progress.md）を確認**: 5ステップの進捗を管理、コンテキストリセット時は未完了ステップから再開
- Construction完了確認（コンテキスト溢れ防止のため、最小限のファイルのみ読み込み）
- **対話形式でデプロイ準備、CI/CD構築、監視設定**: 不明点を質問してきます
- リリース後の運用

**完了後**: 自動的にGitコミットが作成されます

**バックトラック**: バグ修正が必要になった場合は、Construction Phaseに戻って修正できます

### 4. 次サイクルの開発（ライフサイクルの継続）

Operations Phase完了後、フィードバックを収集して次サイクルの開発を開始します：

```markdown
以下のファイルを読み込んで、{PROJECT_NAME} の次サイクル の AI-DLC 環境をセットアップしてください：
/path/to/ai-dlc-starter-kit/prompts/setup-prompt.md

変数を以下に設定してください：
- CYCLE = v2.0.0（または 2024-12、feature-y など）
- DOCS_ROOT = docs（前サイクルと同じ）
- その他の変数も適宜設定
```

**必要に応じて前サイクルのファイルを引き継ぐ**:
- `docs/cycles/rules.md` は全サイクル共通なので引き継がれます
- `docs/cycles/operations.md` も全サイクル共通（運用設定の引き継ぎ）
- `docs/cycles/v1.0.0/requirements/intent.md` → 参照して改善点を反映
- その他、引き継ぎたいファイルがあればコピー

セットアップ完了後、新しいセッションで Inception Phase を開始し、**Inception → Construction → Operations → (次サイクル)** のライフサイクルを継続します。

## ✨ 主要な機能

### 1. 対話形式による開発
- AIが独自判断をせず、不明点は `[Question]`/`[Answer]` タグで質問
- ユーザーとの対話を通じて要件や設計を明確化

### 2. 進捗管理の一元化（v1.0.0新機能）
- **全フェーズでprogress.mdを自動管理**
  - Inception Phase: 6ステップの進捗（`inception/progress.md`）
  - Construction Phase: Unit一覧、状態、依存関係、優先度、見積もりを1つのファイルで管理（`construction/progress.md`）
  - Operations Phase: 5ステップの進捗（`operations/progress.md`）
- **コンテキストオーバーフロー対策**: 長いセッションで中断しても、progress.mdを読み込むだけで未完了ステップから自動再開
- Construction Phase実行時に1ファイル読むだけで全体状況を把握（コンテキスト削減）
- 各Unit完了後に自動更新（次回実行可能なUnit候補を再計算）

### 3. Unit依存関係の自動管理
- Inception PhaseでUnit間の依存関係を定義
- Construction PhaseでAIが依存関係を解析し、実行可能なUnitを自動判断
- 複数のUnitが実行可能な場合は優先度と見積もりを提示し、推奨を提案

### 4. 設計と実装の明確な分離
- **Phase 1（設計）**: コードは書かず、構造・責務・インターフェースのみを定義
- **Phase 2（実装）**: 設計ファイルを参照してコードを生成
- 設計時点でのコード大量生成を防止し、レビューしやすい設計書を作成

### 5. テンプレートの事前作成（v1.0.0で変更）
- セットアップ時に全テンプレートを `docs/aidlc/templates/` に作成
- 各フェーズで必要なテンプレートを即座に利用可能
- **v0.1.0からの変更**: JIT生成から事前作成に変更し、セットアップを一度で完結

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

### 10. バックトラック機能（v1.0.0新機能）
- **フェーズ間を柔軟に行き来できる仕組み**
  - Inception ← Construction: Unit追加・拡張が必要な場合
  - Construction ← Operations: バグ修正が必要な場合
- 各フェーズプロンプトに「このフェーズに戻る場合」セクションを追加
- progress.mdを活用して、既存成果物を保持しながら追加作業が可能
- 短サイクル開発と要件変更への柔軟な対応をサポート

### 11. 履歴管理の簡素化
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
10. **カスタマイズ可能** - プロジェクト固有のルールを rules.md に記述可能

## 🔄 v0.1.0 から v1.0.0 への移行

### 破壊的変更（BREAKING CHANGES）

v1.0.0 では以下の破壊的変更があります：

#### 1. 変数名の変更
- `VERSION` → `CYCLE`（開発サイクル識別子）
- `VERSIONS_ROOT` → `CYCLES_ROOT`
- **理由**: 「バージョン」概念はモバイルアプリには適応的だが、Web/バックエンド開発には馴染まないため、より汎用的な「サイクル」に変更

#### 2. ディレクトリ構造の変更
```
# v0.1.0
docs/example/v1/
├── prompts/
├── templates/
└── ...

# v1.0.0
docs/
├── aidlc/              # 全サイクル共通（新規）
│   ├── prompts/
│   └── templates/
└── cycles/v1.0.0/      # サイクル固有
    ├── inception/
    ├── requirements/
    └── ...
```

### v1.0.0 の新機能

1. **全フェーズでのprogress.md対応**
   - Inception/Operations Phaseでも進捗管理
   - コンテキストオーバーフロー時の自動再開

2. **バックトラック機能**
   - Inception ← Construction（Unit追加）
   - Construction ← Operations（バグ修正）
   - フェーズ間を柔軟に行き来できる

3. **テンプレートの事前作成**
   - v0.1.0: JIT（Just-In-Time）生成
   - v1.0.0: セットアップ時に全テンプレート作成

4. **共通プロンプトの分離**
   - `docs/aidlc/` に全サイクル共通ファイルを配置
   - メンテナンス性とスケーラビリティの向上

### 既存プロジェクトの移行

v0.1.0 を使用中のプロジェクトは、以下の手順で v1.0.0 に移行できます：

1. **変数の読み替え**: `VERSION` → `CYCLE` として継続使用可能
2. **新規サイクル作成時**: 新しい `CYCLE` で v1.0.0 の setup-prompt.md を実行
3. **既存成果物**: v0.1.0 で作成したファイルは参考資料として保持可能

### 開発履歴

`docs/versions/v1.0.0/` には、v0.1.0 を使ってこのプロジェクト自体（v1.0.0）を開発した記録が残されています。AI-DLC の実践例として参考にしてください。

## 🆕 v1.2.0 の新機能

### 1. プロンプトの分割・短縮化
- AIがプロンプトを最後まで読まない問題への対策
- 各フェーズプロンプトを簡潔化し、必要な情報のみを記載
- セットアッププロンプトを複数ファイルに分割

### 2. セットアップ処理の分離
- **初回セットアップ** (`setup-init.md`): 新規プロジェクトへの導入・アップグレード
- **サイクルセットアップ** (`setup-cycle.md`): 既存プロジェクトでの新サイクル開始
- `setup-prompt.md` がエントリーポイントとして状態を判定し、適切なセットアップに誘導

### 3. ライト版プロンプト
- `docs/aidlc/prompts/lite/` にライト版（簡易版）プロンプトを追加
- 小規模な変更や迅速な開発に最適
- Full版を参照しつつ、スキップ・簡略化するステップを定義

### 4. バックログ機能
- **Inception Phase**: `docs/cycles/backlog.md` を確認し、前サイクルからの引き継ぎタスクを表示
- **Operations Phase**: 次サイクルへの引き継ぎタスクをバックログに記録

### 5. サイクル存在確認
- 各フェーズプロンプト開始時にサイクルディレクトリの存在を確認
- 存在しない場合はエラーを表示し、既存サイクル一覧を提示

### 6. rules.md の上書き防止
- アップグレード時にプロジェクト固有のルールファイルを保護
- 既に存在する場合はコピーをスキップ

### 7. GitHub Actions による自動タグ付け
- main ブランチへのマージ時に `version.txt` を読み取り自動でタグを作成
- `.github/workflows/auto-tag.yml` で設定

### 8. バージョン・ブランチ整合性チェック
- セットアップ時にサイクルバージョンとブランチ名の整合性をチェック
- 不一致の場合は警告を表示し、対応を選択可能

## 🔧 v1.2.1 の改善点

v1.2.1 は技術的負債解消のメンテナンスリリースです。

### 1. セットアップ体験の向上
- プロジェクト情報の確認を一問一答形式からまとめて確認する形式に変更
- デフォルト値を一覧表示し、変更があるものだけ指定可能

### 2. バックログ管理の自動化
- Operations Phase完了時に対応済み項目を自動的に `backlog-completed.md` に移動
- サイクル固有バックログ（`docs/cycles/{{CYCLE}}/backlog.md`）の導入

### 3. フェーズ間の責務明確化
- Construction Phase開始時に自身でprogress.mdを作成するよう変更
- Inception Phaseの責務を要件定義に集中

### 4. 運用引き継ぎの強化
- サイクル横断の運用引き継ぎファイル（`docs/cycles/operations.md`）を追加
- CI/CD設定、監視設定、デプロイ手順などをサイクル間で引き継ぎ可能

## 🔧 v1.2.2 の改善点

v1.2.2 はファイル構成の整理とプロンプト改善のメンテナンスリリースです。

### 1. ファイル構成の変更（破壊的変更）
- `docs/aidlc/project.toml` → `docs/aidlc.toml` に移動
- `docs/aidlc/prompts/additional-rules.md` → `docs/cycles/rules.md` に移動
- `docs/aidlc/version.txt` 廃止（`aidlc.toml` に統合）
- **効果**: `docs/aidlc/` がスターターキットと rsync で完全同期可能に

### 2. Operations Phase の改善
- 開始時に運用引き継ぎ情報（`docs/cycles/operations.md`）を自動確認
- 前回サイクルの設定を再利用可能、毎回同じ質問を繰り返さない

### 3. Lite版プロンプトの改善
- パスがプロジェクトルートからの絶対パスであることを明示
- 簡易実装先確認ステップを追加

### 4. コンテキストリセットルールの強化
- 継続プロンプトを「推奨」から「必須」に変更
- progress.md のパスを明確化（サブディレクトリ内であることを強調）

### 5. 既存プロジェクトの移行
v1.2.1 以前を使用中のプロジェクトは、setup-init.md を実行すると自動で移行されます。

## 🔧 v1.2.3 の改善点

v1.2.3 は運用中に発見された問題点を修正するパッチリリースです。

### 1. Lite版パス解決安定化
- Lite版プロンプトでファイルパスをより明示的に指定
- 相対パスの基準ディレクトリを明確化

### 2. フェーズ遷移ガードレール強化
- 各プロンプトに「このフェーズでは実装しない」等のガードレール追加
- フェーズごとの許可アクションを明確化

### 3. starter_kit_versionフィールド追加
- aidlc.toml テンプレートに `starter_kit_version` フィールドを追加
- setup-init.md でフィールドを自動生成

### 4. 移行時ファイル削除確認追加
- アップグレード時にrsyncで削除されるファイル一覧をユーザーに表示
- 削除前に必ずユーザー確認を要求

### 5. 日時記録必須ルール化
- プロンプトに「日時を記録する際は必ず `date` コマンドで現在時刻を取得すること」を明記
- セッション開始時の日時使い回しを防止

### 6. Inception Phaseステップ6削除
- v1.2.1で対応済みのConstruction用進捗管理ファイル作成ステップを削除
- Construction Phaseが自身で作成する責務に集中

## 🔧 v1.4.0 の新機能

v1.4.0 は開発体験向上とチーム開発サポートのためのリリースです。

### 1. サイクルバージョン提案改善
- 既存サイクルから次バージョンを自動推測
- バージョン番号の入力ミスを防止

### 2. GitHub Issue確認とセットアップ統合
- Inception Phase開始時にGitHub Issueを確認
- main/masterブランチでの作業時にサイクル用ブランチ作成を提案

### 3. npm-scripts自動実行の提案
- package.json検出時に利用可能なスクリプトを表示
- ビルド・テスト実行の効率化

### 4. 割り込み対応ルール追加
- 作業中の割り込み要望を適切に分類
- 計画を崩さずに追加要望を管理

### 5. AI MCPレビュー推奨機能
- MCPサーバーが利用可能な場合にレビュー活用を提案
- 成果物の品質向上をサポート

### 6. git worktree提案機能
- セットアップ時にgit worktreeの使用を提案
- 複数サイクルの並行作業を支援

### 7. 複数人開発時コンフリクト対策
- history.mdとbacklog.mdのコンフリクト防止策を追加
- チーム開発でのスムーズな運用をサポート

## 🔧 v1.5.3 の改善点

v1.5.3 はシェル互換性・後方互換性の強化と開発体験向上のためのリリースです。

### 1. シェル互換性の改善
- zsh/bash両方での動作を保証
- `grep -oP` を使用しない互換性のある実装に変更
- macOS標準環境での動作安定化

### 2. 後方互換性の強化
- v1.5.0以前のプロジェクトからのアップグレード時に `setup.md` が見つからない問題を修正
- スターターキット側のファイルを参照するように変更

### 3. サイクル名自動検出機能
- ブランチ名から自動でサイクル名を検出
- 入力の手間を削減

### 4. アップグレードフローの改善
- アップグレード後に自動でサイクル開始フローに入らないよう修正
- ユーザーが明示的に操作するまで待機

### 5. worktree機能の改善
- worktree使用時のディレクトリ構造を改善
- 並行作業時の体験向上

### 6. AIレビュー機能の強化
- 人間の承認前にAIレビューを優先実行
- AIが検出できる問題を事前にフィルタリング

### 7. CI/CD構築
- GitHub Actions による Markdown リンター追加
- PR時に自動でリントチェックを実行

### 8. 監視・分析ガイドの作成
- GitHub Insights活用ガイドを追加
- プロジェクトの利用状況把握方法を文書化

## 🔧 v1.5.2 の新機能

v1.5.2 は並行作業対応とセットアップ改善のためのリリースです。

### 1. ドラフトPRベースの並行作業ワークフロー
- Inception Phase 完了時に main へのドラフト PR を作成
- 各 Unit は サイクルブランチに対して PR を作成・マージ
- Operations Phase 完了時にドラフト PR を Ready 化
- 複数人・複数セッションでの並行開発を支援

### 2. バックログ移行の自動化
- 旧形式 `backlog.md` を新形式（個別ファイル方式）に自動移行
- 完了済みバックログとの重複チェック機能
- セットアップ時に移行を実行

### 3. セットアップ柔軟性向上
- アップグレードしない場合でも新サイクルを開始可能
- `setup-prompt.md` でアップグレード不要時の案内を追加

## 🔧 v1.5.1 の改善点

v1.5.1 はセットアップ体験とプロンプト構成を改善するメンテナンスリリースです。

### 1. プロジェクトタイプ設定機能
- 初回セットアップ時にプロジェクトタイプを明示的に設定
- Operations Phase でプロジェクトタイプに応じた自動判断（配布ステップのスキップ等）

### 2. 履歴記録設定機能
- `aidlc.toml` に `[rules.history]` セクションを追加
- 履歴記録レベルを選択可能: `detailed`（詳細）/ `standard`（標準）/ `minimal`（最小）

### 3. コミットメッセージ改善
- Unit 完了時のコミットメッセージにサイクル名を含める形式に変更
- 例: `feat: [v1.5.1] Unit 001完了 - 機能追加`

### 4. セットアップエントリーポイント変更
- 通常のサイクル開始は `docs/aidlc/prompts/setup.md` を使用
- アップデート時のみ `prompts/setup-prompt.md` を使用
- 毎回アップデート確認を行わず効率的に

### 5. セットアッププロンプト統合
- `setup-cycle.md` を `setup.md` に統合
- 責務分離と導線の明確化

## 🔧 v1.5.0 の新機能

v1.5.0 は AI の振る舞い改善とセットアップ体験向上のためのリリースです。

### 1. 予想禁止・一問一答質問ルール
- AIが独自に予想して方針を決定することを禁止
- 不明点は必ずユーザーに質問し、一問一答形式で対話

### 2. コード記述制限ルール
- Construction Phase の実装時以外でのコード記述を原則禁止
- 計画なしに実装が進むリスクを防止

### 3. 外部入力検証ルール
- AI MCP 呼び出しやユーザー入力を受け取る際、そのまま信頼せず AI の判断を明示的に提示
- 外部入力に対して批判的に評価するルールを追加

### 4. サイクルセットアップ処理の分離
- サイクルディレクトリ作成処理を専用プロンプト（setup-cycle.md）に移動
- inception.md からはサイクル存在確認のみ行い、存在しない場合は専用プロンプトを案内

### 5. グリーンフィールドセットアップ改善
- グリーンフィールド（新規プロジェクト）セットアップの体験向上
- セットアップ手順の簡略化

### 6. セルフアップデート機能廃止
- Operations Phase での setup-init 実行を廃止
- アップデートは通常のセットアップフローを使用するように変更

## 🔧 v1.4.1 の改善点

v1.4.1 はプロンプト・テンプレートの改善を行うメンテナンスリリースです。

### 1. コミットハッシュ記録の廃止
- Unit定義テンプレートからコミットハッシュフィールドを削除
- git log で履歴参照する運用に変更

### 2. Unit定義ファイルの番号付け
- Unit定義ファイル名に実行順序番号を付与（例: `001-setup-database.md`）
- 依存関係の実行順序を明示化

### 3. workaround時のバックログ追加ルール
- その場しのぎの対応をする際に本質的な対応をバックログに記録するルールを追加
- コード内にTODOコメント（バックログファイル名を参照）を追加するルール

### 4. README.mdリンク辿りルール
- セットアップ時にREADME.mdのリンク先ドキュメントも読み込むルールを追加
- プロジェクト内部のドキュメントリンクのみ対象（外部リンクは辿らない）

### 5. CLIプロジェクトタイプ追加
- Operations Phaseのプロジェクトタイプに `cli` を追加
- CLIツールは配布ステップを実施（デスクトップアプリと同様の扱い）

## 🔧 v1.3.2 の改善点

v1.3.2 はドキュメント改善とアップグレード体験向上のためのパッチリリースです。

### 1. バージョン同期の修正
- Operations Phase の setup-init 実行時に `aidlc.toml` の `starter_kit_version` が適切に更新されるよう修正

### 2. コミットハッシュ記録の注意事項追加
- Unit完了時のコミットハッシュ記録後に --amend や rebase すると記録が無効になる問題への注意書きを追加

### 3. PRマージ後のブランチ削除ルール追加
- `operations.md` の「PRマージ後の手順」でブランチ削除を標準手順として明記

### 4. 「最終更新」セクションの廃止
- 全ファイルから「最終更新」セクションを削除
- Git履歴で代替可能であり、手動メンテナンスコストを削減

### 5. アップグレード時の変更要約表示
- setup-init.md に更新されるファイルの要約表示機能を追加
- rsync 実行後に更新されたプロンプト・テンプレートを一覧表示

## 🔧 v1.3.1 の改善点

v1.3.1 は Inception Phase 効率化のためのパッチリリースです。

### 1. バックログ対応済みチェック機能
- Inception Phase でバックログ確認時に、過去サイクルで対応済みかどうかを自動チェック
- history.md や backlog-completed.md を参照して重複作業を防止

### 2. セットアップスキップ機能
- AI-DLC ツールキットのアップグレードが不要な場合、セットアップを経由せず直接 Inception Phase を開始可能
- Inception Phase でサイクルディレクトリを自動作成
- 最新バージョンチェックを行い、必要に応じてセットアップを案内

### 3. Dependabot PR 確認機能
- Inception Phase 開始時に Dependabot PR の有無を確認
- セキュリティ更新を適切なタイミングで検討可能

## 🔧 v1.3.0 の改善点

v1.3.0 は運用効率化・安定性向上のためのリリースです。

### 1. 進捗管理再設計
- progress.mdを廃止し、Unit定義ファイルに実装状態を追加
- 複数人開発時のコンフリクト問題を解消
- Git状態や既存ファイルから進捗を自動検出する方式に変更

### 2. バージョン管理改善
- Operations Phaseでのstarter_kit_version更新手順を改善
- 初回セットアップ時にプロジェクトの既存バージョン（package.json等）を調査するステップを追加

### 3. ワークフロー改善
- PRマージ後のmainブランチ移動・pull手順をoperations.mdに追加
- サイクル完了後のブランチ整理手順を明確化

### 4. バックログ構造改善
- 「最終更新」セクションを廃止し、追記しやすい構造に変更
- heredocで追記しても構造が崩れない形式を採用

## 🔗 関連リンク

- [オリジナルのホワイトペーパー](https://prod.d13rzhkk8cj2z0.amplifyapp.com) - AWS による AI-DLC 公式ドキュメント

## 📄 ライセンス

このリポジトリのオリジナルコンテンツ（プロンプトテンプレート等）は MIT License で提供されています。

AI-DLC 翻訳文書については、オリジナルのホワイトペーパーは AWS (Amazon Web Services) により公開されており、著者は Raju SP です。オリジナルドキュメントには明示的なライセンス情報が記載されていないため、このリポジトリの翻訳文書は学習・参考目的での利用を想定しています。商用利用や再配布については、AWS または著者に直接確認することを推奨します。

## 🤝 コントリビューション

問題や改善提案がありましたら、Issue や Pull Request をお気軽にお送りください。

## 📮 フィードバック

このスターターキットについてのフィードバックや質問は、GitHub Issues でお願いします。
