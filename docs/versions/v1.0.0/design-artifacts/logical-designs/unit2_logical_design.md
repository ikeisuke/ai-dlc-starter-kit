# 論理設計: Unit2 - 各フェーズプロンプトのパス参照更新

## 概要
inception.md、construction.md、operations.md の3つのフェーズプロンプトファイル内のパス参照を、新しいディレクトリ構造（Unit1で定義された`{{AIDLC_ROOT}}/`と`{{VERSIONS_ROOT}}/{{VERSION}}/`）に対応した変数ベースのパス参照に更新します。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的な実装（ファイル編集）はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン
シンプルなファイル置換パターン（レイヤードアーキテクチャは不要）

## コンポーネント構成

### レイヤー / モジュール構成

```
PathReferenceUpdater (メインコンポーネント)
├── PathDetector (パス検出)
├── PathReplacer (パス置換)
└── ValidationChecker (検証)
```

### コンポーネント詳細

#### PathDetector
- **責務**: フェーズプロンプトファイル内のパス参照を検出する
- **依存**: なし
- **公開インターフェース**:
  - detectSetupPromptPath(fileContent): String - セットアッププロンプトパスを検出
  - detectTemplatePaths(fileContent): List<String> - テンプレート参照パスを検出
  - detectArtifactPaths(fileContent): List<String> - 成果物ディレクトリパスを検出

#### PathReplacer
- **責務**: 検出されたパス参照を新しい形式に置換する
- **依存**: PathDetector
- **公開インターフェース**:
  - replaceSetupPromptPath(oldPath, newPath): String - セットアッププロンプトパスを置換
  - replaceTemplatePaths(oldPaths, replacementRules): Map<String, String> - テンプレートパスを置換
  - replaceArtifactPaths(oldPaths, replacementRules): Map<String, String> - 成果物ディレクトリパスを置換

#### ValidationChecker
- **責務**: 置換後のパス参照が正しいことを検証する
- **依存**: なし
- **公開インターフェース**:
  - validateVariableReferences(content): Boolean - 変数参照の形式が正しいか検証
  - validatePathConsistency(content): Boolean - パス参照の整合性を検証

## インターフェース設計

### 置換操作

#### updatePhasePromptPaths
- **パラメータ**:
  - filePath: String - 対象ファイルのパス
  - replacementRules: List<ReplacementRule> - 置換ルールのリスト
- **戻り値**: UpdateResult - 置換結果（成功/失敗、変更箇所数）
- **副作用**: ファイル内容を書き換える

## データモデル概要

### ファイル形式（Markdown）

3つのフェーズプロンプトファイル:
- `docs/versions/v1.0.0/prompts/inception.md`
- `docs/versions/v1.0.0/prompts/construction.md`
- `docs/versions/v1.0.0/prompts/operations.md`

**主要フィールド**:
- セットアッププロンプトパス（先頭付近に記載）
- テンプレート参照パス（`docs/versions/v1.0.0/templates/` を参照）
- 成果物ディレクトリ参照パス（`docs/versions/v1.0.0/requirements/` など）

## 処理フロー概要

### パス参照更新の処理フロー

**ステップ**:
1. 対象ファイル（inception.md, construction.md, operations.md）を順次読み込み
2. 各ファイル内のパス参照を検出
   - テンプレート参照パス（`docs/versions/v1.0.0/templates/` 形式）
   - 成果物ディレクトリ参照パス（`docs/versions/v1.0.0/requirements/` など）
   - JITテンプレート生成ロジック（削除対象）
3. 置換ルールに基づいてパスを置換
   - 固定パス → 変数ベースのパス参照（`{{AIDLC_ROOT}}/`, `{{VERSIONS_ROOT}}/{{VERSION}}/`）
   - JITテンプレート生成ロジックを削除し、存在確認のみに変更
4. 置換後の内容を検証
5. ファイルに書き戻し

**関与するコンポーネント**: PathDetector, PathReplacer, ValidationChecker

## 具体的な置換パターン

### 1. セットアッププロンプトパス（維持）

**対象ファイル**: inception.md:3, construction.md:3, operations.md:3

**現在のパス**:
```
**セットアッププロンプトパス**: /Users/isonokeisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md
```

**置換後のパス**: **変更なし（絶対パスまたはGitHubリモートファイル参照のまま維持）**

**理由**: setup-prompt.md は AI-DLC Starter Kit の配布物であり、ユーザーのプロジェクトとは別の場所に配置される。ユーザーがセットアップ時に指定した場所（絶対パスまたはリモートURL）をそのまま使用する。

### 2. テンプレート参照パス（固定パス → 変数ベースパス）

**対象**: 各プロンプトファイル内のテンプレート参照

**置換パターン**:
| 置換前 | 置換後 |
|--------|--------|
| `docs/versions/v1.0.0/templates/intent_template.md` | `{{AIDLC_ROOT}}/templates/intent_template.md` |
| `docs/versions/v1.0.0/templates/user_stories_template.md` | `{{AIDLC_ROOT}}/templates/user_stories_template.md` |
| `docs/versions/v1.0.0/templates/unit_definition_template.md` | `{{AIDLC_ROOT}}/templates/unit_definition_template.md` |
| `docs/versions/v1.0.0/templates/prfaq_template.md` | `{{AIDLC_ROOT}}/templates/prfaq_template.md` |
| `docs/versions/v1.0.0/templates/domain_model_template.md` | `{{AIDLC_ROOT}}/templates/domain_model_template.md` |
| `docs/versions/v1.0.0/templates/logical_design_template.md` | `{{AIDLC_ROOT}}/templates/logical_design_template.md` |
| `docs/versions/v1.0.0/templates/implementation_record_template.md` | `{{AIDLC_ROOT}}/templates/implementation_record_template.md` |
| `docs/versions/v1.0.0/templates/deployment_checklist_template.md` | `{{AIDLC_ROOT}}/templates/deployment_checklist_template.md` |
| `docs/versions/v1.0.0/templates/monitoring_strategy_template.md` | `{{AIDLC_ROOT}}/templates/monitoring_strategy_template.md` |
| `docs/versions/v1.0.0/templates/post_release_operations_template.md` | `{{AIDLC_ROOT}}/templates/post_release_operations_template.md` |

**理由**: テンプレートは全バージョン共通なので`{{AIDLC_ROOT}}/templates/`を使用

### 3. 成果物ディレクトリ参照パス（固定パス → 変数ベースパス）

**置換パターン**:
| 置換前 | 置換後 |
|--------|--------|
| `docs/versions/v1.0.0/requirements/` | `{{VERSIONS_ROOT}}/{{VERSION}}/requirements/` |
| `docs/versions/v1.0.0/story-artifacts/` | `{{VERSIONS_ROOT}}/{{VERSION}}/story-artifacts/` |
| `docs/versions/v1.0.0/design-artifacts/` | `{{VERSIONS_ROOT}}/{{VERSION}}/design-artifacts/` |
| `docs/versions/v1.0.0/construction/` | `{{VERSIONS_ROOT}}/{{VERSION}}/construction/` |
| `docs/versions/v1.0.0/operations/` | `{{VERSIONS_ROOT}}/{{VERSION}}/operations/` |
| `docs/versions/v1.0.0/plans/` | `{{VERSIONS_ROOT}}/{{VERSION}}/plans/` |
| `docs/versions/v1.0.0/prompts/history.md` | `{{VERSIONS_ROOT}}/{{VERSION}}/history.md` |
| `docs/versions/v1.0.0/prompts/additional-rules.md` | `{{AIDLC_ROOT}}/prompts/additional-rules.md` |

**理由**: バージョン固有の成果物は`{{VERSIONS_ROOT}}/{{VERSION}}/`、共通プロンプトは`{{AIDLC_ROOT}}/prompts/`を使用

### 4. 特殊なパス参照（コマンド内のパス）

**対象**: `ls`, `grep`, `cat` などのコマンド内で使用されているパス

**置換パターン**:
| 置換前 | 置換後 |
|--------|--------|
| `ls docs/versions/v1.0.0/templates/` | `ls {{AIDLC_ROOT}}/templates/` |
| `grep -l "完了" docs/versions/v1.0.0/construction/units/*` | `grep -l "完了" {{VERSIONS_ROOT}}/{{VERSION}}/construction/units/*` |

**注意**: コマンド内のパスも変数参照に置換する（setup-prompt.mdで変数展開される）

### 5. JITテンプレート生成ロジックの削除

**対象セクション**: 各フェーズプロンプトの「最初に必ず実行すること」ステップ2

**削除内容**:
- `**テンプレートが存在しない場合**:` 以降のJIT生成ロジック全体
  - setup-prompt.md を MODE=template で読み込む指示
  - テンプレート生成完了メッセージ
  - 処理中断と再読み込み待機の指示

**置換後の内容**:
- テンプレート存在確認のみ（`ls` コマンドでチェック）
- 存在しない場合は初期セットアップが未完了であることを通知

**例（inception.md の場合）**:

**置換前**:
```
2. **テンプレート確認（JIT生成）**:
   - `ls docs/versions/v1.0.0/templates/intent_template.md ...` で必要なテンプレートの存在を確認
   - **テンプレートが存在しない場合**:
     - 上記の「セットアッププロンプトパス」に記載されているパスから setup-prompt.md を MODE=template で読み込み、不足しているテンプレートを自動生成する（intent_template, ...）
     - 生成完了後、ユーザーに「テンプレート生成が完了しました。再度このプロンプト（common.md + inception.md）を読み込んでInception Phaseを続行してください」と伝える
     - **重要**: テンプレート生成後は処理を中断し、ユーザーがプロンプトを再読み込みするまで待機する
```

**置換後**:
```
2. **テンプレート確認**:
   - `ls {{AIDLC_ROOT}}/templates/intent_template.md {{AIDLC_ROOT}}/templates/user_stories_template.md {{AIDLC_ROOT}}/templates/unit_definition_template.md {{AIDLC_ROOT}}/templates/prfaq_template.md` で必要なテンプレートの存在を確認
   - **テンプレートが存在しない場合**: 初期セットアップが未完了です。setup-prompt.md を実行してテンプレートを生成してください
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 特に制約なし
- **対応策**: 手動でのファイル編集（3ファイルのみなので高速）

### セキュリティ
- **要件**: 特に制約なし
- **対応策**: ファイル編集のみ、外部入力は扱わない

### スケーラビリティ
- **要件**: パス参照が正確であること
- **対応策**: 置換パターンを明確に定義し、すべてのパス参照を網羅的に更新

### 可用性
- **要件**: エラーのないパス置換
- **対応策**: 置換前後のファイル内容を確認し、変数参照の形式が正しいことを検証

## 技術選定
- **言語**: 手動編集（Markdown）
- **フレームワーク**: なし
- **ライブラリ**: なし
- **ツール**: Claude Code の Edit ツール

## 実装上の注意事項
- **正規表現の注意**: パス文字列の置換時は、完全一致を使用して誤置換を防ぐ
- **バックアップ**: 置換前にファイル内容を確認し、置換ミスがあれば復元できるようにする
- **検証**: 置換後、変数参照（`{{...}}`）が正しく記載されているかを確認
- **網羅性**: すべてのパス参照を漏れなく更新する（inception.md, construction.md, operations.md の3ファイル）

## 不明点と質問（設計中に記録）

現時点で不明点はありません。Unit1の実装記録により、新しいディレクトリ構造と変数定義が明確になっています。
