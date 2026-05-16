# Unit: operations-release.sh への validate_cycle 検証拡張

## 概要

`operations-release.sh` の `cmd_record_release_prep_commit`（パストラバーサル経路あり / 必須）に `validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）検証を導入し、v2.6.3 Unit 002 で `cmd_squash_712` のみに導入された `--cycle` 検証を必須経路へ網羅的に拡張する。`cmd_pr_ready` は影響範囲調査結果に基づき条件付き対応する。

## 含まれるユーザーストーリー

- ストーリー 2: `operations-release.sh` への `validate_cycle` 検証拡張（#708）

## 責務

- **必須対応**: `cmd_record_release_prep_commit` への `validate_cycle` 検証導入 + 新規 bats テスト追加
  - `__operations_release_progress_path` でパス展開する経路を持つため、v2.6.3 Unit 002 の `cmd_squash_712` と同種のパストラバーサル経路を閉じる
  - bats テスト: 不正値（`../` / 絶対パス / 制御文字 / 空文字 / 予約名）と正常値（`v2.6.x` / `cycle_name/version` 等）の境界ケースを網羅
- **条件付き対応**: `cmd_pr_ready` の `--cycle` 経路の影響範囲調査
  - 下流（`pr-ops.sh get-related-issues "$cycle"`）で `--cycle` がパス展開に使われるか調査
  - 結果を `inception/decisions.md` に DR として記録
  - 必要なら同サイクル内で `validate_cycle` 導入、不要なら別 Issue 化
- 既存 bats 群（`tests/migration/*.bats` 含む）の回帰なし確認

## 境界

- `validate_cycle` 関数本体（`skills/aidlc/scripts/lib/validate.sh`）の改修は本 Unit 対象外（v2.6.3 Unit 002 で導入済みの実装をそのまま流用）
- `cmd_squash_712` の既存検証への追加変更は本 Unit 対象外
- `operations-release.sh` の他のサブコマンド（`--cycle` を受け取らないもの）は本 Unit 対象外

## 依存関係

### 依存する Unit

- なし（独立 Unit。v2.6.3 Unit 002 で実装済みの `validate_cycle` を呼び出すだけ）

### 外部依存

- `skills/aidlc/scripts/lib/validate.sh` の `validate_cycle` 関数（既存）
- bats-core（テスト実行）

## 非機能要件（NFR）

- **セキュリティ**: パストラバーサル文字列の境界ケースを bats テストで網羅
- **後方互換性**: 既存呼び出し経路（CI / Operations Phase ステップ）の引数形式不変
- **保守性**: `cmd_squash_712` で確立された検証パターンを踏襲（実装パターンの統一）

## 技術的考慮事項

- `printf -v` 系 result-out 関数を新規導入する場合は v2.6.3 で追加された namespace 規約（`_local_<関数省略名>_<名>`）に従う
- AI エージェント Bash ツール経由の安全パターン遵守（コマンド置換禁止）
- 影響範囲調査の結果は `inception/decisions.md` に DR-NNN として明示記録（`cmd_pr_ready` 対応 / 別 Issue 化の判断根拠を後で参照できるように）

## 関連Issue

- #708（クローズ対象 / 必須対応分。`cmd_pr_ready` の扱いによっては部分対応で `Relates` 扱いもあり得る）
- 元 Issue: #701（v2.6.3 Unit 002 で `cmd_squash_712` のみ対応）

## 実装優先度

High（security / patch スコープ）

## 見積もり

1 日（必須対応 + 影響範囲調査 + bats テスト）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
