# Unit: aidlc-v3 skill 骨組み

## 概要

`skills/aidlc-v3/SKILL.md`（ルーティング）と `steps/define.md` / `steps/status.md`（手順・出力仕様）を作成する。v3 の define 手順と status 出力仕様を**読める形**で固定し、Phase 3 の実装インプットを明確化する。フロー実行実装は含まない。

## 含まれるユーザーストーリー
- ストーリー 3: aidlc-v3 skill の骨組みを作る

## 責務
- `SKILL.md`: define / develop / release / reflect / status / doctor + 連続実行ラッパ `express` + 旧名エイリアス（inception / construction / operations / retrospective）+ 引数なし実行のフェーズ導出ルーティング + コアルール参照。`express` は単一 work item サイクル専用ラッパ（複数 work item / risky は個別実行へ案内、`docs/v3/workflow.md` §4）
- `steps/define.md`: define フロー Step 1-4（環境チェック / Intent 定義 / Work Item 分割 / 初期化）を読める手順として記述
- `steps/status.md`: status 出力仕様（フェーズ導出ロジック + 出力例。complete 判定は `release.merge_approved` と PR merged 実態の両方を参照）

## 境界
- define / status フローの**実行実装**は対象外（Phase 3）。本 Unit は手順・出力仕様の記述に留める
- `marketplace.json` への `aidlc-v3` 登録（`/aidlc-v3` 起動有効化）は対象外（Phase 3 以降へ defer）
- `steps/develop.md` / `release.md` / `recovery.md` / `rules.md` は対象外（後続 Phase）
- フェーズ導出ロジックの正本は `docs/v3/data-model.md` §5。本 Unit は導出結果を参照する（再定義しない）

## 依存関係

### 依存する Unit
- 001-v3-state-scripts（依存理由: `status.md` が state-read.sh を参照するため、スクリプトのパス・I/F が確定している必要がある）
- 002-v3-templates（依存理由: `define.md` の Work Item 分割・初期化手順がテンプレートを参照するため、テンプレートのパス・構成が確定している必要がある）

### 外部依存
- 入力: `docs/v3/workflow.md` §2 / §3.1 / §3.5（コマンド設計 / define / status）, `docs/v3/data-model.md` §5（フェーズ導出）, `docs/v3/rfc.md` DG-1（コマンド名）

## 非機能要件（NFR）
- **整合性**: コマンド名・フェーズ導出・schema が確定 RFC と一致
- **可読性**: AI エージェントが 1 ファイル読了で define / status の責務を把握できる
- **共存**: 成果物は `skills/aidlc-v3/` に限定し、v2 に非影響

## 技術的考慮事項
- コマンド名は `develop`（`build` / `implement` はエイリアスにもしない / RFC DG-1）
- define.md / status.md の参照パス（templates/ / scripts/）が Unit 001/002 の実体と一致すること

## 関連Issue
- なし

## 実装優先度
High（Unit 001 / 002 完了後）

## 見積もり
SKILL.md + steps 2 ファイル（中）。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
