# Unit 005 実行計画: Issue駆動バックログフロー

## 概要
バックログとGitHub Issueの連携フローを定義し、Issue駆動でのバックログ管理をAI-DLCに統合する。

## 依存関係
- Unit 003: バックログ用Issueテンプレート（完了済み）

## Phase 1: 設計

### ステップ1: ドメインモデル設計
**成果物**: `docs/cycles/v1.7.0/design-artifacts/domain-models/unit005_domain_model.md`

フロードキュメント作成が主責務のため、シンプルなドメインモデル:
- バックログアイテムの概念モデル
- 保存先（Issue/Git）の選択概念
- ユビキタス言語の定義

### ステップ2: 論理設計
**成果物**: `docs/cycles/v1.7.0/design-artifacts/logical-designs/unit005_logical_design.md`

- ガイドドキュメントの構成設計
- `docs/aidlc.toml` への設定項目設計
- フロー図（新規作成・完了・参照）

### ステップ3: 設計レビュー
- 設計内容をユーザーに提示
- 承認を得てからPhase 2へ

## Phase 2: 実装

### ステップ4: コード生成（ドキュメント作成）
**成果物**:
1. `prompts/package/guides/issue-driven-backlog.md` - ガイドドキュメント
2. `docs/aidlc.toml` - `[backlog].mode` 設定追加

### ステップ5: テスト生成
- ドキュメントの整合性確認
- 設定項目の動作確認（既存プロンプトとの整合性）

### ステップ6: 統合とレビュー
- 最終レビュー
- 実装記録作成

## 成果物一覧

| ファイル | 種別 |
|----------|------|
| `docs/cycles/v1.7.0/design-artifacts/domain-models/unit005_domain_model.md` | ドメインモデル |
| `docs/cycles/v1.7.0/design-artifacts/logical-designs/unit005_logical_design.md` | 論理設計 |
| `prompts/package/guides/issue-driven-backlog.md` | ガイドドキュメント（新規） |
| `docs/aidlc.toml` | 設定ファイル（更新） |
| `docs/cycles/v1.7.0/construction/units/unit005_implementation.md` | 実装記録 |
| `docs/cycles/v1.7.0/history/construction_unit5.md` | 履歴 |

## 見積もり
中規模（ガイドドキュメント作成 + toml設定追加）
