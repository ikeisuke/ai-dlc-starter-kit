# Unit: adminマージ禁止・auto-merge対応

## 概要
Operations PhaseのマージフローにCIチェック通過後のauto-merge対応を追加する。

## 含まれるユーザーストーリー
- ストーリー 6: adminマージ禁止・auto-merge対応

## 責務
- operations-release.md（ステップ7.13）へのauto-merge分岐追加
- CI未完了時の`gh pr merge --auto`対応
- auto-merge未サポート時・権限不足時・CLIエラー時のフォールバック
- admin権限によるbypass mergeを許容しない前提をマージフローに明文化（adminバイパスが有効な場合は警告を表示し、設定変更を案内する）
- Branch protection rules設定手順のガイド追記（adminバイパス禁止の設定を含む）

## 境界
- 既存のマージ方法選択（通常/Squash/Rebase）は維持
- 既存のマージ条件を緩和しない
- GitHub側のBranch protection設定変更はガイドで案内するのみ（自動設定は行わない）

## 依存関係

### 依存する Unit
なし

### 外部依存
- GitHub Branch protection rules設定（リポジトリ管理者による設定が前提）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: adminバイパスの防止
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
auto-mergeはリポジトリ設定（Settings → General → Allow auto-merge）の有効化が前提。未設定時はフォールバックで手動マージを案内。

## 関連Issue
- #548

## 実装優先度
Low

## 見積もり
小規模（1ファイルの分岐追加 + ガイド追記）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-08
- **完了日**: 2026-04-08
- **担当**: Claude
- **エクスプレス適格性**: -
- **適格性理由**: -
