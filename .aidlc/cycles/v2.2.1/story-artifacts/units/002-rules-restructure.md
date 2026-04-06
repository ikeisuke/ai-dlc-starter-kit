# Unit: rules.md 3階層分割

## 概要
rules.mdを用途別に3ファイルに分割し、agents-rules.mdとの重複を解消・統合する。常時ロードされるルールファイルのサイズを削減する。

## 含まれるユーザーストーリー
- ストーリー 2: rules.md 3階層分割

## 責務
- rules.mdの内容をrules-core.md、rules-automation.md、rules-reference.mdに分割
- agents-rules.mdの内容をrules-core.mdに統合
- SKILL.mdおよび各ステップファイルの参照パス更新
- 元ファイル（rules.md、agents-rules.md）の削除

## 境界
- セミオートゲートフォールバック条件テーブルの内容自体は変更しない（移動のみ）
- スコープ保護ルールの内容自体は変更しない（移動のみ）
- compaction.md、review-flow.md、completion.mdの変更は行わない

## 依存関係

### 依存する Unit
- Unit 001: ベースライン計測（依存理由: 変更前のサイズを記録しておく必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: rules-core.md + rules-automation.md + rules-reference.md 合計 < 14,732B（元のrules.md + agents-rules.md合計）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- rules-core.md: 質問判断基準、承認プロセス、スコープ保護ルール、AskUserQuestion使用ルール、コード品質基準
- rules-automation.md: セミオートゲート仕様、エクスプレスモード仕様
- rules-reference.md: Depth Level詳細テーブル、設定仕様リファレンス
- agents-rules.mdの「質問と深掘り」「禁止事項」「コンテキスト要約時の情報保持」はrules-core.mdに統合

## 関連Issue
- #519

## 実装優先度
High

## 見積もり
中

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
