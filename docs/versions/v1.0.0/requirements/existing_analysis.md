# 既存コード分析（Brownfield開発）

## 分析日時
2025-11-24

## 分析対象
AI-DLC Starter Kit v0.1.0

## 現在の技術スタック

### ドキュメント基盤
- **フォーマット**: Markdown
- **文字エンコーディング**: UTF-8
- **言語**: 日本語

### スクリプト
- **シェル**: Bash
- **用途**: 履歴管理（heredoc による追記）

### バージョン管理
- **VCS**: Git
- **現在のバージョン**: 0.1.0
- **ブランチ**: feature/example

## 現在のアーキテクチャ

### ディレクトリ構造（v0.1.0）

```
ai-dlc-starter-kit/
├── docs/
│   ├── translations/          # AI-DLCホワイトペーパーの日本語翻訳
│   ├── example/               # セットアップ例
│   │   └── v1/               # バージョン単位
│   │       ├── prompts/      # バージョンごとに生成（問題点）
│   │       ├── templates/    # バージョンごとに生成（問題点）
│   │       ├── requirements/
│   │       ├── story-artifacts/
│   │       ├── design-artifacts/
│   │       ├── construction/
│   │       └── operations/
│   └── versions/             # 新規（v1.0.0以降用）
│       └── v1.0.0/
│           ├── prompts/
│           ├── templates/
│           └── ...
│
├── prompts/
│   └── setup-prompt.md       # セットアッププロンプト
│
├── README.md
└── VERSION                    # バージョン番号
```

### 問題点（v0.1.0）

1. **プロンプトファイルがバージョンごとに生成される**
   - `docs/example/v1/prompts/` にバージョン固有のプロンプトが配置
   - スターターキット改善時、すべてのバージョンのプロンプトを手動更新する必要がある
   - メンテナンス負荷が高い

2. **テンプレートファイルがバージョンごとに生成される**
   - `docs/example/v1/templates/` にバージョン固有のテンプレートが配置
   - 同様にメンテナンス負荷が高い

## setup-prompt.md の分析

### 主要機能

1. **MODE変数による動作切り替え**
   - `setup`: 初回セットアップ（ディレクトリ作成、プロンプトファイル生成、テンプレート生成）
   - `template`: 特定のテンプレートのみを生成
   - `list`: テンプレート一覧の表示

2. **変数定義**
   - `PROJECT_NAME`: プロジェクト名
   - `VERSION`: バージョン番号（例: v1）
   - `BRANCH`: ブランチ名
   - `DEVELOPMENT_TYPE`: greenfield / brownfield
   - `PROJECT_TYPE`: ios / android / web / backend / general
   - `DOCS_ROOT`: ドキュメントルート（例: docs/example）
   - `LANGUAGE`: 日本語
   - `PROJECT_README`: README.mdのパス
   - `DEVELOPER_EXPERTISE`: 開発者の専門性
   - `ROLE_INCEPTION`: Inception Phase の役割
   - `ROLE_CONSTRUCTION`: Construction Phase の役割
   - `ROLE_OPERATIONS`: Operations Phase の役割

3. **プロンプトファイル生成**
   - `common.md`: 全フェーズ共通知識
   - `inception.md`: Inception Phase 専用
   - `construction.md`: Construction Phase 専用
   - `operations.md`: Operations Phase 専用
   - `history.md`: プロンプト実行履歴
   - `additional-rules.md`: 追加ルール

4. **テンプレートファイル生成**
   - JIT（Just-In-Time）生成方式
   - 初回セットアップ時は `templates/index.md` のみ生成
   - 各フェーズ実行時に必要なテンプレートを自動生成

5. **テンプレート一覧**
   - **Inception Phase**: intent_template, user_stories_template, unit_definition_template, prfaq_template
   - **Construction Phase**: domain_model_template, logical_design_template, implementation_record_template
   - **Operations Phase**: deployment_checklist_template, monitoring_strategy_template, distribution_feedback_template, post_release_operations_template

### v1.0.0での変更が必要な箇所

1. **ディレクトリ構造の変更**
   - プロンプトファイルの生成先: `{{DOCS_ROOT}}/{{VERSION}}/prompts/` → `docs/aidlc/prompts/`
   - テンプレートファイルの生成先: `{{DOCS_ROOT}}/{{VERSION}}/templates/` → `docs/aidlc/templates/`
   - バージョン固有の成果物: `{{DOCS_ROOT}}/{{VERSION}}/` を維持（requirements/, story-artifacts/, 等）

2. **新しい変数の追加**
   - `AIDLC_ROOT`: 共通プロンプト・テンプレートのルート（例: docs/aidlc）
   - `VERSIONS_ROOT`: バージョンごとの成果物のルート（例: docs/versions）

3. **プロンプトファイルの内容変更**
   - 各フェーズプロンプト（inception.md, construction.md, operations.md）の先頭に common.md の内容を含める
   - ユーザーは各フェーズで1ファイルだけ読めばOKにする

4. **バージョン管理ファイルの追加**
   - `docs/aidlc/version.txt`: セットアップ時に使用したスターターキットのバージョンを記録

## README.md の分析

### 現在の内容

- AI-DLC の概要説明
- クイックスタートガイド（セットアップ → 各フェーズ実行 → 次バージョン開始）
- 主要な機能の説明（対話形式、進捗管理、Unit依存関係、設計と実装の分離、JIT生成等）
- 翻訳文書へのリンク

### v1.0.0での変更が必要な箇所

1. **リポジトリ構成の更新**
   - 新しいディレクトリ構造（`docs/aidlc/` と `docs/versions/`）を反映

2. **クイックスタートの更新**
   - セットアップ手順で新しい変数（AIDLC_ROOT, VERSIONS_ROOT）を説明
   - 各フェーズの読み込み方法を更新（common.md + フェーズプロンプト → 1つのフェーズプロンプトのみ）

3. **docs/example の扱いの説明**
   - v1.0.0で削除されることを明記
   - 新構造への移行を説明

## docs/example/ の分析

### 現在の構造

- `docs/example/v1/`: v0.1.0のセットアップ例
- バージョン固有のプロンプトとテンプレートが含まれている

### v1.0.0での扱い

- **削除**: `docs/example/` ディレクトリを削除
- **理由**: 新構造（`docs/aidlc/` + `docs/versions/`）に移行するため、旧構造の例は不要

## 既存機能の保持確認

以下の既存機能はv1.0.0でも維持する必要がある：

### 1. 対話形式による開発
- ✅ 維持: AIが独自判断をせず、`[Question]`/`[Answer]` タグで質問
- ✅ 維持: 一問一答形式での対話

### 2. 進捗管理の一元化
- ✅ 維持: `construction/progress.md` による進捗管理
- ✅ 維持: Unit一覧、状態、依存関係、優先度、見積もりの記録

### 3. Unit依存関係の自動管理
- ✅ 維持: 依存関係の自動解析と実行可能Unitの判断

### 4. 設計と実装の明確な分離
- ✅ 維持: Phase 1（設計）とPhase 2（実装）の分離

### 5. JIT（Just-In-Time）テンプレート生成
- ✅ 維持: 各フェーズ実行時に必要なテンプレートを自動生成
- ⚠️ 変更: 生成先を `docs/aidlc/templates/` に変更

### 6. コンテキスト溢れ防止
- ✅ 維持: 必要最小限のファイルのみ読み込み
- ✅ 維持: `ls` / `grep` コマンドでの効率的な情報取得

### 7. 人間の承認プロセス
- ✅ 維持: 計画作成後の承認、設計完了後の承認

### 8. 自動Gitコミット
- ✅ 維持: セットアップ完了時、各Phase完了時、各Unit完了時

### 9. プラットフォーム対応
- ✅ 維持: `PROJECT_TYPE` 変数によるプラットフォーム固有の注意事項表示

### 10. 履歴管理の簡素化
- ✅ 維持: Bash heredoc による履歴の追記
- ⚠️ 変更: 履歴ファイルの配置先を `docs/versions/{VERSION}/history.md` に変更

## 制約事項

### 技術的制約
- Markdown、Bash、Gitを継続使用
- UTF-8エンコーディング
- 日本語で記述

### 互換性
- 既存のv0.1.0ドキュメントを削除・変更しない
- docs/example/ のみ削除（新構造への移行のため）

## 移行計画の考慮事項

### 優先度

1. **High**: setup-prompt.md の変更（新しいディレクトリ構造への対応）
2. **High**: 各フェーズプロンプトの変更（common.md の内容を含める、パス参照の更新）
3. **High**: README.md の更新（新構造の説明）
4. **Medium**: docs/example/ の削除
5. **Medium**: VERSION ファイルの更新、Gitタグの作成

### 依存関係

- setup-prompt.md → 各フェーズプロンプト → README.md の順で変更
- docs/example/ の削除は、新構造のドキュメントが完成してから実施

## 分析結果まとめ

### 現状の強み
- 対話形式、進捗管理、JIT生成など、優れた機能が既に実装されている
- コンテキスト溢れ防止の仕組みが効果的

### 現状の課題
- プロンプトとテンプレートがバージョンごとに生成され、メンテナンス負荷が高い

### v1.0.0での改善
- プロンプトとテンプレートを共通化し、メンテナンス負荷を削減
- バージョン固有の成果物のみを分離し、明確な責務分離を実現
- セットアップ時のバージョン記録により、アップデート管理を可能にする
