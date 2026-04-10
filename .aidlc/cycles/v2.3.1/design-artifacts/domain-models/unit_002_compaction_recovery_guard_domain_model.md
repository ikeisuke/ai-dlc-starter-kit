# ドメインモデル: コンパクション復帰時の不変ルール違反防止

## 概要

コンパクション復帰検出時にステップファイル再読み込みを強制するガードメカニズムのモジュール設計。LLM がコンパクション後のサマリーを「覚えている」と判断してステップファイル読み込みを省略する問題を防止する。

**重要**: このモジュール設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## モジュール構成

本Unitの変更対象は3層構造のうち Detection Boundary と Guard Policy の2層。Decision Spec は変更しない。

### Detection Boundary（`session-continuity.md`）

コンパクション復帰の検出と `compaction.md` への即時委譲を担う。

- **責務**: コンパクション復帰判定 → `compaction.md` への即時委譲 → 自身の処理終了
- **出力**: 委譲シグナル（`compaction.md` を読み込ませる指示）
- **不変条件**: 委譲後に追加処理を行わない（再実行ポリシーの定義・ガード実行は責務外）

### Guard Policy（`compaction.md`）

通常フロー継続禁止ガードの発動、再実行要求メッセージの出力、サマリーテンプレートの管理を担う。

- **責務**: ガード発動 → フロー終了 → 再実行要求メッセージ出力
- **入力契約**: `CompactionRecoveryContext`（下記参照）
- **出力**: ガード発動メッセージ（定型文）、サマリーテンプレート
- **不変条件**:
  - コンパクション復帰後は通常フローの継続が禁止される
  - ガード発動後は必ず再実行要求メッセージが出力される

### Decision Spec（`phase-recovery-spec.md`）

復帰すべきフェーズとステップの判定ロジック。本Unitでは変更しない（消費のみ）。

## 入力契約: CompactionRecoveryContext

ガード発動メッセージのフェーズ値確定に必要な入力。

| フィールド | 型 | 供給元 | 説明 |
|-----------|------|-------|------|
| phase | String / None | `judge()` の戻り値 `PhaseRecoveryJudgment.phase.result`、または `undecidable` 時は None | 復帰先フェーズ（inception / construction / operations） |

**フェーズ値の確定フロー**:
- `judge()` が有効なフェーズを返す場合: `/aidlc {phase}` を含むメッセージを出力
- `judge()` が `undecidable` を返す場合、または `judge()` 実行前にガードが発動する場合: `/aidlc` のみを案内（引数なし実行でブランチ名から自動判定）

## 依存方向

```text
session-continuity.md (Detection Boundary)
  → compaction.md (Guard Policy)
    → phase-recovery-spec.md (Decision Spec) [消費のみ、変更なし]
    → index.md (各フェーズ) [既存依存、変更なし]
    → rules-automation.md [既存依存、変更なし]
    → scripts/read-config.sh [既存依存、変更なし]
```

全依存が一方向。循環依存なし。本Unitで追加される依存はなく、既存の依存構造を維持する。

## 不変条件

1. コンパクション復帰後は通常フローの継続が禁止される（SKILL.md 不変ルール#4）
2. ガード発動後は必ず再実行要求メッセージが出力される
3. `session-continuity.md` は委譲後に追加処理を行わない
4. `phase-recovery-spec.md` の判定ロジックは変更しない

## ユビキタス言語

- **コンパクション**: Claude Code がコンテキストウィンドウの限界に近づいた際に自動で会話履歴を要約する機能
- **コンパクション復帰**: コンパクション後に作業を再開すること
- **通常フロー継続禁止ガード**: コンパクション復帰後にステップファイルを再読み込みせずにフローを継続することを禁止する仕組み
- **委譲境界**: `session-continuity.md` が `compaction.md` に制御を渡し、自身の処理を終了する境界点
- **再実行要求**: ユーザーに `/aidlc {phase}`（フェーズ確定時）または `/aidlc`（不確定時）の再実行を求めるメッセージ出力

## 不明点と質問（設計中に記録）

（なし - Unit定義と計画で要件が明確）
