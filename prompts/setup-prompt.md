# AI-DLC セットアッププロンプト

このファイルを使用して、AI-DLC開発環境を初期化します。

---

## 変数定義

開始時にユーザーに変数の変更を確認し入力を促す

```
PROJECT_NAME = AI-DLC Starter Kit
CYCLE = v1  # 開発サイクル識別子（v1.0.0, 2024-12, feature-x など自由に命名可能）
BRANCH = feature/example
DEVELOPMENT_TYPE = greenfield  # greenfield / brownfield
PROJECT_TYPE = ios  # ios / android / web / backend / general
DOCS_ROOT = docs  # ドキュメントルート
LANGUAGE = 日本語
PROJECT_README = /README.md

DEVELOPER_EXPERTISE = ソフトウェア開発
ROLE_INCEPTION = プロダクトマネージャー兼ビジネスアナリスト
ROLE_CONSTRUCTION = ソフトウェアアーキテクト兼エンジニア
ROLE_OPERATIONS = DevOpsエンジニア兼SRE

# 派生変数
AIDLC_ROOT = ${DOCS_ROOT}/aidlc      # 共通プロンプト・テンプレートのルート
CYCLES_ROOT = ${DOCS_ROOT}/cycles    # サイクル固有成果物のルート
```

**PROJECT_TYPE の値**:
- `ios`: iOSアプリ開発
- `android`: Androidアプリ開発
- `web`: Webアプリケーション開発
- `backend`: バックエンドAPI開発
- `general`: 汎用

> **重要**: セットアップ完了後、`{{AIDLC_ROOT}}/prompts/additional-rules.md` をプロジェクトに合わせてカスタマイズしてください。

---

## ⚠️ 実行環境の確認

**まず最初に、現在のカレントディレクトリを確認してください**:

```bash
pwd
```

**このセットアップは、対象プロジェクトのルートディレクトリで実行する必要があります。**

もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合:
- ❌ **このままセットアップを実行しないでください**
- ✅ **対象プロジェクトのルートディレクトリに移動してから、このファイルのフルパスを指定して再度実行してください**

**確認が完了したら、以下をユーザーに表示してください**:

```
現在のディレクトリ: [pwd の結果]

このディレクトリで AI-DLC セットアップを実行してよろしいですか？
```

ユーザーが「はい」と明示的に承認するまで、セットアップ処理を開始しないでください。

---

## バージョン確認

セットアップ開始前に、スターターキットのバージョンを確認します。

### 確認手順

1. **ローカルバージョン確認**: `{{AIDLC_ROOT}}/version.txt` が存在するか確認
2. **最新バージョン確認**: GitHub リポジトリの `version.txt` と `CHANGELOG.md` を確認
   - リポジトリ: https://github.com/ikeisuke/ai-dlc-starter-kit

### ケース別対応

#### ケース A: 新規セットアップ
- **条件**: `{{AIDLC_ROOT}}/version.txt` が存在しない
- **対応**: 最新版を使用して通常のセットアップを実行

#### ケース B: 最新版を使用中
- **条件**: ローカル version.txt = GitHub 最新版
- **対応**: 「最新版です」と通知し、サイクル継続（プロンプト・テンプレート更新不要）
- **処理**: サイクルのディレクトリ構造作成のみ実行し、セットアップ完了

#### ケース C: アップデートあり
- **条件**: ローカル version.txt < GitHub 最新版
- **対応**:
  1. CHANGELOG の差分をユーザーに通知
  2. 変更内容の概要を説明
  3. アップデート方法を案内:
     - 方法1: `git pull`（Git管理している場合）
     - 方法2: 手動で変更ファイルをコピー
  4. 進行中サイクルへの影響を確認
  5. ユーザーに「アップデートする / スキップして続行」を選択させる
  6. アップデート実施後、または続行を選択後にセットアップ継続

#### ケース D: ローカルが新しい（開発版）
- **条件**: ローカル version.txt > GitHub 最新版
- **対応**: 「開発版を使用中です」と通知し、そのまま継続

---

## AI-DLC（AI-Driven Development Lifecycle）概要

AI-DLCは、AIを開発の中心に据えた新しい開発手法です。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **短サイクル反復**: 各フェーズを短いサイクルで反復
- **冪等性の保証**: 各ステップで既存成果物を確認し、差分のみ更新

**3つのフェーズ**:
1. **Inception**: Intentを具体的なUnitに分解し、ユーザーストーリーを作成
2. **Construction**: ドメイン設計・論理設計・コード・テストを生成
3. **Operations**: デプロイ・監視・運用を実施

---

## セットアップ手順

あなたは{{DEVELOPER_EXPERTISE}}に精通した開発者です。
{{BRANCH}} ブランチで {{PROJECT_NAME}} の {{CYCLE}} を開発します。

### 1. ディレクトリ構成の作成

**詳細は `prompts/setup/common.md` を参照**

以下の構造を作成：
```
{{AIDLC_ROOT}}/
├── prompts/
│   ├── inception.md
│   ├── construction.md
│   ├── operations.md
│   └── additional-rules.md
├── templates/
│   └── index.md
└── version.txt

{{CYCLES_ROOT}}/{{CYCLE}}/
├── plans/
├── requirements/
├── story-artifacts/units/
├── design-artifacts/domain-models/
├── design-artifacts/logical-designs/
├── design-artifacts/architecture/
├── inception/
├── construction/units/
├── operations/
└── history.md
```

1. `mkdir -p` で各ディレクトリを作成
2. 各ディレクトリに `.gitkeep` ファイルを配置

---

### 2. プロンプトファイルの作成

各フェーズプロンプトを `{{AIDLC_ROOT}}/prompts/` に作成:

#### inception.md
**詳細は `prompts/setup/inception.md` を参照**
- 役割: {{ROLE_INCEPTION}}
- フロー: Intent明確化 → 既存コード分析 → ユーザーストーリー → Unit定義 → PRFAQ → progress.md作成

#### construction.md
**詳細は `prompts/setup/construction.md` を参照**
- 役割: {{ROLE_CONSTRUCTION}}
- フロー: ドメインモデル設計 → 論理設計 → 設計レビュー → コード生成 → テスト → 統合

#### operations.md
**詳細は `prompts/setup/operations.md` を参照**
- 役割: {{ROLE_OPERATIONS}}
- フロー: デプロイ準備 → CI/CD構築 → 監視・ロギング → 配布 → リリース後運用

---

### 3. 共通ファイルの作成

**詳細は `prompts/setup/common.md` を参照**

- `{{CYCLES_ROOT}}/{{CYCLE}}/history.md`: プロンプト実行履歴
- `{{AIDLC_ROOT}}/prompts/additional-rules.md`: 追加ルール
- `{{AIDLC_ROOT}}/templates/index.md`: テンプレート一覧
- `{{AIDLC_ROOT}}/version.txt`: バージョン記録（1.0.0）

---

### 4. 初回の history.md 記録

セットアップ作業自体を history.md に記録：
- 実行日時（`date '+%Y-%m-%d %H:%M:%S %Z'`）
- フェーズ：準備
- 実行内容：AI-DLC環境セットアップ
- 作成したファイル一覧

---

### 5. 完了確認と次のステップ

1. 作成したファイルの一覧を表示
2. 各プロンプトファイルの概要を簡潔に説明
3. **Gitコミットを作成【必須】**: セットアップで作成したすべてのファイルをコミット
4. セットアップ完了メッセージを表示

---

## セットアップ完了メッセージ

```
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

共通ファイル（{{AIDLC_ROOT}}/）:
- prompts/inception.md - Inception Phase用プロンプト
- prompts/construction.md - Construction Phase用プロンプト
- prompts/operations.md - Operations Phase用プロンプト
- prompts/additional-rules.md - 共通の追加ルール
- templates/index.md - テンプレート一覧
- version.txt - スターターキットバージョン

サイクル固有ファイル（{{CYCLES_ROOT}}/{{CYCLE}}/）:
- history.md - 実行履歴
- 各種ディレクトリ

---

## ⚠️ 重要: カスタマイズが必要です

Inception Phase を開始する前に、**必ず `{{AIDLC_ROOT}}/prompts/additional-rules.md` をプロジェクトに合わせてカスタマイズしてください**。

---

## 次のステップ: Inception Phase の開始

カスタマイズ完了後、**新しいセッション**で以下を実行してください：

以下のファイルを読み込んで、Inception Phase を開始してください：
{{AIDLC_ROOT}}/prompts/inception.md

{{PROJECT_NAME}} {{CYCLE}} の開発を開始します。
```

---

## 重要な設計原則

- **フェーズごとに必要な情報のみ**: 各 .md は該当フェーズに必要な情報だけを含める
- **コンテキストリセット前提**: 該当フェーズの .md のみ読み込む設計
- **AI-DLC原則の反映**: 会話の反転、短サイクル、設計技法統合
- **言語統一**: すべてのドキュメント・コメントは {{LANGUAGE}} で記述
