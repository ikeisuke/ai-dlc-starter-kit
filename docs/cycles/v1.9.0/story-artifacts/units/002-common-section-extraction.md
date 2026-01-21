# Unit: 共通セクション外部化

## 概要

AI-DLC手法の要約、共通開発ルールを外部ファイルに切り出し、各プロンプトから参照する形式に変更する。

## 含まれるユーザーストーリー

- ストーリー2: 共通セクションの外部ファイル化 (#76)

## 責務

- `prompts/package/prompts/common/intro.md`の作成
- `prompts/package/prompts/common/rules.md`の作成
- 各フェーズプロンプトの参照形式への変更
- 250行以上の削減達成

## 境界

- AIレビューフローは別Unit（Unit 003）
- 参照漏れチェックは別Unit（Unit 004）

## 依存関係

### 依存する Unit

- Unit 001: 参照方式PoC（依存理由: 参照形式が動作することを確認してから実施）

### 外部依存

- rsyncデプロイ設定

## 非機能要件（NFR）

- **パフォーマンス**: 参照読み込みがセッション開始に影響しないこと
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

- rsyncデプロイ設定でcommon/ディレクトリが正しくコピーされることを確認
- 各プロンプトの先頭に参照指示を追加
- 参照形式: 「`docs/aidlc/prompts/common/intro.md`を読み込んでください」（rsync後のパス）
- 作成先は`prompts/package/prompts/common/`、利用時の参照先は`docs/aidlc/prompts/common/`

## 実装優先度

High

## 見積もり

Construction Phase Phase 2（実装）で実施

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-21
- **完了日**: 2026-01-22
- **担当**: Claude
