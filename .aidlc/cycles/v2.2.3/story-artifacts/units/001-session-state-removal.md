# Unit: session-state.md廃止

## 概要
session-state.mdの生成・復元ロジックを廃止し、progress.mdベースの復元に一本化する。

## 含まれるユーザーストーリー
- ストーリー 1: session-state.md廃止

## 責務
- session-continuity.mdからsession-state.md関連ロジックを除去
- 各フェーズの01-setup.md（inception, construction, operations）からsession-state.md参照を除去
- context-reset.mdからsession-state.md生成指示を除去
- compaction.mdからsession-state.md参照を除去
- guides/troubleshooting.mdからsession-state.md関連記述を除去

## 境界
- progress.mdの復元ロジック自体の変更は行わない（既存フォールバックをそのまま使用）
- session-continuity.mdファイル自体は残す（内容を簡略化）

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
7ファイルの参照除去。session-continuity.mdはprogress.mdベースの復元のみに簡略化。

## 関連Issue
- #547

## 実装優先度
High

## 見積もり
小規模（7ファイルの参照除去・簡略化）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
