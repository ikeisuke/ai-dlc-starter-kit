# ドメインモデル: メタ開発境界ルール策定

## 概要

メタ開発時のファイル参照境界を定義する分類体系。AIエージェントがどのパスへの参照・作成を許可/禁止されるかを明確にするルールの構造を設計する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ

### 許可ルール（AllowRule）

デフォルト禁止の中で、許可される参照・操作を定義する。

- **属性**:
  - rule_id: String - ルールの一意識別子（例: `ALLOW-AIDLC-CONFIG`）
  - resource_type: ResourceType - 対象リソースの種別
  - path_pattern: String - 対象パスのパターン（例: `.aidlc/**`）
  - access_mode: AccessMode - アクセス方法
  - allowed_operations: OperationSet - 許可される操作の集合
  - description: String - ルールの説明と根拠

### 例外ルール（ExceptionRule）

デフォルト禁止パスに対する例外。メタ開発固有の参照など。

- **属性**:
  - exception_id: String - 例外の一意識別子（例: `META-001`）
  - target_path: String - 例外が適用されるパス
  - allowed_operations: OperationSet - 許可される操作（例: read-only）
  - reason: String - 例外を認める理由
  - scope: ExceptionScope - 適用範囲
  - note: String - 注意事項（例: 直接編集禁止）

## 値オブジェクト

### ResourceType（リソース種別）
- `aidlc_config` — AIDLC設定ファイル（`.aidlc/config.toml` 等）
- `cycle_data` — サイクルデータ（`.aidlc/cycles/` 配下）
- `skill_resource` — スキル内リソース（`templates/`, `scripts/`, `steps/`）
- `agent_config` — エージェント設定ファイル（`CLAUDE.md`, `AGENTS.md`）
- `project_file` — プロジェクトファイル（上記以外の一般ファイル）

### AccessMode（アクセス方法）
- `direct` — パス直接指定（プロジェクトルート相対パス）
- `skill_relative` — スキルベースディレクトリからの相対パス解決

### OperationSet（操作種別の集合）
- `read` — ファイル内容の読み取り
- `write` — 既存ファイルの編集
- `create` — 新規ファイルの作成
- `execute` — スクリプトの実行

### ExceptionScope（例外の適用範囲）
- `meta_dev_only` — メタ開発リポジトリでのみ有効
- `custom_workflow` — `.aidlc/rules.md` のカスタムワークフローで明示指定された場合のみ

## 集約

### パス境界ポリシー（PathBoundaryPolicy）
- **集約ルート**: PathBoundaryPolicy
- **含まれる要素**: AllowRule（複数）、ExceptionRule（複数）
- **デフォルト動作**: 許可リスト・例外リストに該当しないパスは全て禁止
- **不変条件**:
  - 全ての許可ルールには明示的なpath_patternとallowed_operationsが定義されている
  - 例外ルールのallowed_operationsはデフォルト禁止の範囲内に限定される

## ルール判定ロジック

パス参照の許可/禁止を以下の優先順位で判定:

1. **許可ルールチェック**: 対象パスが許可パターンに該当し、操作がallowed_operationsに含まれるか → 許可
2. **例外ルールチェック**: 対象パスが例外リストに該当し、操作がallowed_operationsに含まれるか → 許可（注意事項あり）
3. **デフォルト禁止**: 上記いずれにも該当しない → 禁止

## ユビキタス言語

- **メタ開発**: AI-DLCスターターキット自体をAI-DLCを使って開発すること
- **スキルベースディレクトリ**: SKILL.mdが配置されるディレクトリ。`steps/`, `scripts/`, `templates/` の相対パス解決の基点
- **許可パス**: AllowRuleに該当し、操作が許可されているパス
- **禁止パス**: AllowRule・ExceptionRuleのいずれにも該当しないパス（デフォルト禁止）
- **例外**: デフォルト禁止の対象だが、特定の理由と条件で許可されるケース
- **rsyncコピー**: `prompts/package/` → `docs/aidlc/` の同期。`docs/aidlc/` は直接編集禁止

## 不明点と質問

（現時点で不明点なし）
