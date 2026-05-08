# Unit: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加

## 概要

`steps/operations/04-completion.md` ステップ 3（バージョンタグ付け）に「リモート CI 自動 tag 機構との競合確認」手順を追加。事前確認 + 衝突時の判定マトリクス（不在 / 同 SHA / 異 SHA）+ fallback 手順を文書化し、Visitory v1.15.0 cycle で観測された tag push reject 時の誤判断リスクを排除する。

## 含まれるユーザーストーリー

- ストーリー 4: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加（#650）

## 責務

- `steps/operations/04-completion.md` ステップ 3 に `git ls-remote --tags origin vX.X.X` による事前確認手順を追加
- リモート tag 状態の判定マトリクス（3 ケース必須: 不在 / 同 SHA 衝突 / 異 SHA 衝突）を表形式（markdown table）で記載。各ケースに実行コマンド 1 つ以上 / 期待結果 1 つ以上 / 次アクション 1 つ以上を必須カラムとして含める
- 同 SHA 衝突時の fallback 手順を 3 項目（ローカル tag 削除 / `git fetch origin tag vX.X.X` / 同期後検証）で文書化
- 異 SHA 衝突時の手順を 3 項目（自動 push 中止 / 差分提示 / ユーザー選択肢提示）で文書化

## 境界

- 既存の `version_tag = false`/`true` 設定の構造変更は行わない（独立した運用補強）
- CI 自動 tag ワークフローのテンプレート提供は行わない（既存運用は各プロジェクト責務）
- bats テスト追加は不要（文書追加が主作業のため、成功基準は grep / markdown 構造検証で機械的にチェック）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- 既存の `steps/operations/04-completion.md` 構造、`git ls-remote` / `git fetch` の標準 git 仕様

## 非機能要件（NFR）

- **パフォーマンス**: `git ls-remote` 1 回追加（リモート問い合わせ 1 ラウンドトリップ）。許容範囲
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 異 SHA 衝突時の自動 push 中止により、ユーザーに判断機会を提供し誤操作リスクを低減

## 技術的考慮事項

- 異 SHA 衝突時のユーザー選択肢: (i) リモート優先（ローカル削除→ fetch 同期）、(ii) ローカル優先（force push、ただし破壊的なので明示確認必須）、(iii) 中断
- 表形式（markdown table）の必須カラム: ケース名 / 検出コマンド / 期待結果 / 次アクション の 4 列以上
- 同 SHA 衝突は CI 自動 tag が正規版である運用の典型ケースなので、ローカル削除→ fetch 同期を推奨パスとして文書化

## 関連Issue

- #650（[Feedback] 04-completion ステップ3 に「リモート CI 自動 tag 機構との競合確認」手順追加）

## 実装優先度

High

## 見積もり

2 時間（04-completion.md ステップ 3 の文書追加 + 判定マトリクス + 3 ケース手順記述）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
