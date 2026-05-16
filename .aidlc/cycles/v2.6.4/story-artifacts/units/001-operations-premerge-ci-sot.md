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

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
