# ドメインモデル: Claude Code機能活用

## 概要
Claude Code固有の設定ファイル（CLAUDE.md/AGENTS.md）のテンプレート管理と、セットアップ時の配置・マージ処理の構造を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### TemplateFile
- **属性**:
  - path: String - テンプレートファイルのパス
  - content: String - テンプレートの内容
  - requiredSections: List<Section> - 必須セクションのリスト
- **不変性**: テンプレートファイルの内容はスターターキットのバージョンごとに固定
- **等価性**: pathで識別

### Section
- **属性**:
  - header: String - セクション見出し（例: `## Claude Code固有の設定`）
  - content: String - セクション内容
  - level: Integer - 見出しレベル（1-6）
- **不変性**: セクションは見出しと内容のペアとして不変
- **等価性**: headerで識別（同一見出しは同一セクション）

### TargetFile
- **属性**:
  - path: String - 対象ファイルのパス（CLAUDE.md, AGENTS.md）
  - exists: Boolean - ファイルが存在するか
  - sections: List<Section> - 既存セクションのリスト

## ドメインサービス

### TemplateMergeService
- **責務**: テンプレートとターゲットファイルのマージ処理
- **操作**:
  - checkMissingSections(template, target) - ターゲットに欠けている必須セクションを検出
  - appendSections(target, sections) - 欠けているセクションをターゲットに追記
  - copyTemplate(template, targetPath) - テンプレートを新規コピー

### SetupFlowService
- **責務**: セットアップフローにおけるCLAUDE.md/AGENTS.md処理
- **操作**:
  - processTemplates() - テンプレート処理のエントリーポイント
    1. ターゲットファイルの存在確認
    2. 存在しない場合: テンプレートをコピー
    3. 存在する場合: 必須セクション追記

## ファイル配置設計

### 配置場所の区分

| ディレクトリ | 役割 | rsync対象 |
|-------------|------|-----------|
| `prompts/package/templates/` | rsync同期されるテンプレート | Yes |
| `prompts/setup/templates/` | 初回のみコピーされるテンプレート | No |
| プロジェクトルート | 実際に使用されるファイル | - |

### CLAUDE.md/AGENTS.mdの配置

- **テンプレート配置**: `prompts/setup/templates/`
  - `CLAUDE.md.template`
  - `AGENTS.md.template`
- **理由**: これらはプロジェクト固有の設定を含むため、rsyncで上書きされるべきではない

## ユビキタス言語

- **必須セクション**: テンプレートに定義され、ターゲットファイルに必ず存在すべきセクション
- **マージ**: 既存ファイルに欠けている必須セクションのみを追記する処理
- **rsync対象**: セットアップ/アップグレード時に毎回同期されるファイル群
- **初回のみコピー**: 最初のセットアップ時のみコピーされ、以降は保持されるファイル

## 不明点と質問（設計中に記録）

（なし - 事前の質問で必須セクション自動追記方式を確定済み）
