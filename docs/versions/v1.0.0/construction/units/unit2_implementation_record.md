# 実装記録: Unit2 - 各フェーズプロンプトのパス参照更新

## 実装日時
2025-11-24 開始 〜 2025-11-24 13:49 完了

## 作成ファイル

### 設計ドキュメント
- docs/versions/v1.0.0/design-artifacts/domain-models/unit2_domain_model.md - DDDに基づくドメインモデル設計
- docs/versions/v1.0.0/design-artifacts/logical-designs/unit2_logical_design.md - 論理設計（パス置換パターン、JIT削除仕様）

### 更新ファイル
- docs/versions/v1.0.0/prompts/inception.md - パス参照を変数ベースに更新、JITロジック削除
- docs/versions/v1.0.0/prompts/construction.md - パス参照を変数ベースに更新、JITロジック削除
- docs/versions/v1.0.0/prompts/operations.md - パス参照を変数ベースに更新、JITロジック削除

## 変更内容

### 1. セットアッププロンプトパスの扱い（変更なし）

**方針**: 絶対パスのまま維持

**理由**:
- setup-prompt.md は AI-DLC Starter Kit の配布物であり、ユーザーのプロジェクトとは別の場所に配置される
- ユーザーがセットアップ時に指定した場所（絶対パスまたはリモートURL）をそのまま使用する
- メタ開発中のため、現在は同一プロジェクト内にあるが、本来は外部参照

### 2. JITテンプレート生成ロジックの削除

**削除内容**:
各フェーズプロンプトの「最初に必ず実行すること」ステップ2から以下を削除：
- `**テンプレートが存在しない場合**:` 以降のJIT生成ロジック全体
- setup-prompt.md を MODE=template で読み込む指示
- テンプレート生成完了メッセージと処理中断の指示

**置換後の内容**:
- テンプレート存在確認のみ（`ls` コマンドでチェック）
- 存在しない場合は初期セットアップが未完了であることを通知

**理由**: 初期セットアップ時にすべてのテンプレートを生成する方針に変更

### 3. テンプレート参照パスの更新

**置換パターン**:
| 置換前 | 置換後 |
|--------|--------|
| `docs/versions/v1.0.0/templates/xxx_template.md` | `{{AIDLC_ROOT}}/templates/xxx_template.md` |

**対象テンプレート**:
- intent_template, user_stories_template, unit_definition_template, prfaq_template
- domain_model_template, logical_design_template, implementation_record_template
- deployment_checklist_template, monitoring_strategy_template, post_release_operations_template

**理由**: テンプレートは全バージョン共通なので `{{AIDLC_ROOT}}/templates/` を使用

### 4. 成果物ディレクトリ参照パスの更新

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

**理由**: バージョン固有の成果物は `{{VERSIONS_ROOT}}/{{VERSION}}/` を使用

### 5. 共通プロンプトパスの更新

**置換パターン**:
| 置換前 | 置換後 |
|--------|--------|
| `docs/versions/v1.0.0/prompts/additional-rules.md` | `{{AIDLC_ROOT}}/prompts/additional-rules.md` |
| `docs/versions/v1.0.0/prompts/common.md` | `{{AIDLC_ROOT}}/prompts/common.md` |

**理由**: 共通プロンプトは全バージョンで共有なので `{{AIDLC_ROOT}}/prompts/` を使用

## ビルド結果
該当なし（プロンプトファイルの更新のみ）

## テスト結果
パス整合性確認:
- ✅ `{{AIDLC_ROOT}}` 参照: 21箇所（inception.md: 8, construction.md: 7, operations.md: 6）
- ✅ `{{VERSIONS_ROOT}}` 参照: 25箇所（inception.md: 9, construction.md: 7, operations.md: 9）
- ✅ 旧パス `docs/versions/v1.0.0/` は完全に削除済み
- ✅ JITテンプレート生成ロジック (`MODE=template`) は完全に削除済み
- ✅ セットアッププロンプトパスは絶対パスのまま維持（変更なし）

## コードレビュー結果
- [x] セキュリティ: OK（ファイル編集のみ、外部入力なし）
- [x] コーディング規約: OK（Markdown形式、UTF-8エンコーディング）
- [x] エラーハンドリング: OK（パス参照の検証を実施）
- [x] テストカバレッジ: OK（すべてのパス参照を網羅的に更新）
- [x] ドキュメント: OK（設計ドキュメント完備）

## 技術的な決定事項

### 1. セットアッププロンプトパスの絶対パス維持

**決定**: セットアッププロンプトパスは絶対パスのまま維持

**理由**:
- setup-prompt.md は AI-DLC Starter Kit の配布物として、ユーザーのプロジェクトとは別の場所に配置される
- ユーザーがセットアップ時に指定した場所（絶対パスまたはGitHubリモートURL）をそのまま使用する
- メタ開発中のため、現在は同一プロジェクト内にあるが、本来は外部参照

### 2. JITテンプレート生成の廃止

**決定**: JIT（Just-In-Time）テンプレート生成ロジックを完全に削除し、初期セットアップ時にすべてのテンプレートを生成する方針に変更

**理由**:
- テンプレートの一貫性を保つため、初期セットアップ時に一括生成する方が適切
- JITロジックは複雑性を増すため、シンプルな設計を優先
- 各フェーズ開始時にテンプレートが存在しない場合は、初期セットアップが未完了であることをユーザーに通知

### 3. 変数ベースのパス参照への統一

**決定**: `{{AIDLC_ROOT}}/` と `{{VERSIONS_ROOT}}/{{VERSION}}/` を使用した変数ベースのパス参照に統一

**理由**:
- Unit1で定義された新しいディレクトリ構造との整合性を保つ
- 共通ファイルとバージョン固有ファイルの明確な区別
- setup-prompt.md の変数置換ロジックを活用

## 課題・改善点
なし

## 状態
**完了**

## 備考
- Unit3（新しいディレクトリ構造の作成）で、実際のファイル配置を新しい構造に移行する必要がある
- この実装により、フェーズプロンプトは新しいディレクトリ構造に完全に対応し、バージョン間の共通化が実現される
