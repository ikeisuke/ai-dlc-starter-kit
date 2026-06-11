# status 出力仕様

> **位置づけ（v3.0.0-alpha.2 / Phase 2 skeleton）**: 本ファイルは status コマンドの
> **出力仕様**である。出力生成の実行実装は Phase 3 以降。本ファイルはフェーズ導出の
> 参照先と出力フォーマットを規定する。

## 責務

`state.json` + work item frontmatter を読み取り、フェーズを導出して**現在地・次アクション**
を表示する。**状態を変更しない（読み取り専用）**。

## フェーズ導出

- フェーズ導出ロジックの**正本（SoT）は `docs/v3/data-model.md` §5**。本ファイルは
  導出**結果の表示仕様**を規定し、導出規則そのものを再定義しない。
- 導出は `state.json`（`define_completed` / `release.*`）と work item frontmatter
  （各 `status`）から行う。`current_phase` は状態として保持しない。

### complete 判定（重要）

`complete`（reflect 可能）の判定には、以下の**両方**が必要:

1. `state.json` の `release.merge_approved: true`（ブランチ上の承認記録）
2. PR が実際に **merged** 状態であること（PR 実態）

`merge_approved` 単独では `complete` としない。PR の merged 実態を確認できない場合は
`complete` とせず、release / 警告扱いとする。

> **非規範サマリ**（正本は data-model §5 / 評価順序・`complete` 最優先は §5.1）:
> `release.merge_approved: true` かつ PR merged → complete /
> `define_completed: false`（または state.json 不在）→ define /
> `define_completed: true` かつ未完了 work item あり → develop /
> `define_completed: true` かつ全 work item が done / withdrawn → release 可能。

## 状態読み取りの参照

`state.json` フィールドの読み取りは `scripts/state-read.sh` を用いる（実行実装は Phase 3。
本 skeleton は参照に留める）。

## 出力フォーマット

### 通常時（active cycle あり）

以下の項目を表示する（`docs/v3/workflow.md` §3.5 の出力例と一致）:

- `Cycle`: 対象サイクル識別子
- `Phase`: 導出フェーズ（導出根拠を併記）
- `Current work item`: 現在の work item（size / risk / status）
- `Completed`: 完了数 / 総数（done / withdrawn の内訳）
- `Blocked`: blocked 状態の work item（なければ `none`）
- `Remaining`: 残りの work item
- `Suggested command`: 次に実行すべきコマンド

出力例:

```text
Cycle: v3.0.0
Phase: develop (derived: define_completed=true, 2/4 items remaining)
Current work item: 002-normalize-state (size: normal, risk: medium, status: in_progress)
Completed: 2/4 (001-example done, 003-cleanup withdrawn)
Blocked: none
Remaining: 002-normalize-state, 004-review-merge
Suggested command: /aidlc-v3 develop
```

### state.json 不在時

```text
No active cycle found.
Suggested command: /aidlc-v3 define
```
