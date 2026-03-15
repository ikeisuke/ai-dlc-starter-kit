# 実装記録: 外部レビューツール制約のドキュメント化

## 実装日時

2026-03-15

## 作成ファイル

### ソースコード

- `prompts/package/prompts/common/review-flow.md` - 「外部レビューツールの既知制約と対処法」セクション追加

### テスト

- markdownlint実行: エラー0件

### 設計ドキュメント

- `docs/cycles/v1.22.0/design-artifacts/domain-models/external_tool_constraints_domain_model.md`
- `docs/cycles/v1.22.0/design-artifacts/logical-designs/external_tool_constraints_logical_design.md`

## ビルド結果

N/A（ドキュメント変更のみ）

## テスト結果

成功（markdownlint 0 error(s)）

## コードレビュー結果

- [x] セキュリティ: OK
- [x] コーディング規約: OK
- [x] エラーハンドリング: OK
- [x] テストカバレッジ: OK
- [x] ドキュメント: OK

## 技術的な決定事項

- セクション配置: 「レビューサマリファイル更新手順」と「外部入力検証ルール」の間（リファレンス情報として独立配置）
- 構成軸: ツール軸（Codex > Claude > Gemini > 共通）で統一、各ツール内でカテゴリ別に分類
- 重複防止: 既存エラー分類表との責務分離（事前予防 vs エラー後対処）
- auth_lifecycle: ツール固有情報（検知/再認証コマンド）と共通手順の分離
- セキュリティ注意事項: 機密情報除外、マスキング、認証情報管理、サプライチェーン対策を冒頭に明記

## 課題・改善点

なし

## 状態

**完了**
