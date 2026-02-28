# Unit: squash retroactiveモード改善

## 概要
squash-unit.shのretroactiveモードにおけるコミットフォーマット依存リスクを軽減する。Construction Phase Phase 1で4つの対策候補を比較検討し設計決定、Phase 2で実装する。

## 含まれるユーザーストーリー
- ストーリー 5: retroactiveモードのコミットフォーマット依存リスク軽減 (#244)

## 関連Issue
- #244

## 責務
- 4つの対策候補（gitトレーラー方式、ハッシュ直接指定、ドライラン必須化、git notes）の比較検討と設計決定
- 採用方式のcommit-flow.mdへの明記と入出力仕様のドキュメント化
- `--dry-run --retroactive`での対象コミット一覧表示の正常動作
- コミットメッセージ表記ゆれ時の具体的なエラーメッセージ出力
- 新方式失敗時のリカバリ手順のcommit-flow.mdへの記載

## 境界
- 通常のsquash（`--base`指定によるreset --soft方式）の動作変更は含まない
- 既存のパターンマッチ方式の削除は含まない（後方互換性のため維持）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **セキュリティ**: 既存の`--base`オプションのrevset演算子混入防止は維持

## 技術的考慮事項
- Construction Phase Phase 1で比較検討し設計決定
- 既存のパターンマッチ方式は後方互換性のため維持
- 変更対象: prompts/package/bin/squash-unit.sh, prompts/package/docs/commit-flow.md

## 実装優先度
High

## 見積もり
中規模（Construction Phase Phase 1で設計決定、Phase 2で実装+ドキュメント化。対象ファイルは2つのみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
