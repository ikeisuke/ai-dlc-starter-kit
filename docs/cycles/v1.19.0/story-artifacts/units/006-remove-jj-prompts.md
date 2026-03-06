# Unit: jjサポート削除 - プロンプト

## 概要
別リポジトリに移植済みのjjサポート関連のプロンプトファイル・スキルファイルを本体から削除する。

## 含まれるユーザーストーリー
- ストーリー 5: jjサポート関連処理の削除（プロンプト部分）

## 責務
- `prompts/package/skills/versioning-with-jj/` ディレクトリ全体を削除
- `prompts/package/prompts/common/rules.md` からjjサポート設定セクション（L20-21, L86-90）・コマンド読み替え指示（L157）を除去
- `prompts/package/prompts/common/commit-flow.md` からjj環境固有のフロー（計10箇所）を除去
- `prompts/package/prompts/common/ai-tools.md` からjjスキル参照行（L25）を除去
- `prompts/package/prompts/inception.md`、`construction.md`、`operations.md` からjj固有の注釈を除去
- `docs/aidlc.toml` の `[rules.jj]` セクションで `enabled = true` 時の警告表示をルールに追加

## 境界
- スクリプト（bin/*.sh）からのjj処理除去はUnit 007の責務
- `docs/aidlc/` 配下は `prompts/package/` のrsyncコピーなので直接編集しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 削除対象の行番号は既存コード分析時点のもの。実装時に再確認が必要
- jj関連のConditional分岐を除去する際、git処理ロジックに影響がないことを確認
- `docs/aidlc.toml` はプロジェクト設定ファイルであり直接編集対象
- `common/rules.md` はUnit 001（Overconfidence Prevention）・Unit 002（Depth Levels）でも変更される。推奨実装順: Unit 006（削除）→ Unit 001（再構成）→ Unit 002（追加）で競合リスクを最小化

## 実装優先度
High

## 見積もり
中規模（6プロンプトファイル + 1スキルディレクトリの削除・除去）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
