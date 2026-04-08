# Unit: Construction フェーズのインデックス化

## 概要

Unit 001 で確立したインデックス構造を Construction Phase に展開し、Construction 初回ロードを最適化する。

## 含まれるユーザーストーリー

- ストーリー2: Construction フェーズインデックス化

## 責務

- `steps/construction/` 配下にフェーズインデックスファイルを作成し、Unit 001 と同じ3点（目次・分岐・判定チェックポイント）を集約する
- Construction フェーズの全ステップ（01-setup.md 〜 04-completion.md）から、インデックスに集約された分岐・判定の重複記述を削除する
- `SKILL.md` の引数ルーティング（`cycle/*` ブランチ判定および `action=construction`）をインデックスファイル読み込みに更新する
- **Unit 002 で策定された共通判定仕様（`steps/common/phase-recovery-spec.md`）に基づき、Construction インデックスに「現在位置判定セクション」を実装する**
- Construction フェーズ固有の判定ポイント（Unit 実装状態、Phase 1 完了、Phase 2 完了、Unit 完了等）を共通仕様にマップする
- 正常系・異常系の検証を Construction フェーズで実施する（Unit 002 で定義された4系統のうち Construction 固有のケース）
- Construction 初回ロードが 17,980 tok 以下（v2.2.3 ベースライン維持）であることを確認する
- 最低1つの Unit（サンプル Unit「dummy-feature」）での Phase 1 → Phase 2 → 完了処理の回帰検証を実施する

## 境界

- **含まない**: Inception / Operations フェーズのインデックス化（Unit 001 / 004）
- **含まない**: 共通判定仕様そのものの策定（Unit 002 の責務。本 Unit では策定された仕様を Construction に適用するのみ）
- **含まない**: Tier 2 施策（Unit 005）

## 依存関係

### 依存する Unit

- Unit 001（Inception インデックス構造のパイロット、共通仕様の確立）
- Unit 002（汎用復帰判定基盤、Construction インデックスに組み込むため）

### 外部依存

- tiktoken (cl100k_base) — 初回ロード計測

## 非機能要件（NFR）

- **パフォーマンス**: Construction 初回ロード 17,980 tok 以下を維持
- **可用性**: 既存 Construction フローの動作を破壊しない（回帰検証で確認）

## 技術的考慮事項

- **Unit 001 との整合**: Unit 001 で確立した構造仕様をそのまま流用し、Construction 固有のステップ名・分岐だけを追加する
- **サンプル Unit の選定**: 回帰検証には軽量な Unit（1 ファイル変更程度）を選ぶ。本サイクルの Unit 001 自体を検証対象にすることも検討
- **エクスプレス適格性**: Unit 001 / 002 完了後は構造が確立しているため、パターン適用のみで比較的単純。小〜中規模

## 関連Issue

- #519: コンテキスト圧縮メイン Issue

## 実装優先度

High

## 見積もり

小〜中規模（1-2 日相当）。Unit 001 のパターンを Construction に適用 + 回帰検証。

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
