# Unit: aidlcスキル - Construction Phase

## 概要
`steps/construction/` を作成し、construction.md（1,233行）を分割・移行する。

## 含まれるユーザーストーリー
- ストーリー 6: Construction Phaseスキル化

## 責務
- `steps/construction/01-setup.md`: セットアップ（サイクル確認、Unit選択、進捗管理）
- `steps/construction/02-design.md`: 設計（ドメインモデル、論理設計）
- `steps/construction/03-implementation.md`: 実装（コード生成、テスト、Self-Healing）
- `steps/construction/04-completion.md`: 完了処理（レビュー、コミット、次Unit選択）

## 境界
- 共通ステップは参照のみ
- Self-Healingの基本ロジックは維持（機能変更なし）

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
- 1,233行のプロンプトを4ファイルに分割
- Self-Healingループの動作を維持

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
