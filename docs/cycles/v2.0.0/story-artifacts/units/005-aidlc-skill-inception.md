# Unit: aidlcスキル - Inception Phase

## 概要
`steps/inception/` を作成し、inception.md（1,436行）を分割・移行する。

## 含まれるユーザーストーリー
- ストーリー 5: Inception Phaseスキル化

## 責務
- `steps/inception/01-setup.md`: セットアップ（サイクル作成、ブランチ確認、進捗管理）
- `steps/inception/02-intent.md`: Intent明確化
- `steps/inception/03-stories.md`: ユーザーストーリー作成
- `steps/inception/04-units.md`: Unit定義
- `steps/inception/05-prfaq.md`: PRFAQ作成
- `steps/inception/06-completion.md`: 完了処理（サイクルラベル、履歴記録、PR作成、コミット）

## 境界
- 共通ステップ（preflight, rules等）は参照のみ（Unit 004で実装済み）
- エクスプレスモードの遷移ロジックはSKILL.md（Unit 004）に含まれる

## 依存関係

### 依存する Unit
- Unit 004: aidlcスキル - 共通基盤（依存理由: SKILL.mdのフェーズルーティングと共通ステップが必要）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 各ステップファイルのサイズを適切に保つ
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- 1,436行のプロンプトを6ファイルに分割（各200-300行程度）
- v1との動作同等性を確認する必要がある

## 実装優先度
High

## 見積もり
中〜大

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
