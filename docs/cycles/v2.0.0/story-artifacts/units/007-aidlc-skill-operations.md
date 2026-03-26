# Unit: aidlcスキル - Operations Phase

## 概要
`steps/operations/` を作成し、operations.md（779行）を分割・移行する。

## 含まれるユーザーストーリー
- ストーリー 7: Operations Phaseスキル化

## 責務
- `steps/operations/01-setup.md`: セットアップ（サイクル確認、進捗管理）
- `steps/operations/02-deploy.md`: デプロイ準備・実行
- `steps/operations/03-release.md`: リリース準備（CHANGELOG、バージョン更新、PR管理）
- `steps/operations/04-completion.md`: 完了処理（履歴記録、コミット）

## 境界
- 共通ステップは参照のみ
- operations-release.md の統合も含む

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
- 779行のプロンプトを4ファイルに分割
- operations-release.mdとの統合方針を設計時に決定

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
