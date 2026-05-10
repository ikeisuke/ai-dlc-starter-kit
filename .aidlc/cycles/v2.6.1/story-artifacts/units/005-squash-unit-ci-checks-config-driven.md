# Unit: `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化

## 概要

v2.6.0 Unit 007 で opt-in シグナル方式にリファクタした `skills/aidlc/scripts/squash-unit.sh` の CI 構造チェック（`bin/check-skill-references.sh` / `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh`）について、現状本体スクリプトに 3 種固定でハードコードされている部分を `.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` 設定キー経由に置き換え、CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則への準拠度を上げる。

## 含まれるユーザーストーリー

- ストーリー 5: `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化

## 責務

- `.aidlc/config.toml` に `[rules.squash.internal_ci_checks].scripts` 設定キーを追加し、starter kit デフォルトとして既存 3 種を指定
- `skills/aidlc/scripts/squash-unit.sh` の `run_internal_ci_checks_or_skip()` を設定リスト駆動に変更し、本体スクリプトはチェックスクリプト名・パスをハードコードしない
- 設定不在 / 空配列 / 一部スクリプト不在の各ケースで適切に動作する fallback ロジックを実装
- bats テストで上記分岐を検証

## 境界

- `bin/check-*.sh` 各チェックスクリプト本体のロジック変更は対象外
- consumer プロジェクト向けの「独自 CI チェック追加ガイド」は対象外（本 Unit では設定キー導入のみ）
- Issue #691（汎用 CI チェックをスキル本体に取り込む設計検討、v2.7.0 へ送り）は本 Unit のスコープ外。本 Unit では設定キーのみで吸収し、スキル本体への取り込みは v2.7.0 で再検討する

## 依存関係

### 依存する Unit

- Unit 004（dasel 直接呼び出しの `read-config.sh` 経由統一）（推奨依存 / 強制依存ではない）
  - 理由: `[rules.squash.internal_ci_checks].scripts` の読取で `read-config.sh` 経由を採用するため、Unit 004 の規約追記後に実装するのが望ましい
  - 強制依存にしない理由: 本 Unit 単独でも `read-config.sh` を呼ぶだけで完結する。並行実行可

### 外部依存

- bash
- dasel v3 / `scripts/read-config.sh`（設定読取）

## 非機能要件（NFR）

- **パフォーマンス**: 設定読取オーバーヘッドは squash 実行ごとに 1 回（数 ms 程度で許容）
- **セキュリティ**: 設定値（スクリプトパス）の正規化（リポジトリルート相対のみ許容、絶対パス・上位パス traversal 禁止）を維持
- **スケーラビリティ**: 設定リストのスクリプト数増加に対してリニアスケール（既存挙動維持）
- **可用性**: 設定不在時の fallback で v2.6.0 と同等の挙動を保証（後方互換）

## 技術的考慮事項

- 後方互換最優先: 設定不在 / セクション不在の場合に既存 3 種を fallback default で読み込む
- `read-config.sh` が配列を返す方式（既存パターン）を踏襲し、新規パーサを追加しない
- 既存の opt-in シグナル方式（ファイル存在チェック）は維持（設定にあるが実体が無いケースは個別 skip）
- 空配列指定時は集約 skip + info ログ（`internal-ci-checks:skip:reason=empty-config`）

## 関連Issue

- #687

## 実装優先度

Medium（設計原則準拠 / メンテナビリティ向上、影響範囲は squash-unit.sh に限定）

## 見積もり

1 day（設計 + 実装 + bats テスト追加 + 後方互換検証）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
