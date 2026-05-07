# Construction Phase 進捗管理

## Unit一覧

| Unit | タイトル | 状態 | Phase 1（設計） | Phase 2（実装） | 完了日 |
|------|---------|------|-----------------|-----------------|--------|
| 001 | 振り返り対話強制ガード強化（Operations §1） | 完了 | 完了 | 完了 | 2026-05-07 |
| 002 | write-history skill にモード追加（unit-complete-short-note + operations-round） | 完了 | 完了 | 完了 | 2026-05-07 |
| 003 | 事実テーブル先抽出ステップ + 推定値検出ガード（#634 絞込） | 未着手 | 未着手 | 未着手 | - |
| 004 | predecessor-issue.sh の retrospective-issue.sh 横依存解消（用途別 helper 独立化） | 未着手 | 未着手 | 未着手 | - |

## 依存関係

- 論理依存: なし（4 Unit すべて独立した価値を提供）
- 実装順依存:
  - Unit 001 → Unit 003（同一ファイル `skills/aidlc/steps/operations/04-completion.md` §1 を改訂するためコンフリクト回避）
  - Unit 002A / 2B（同一スクリプト `skills/aidlc/scripts/write-history.sh` 改修のため、Unit 002 として 1 Unit に統合）
  - Unit 004 は完全独立で並列実装可能

## 実装順序の推奨

1. Unit 004（独立 / 並列実装可 / refactor）
2. Unit 002（独立 / write-history skill 改修 / Must-have）
3. Unit 001（Operations §1 対話強制ガード強化 / Must-have）
4. Unit 003（Unit 001 後 / 04-completion §1 への追記）

または:

- Unit 004 と Unit 002 を並列実装し、その後 Unit 001 → Unit 003 を逐次実装

## 現在のステップ

Unit 001 / Unit 002 完了。次は Unit 003（事実テーブル先抽出ステップ + 推定値検出ガード）に着手予定。

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc construction`
