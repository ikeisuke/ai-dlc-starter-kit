# Unit: defaults.toml 不在時の耐障害性強化

## 概要
defaults.toml不在時にread-config.shが診断メッセージを出力し、プリフライトチェックでwarning報告する機能を追加する。

## 含まれるユーザーストーリー
- ストーリー 4: defaults.toml 不在時の耐障害性強化

## 責務
- read-config.shにdefaults.toml不在時の診断メッセージ出力を追加
- プリフライトチェック（preflight.md）のconfig-validationにdefaults.toml存在チェックを追加

## 境界
- read-config.shの設定マージロジック自体は変更しない（不在時はスキップする既存動作を維持）
- aidlc-setup.shの同期ロジックは変更しない
- ドキュメントのパス明記は Unit 003 の責務

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: defaults.toml不在時でもread-config.shが終了コード0で動作し続けること

## 技術的考慮事項
- 正本は `prompts/package/` 配下のファイルを編集
- 対象: `prompts/package/bin/read-config.sh`, `prompts/package/prompts/common/preflight.md`
- `docs/aidlc/` にはrsync同期で反映
- 診断メッセージは標準エラーに出力（標準出力は設定値のみ）

## 実装優先度
High

## 見積もり
小規模（診断メッセージ追加 + プリフライトチェック修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-23
- **完了日**: 2026-03-23
- **担当**: @ai
