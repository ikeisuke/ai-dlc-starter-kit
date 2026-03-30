# Unit: migrate-backlog.sh macOS sed互換性修正

## 概要
`migrate-backlog.sh` の `generate_slug()` 関数で使用している `sed` コマンドの日本語文字範囲指定を `perl` に置換し、macOS（BSD sed）で発生する `RE error: invalid character range` エラーを解消する。

## 含まれるユーザーストーリー
- ストーリー 4: migrate-backlog.sh macOS sed互換性修正 (#190)

## 関連Issue
- #190

## 責務
- `generate_slug()` 関数の `sed` を `perl -pe` に置換
- macOS / Linux 両環境での動作確認

## 境界
- `generate_slug()` 以外の `sed` コマンドは変更しない
- `migrate-backlog.sh` のその他のロジックは変更しない
- バックログ移行のビジネスロジックは変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- perl（macOS標準搭載）

## 非機能要件（NFR）
- **パフォーマンス**: perlとsedの性能差はスラッグ生成で無視できるレベル
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: perl は macOS / Linux 両環境で標準搭載

## 技術的考慮事項
- `prompts/package/bin/migrate-backlog.sh` の60行目を修正（メタ開発ルール）
- `sed 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'` → `perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`
- Unicode文字範囲のクロスプラットフォーム対応

## 実装優先度
Low

## 見積もり
小規模（1行の修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-18
- **完了日**: 2026-02-18
- **担当**: @claude
