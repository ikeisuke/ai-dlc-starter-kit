# Unit: status 出力拡充

## 概要

`/aidlc-v3 status` の出力を `docs/v3/workflow.md §3.5` の出力例に揃え、残作業・次の推奨コマンド・導出根拠を含む現在地表示に拡充する。

## 含まれるユーザーストーリー
- ストーリー 3: status の現在地表示拡充

## 責務
- `skills/aidlc-v3/steps/status.md` の拡充: active cycle 時に `Cycle` / `Phase`（導出根拠併記）/ `Current work item`（size・risk・status）/ `Completed`（done・withdrawn 内訳）/ `Blocked` / `Remaining` / `Suggested command` を出力する仕様に更新。
- state.json 不在時に `No active cycle found.` + `Suggested command: /aidlc define` を出力する仕様を明記。
- 出力整合の検証（テストまたは再現可能なドライ検証）を追加。

## 境界
- フェーズ導出規則そのものは再定義しない（SoT は `data-model.md §5`）。status は導出結果の表示のみ。
- doctor の `[phase]` 導出 code 化は本 Unit の対象外（alpha.8 / Unit 003 doctor で defer 反映済み）。
- status は状態を変更しない（読み取り専用）。

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `scripts/state-read.sh`（state.json 読み取り）
- work item frontmatter（`lib/frontmatter.sh` 経由）
- `docs/v3/workflow.md §3.5` / `docs/v3/data-model.md §5`（SoT 参照）

## 非機能要件（NFR）
- **パフォーマンス**: 読み取り専用・軽量。
- **セキュリティ**: 該当なし（公開可能な状態情報のみ）。
- **スケーラビリティ**: work item 数に比例した表示。
- **可用性**: state.json 不在でも No active cycle を案内。

## 技術的考慮事項
- 出力フォーマットは workflow.md §3.5 の出力例を正本として一致させる。

## 関連Issue
- Relates to #736（v3 リニューアル Epic / Phase 6）

## 実装優先度
High

## 見積もり
0.5 サイクル日相当（仕様拡充 + 出力整合検証）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
