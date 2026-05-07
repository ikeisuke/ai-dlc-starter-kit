# Unit: helper の zsh source 互換性保証（必須対象 1 ファイル修正 + 全 helper テスト追加）

## 概要

`skills/aidlc/scripts/lib/predecessor-issue.sh` を zsh interactive shell から `source && 関数呼び出し` した際に `__PRED_SCRIPT_DIR` 解決が失敗する問題を修正する。同時に全 helper 6 ファイルに zsh source 動作確認テストを追加し、AI エージェントがデフォルトシェル（zsh）から手順記述通りに source 呼び出しした場合の互換性を保証する。

## 含まれるユーザーストーリー

- ストーリー 4: helper の zsh source 互換性保証

## 責務

- **必須修正対象 1 ファイル**: `skills/aidlc/scripts/lib/predecessor-issue.sh` の `__PRED_SCRIPT_DIR` 解決を zsh / bash 両対応に修正
  - 現状: `__PRED_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)` が zsh interactive で `BASH_SOURCE` 解決失敗 → 空文字 → cwd 起点で source 失敗
  - 修正案候補（設計フェーズで確定 / `source` 経路で動作するもののみ）:
    1. `${BASH_SOURCE[0]:-${(%):-%N}}` 形式で zsh の `%N` プロンプト展開を fallback として併記（zsh / bash 両対応の最小修正）
    2. helper 内で `[[ -n ${ZSH_VERSION:-} ]]` を判定し zsh 用ロジック（`%N` 展開）を分岐させる方式
  - **採用しない案**: shebang 統一（`#!/usr/bin/env bash`）— 本問題は `source` 経由の関数呼び出しに対する解決策が必要であり、shebang は `source` 経路を改善しないため候補から除外
- **テスト追加対象 6 ファイル**: 以下の helper 群に zsh source 動作確認テストを追加（**追加テスト 6 件以上**）:
  - `aidlc-paths.sh`
  - `aidlc-validate.sh`
  - `aidlc-gh.sh`
  - `aidlc-spool.sh`
  - `predecessor-issue.sh`
  - `retrospective-issue.sh`
- 各テストは `bash -c "source <helper>"` と `zsh -c "source <helper>"` 両方が exit 0 を返し、かつ helper 内の `__*_SCRIPT_DIR` 変数が空でない有効パスとして解決されることを確認（`predecessor_resolve_issue` 等の関数実行はネットワーク依存のため対象外、source 互換性のみ検証）
- 既存の `tests/aidlc-helpers-migration.bats` または新規 bats ファイルに追加
- 履歴記録 (`history/construction_unit04.md`) への変更内容反映

## 境界

- **修正対象は `predecessor-issue.sh` の 1 ファイルに限定**（patch スコープ保護）
- 他 5 ファイル（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `retrospective-issue.sh`）は **テスト追加のみで構造変更しない**
  - テスト実行で問題が発覚した場合は OUT_OF_SCOPE として次サイクル候補とし、本 Unit では fix しない
- helper の責務分離（v2.5.3 Unit 004 の延長）は本 Unit のスコープ外
- Inception / Construction Phase の他 helper（`feedback-mode.sh` / `validate-git.sh` 等）への zsh 互換性確認は本 Unit のスコープ外
- ステップファイル（手順記述）の `source` コマンド表記の bash 強制（`bash -c "source ..."` への統一）は本 Unit のスコープ外（次サイクル候補）

## 依存関係

### 依存する Unit

- なし（論理依存なし）

### 外部依存

- bash 4+
- zsh（テスト実行環境に必須）
- 既存の bats テストフレームワーク

## 非機能要件（NFR）

- **パフォーマンス**: helper の SCRIPT_DIR 解決ロジック変更のみで、関数実行時の性能影響なし
- **セキュリティ**: 既存の path traversal ガード等を維持
- **スケーラビリティ**: 影響なし
- **可用性**: zsh / bash 両対応により AI エージェントの実行環境依存性が解消
- **後方互換**: bash での既存呼び出しは完全互換（exit code / stdout / stderr すべて維持）

## 技術的考慮事項

- zsh の `${(%):-%N}` プロンプト展開は zsh 専用構文。bash では `(%)` パラメータ展開がエラーになるため、shell 判定が必要
- `${BASH_SOURCE[0]:-${(%):-%N}}` は zsh では「`BASH_SOURCE[0]` が空 → `%N` 展開」が期待動作
- shell 判定: `[[ -n ${ZSH_VERSION:-} ]]` で zsh 検出可能
- 多重 source ガード（`__AIDLC_<NAME>_SH_LOADED=1`）への影響なし
- bats テストは `bats-core` 標準で動作。`zsh -c` 呼び出しは bats から問題なく実行可能（bats 自体は bash 動作）
- macOS / Linux 互換性: zsh は両 OS で動作するが、デフォルト zsh バージョンに差異あり（macOS は zsh 5.9 系、Ubuntu は環境依存）

## 関連Issue

- **#659**（[Bug] predecessor-issue.sh の zsh source 互換性問題）— 本 Unit の主対象
- 関連: #643（v2.5.3 Unit 004 で導入した helper 分離が原因）

## 実装優先度

Medium（Should-have / AI エージェント実行環境依存性の解消）

## 見積もり

- 設計フェーズ: 0.5 日（修正アプローチ確定 / shell 判定方針）
- 実装フェーズ: 1.5 日（predecessor-issue.sh 修正 + bats テスト 6 件以上追加 + 検証）
- 合計: **2 日**

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-07
- **完了日**: 2026-05-07
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
