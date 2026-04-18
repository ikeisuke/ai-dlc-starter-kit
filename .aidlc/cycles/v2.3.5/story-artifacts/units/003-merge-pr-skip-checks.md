# Unit: merge-pr `--skip-checks` オプション追加

## 概要

`scripts/operations-release.sh merge-pr` に `--skip-checks` オプションを追加し、CI 状態が `checks-status-unknown` と解釈される場合（典型的には `gh pr checks` が `no checks reported` を返すケース）に限って安全にバイパスできるようにする。`failed` / `pending` 等の状態では従来通りエラー終了する。エラーメッセージ改善とドキュメント記載も合わせて実施する。

## 含まれるユーザーストーリー

- ストーリー 3: CIチェック未設定リポジトリで merge-pr が安全にスキップできる（#575）

## 責務

- `scripts/operations-release.sh merge-pr` に `--skip-checks` オプションを追加
- CI 状態が `checks-status-unknown` と解釈された場合のみ `--skip-checks` でバイパスを許可
- CI 状態が `failed` / `pending` / その他既知状態の場合、`--skip-checks` 指定の有無に関わらず従来通りエラー終了（安全性を損なわない）
- CI 状態 `checks-status-unknown` 検出時のエラーメッセージに `--skip-checks` の存在と適用条件を案内する具体的な文言を追加
- `merge-pr --help` またはスクリプト冒頭の Usage 情報に `--skip-checks` の説明と適用条件を追加
- `skills/aidlc/steps/operations/03-release.md` に `merge-pr` の前提条件と `--skip-checks` の適用条件を記載
- `skills/aidlc/guides/` 配下に `merge-pr` の挙動サマリ（挙動マトリクス含む）を 1 箇所追加（ファイル名は Construction Phase で確定）

## 境界

- 実装対象外:
  - `operations-release.sh` の他のサブコマンド（`verify-git` 等）の変更（Unit 002 のスコープ）
  - CI ステータス判定ロジック全体の再設計
  - `failed` / `pending` ケースのスキップ機能（安全性確保のため対象外）
  - `gh` CLI バージョン固定・依存ライブラリ変更

## 依存関係

### 依存する Unit

- **Unit 002**（`operations-release.sh` の共有更新対象のため）: 論理要件は独立しているが、同一ファイル（`scripts/operations-release.sh`）を更新するため並行実装禁止。Unit 002 完了後に着手する

### 外部依存

- `gh` CLI（`gh pr checks` 出力パース）

## 非機能要件（NFR）

- **パフォーマンス**: 既存と同等（オプション追加のみで処理時間増加なし）
- **セキュリティ**: `failed` / `pending` では必ず拒否することで、CI を無視した不正なマージを防ぐ
- **スケーラビリティ**: N/A
- **可用性**: `--skip-checks` を指定しない場合、既存呼び出しの挙動と完全互換

## 技術的考慮事項

- **`checks-status-unknown` 判定**: `gh pr checks` 出力の解釈ロジックを調査し、既存実装との整合性を保つ（現行コードで `no checks reported` 判定がどこで行われているかを設計フェーズで確認）
- **引数パース**: shell script の引数パースに `--skip-checks` フラグを追加。`getopts` ではロングオプションが扱いにくいため、既存の実装パターンに合わせてループ処理で実装
- **エラーメッセージの改善**: `checks-status-unknown` ケースは従来「`error:checks-status-unknown` で中断」とだけ出力していたところを、「CIチェックが設定されていません（`no checks reported`）。`--skip-checks` でスキップできます」のような具体的なメッセージに変更
- **失敗時の挙動統一**: `--skip-checks` を指定しても `failed` / `pending` ではエラー終了する旨をエラーメッセージに明示する（ユーザーが誤解しないよう）
- **guides/ 配下の新規ドキュメント**: 既存の `guides/` 配下のファイル命名規則（例: `guides/backlog-management.md`, `guides/config-merge.md`）に合わせた名前（例: `guides/merge-pr-usage.md`）を Construction Phase で確定
- **下位互換の検証**: 既存の呼び出し箇所（`03-release.md` の 7.13 PR マージ処理）で `--skip-checks` を指定しないケースの挙動が変わらないことを確認

## 関連Issue

- #575

## 実装優先度

High

## 見積もり

**S（Small）** - スクリプトへのオプション追加と既存エラーメッセージ改善が中心。ステップファイル更新と guides への新規ドキュメント追加が付随するが、変更範囲は Unit 001, 002 より小さい。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-17
- **完了日**: 2026-04-18
- **担当**: Claude Code + Codex
- **エクスプレス適格性**: -
- **適格性理由**: -
