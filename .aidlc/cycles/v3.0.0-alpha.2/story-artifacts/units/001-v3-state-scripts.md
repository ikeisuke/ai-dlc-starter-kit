# Unit: v3 state スクリプト基盤

## 概要

`skills/aidlc-v3/scripts/` に state.json を操作する 3 本のスクリプト（state-read.sh / state-write.sh / state-validate.sh）を作成する。`docs/v3/data-model.md` §3 の確定スキーマに基づき、read（フィールド抽出）/ write（atomic 書き込み）/ validate（schema 検証）の最小 API を確立する。

## 含まれるユーザーストーリー
- ストーリー 1: state.json 操作スクリプト基盤を確立する

## 責務
- `state-read.sh`: state.json から指定フィールド（`schema_version` / `current_cycle` / `define_completed` / `release.*` / `updated_at`）を抽出
- `state-write.sh`: state.json を temp file + mv で atomic に書き込み（schema validation + 許可フィールド更新に限定）
- `state-validate.sh`: 必須フィールド（`schema_version` / `current_cycle` / `define_completed` / `release` / `updated_at`）と `release` サブフィールド（`pr_number`: integer or null / `ready`: boolean / `merge_approved`: boolean、`docs/v3/data-model.md` §3.2）の存在・型・JSON 妥当性を検証し exit code で結果を返す

## 境界
- 許可/禁止状態遷移ルールの具体化は Phase 3（flow 実装）へ defer（本 Unit は schema validation + atomic write + 許可フィールド更新まで）
- define / status フロー本体の実装は対象外（Unit 003 は手順記述のみ）
- state.json schema の正本は `docs/v3/data-model.md` §3（本 Unit は実装側として準拠する）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- 入力: `docs/v3/data-model.md` §3（state.json schema / 必須フィールド / 型）
- ツール: `jq`（JSON 操作 / 環境に存在）

## 非機能要件（NFR）
- **atomic 性**: write は temp file + mv で中断時の破損を防ぐ
- **可搬性**: `bash -n` 通過、shellcheck 重大警告なし、macOS / Linux 両対応
- **共存**: 成果物は `skills/aidlc-v3/scripts/` に限定し、v2 に非影響

## 技術的考慮事項
- `updated_at` は必須フィールド（SoT 確認済み）。validate で欠落も無効判定する
- コマンド置換 `$(...)` / backtick をスクリプト内 AI 生成時に誤用しない（本リポジトリ規約 / Issue #697）

## 関連Issue
- なし

## 実装優先度
High

## 見積もり
スクリプト 3 本（小〜中）。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-11
- **完了日**: 2026-06-11
- **担当**: Claude Code
- **エクスプレス適格性**: -
- **適格性理由**: -
