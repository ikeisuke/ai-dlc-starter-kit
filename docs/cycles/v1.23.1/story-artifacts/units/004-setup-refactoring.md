# Unit: セットアップ処理リファクタリング

## 概要
setup-prompt.mdの責務分類と、aidlc-setupスキルへの移管計画文書化を行う。

## 含まれるユーザーストーリー
- ストーリー5: セットアップ処理の責務分類
- ストーリー6: aidlc-setupスキルへの移管計画文書化

## 成果物
- `docs/cycles/v1.23.1/requirements/setup-classification.md`: setup-prompt.mdの責務分類結果
- `docs/cycles/v1.23.1/requirements/setup-migration-plan.md`: aidlc-setupスキルへの移管計画

## 責務
- setup-prompt.mdの全セクションを「初回セットアップ固有」「アップグレード固有」「共通」に分類し、`setup-classification.md`に記録
- aidlc-setupスキルへの移管対象・残存項目・技術的課題を`setup-migration-plan.md`に文書化

## 境界
- setup-prompt.mdの実際のスキル化は含まない（次サイクル）
- aidlc-setup.shの機能変更は含まない
- 新規スクリプトの作成は含まない

## 依存関係

### 依存する Unit
- なし（Unit 003との弱依存: Unit 003完了後にsetup-prompt.md内のInception Phase参照が影響を受けていないか差分確認を実施する。ただし実装ブロッカーではない）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし（文書作成のみ）

## 技術的考慮事項
- setup-prompt.mdは1266行の大型プロンプト
- 分類結果は`docs/cycles/v1.23.1/requirements/setup-classification.md`に記録する（setup-prompt.md自体へのコメント追記は行わない）
- 移管計画文書は`docs/cycles/v1.23.1/requirements/setup-migration-plan.md`に作成する

## 実装優先度
Medium

## 見積もり
中規模（分析・文書化）

## 関連Issue
- なし（Issue外の対応項目）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
