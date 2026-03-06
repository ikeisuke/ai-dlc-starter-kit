# Unit: Depth Levelsフェーズプロンプト反映

## 概要
Unit 002で定義したDepth Levels仕様を各フェーズプロンプトに組み込み、成果物詳細度の実際の制御を実装する。

## 含まれるユーザーストーリー
- ストーリー 2: 成果物詳細度の適応的制御（フェーズプロンプト部分）

## 責務
- `prompts/package/prompts/inception.md` にDepth Level判定ロジックを組み込み（ステップ1-5の成果物詳細度調整）
- `prompts/package/prompts/construction.md` にDepth Level判定ロジックを組み込み（Phase 1-2の設計・実装詳細度調整）
- `prompts/package/prompts/operations.md` にDepth Level判定ロジックを組み込み（ステップ1-5の成果物詳細度調整）
- minimal設定時: PRFAQ作成スキップ、受け入れ基準簡略化（主要エラーケースは維持）
- comprehensive設定時: リスク分析・代替案検討等の追加セクション

## 境界
- `docs/aidlc.toml` の設定定義と `common/rules.md` の共通仕様はUnit 002の責務
- テンプレートファイル自体は変更しない（プロンプト内の指示で制御）
- Lite版プロンプト（`prompts/package/prompts/lite/*.md`）は本Unitの対象外。Lite版はすでにPRFAQスキップ等の簡略化を独自に行っており、Depth Level連動は将来サイクルで検討

## 依存関係

### 依存する Unit
- Unit 002: depth-levels-config（依存理由: Depth Levelの設定仕様・共通ルールが定義されている必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A（プロンプト変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 3フェーズプロンプトへの一貫した判定ロジックの組み込み
- 各フェーズの既存ステップ指示を壊さないよう条件分岐で追加

## 実装優先度
High

## 見積もり
中規模（3ファイルへの判定ロジック追加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
