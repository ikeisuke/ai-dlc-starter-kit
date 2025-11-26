# 論理設計: Unit1 - setup-prompt.mdのリファクタリング

## 概要
setup-prompt.mdを新しいディレクトリ構造に対応させ、共通プロンプト・テンプレートとバージョン固有成果物を適切に分離する具体的な設計を行います。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（Bashスクリプト、heredoc、実装コード等）はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

**パイプライン & フィルタパターン**を採用：

1. 変数入力 → 2. 検証 → 3. ディレクトリ作成 → 4. ファイル生成 → 5. 履歴記録

各ステップは独立して処理を行い、エラー時は即座に停止します。

## コンポーネント構成

### レイヤー / モジュール構成

```
setup-prompt.md
├── 変数定義セクション
│   ├── MODEチェック（setup/template/list）
│   ├── 基本変数（DOCS_ROOT, VERSION, PROJECT_NAME, etc.）
│   └── 派生変数（AIDLC_ROOT, VERSIONS_ROOT）
│
├── 実行環境検証セクション
│   ├── カレントディレクトリ確認
│   └── ユーザー承認待機
│
├── MODE振り分けセクション
│   ├── MODE=list → index.md表示
│   ├── MODE=template → 個別テンプレート生成
│   └── MODE=setup → 完全セットアップ
│
└── セットアップ処理セクション（MODE=setup時）
    ├── ディレクトリ作成
    ├── プロンプトファイル生成
    ├── テンプレートファイル生成
    ├── 履歴記録
    └── 完了メッセージ表示
```

### コンポーネント詳細

#### 1. 変数定義コンポーネント
- **責務**: セットアップに必要な全変数を定義
- **依存**: なし
- **公開インターフェース**:
  - 既存変数: `MODE`, `TEMPLATE_NAME`, `PROJECT_NAME`, `VERSION`, `DOCS_ROOT`, `LANGUAGE`, 等
  - **新規変数**: `AIDLC_ROOT`, `VERSIONS_ROOT`

#### 2. 変数検証コンポーネント
- **責務**: 必須変数の存在確認、MODEに応じた変数チェック
- **依存**: 変数定義コンポーネント
- **公開インターフェース**:
  - validateMode(): MODEの値が有効か確認
  - validateRequiredVariables(): 必須変数が設定されているか確認
  - validateTemplateMode(): MODE=templateの場合、TEMPLATE_NAMEが指定されているか確認

#### 3. 環境検証コンポーネント
- **責務**: 実行環境の確認とユーザー承認
- **依存**: なし
- **公開インターフェース**:
  - checkCurrentDirectory(): `pwd`でカレントディレクトリを確認
  - requestUserApproval(): ユーザーに確認メッセージを表示し、承認を待つ

#### 4. ディレクトリ初期化コンポーネント
- **責務**: 新しいディレクトリ構造を作成
- **依存**: 変数定義コンポーネント
- **公開インターフェース**:
  - createCommonDirectories(): `${AIDLC_ROOT}/prompts/`, `${AIDLC_ROOT}/templates/` を作成
  - createVersionDirectories(): `${VERSIONS_ROOT}/${VERSION}/` 配下のディレクトリを作成
  - placeGitkeepFiles(): 各ディレクトリに `.gitkeep` を配置

#### 5. プロンプト生成コンポーネント
- **責務**: プロンプトファイルを生成（common.mdの内容を各フェーズに直接埋め込み）
- **依存**: 変数定義コンポーネント、ディレクトリ初期化コンポーネント
- **公開インターフェース**:
  - generateInceptionPrompt(): `${AIDLC_ROOT}/prompts/inception.md` を生成（common部分 + inception固有部分）
  - generateConstructionPrompt(): `${AIDLC_ROOT}/prompts/construction.md` を生成（common部分 + construction固有部分）
  - generateOperationsPrompt(): `${AIDLC_ROOT}/prompts/operations.md` を生成（common部分 + operations固有部分）
  - generateAdditionalRules(): `${AIDLC_ROOT}/prompts/additional-rules.md` を生成（共通）
  - generateVersionAdditionalRules(): `${VERSIONS_ROOT}/${VERSION}/additional-rules.md` を生成（バージョン固有、オプション）
  - generateHistory(): `${VERSIONS_ROOT}/${VERSION}/history.md` を生成

#### 6. テンプレート生成コンポーネント
- **責務**: テンプレートファイルを生成（JIT生成を維持）
- **依存**: 変数定義コンポーネント、ディレクトリ初期化コンポーネント
- **公開インターフェース**:
  - generateIndexTemplate(): `${AIDLC_ROOT}/templates/index.md` を生成
  - generateSpecificTemplate(templateName): 指定されたテンプレートを生成
  - checkTemplateExists(templateName): テンプレートの存在確認

#### 7. バージョン記録コンポーネント
- **責務**: スターターキットのバージョンを記録
- **依存**: 変数定義コンポーネント、ディレクトリ初期化コンポーネント
- **公開インターフェース**:
  - saveStarterKitVersion(): `${AIDLC_ROOT}/version.txt` にスターターキットのバージョン（例: 1.0.0）を保存

#### 8. 履歴記録コンポーネント
- **責務**: セットアップ作業を履歴に記録
- **依存**: プロンプト生成コンポーネント
- **公開インターフェース**:
  - recordSetupHistory(): history.mdにセットアップ実行履歴を追記

#### 9. 完了報告コンポーネント
- **責務**: セットアップ完了メッセージとGitコミットの実行
- **依存**: すべてのコンポーネント
- **公開インターフェース**:
  - displayCompletionMessage(): 完了メッセージを表示
  - createGitCommit(): Gitコミットを作成

## 処理フロー概要

### MODE=setup の処理フロー

**ステップ**:
1. 変数定義を読み込み、`AIDLC_ROOT = ${DOCS_ROOT}/aidlc`, `VERSIONS_ROOT = ${DOCS_ROOT}/versions` を設定
2. 環境検証（カレントディレクトリ確認、ユーザー承認）
3. 共通ディレクトリ作成（`${AIDLC_ROOT}/prompts/`, `${AIDLC_ROOT}/templates/`）
4. バージョン固有ディレクトリ作成（`${VERSIONS_ROOT}/${VERSION}/plans/`, `requirements/`, `story-artifacts/`, 等）
5. 共通プロンプトファイル生成
   - inception.md（common部分を先頭に埋め込み + inception固有部分）
   - construction.md（common部分を先頭に埋め込み + construction固有部分）
   - operations.md（common部分を先頭に埋め込み + operations固有部分）
   - additional-rules.md（共通）
6. バージョン固有ファイル生成
   - history.md（`${VERSIONS_ROOT}/${VERSION}/history.md`）
   - additional-rules.md（`${VERSIONS_ROOT}/${VERSION}/additional-rules.md`、オプション）
7. テンプレートindex.md生成（`${AIDLC_ROOT}/templates/index.md`）
8. version.txt生成（`${AIDLC_ROOT}/version.txt`）
9. 履歴記録（history.mdに追記）
10. Gitコミット作成
11. 完了メッセージ表示

**関与するコンポーネント**: 全コンポーネント

### MODE=template の処理フロー

**ステップ**:
1. TEMPLATE_NAMEが指定されているか確認
2. テンプレートの存在確認
3. 存在する場合: 上書き確認
4. テンプレート生成
5. 完了報告

**関与するコンポーネント**: 変数定義、変数検証、テンプレート生成、完了報告

### MODE=list の処理フロー

**ステップ**:
1. `${AIDLC_ROOT}/templates/index.md` の存在確認
2. 存在する場合: 内容を表示
3. 存在しない場合: 「まずMODE=setupで初回セットアップを実行してください」と表示

**関与するコンポーネント**: 変数定義、テンプレート生成

## データモデル概要

### ディレクトリ構造

#### 共通ディレクトリ（全バージョンで共有）
```
${AIDLC_ROOT}/
├── prompts/
│   ├── inception.md           # common部分 + inception固有部分
│   ├── construction.md        # common部分 + construction固有部分
│   ├── operations.md          # common部分 + operations固有部分
│   └── additional-rules.md    # 共通の追加ルール
├── templates/
│   ├── index.md               # テンプレート一覧
│   ├── intent_template.md     # JIT生成
│   ├── user_stories_template.md
│   └── （その他のテンプレート、JIT生成）
└── version.txt                # スターターキットのバージョン
```

#### バージョン固有ディレクトリ
```
${VERSIONS_ROOT}/${VERSION}/
├── plans/
├── requirements/
├── story-artifacts/
│   └── units/
├── design-artifacts/
│   ├── domain-models/
│   ├── logical-designs/
│   └── architecture/
├── construction/
│   └── units/
├── operations/
├── history.md                  # バージョン固有の履歴
└── additional-rules.md         # バージョン固有の追加ルール（オプション）
```

### ファイル形式

#### version.txt
- **形式**: プレーンテキスト
- **内容**: スターターキットのバージョン番号（例: "1.0.0"）

#### history.md
- **形式**: Markdown
- **配置**: `${VERSIONS_ROOT}/${VERSION}/history.md`
- **構造**:
  - 先頭: 記録テンプレート
  - 中間: `## 実行履歴` セクション
  - 末尾: 実際の履歴エントリ（追記形式）

## 変数システム設計

### 変数定義の階層

```
基本変数（ユーザー指定）:
  - DOCS_ROOT = "docs"
  - VERSION = "v1.0.0"
  - PROJECT_NAME = "My Project"
  - 等

派生変数（自動計算）:
  - AIDLC_ROOT = "${DOCS_ROOT}/aidlc"
  - VERSIONS_ROOT = "${DOCS_ROOT}/versions"
```

### 変数置換処理

setup-prompt.md内のテンプレート文字列（例: プロンプトファイルの内容）で使用される変数：
- `{{AIDLC_ROOT}}` → 実際の値に置換
- `{{VERSIONS_ROOT}}` → 実際の値に置換
- `{{VERSION}}` → 実際の値に置換
- `{{PROJECT_NAME}}` → 実際の値に置換
- 等

### 後方互換性の保証

既存の変数（`DOCS_ROOT`, `VERSION`）も引き続き使用可能：
- 新しい変数（`AIDLC_ROOT`, `VERSIONS_ROOT`）を**追加**
- 既存の変数は変更しない
- 既存のセットアップフローも動作する（v0.1.0互換性）

## パス変換ロジック

### 旧パス → 新パス変換マッピング

| ファイル種別 | 旧パス | 新パス | 理由 |
|------------|-------|-------|------|
| inception.md | `${DOCS_ROOT}/${VERSION}/prompts/` | `${AIDLC_ROOT}/prompts/` | 共通化 |
| construction.md | `${DOCS_ROOT}/${VERSION}/prompts/` | `${AIDLC_ROOT}/prompts/` | 共通化 |
| operations.md | `${DOCS_ROOT}/${VERSION}/prompts/` | `${AIDLC_ROOT}/prompts/` | 共通化 |
| additional-rules.md（共通） | - | `${AIDLC_ROOT}/prompts/` | 新設 |
| history.md | `${DOCS_ROOT}/${VERSION}/prompts/` | `${VERSIONS_ROOT}/${VERSION}/` | バージョン固有 |
| additional-rules.md（バージョン固有） | `${DOCS_ROOT}/${VERSION}/prompts/` | `${VERSIONS_ROOT}/${VERSION}/` | バージョン固有（オプション） |
| テンプレート全般 | `${DOCS_ROOT}/${VERSION}/templates/` | `${AIDLC_ROOT}/templates/` | 共通化 |
| 成果物（requirements等） | `${DOCS_ROOT}/${VERSION}/requirements/` | `${VERSIONS_ROOT}/${VERSION}/requirements/` | バージョン固有 |

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: セットアップ完了時間はv0.1.0と同等
- **対応策**:
  - JIT生成を維持（MODE=setupではindex.mdのみ生成）
  - ディレクトリ作成は`mkdir -p`で一括実行
  - ファイル生成は並列化せず順次実行（シンプルさ優先）

### セキュリティ
- **要件**: ファイル操作の安全性確保
- **対応策**:
  - パス変数のバリデーション（不正な文字を含まないか確認）
  - ファイル上書き前に確認プロンプト（MODE=templateの場合）
  - heredocでの安全な複数行テキスト生成

### スケーラビリティ
- **要件**: 新しいバージョン追加時の作業量削減
- **対応策**:
  - プロンプトとテンプレートの共通化により、新バージョン開始時はVERSION変数を変更するだけ
  - バージョン固有の成果物のみ新規作成

### 可用性
- **要件**: エラーハンドリングの実装
- **対応策**:
  - 環境検証ステップでカレントディレクトリを確認
  - ユーザー承認待機（誤実行防止）
  - MODE分岐での不正値チェック
  - テンプレート生成時の存在確認

## 技術選定

- **言語**: Bash（既存と同じ）
- **ファイル生成**: heredoc（`cat <<'EOF'`）
- **ディレクトリ作成**: `mkdir -p`
- **変数置換**: Bashの変数展開
- **バージョン管理**: Git

## 実装上の注意事項

### セキュリティ
- ユーザー入力変数（DOCS_ROOT等）に不正な文字（`..`, `/`, 等）が含まれていないか検証
- heredocでのクォート使用（`<<'EOF'`）により変数展開を制御

### パフォーマンス
- ファイル生成は必要最小限（MODE=setupではテンプレート本体は生成しない）
- ディレクトリ作成は`mkdir -p`で効率化

### 保守性・拡張性
- 各コンポーネントは独立して動作（モジュール性）
- 新しいフェーズやテンプレート追加時は該当セクションのみ修正
- 変数定義セクションに新変数を追加するだけで拡張可能

### 後方互換性
- 既存の`DOCS_ROOT`、`VERSION`変数は維持
- 新しい変数（`AIDLC_ROOT`、`VERSIONS_ROOT`）は既存変数から派生
- v0.1.0のユーザーも新しいsetup-prompt.mdを使用可能（DOCS_ROOT, VERSION指定で動作）

## common.md埋め込み方式の詳細

### 設計方針
common.mdは中間ファイルとして生成せず、各フェーズプロンプト（inception.md, construction.md, operations.md）に直接埋め込みます。

### 埋め込み構造

各フェーズプロンプトは以下の構造を持ちます：

```markdown
# [Phase Name] Phase（[フェーズ名]フェーズ）

[common.mdの全内容をここに埋め込み]

---

## [Phase固有のセクション]
...
```

### 利点
- ユーザーは各フェーズで1ファイルだけ読めばOK
- common.mdを誤って直接読み込む心配がない
- ファイル数が削減される

### 欠点と対処
- 3つのファイルに同じ内容が重複
  - **対処**: setup-prompt.md側で管理するため、メンテナンスコストは変わらない
  - スターターキット更新時は setup-prompt.md の1箇所を修正するだけ

## 不明点と質問（設計中に記録）

[Question 1] history.mdの配置場所は？
[Answer 1] `${VERSIONS_ROOT}/${VERSION}/history.md`（プロンプトディレクトリの外、バージョン固有）

[Question 2] common.mdを中間ファイルとして生成するか、各フェーズに直接埋め込むか？
[Answer 2] 各フェーズに直接埋め込む（ユーザーが1ファイルだけ読めばOK）
