# Unit: squash-unit.sh 複数 --message 段落結合修正（#735）

## 概要

`skills/aidlc/scripts/squash-unit.sh` の複数 `--message` footgun（subject 行消失 / Co-Authored-By 重複）を修正し、`git commit` 準拠の段落結合に対応する。回帰テストを追加する。

## 含まれるユーザーストーリー
- ストーリー 4: squash-unit.sh を複数 --message で安全に呼ぶ（#735）

## 責務
- `parse_args` の `--message` ハンドラを後勝ち上書きから**段落結合**（1 個目 = subject、2 個目以降 = 本文段落 / `git commit` 準拠）に変更。
- Co-Authored-By トレーラの別経路付与と最後の `--message` の二重出力を解消。
- 複数 `--message` / Co-Authored-By 重複の回帰テストを `skills/aidlc/scripts/tests/` に追加。
- `--help` の `--message` 説明を複数指定対応に更新。

## 境界
- v2 ツール（`skills/aidlc/`）の修正であり、v3 サブシステム（`skills/aidlc-v3/`）には触れない。
- `--message-file` 経路の新設は本 Unit のスコープ外（段落結合方針を採用）。
- 単一 `--message` の既存挙動は後方互換を維持する。

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `git`（commit / amend）
- 既存テストハーネス（`skills/aidlc/scripts/tests/`）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし。
- **セキュリティ**: コミットメッセージに機密情報を混入させない。
- **スケーラビリティ**: 任意個数の `--message` を段落結合できる。
- **可用性**: 該当なし。

## 技術的考慮事項
- コミットメッセージ生成は `git commit -m`（複数 -m）相当の段落結合に揃える。Bash ツール経由のコマンド置換禁止規約（#697）に注意。
- 既存の Co-Authored-By 付与経路と新しい段落結合の責務境界を明確化する。

## 関連Issue
- Closes #735（squash-unit.sh 複数 --message footgun）

## 実装優先度
High

## 見積もり
0.5 サイクル日相当（修正 + 回帰テスト）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-28
- **完了日**: 2026-06-28
- **担当**: Claude (Construction Phase)
- **エクスプレス適格性**: -
- **適格性理由**: -
