# Unit: defaults.toml フルパス明記

## 概要
プロンプト・ガイド文書でdefaults.tomlのフルパスを明記し、AIエージェントによるパス誤案内を防止する。

## 含まれるユーザーストーリー
- ストーリー 3: defaults.toml フルパス明記（ドキュメント改善）

## 責務
- config-merge.mdの設定ファイル階層テーブルでdefaults.tomlのフルパスを明記
- rules.mdの設定読み込みセクションでパス情報を追加

## 境界
- read-config.shのロジックは変更しない
- aidlc-setup.shの同期ロジックは変更しない
- defaults.toml不在時の診断機能は Unit 004 の責務

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 正本は `prompts/package/` 配下のファイルを編集
- 対象: `prompts/package/guides/config-merge.md`, `prompts/package/prompts/common/rules.md`
- `docs/aidlc/` にはrsync同期で反映

## 実装優先度
Low

## 見積もり
小規模（ドキュメント修正のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
