# 実装記録: jjサポート有効化フラグ

## 実装日時

2026-01-11

## 作成ファイル

### 設定ファイル

- `docs/aidlc.toml` - `[rules.jj]`セクション追加

### プロンプトファイル

- `prompts/package/prompts/setup.md` - jj設定確認ブロック追加（worktree例外注記含む）
- `prompts/package/prompts/inception.md` - jj設定確認ブロック追加
- `prompts/package/prompts/construction.md` - jj設定確認ブロック追加
- `prompts/package/prompts/operations.md` - jj設定確認ブロック追加（タグ操作例外注記含む）

### 設計ドキュメント

- `docs/cycles/v1.7.1/design-artifacts/domain-models/008-jj-enabled-flag_domain_model.md`
- `docs/cycles/v1.7.1/design-artifacts/logical-designs/008-jj-enabled-flag_logical_design.md`

## テスト結果

- Markdownlint: 成功（プロンプトファイルにエラーなし）

## コードレビュー結果

- [x] 設計書との整合性: OK
- [x] 既存ガイドとの整合性: OK
- [x] 例外事項の明記: OK（worktree、タグ操作）

## 技術的な決定事項

1. **gitコマンドはそのまま維持**: 既存のjj-support.mdの「読み替え前提」方針を維持し、プロンプト内のgitコマンドは変更しない
2. **設定ファイルの直接編集**: `prompts/package/aidlc.toml.template`は存在しないため、`docs/aidlc.toml`を直接編集
3. **例外の明記**: worktree操作（setup.md）とタグ操作（operations.md）はjjでサポートされないため、gitを継続使用する旨を注記

## 課題・改善点

- Lite版プロンプト（`prompts/package/prompts/lite/`）への適用は本Unitのスコープ外

## 状態

**完了**

## 備考

バックログ`feature-jj-enabled-flag.md`の要件を反映
