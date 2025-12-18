# Unit 7: 複数人開発時コンフリクト対策 - 実装記録

## 概要

history.md と backlog.md の複数人開発時コンフリクトを防ぐためのファイル分割方式を実装。

## 実装内容

### History の変更

**Before**: `docs/cycles/{{CYCLE}}/history.md` (単一ファイル)

**After**: `docs/cycles/{{CYCLE}}/history/` (ディレクトリ)
- `inception.md` - Inception Phase の履歴
- `construction_unit{N}.md` - 各Unit の履歴
- `operations.md` - Operations Phase の履歴

### Backlog の変更

**Before**:
- `docs/cycles/backlog.md` (共通、単一ファイル)
- `docs/cycles/{{CYCLE}}/backlog.md` (サイクル固有、単一ファイル)

**After**:
- `docs/cycles/backlog/` (共通、ディレクトリ)
  - `{種類}-{スラッグ}.md` (1気づき1ファイル)
- サイクル固有バックログは廃止

### 完了済みバックログの変更

**Before**: `docs/cycles/backlog-completed.md` (単一ファイル)

**After**: `docs/cycles/backlog-completed/{{CYCLE}}/` (サイクル別ディレクトリ)
- 旧形式（単一ファイル）は後方互換性のため参照可能

## 更新ファイル一覧

### プロンプト（通常版）
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/operations.md`

### プロンプト（Lite版）
- `prompts/package/prompts/lite/construction.md`
- `prompts/package/prompts/lite/inception.md`
- `prompts/package/prompts/lite/operations.md`

### セットアップ
- `prompts/setup-cycle.md`

### テンプレート
- `prompts/package/templates/backlog_item_template.md` (新規)
- `prompts/package/templates/history_entry_template.md` (新規)
- `prompts/package/templates/cycle_backlog_template.md` (削除)

## 設計成果物
- `docs/cycles/v1.4.0/design-artifacts/domain-models/unit7_domain_model.md`
- `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit7_logical_design.md`

## 気づき（バックログ追加）
- `docs/cycles/backlog/chore-workaround-backlog-rule.md` - その場しのぎ対応時のバックログ追加ルール

## 完了基準の確認

- [x] history分割方式のプロンプト更新完了
- [x] backlog分割方式のプロンプト更新完了（共通バックログに統一）
- [x] テンプレート更新完了
- [x] 既存ドキュメントとの整合性確認済み
- [x] 実装記録作成済み

## 状態

**完了**

---

作成日: 2025-12-14
