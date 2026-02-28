# Construction Phase 履歴: Unit 08

## 2026-02-28 18:00:00 JST

- **フェーズ**: Construction Phase
- **Unit**: 08-008-upgrade-scriptify（アップグレード処理スクリプト化）
- **ステップ**: Unit完了
- **実行内容**: migrate-config.shを新規作成し、setup-prompt.mdのセクション7.4/7.5の~230行のインラインbashをスクリプト呼び出しに置換。セクション8.2の6つのrsync操作を既存sync-package.sh呼び出しに置換（個別セクション→統合テーブル形式）。レビューで一時ファイル管理、BSD/GNU互換性、ログインジェクション対策等を修正。
- **成果物**:
  - `prompts/package/bin/migrate-config.sh`
  - `prompts/setup-prompt.md`

---
