# Unit: バリデーションスクリプト統合

## 概要
validate-uncommitted.shとvalidate-remote-sync.shを`validate-git.sh`に統合し、サブコマンド方式で一括実行も可能にする。

## 含まれるユーザーストーリー
- ストーリー 3: バリデーションスクリプトの統合 (#248)

## 責務
- `validate-git.sh`の新規作成（uncommitted / remote-sync / all サブコマンド）
- 旧スクリプトの互換ラッパー化（非推奨警告付き）
- operations-release.md（分割後）の呼び出し箇所更新

## 境界
- バリデーションロジック自体の変更は行わない（既存ロジックの移植）
- 新しいバリデーション種別の追加は行わない

## 依存関係

### 依存する Unit
- Unit 001: operations.md分割リファクタリング（依存理由: 呼び出し箇所がoperations-release.mdに移動するため、分割完了後に更新する必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 既存と同等の実行速度
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 将来のバリデーション種別追加が容易なサブコマンド構造
- **可用性**: 該当なし

## 技術的考慮事項
- 正本は `prompts/package/bin/validate-git.sh`（新規）
- 旧スクリプトは `prompts/package/bin/validate-uncommitted.sh` と `validate-remote-sync.sh`
- 出力形式は既存と完全互換（status:ok|warning|error）
- 終了コード: ok/warning=0、error=1
- 関連Issue: #248

## 実装優先度
Medium

## 見積もり
中（スクリプト統合 + ラッパー作成 + プロンプト更新）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
