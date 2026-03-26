# Unit 008 計画: deprecation準備

## 概要

将来削除予定の後方互換性コードを明確に管理し、計画的なコード整理を可能にする。

## 関連Issue

- #80: [v1.9.0] 後方互換性コードのdeprecation準備

## deprecation対象（Issue #80より）

1. `docs/cycles/{{CYCLE}}/construction/progress.md` への後方互換参照
2. `docs/cycles/backlog.md`（旧形式単一ファイル）移行コード
3. 旧形式バックログ移行セクション（setup.md内）

## 変更対象ファイル

### 新規作成

- `prompts/package/deprecation.md` - deprecation対象一覧ドキュメント

### 修正対象

- `prompts/package/prompts/construction.md` - progress.md参照箇所に警告コメント追加
- `prompts/package/prompts/setup.md` - バックログ移行セクションに警告コメント追加

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: deprecation管理の概念モデル定義
2. **論理設計**: ドキュメント構成とコメント形式の設計

### Phase 2: 実装

1. **deprecation一覧ドキュメント作成**: `prompts/package/deprecation.md`
2. **警告コメント追加**: 各対象ファイルへdeprecation予告コメントを追加
3. **CHANGELOG.md更新**: deprecation情報を記載（Operations Phaseで実施）

## 完了条件チェックリスト

- [ ] deprecation対象の一覧ドキュメント作成
- [ ] 各対象への削除予定バージョン記載
- [ ] 警告メッセージまたはコメントの追加
- [ ] v1.9.0でdeprecation warningを追加（Issue #80）

## 注意事項

- 実際の削除は行わない（準備のみ）
- 削除予定バージョンはv2.0.0を想定
- `prompts/package/`を編集（`docs/aidlc/`は直接編集禁止）
