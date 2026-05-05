# Construction Phase 進捗管理

## Unit一覧

| Unit | タイトル | 状態 | Phase 1（設計） | Phase 2（実装） | 完了日 |
|------|---------|------|-----------------|-----------------|--------|
| 001 | feedback_mode 5 値拡張 + マイグレーション + 初回 wizard（基盤） | 完了 | 完了 | 完了 | 2026-05-05 |
| 002 | retrospective Issue 一本化 + spool + mirror_state ラベル化 | 完了 | 完了 | 完了 | 2026-05-05 |
| 003 | 主因分類 LLM 下書き + 人間確認運用 | 未着手 | - | - | - |
| 004 | predecessor handoff の Issue 検索化 | 未着手 | - | - | - |
| 005 | #616 マージ前 write-history 追加コミット漏れガード | 未着手 | - | - | - |

## 依存関係

- Unit 001（基盤）→ Unit 002 → (Unit 003, Unit 004 並列可)
- Unit 005 は依存なしで並列着手可（ファイル競合リスクあり、Unit 001/002 主要改修後を推奨）

## 実装順序の推奨

1. Unit 001（基盤）
2. Unit 002（Issue 化本体、Unit 001 依存）
3. Unit 003 / Unit 004（Unit 002 後、並列可）
4. Unit 005（並列、ただし Unit 001/002 後を推奨）

## 現在のステップ

Unit 002 完了。次回: Unit 003（主因分類 LLM 下書き + 人間確認運用）または Unit 004（predecessor handoff の Issue 検索化）

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc construction`
