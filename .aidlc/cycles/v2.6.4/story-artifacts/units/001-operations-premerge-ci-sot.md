# Unit: Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化

## 概要

`skills/aidlc/steps/operations/` 配下のマージ前ステップに「CI 通過確認 + 失敗時修復経路 + `check-cycle-phase-completion` 常時実行」フローを Single Source of Truth として明文化する。v2.6.0 サイクルで属人的に対応していた CI 修復経路を、サイクル横断で同じ手順で再現できる状態にする。

## 含まれるユーザーストーリー

- ストーリー 1: Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化（#694）

## 責務

- Operations Phase マージ前ステップに以下 3 セクションを SoT 化:
  1. **マージ前 CI 通過確認**: `gh pr checks <PR>` / `gh run list --branch <branch>` での全 CI ジョブ通過確認手順
  2. **CI 失敗時の修復経路**: (a) 修復可能（テスト・コード修正）/ (b) 修復不能（環境依存・flaky）/ (c) 構造的不整合（Unit 跨ぎ）の 3 分岐
  3. **`check-cycle-phase-completion` の常時実行**: マージ前ステップで明示呼び出しを SoT 化
- 関連スキル（`aidlc:reviewing-operations-premerge` 等）との重複・補完関係の明示
- 既存ステップ参照経路の破壊防止

## 境界

- 本 Unit は **docs のみ** の改修（スクリプト変更・新規スクリプト追加は本 Unit 対象外）
- `steps/common/preflight.md` への CI 状態確認組み込みは別 Issue として扱う（Intent「除外」節準拠）
- `aidlc:reviewing-operations-premerge` スキル本体の改修は本 Unit 対象外（既存スキルとの「関係明示」のみ）

## 依存関係

### 依存する Unit

- なし（独立 Unit。他 Unit の完了を待たず着手可能）

### 外部依存

- `gh` CLI（`pr checks` / `run list` コマンド）
- `check-cycle-phase-completion` スクリプト（既存）

## 非機能要件（NFR）

- **再現性**: AI エージェントが新規 consumer プロジェクトでも同じ手順を辿れる粒度で記述
- **保守性**: SoT セクションを参照する他ドキュメントは参照に留め、本文の重複を避ける

## 技術的考慮事項

- 配布物 baseline 規約遵守
- ドッグフーディング特殊処理禁止（starter kit 自身か consumer かを判定する分岐を埋め込まない）
- Operations Phase の既存ステップ番号体系を尊重し、追加セクションは適切な位置に挿入する

## 関連Issue

- #694（クローズ対象）

## 実装優先度

High（v2.6.3 振り返り由来、status:in-progress）

## 見積もり

0.5 〜 1 日（docs のみ）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 取り下げ
- **開始日**: 2026-05-17
- **完了日**: 2026-05-17
- **担当**: AI Agent (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -

### 取り下げ理由

v2.6.3 Unit 004（`operations-premerge-ci-sot`、Issue #694）で本 Unit の責務全項目が完全実装済みであることが Construction Phase 着手時の差分突合で判明したため、取り下げる。

**重複の根拠**（v2.6.3 Unit 004 の成果と v2.6.4 Unit 001 責務の対応）:

| v2.6.4 Unit 001 責務 | v2.6.3 Unit 004 既存実装 |
|---|---|
| マージ前 CI 通過確認（`gh pr checks` / `gh run list`） | `operations-release.md §7.12.6.2` |
| CI 失敗時 3 分岐修復経路（修復可 / 修復不能 / 構造的不整合） | `operations-release.md §7.12.6.4` / `§7.12.6.5` |
| `check-cycle-phase-completion` 常時実行 SoT | `operations-release.md §7.12.6.3`（opt-in シグナル方式） |
| `reviewing-operations-premerge` との重複・補完関係明示 | `operations-release.md §7.12.6.1` 観点分担マトリクス / `§7.12.6.6` 役割分担 |
| 既存ステップ参照経路の破壊防止 | v2.6.3 Unit 004 完了時点で達成済み |

該当セクション見出しに `【必須 / Unit 004 / #694 追加】` と明示記載あり、関連 Issue #694 も v2.6.3 で CLOSED 済み。

**Inception 差分検出漏れの追跡**: v2.6.4 Inception Phase 時に v2.6.3 完了サイクルの実装内容との突合が漏れた事象は、振り返り改善として Issue #712 で追跡（本 Unit 取り下げ処理の範囲外）。
