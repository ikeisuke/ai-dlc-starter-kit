# ドメインモデル: Unit 4 - フェーズプロンプト改修

## 概要
変数置換方式から設定ファイル参照方式への移行におけるドメインモデルを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

---

## 値オブジェクト（Value Object）

### ConfigReference（設定参照）
プロンプト内で設定ファイルを参照するための指示パターン

- **属性**:
  - sourceFile: String - 参照元ファイルパス（例: `docs/aidlc/project.toml`）
  - targetInfo: String - 取得する情報（例: 「プロジェクト名」）
- **不変性**: 参照パターンは確定後変更しない
- **等価性**: sourceFile と targetInfo の組み合わせで判定

### FixedPath（固定パス）
変数置換不要な固定パス

- **属性**:
  - path: String - 固定パス値（例: `docs/aidlc`）
  - description: String - パスの説明
- **不変性**: パスは確定後変更しない
- **等価性**: path で判定

### CycleReference（サイクル参照）
ユーザー指示に基づくサイクル特定方法

- **属性**:
  - instructionText: String - 「ユーザーから指示されたサイクル」
  - derivationPattern: String - `docs/cycles/{サイクル}`
- **不変性**: 参照パターンは確定後変更しない

---

## エンティティ（Entity）

### PhasePrompt（フェーズプロンプト）
各フェーズ用のプロンプトファイル

- **ID**: filePath（ファイルパス）
- **属性**:
  - phaseName: String - フェーズ名（Inception/Construction/Operations）
  - roleName: String - 役割名（固定値）
  - configReferences: List<ConfigReference> - 設定参照一覧
  - fixedPaths: List<FixedPath> - 固定パス一覧
  - cycleReference: CycleReference - サイクル参照方法
- **振る舞い**:
  - replaceVariables(): 変数を設定参照/固定パスに置換
  - addConfigReadingSection(): 設定読み込みセクションを追加

### CommonSetup（共通セットアップ）
共通処理を定義するファイル

- **ID**: filePath（`prompts/setup/common.md`）
- **属性**:
  - configReferenceRules: String - 設定参照ルールの説明
  - directoryStructure: String - ディレクトリ構成定義
  - commonFiles: List<String> - 生成する共通ファイル一覧
- **振る舞い**:
  - removeVariableSubstitutionRules(): 変数置換ルールセクションを削除
  - addConfigReferenceRules(): 設定参照ルールセクションを追加

---

## 集約（Aggregate）

### PhasePromptSet（フェーズプロンプトセット）
改修対象のプロンプトファイル群

- **集約ルート**: CommonSetup
- **含まれる要素**:
  - CommonSetup（1）
  - PhasePrompt（3: inception, construction, operations）
- **境界**: prompts/setup/ ディレクトリ内のファイル
- **不変条件**:
  - すべてのファイルで変数置換方式が廃止されていること
  - すべてのファイルで設定参照方式が統一されていること

---

## ドメインサービス

### VariableReplacementService
変数置換から設定参照への変換サービス

- **責務**: `{{VAR}}` 形式の変数を設定参照/固定パスに変換
- **操作**:
  - convertToFixedPath(variable): 変数を固定パスに変換
  - convertToConfigReference(variable): 変数を設定参照に変換
  - convertToCycleReference(variable): 変数をサイクル参照に変換

---

## 変換マッピング

| 旧変数 | 変換タイプ | 変換後 |
|--------|-----------|--------|
| `{{AIDLC_ROOT}}` | FixedPath | `docs/aidlc` |
| `{{CYCLES_ROOT}}` | FixedPath | `docs/cycles` |
| `{{SETUP_PROMPT_PATH}}` | FixedPath | `prompts/setup-prompt.md` |
| `{{CYCLE}}` | CycleReference | ユーザー指示から取得 |
| `{{PROJECT_SUMMARY}}` | ConfigReference | project.toml から取得 |
| `{{PROJECT_NAME}}` | ConfigReference | project.toml から取得 |
| `{{ROLE_INCEPTION}}` | FixedPath | プロダクトマネージャー兼ビジネスアナリスト |
| `{{ROLE_CONSTRUCTION}}` | FixedPath | ソフトウェアアーキテクト兼エンジニア |
| `{{ROLE_OPERATIONS}}` | FixedPath | DevOpsエンジニア兼SRE |
| `{{LANGUAGE}}` | ConfigReference | project.toml から取得（デフォルト: 日本語） |

---

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| 変数置換方式 | `{{VAR}}` 形式の変数をセットアップ時に値に置き換える旧方式 |
| 設定参照方式 | AIが設定ファイルを読み込んで情報を取得する新方式 |
| 固定パス | 変更されない確定したパス値 |
| サイクル参照 | ユーザー指示に基づいてサイクルを特定する方法 |
| project.toml | プロジェクト設定を集約するファイル |

---

## 設計判断の記録

| 項目 | 決定 | 理由 |
|------|------|------|
| パスの固定化 | `docs/aidlc`, `docs/cycles` を固定 | 変動する必要がなく、固定化でシンプルに |
| 役割名の固定化 | 各フェーズの役割を固定値に | カスタマイズ需要が低く、固定化で十分 |
| CYCLE の扱い | ユーザー指示から取得 | 実行時に決まる値のため |
| project.toml 参照 | プロンプト冒頭で読み込み指示 | 設定を文脈として理解させる |
