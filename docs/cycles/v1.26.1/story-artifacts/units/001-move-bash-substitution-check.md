# Unit: Bash Substitution Check移動

## 概要
operations-release.mdからリポジトリ固有の7.6 Bash Substitution Checkを削除し、プロジェクト固有ルール（rules.md）に移動する。後続ステップ番号の繰り上げと関連参照の更新を行う。

## 含まれるユーザーストーリー
- ストーリー 3: Bash Substitution Checkのプロジェクト固有ルールへの移動

## 関連Issue
- #374

## 責務
- operations-release.mdから7.6 Bash Substitution Checkの削除
- 後続ステップ番号の繰り上げ（7.7→7.6, ..., 7.14→7.13）
- rules.mdのカスタムワークフローにBash Substitution Checkを追加
- 既存カスタムワークフロー（バージョンファイル更新、aidlc-setup同期）のステップ番号参照更新
- ステップ番号を参照する他ドキュメントの更新

## 境界
- check-bash-substitution.sh自体の修正は含まない
- operations-release.md以外のフェーズプロンプトは変更しない

## 依存関係

### 依存する Unit
- なし（他Unitのステップ番号参照の基盤となるため、最初に実施）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし（ドキュメント変更のみ）

## 技術的考慮事項
- 編集対象は `prompts/package/` 配下（docs/aidlc/ は直接編集禁止）
- ステップ番号繰り上げの影響範囲が広いため、grep等で網羅的に検索して漏れを防ぐ

## 実装優先度
High

## 見積もり
小（ドキュメント移動とステップ番号更新）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
