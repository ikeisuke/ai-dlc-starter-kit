# Unit: operations-release.sh cmd_squash_712 への --cycle バリデーション導入

## 概要

`skills/aidlc/scripts/operations-release.sh` の `cmd_squash_712` に対し、`--cycle` 引数の包括的なバリデーション（既存の `validate_cycle`）を導入し、パストラバーサル文字列による参照先パスの逸脱を防ぐ（#701）。

## 含まれるユーザーストーリー

- ストーリー 3: operations-release.sh cmd_squash_712 への --cycle バリデーション導入（#701）

## 責務

- `cmd_squash_712` 起動時に `--cycle` 引数を `validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）で検証
- 不正値時は exit 1 + tab 区切り stderr `error\tsquash-712:invalid-cycle\t<value>` で停止
- `cmd_squash_712` 配下の `--cycle` 利用経路（`__operations_release_progress_path` 等）が検証後のパスを参照することを保証
- 不正 cycle / 正常 cycle の両ケースをカバーする bats テスト追加

## 境界

- 本 Unit の Done は `cmd_squash_712` の `--cycle` 防御実装 + bats テストに限定する
- `record-release-prep-commit` 等の他サブコマンドへの同種検証導入の要否は、本 Unit の設計時に intent.md「分離判定基準」(a)(b)(c) に照らして判断する。本サイクルで扱わないと判断した場合は別 Issue 化する（意思決定は decisions.md に記録）
- 新規バリデーションロジックの実装は行わない（既存 `validate_cycle` を再利用）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `skills/aidlc/scripts/lib/validate.sh` の `validate_cycle` 関数
- `operations-release.sh` の既存 bats テスト群

## 非機能要件（NFR）

- **パフォーマンス**: 引数検証 1 回追加のみで性能影響なし
- **セキュリティ**: パストラバーサル文字列による `.aidlc/cycles/<cycle>/...` 参照先逸脱の防止（本 Unit の主目的）
- **スケーラビリティ**: 該当なし
- **可用性**: 既存挙動の回帰がないこと（正常 cycle 値で従来どおり動作）

## 技術的考慮事項

- v2.6.2 Unit 003（#677）で `__squash_712_check_history_clean` 経路には最小限のトラバーサル拒否が実装済み。本 Unit は `cmd_squash_712` 全体への `validate_cycle` 適用に拡張する
- `write-history.sh` は既に `validate_cycle` を参照しており、同じ呼び出し形を踏襲できる

## 関連Issue

- #701

## 実装優先度

High

## 見積もり

小〜中（既存関数の再利用 + 呼び出し箇所への適用 + bats テスト追加）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
