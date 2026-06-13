# Unit: work-item-next.sh（依存解決による次 work item 選定）

## 概要

`work-items/*.md` の frontmatter（status / dependencies）を走査し、依存グラフを解決して次に着手可能な work item を選定するスクリプト `work-item-next.sh` を実装する。

## 含まれるユーザーストーリー

- ストーリー 2: 依存解決で次に着手すべき work item を選定する

## 責務

- frontmatter の status / dependencies の読み取り
- 依存解決ロジック: **新規着手候補の対象 status は `pending` のみ**とし、依存がすべて `done` の `pending` work item を選定する。`done` / `withdrawn` / `blocked` は候補外。`in_progress` の work item が存在する場合の挙動（resume 優先または WARN）を定義する
- 境界条件 (a)〜(e) の処理（pending + 依存 done で選定 / 未完了依存は除外 / withdrawn 依存は候補外 blocked 相当 / 不在 dependency は WARN + 候補外 / 複数候補時の選定順）
- `bash -n` / shellcheck 通過、境界テスト（候補 status 規約 + (a)〜(e)）

## 境界

- frontmatter の atomic 書き込み（`work-item-state.sh` の完全実装は後続 / 本 Unit は読み取り中心）
- develop フロー本体（Unit 003）

## 依存関係

### 依存する Unit

- なし（独立スクリプト。frontmatter 仕様は `docs/v3/data-model.md` §4 を正本とする）

### 外部依存

- frontmatter パースに必要な標準ツール（grep / sed / awk 等）

## 非機能要件（NFR）

- **パフォーマンス**: work item 数が数十件規模で即時応答
- **セキュリティ**: 読み取り専用（状態変更しない）
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

依存解決は `docs/v3/data-model.md` §5.2（dependency 解決規則）を正本とする。`withdrawn` 依存先は `done` と異なり自動充足しない点に注意（§5.2）。frontmatter パースは安全境界が必要なためスクリプト化する（RFC P4）。

## 関連Issue

- なし

## 実装優先度

High

## 見積もり

0.5 サイクル相当

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-14
- **完了日**: 2026-06-14
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
