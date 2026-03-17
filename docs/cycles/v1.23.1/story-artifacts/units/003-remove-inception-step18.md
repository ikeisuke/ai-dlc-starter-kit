# Unit: Inception Phaseステップ18削除

## 概要
Inception Phaseプロンプトからsession-state.md復元チェック（ステップ18）を削除し、ステップ番号を繰り上げる。

## 含まれるユーザーストーリー
- ストーリー4: Inception Phaseステップ18の削除

## 責務
- inception.mdからステップ18（セッション状態の復元）の削除
- 旧ステップ19以降のステップ番号繰り上げ
- ステップ18への参照の除去（コンテキストリセット対応内のsession-state.md参照は維持）
- inception.md内のクロスリファレンス（ステップ番号参照）の整合性修正

## 編集対象ファイル
- `prompts/package/prompts/inception.md`（唯一の編集対象）
- inception.md以外のファイル（compaction.md, session-continuity.md, construction.md, operations.md等）は編集しない。万一inception.md外に旧ステップ番号への参照が見つかった場合は、別Issueとしてバックログに登録する

## 境界
- compaction.md、session-continuity.mdの内容変更は含まない
- コンテキストリセット対応のsession-state.md生成指示は変更しない
- Construction Phase、Operations Phaseのプロンプトは変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし（プロンプト修正のみ）

## 技術的考慮事項
- メタ開発ルール: `prompts/package/prompts/inception.md`を編集する
- ステップ番号変更に伴い、progress.mdテンプレートやクロスリファレンスの整合性を確認する

## 実装優先度
High

## 見積もり
小規模（プロンプト修正1ファイル）

## 関連Issue
- なし（Issue外の対応項目）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
