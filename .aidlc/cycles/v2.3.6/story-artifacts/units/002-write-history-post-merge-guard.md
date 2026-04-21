# Unit: write-history.sh マージ後呼び出しガード + 04-completion.md 禁止記述

## 概要

`skills/aidlc/scripts/write-history.sh` に Operations Phase マージ後の呼び出しを検出・拒否するガードを実装し、併せて `skills/aidlc/steps/operations/04-completion.md` に「7.8〜7.13 以降で write-history.sh を呼ばない」明示的禁止記述を追加する。マージ後に発生する `history/operations.md` への未コミット追記（post-merge-sync.sh 前の差分残存）を防ぐ。

## 含まれるユーザーストーリー

- ストーリー 1.2: マージ後の `write-history.sh` 呼び出しが拒否される（#583-B）

## 責務

- `write-history.sh` にマージ後判定ロジックを追加し、該当時は exit code `3` で拒否 + 標準出力と標準エラーの両方に同一の `error:post-merge-history-write-forbidden:<reason_code>:<diagnostics>` 形式の機械可読メッセージを出力する（設計レビューで決定した両チャネル契約）。stdout 出力は既存 `emit_error` 互換、stderr 出力は Story 1.2 受け入れ基準準拠。
- 判定契約は DR-001 に従う: 第一条件 `--operations-stage=post-merge`、第二条件 `completion_gate_ready=true` AND `gh pr view` で PR が `state=MERGED` の AND 条件。
- 既存の exit code `1` / `2` の意味を維持し、`3` の新規割り当てが既存呼び出し元に副作用を与えないことを保証する。
- `/write-history` スキル SKILL.md（委譲スキル側）の「出力」表に exit code `3`（`error:post-merge-history-write-forbidden`）を追記し、呼び出し側契約との整合を取る。
- テスト整備: `skills/aidlc/scripts/` 配下に回帰検証スクリプト／フィクスチャを追加し、Story 1.2 で定義されたテストケース（`TC_POST_MERGE_REJECT_EXPLICIT` / `TC_POST_MERGE_REJECT_FALLBACK` / `TC_PRE_MERGE_GATE_READY_PASS` / `TC_PRE_MERGE_PASS` / `TC_INCEPTION_PASS`）を実行可能にする。
- `04-completion.md` §5 以降の該当箇所に、マージ後に `write-history.sh` を呼ばない旨の明示的禁止記述と exit 3 の取り扱いを追加する。

## 境界

- `operations-release.md` §7.6 への固定スロット反映ステップ追加は扱わない（Unit 001 の責務）。
- `phase-recovery-spec.md` 本体の仕様記述変更は扱わない（参照のみ）。
- Inception Phase の progress.md 表記変更・CHANGELOG 追記は扱わない（Unit 003 の責務）。
- `/write-history` スキル SKILL.md 側は exit code 表の追記に限定し、引数仕様を破壊的に変更しない（新引数 `--operations-stage` の追加のみ、既存引数は維持）。

## 依存関係

### 依存する Unit

- なし（Unit 001 とは独立に着手可能）

### 外部依存

- なし（シェルスクリプト + 手順書のみ）

## 非機能要件（NFR）

- **互換性**: Inception / Construction の既存呼び出しは挙動を変えない（exit 0 系の appended / created ステータス出力を維持）。
- **明確性**: 拒否時のエラーメッセージは機械可読（`error:post-merge-history-write-forbidden`）かつ人間可読。
- **診断性**: 拒否理由を特定できるよう、判定の根拠（引数値・progress.md 状態）を標準出力と標準エラー両方の機械可読メッセージ内 `<diagnostics>` フィールドに付記する（機密情報は含めない）。

## 技術的考慮事項

- **判定方式**: DR-001 の決定に従い、(a) 第一条件 `--operations-stage=post-merge`、(b) 第二条件 `completion_gate_ready=true` AND `gh pr view` で `state=MERGED` の AND 条件を採用する。`gh` 実行失敗時（`cli_runtime_error` 等）は第二条件を undecidable 扱いとし従来動作（appended / created）を継続する（DR-001 確定）。`gh pr view` 呼び出しはガード判定中に最大 1 回に留める（無駄な再実行を避ける実装最適化）。
- **exit code 設計**: 既存 `1`（引数不正）/ `2`（I/O 失敗）との区別を明確化。`3` の意味を `write-history.sh` 冒頭コメントと `/write-history` スキル SKILL.md の出力表に追記する。
- **テスト戦略**: 既存のテストスクリプト（`scripts/test-*` 等）があれば新規シナリオを追加し、未整備なら最低限のフィクスチャ検証を含める。
- **04-completion.md の記述**: §5（未コミット変更確認）や §7 以降の境界セクションに、禁止記述と exit 3 の取り扱いを追加。重複記述は避ける。

## 関連Issue

- #583（部分対応: パターン B のみ。パターン A は Unit 001）

## 実装優先度

High

## 見積もり

1 日

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-19
- **完了日**: 2026-04-19
- **担当**: Claude Code (v2.3.6 cycle)
- **エクスプレス適格性**: -
- **適格性理由**: -
