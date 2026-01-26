# Unit: ドキュメント修正一括

## 概要
jj-support.md の誤記修正、codex skill の resume 説明追加、アップグレード指示へのパス参照追加を一括で実施する。

## 含まれるユーザーストーリー
- ストーリー 1: jjドキュメント誤記修正 (#89)
- ストーリー 2: codex skill resume説明追加 (#121)
- ストーリー 4: アップグレード指示にパス参照追加 (#87)

## 責務
- jj-support.md の未追跡ファイル記述を修正
- jj-support.md のリモートブックマーク表記を修正
- codex skill に resume 機能の説明を追加
- アップグレード指示にメタ開発用パスを追記

## 境界
- スクリプトの変更は含まない（ドキュメントのみ）

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
対象ファイル:
- `prompts/package/guides/jj-support.md`
- `prompts/package/skills/codex/SKILL.md`
- `prompts/setup-prompt.md` または `docs/cycles/rules.md`

## 実装優先度
High

## 見積もり
小（ドキュメント修正のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-26
- **完了日**: 2026-01-26
- **担当**: Claude
