# Unit: retrospective-issue.sh の zsh source 互換性復元

## 概要

`skills/aidlc/scripts/lib/retrospective-issue.sh` の `__RETRO_ISSUE_SCRIPT_DIR` 解決を v2.5.4 Unit 004 と同じ shell 判定分岐方式（`if [[ -n "${ZSH_VERSION:-}" ]]; then ${(%):-%N}; else ${BASH_SOURCE[0]}; fi`）に揃える。`tests/aidlc-helpers-zsh-source.bats` の `retrospective-issue.sh` zsh skip マーカーを解除して bash/zsh 両 source 検証を通常実施に戻す。v2.5.4 Inception DR-001 で OUT_OF_SCOPE 化された対象を本サイクルで対応。

## 含まれるユーザーストーリー

- ストーリー 2: retrospective-issue.sh の zsh source 互換性復元（#661）

## 責務

- `skills/aidlc/scripts/lib/retrospective-issue.sh:43` 付近の `__RETRO_ISSUE_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" ...)` を v2.5.4 Unit 004 と同じパターンに置換
- `tests/aidlc-helpers-zsh-source.bats` の `retrospective-issue.sh` テストから `skip "OUT_OF_SCOPE: see backlog #..."` マーカーを削除
- bash/zsh 両 source 検証 + SCRIPT_DIR 検証が通常実行されることを確認

## 境界

- 他の helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `predecessor-issue.sh`）の追加 refactor は行わない（OUT_OF_SCOPE）
- `retrospective-issue.sh` の API 変更（関数シグネチャ変更等）は行わない（互換性維持）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- v2.5.4 Unit 004（#659）で確立された `predecessor-issue.sh` の修正パターン（参考実装として活用）

## 非機能要件（NFR）

- **パフォーマンス**: shell 判定分岐 1 回追加のため計測対象外
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: bash / zsh 両 source 経路で動作（AI エージェント実行環境互換性向上）

## 技術的考慮事項

- v2.5.4 Unit 004 と同じ修正パターンを踏襲し独自実装は避ける
- bats skip 解除後、CI で `bash` / `zsh` 両方の source 検証が走ることを確認
- 検証手段: 既存テストの skip 解除で要件充足（新規 bats テスト追加は不要）

## 関連Issue

- #661（[Backlog] retrospective-issue.sh の zsh source 互換性問題（v2.5.4 Unit 004 OUT_OF_SCOPE））

## 実装優先度

High

## 見積もり

1 時間（shell 判定分岐パターン置換 + skip マーカー削除 + 動作確認）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
