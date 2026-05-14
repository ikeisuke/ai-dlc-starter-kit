# Unit: write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化

## 概要

`skills/aidlc/scripts/write-history.sh` の `check_history_staged_status()` と `_commit_operations_round_history()` で重複している「symlink 解決 → repo-root 取得 → repo-root 相対パス正規化」処理を共通ヘルパ関数に統一し、片側だけ修正される保守リスクを排除する（#702）。

## 含まれるユーザーストーリー

- ストーリー 7: write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化（#702）

## 責務

- 共通ヘルパ関数（例: `_resolve_history_filepath_in_repo()`）を追加し、`(repo_root, rel_path)` を出力するインターフェースに統一
- `check_history_staged_status()` と `_commit_operations_round_history()` の双方が共通ヘルパを使用するよう改修し重複コードを解消
- パス解決失敗時のスキップ挙動（warning + return 0）を従来どおり維持
- 双方が同一ヘルパを呼ぶことを bats またはコード差分（静的確認）で検証

## 境界

- `write-history.sh` の履歴記録ロジック本体（追記処理・モード分岐）の変更は行わない
- パス解決の挙動自体の変更は行わない（重複コードの共通化のみ、入出力は等価）
- 外部公開インターフェース（コマンドライン引数）の変更は行わない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `skills/aidlc/scripts/lib/bootstrap.sh`（共通ヘルパの配置先候補）
- `write-history.sh` の既存 bats テスト群（回帰確認）

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし（処理内容は等価）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 既存 bats テストが回帰なく全 pass すること

## 技術的考慮事項

- `bootstrap.sh` が共通ヘルパの配置先候補。配置先（`write-history.sh` 内のローカル関数 / `bootstrap.sh` / 別 lib）は設計時に確定する
- v2.6.2 Unit 003（#677 fix）の Codex レビュー Round 1 LOW #2 指摘が起点

## 関連Issue

- #702

## 実装優先度

Low

## 見積もり

小（重複ロジックの抽出 + 2 箇所の置き換え + bats 回帰確認）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
