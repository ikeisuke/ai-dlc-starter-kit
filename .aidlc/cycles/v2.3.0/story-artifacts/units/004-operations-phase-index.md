# Unit: Operations フェーズのインデックス化

## 概要

Unit 001 で確立したインデックス構造を Operations Phase に展開し、Operations 初回ロードを最適化する。

## 含まれるユーザーストーリー

- ストーリー3: Operations フェーズインデックス化

## 責務

- `steps/operations/` 配下にフェーズインデックスファイルを作成し、Unit 001 と同じ3点（目次・分岐・判定チェックポイント）を集約する
- Operations フェーズの全ステップ（01-setup.md 〜 04-completion.md）から、インデックスに集約された分岐・判定の重複記述を削除する
- `SKILL.md` の引数ルーティング（`action=operations`）をインデックスファイル読み込みに更新する
- **Unit 002 で策定された共通判定仕様（`steps/common/phase-recovery-spec.md`）に基づき、Operations インデックスに「現在位置判定セクション」を実装する**
- Operations フェーズ固有の判定ポイント（デプロイ計画、リリース準備、PR マージ等）を共通仕様にマップする
- 正常系・異常系の検証を Operations フェーズで実施する（Unit 002 で定義された4系統のうち Operations 固有のケース）
- Operations 初回ロードが 17,209 tok 以下（v2.2.3 ベースライン維持）であることを確認する
- サンプルサイクル（完了済み Construction 成果物を持つ）での Operations Phase 回帰検証を実施する

## 境界

- **含まない**: Inception / Construction フェーズのインデックス化（Unit 001 / 003）
- **含まない**: 共通判定仕様そのものの策定（Unit 002 の責務。本 Unit では策定された仕様を Operations に適用するのみ）
- **含まない**: `operations-release.md` のスクリプト化（Unit 005）
- **含まない**: Tier 2 施策全般（Unit 005）

## 依存関係

### 依存する Unit

- Unit 001（Inception インデックス構造のパイロット、共通仕様の確立）
- Unit 002（汎用復帰判定基盤、Operations インデックスに組み込むため）

### 外部依存

- tiktoken (cl100k_base) — 初回ロード計測
- `gh` CLI — 回帰検証で PR 操作の dry-run に使用

## 非機能要件（NFR）

- **パフォーマンス**: Operations 初回ロード 17,209 tok 以下を維持
- **可用性**: 既存 Operations フローの動作を破壊しない（回帰検証で確認）

## 技術的考慮事項

- **Unit 001 / 003 との整合**: パターン適用のみで大半の実装が進む。Operations 固有の「リリース準備・PR 管理」セクションへの対応が必要
- **operations-release.md の扱い**: 本 Unit ではインデックスからの参照形式には変更しない。スクリプト化は Unit 005 で対応
- **回帰検証**: `gh pr create` / `gh pr edit` を dry-run で実行して引数を捕捉する（実際に PR を作らない）

## 関連Issue

- #519: コンテキスト圧縮メイン Issue

## 実装優先度

High

## 見積もり

小〜中規模（1-2 日相当）。Unit 001 のパターンを Operations に適用 + 回帰検証。

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
