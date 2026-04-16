# Unit: リモート同期チェックの squash 後 divergence 対応（runtime 判定修正）

## 概要

`scripts/operations-release.sh verify-git remote-sync` のリモート同期チェックを改修し、squash 後の history rewrite による divergence を誤検知しない仕組みに変更する。`merge-base --is-ancestor` の先行チェックと新規ステータス `diverged` の区別を導入し、Operations 開始時のステップファイルに反映する。

## 含まれるユーザーストーリー

- ストーリー 2: リモート同期チェックが squash 後の divergence を誤検知しない（#574 (1)(2) を担当）

## 責務

**Operations 開始時の runtime 判定ロジック修正（#574 (1)(2)）**:

- `scripts/operations-release.sh` の `verify-git remote-sync` サブルーチンに `git merge-base --is-ancestor @{u} HEAD` 先行チェックを追加し、true なら `up-to-date` と判定
- divergence 検出時のステータスを `behind` から `diverged` に分離
- `diverged` ステータス時のメッセージに `git push --force-with-lease <remote> <branch>` の推奨コマンドを含める（自動実行はしない）
- `steps/operations/01-setup.md` のリモート同期チェック分岐に `diverged` ステータス向けユーザー選択フロー（force push 案内を表示 or スキップ）を追加
- 既存ステータス（`up-to-date` / `behind` / `fetch-failed`）の挙動を維持（回帰防止）

**検証**:

- squash 後に Operations Phase を開始するシナリオで誤検知が再現しないことを手動確認または自動テストで検証

## 境界

- 実装対象外:
  - `operations-release.sh` の他のサブコマンド（`merge-pr` 等）の変更（Unit 003 のスコープ）
  - Construction Phase の squash 完了後の案内追加（Unit 004 のスコープ）
  - `force-with-lease` の自動実行（案内のみ）
  - 復帰判定の参照先変更（Unit 001 のスコープ）

## 依存関係

### 依存する Unit

- なし（Unit 001 とは独立。Operations Phase 開始時のステータス判定は Unit 001 の復帰判定と別レイヤー）

### 外部依存

- `git` CLI（`merge-base --is-ancestor`, `rev-list`, `fetch`, `push --force-with-lease`）

### 共有更新対象に関する実装順序

- `operations-release.sh` は Unit 002 と Unit 003 の共通更新対象である。Unit 002 を先に実装完了し、Unit 003 はその上に積み上げる実装順序とする（並行実装禁止）

### 後続 Unit

- Unit 004（Construction 側の squash 後案内追加）は本 Unit の `diverged` ステータス仕様を前提とするため、本 Unit 完了後に着手する

## 非機能要件（NFR）

- **パフォーマンス**: `merge-base --is-ancestor` は軽量（既存 fetch + rev-list と同程度の処理時間）
- **セキュリティ**: `--force-with-lease` は `--force` と異なりリモートの現状を検査してから上書きするため、他者コミットを破壊するリスクを低減。ただし自動実行はしないためユーザー承認が必須
- **スケーラビリティ**: N/A
- **可用性**: `fetch-failed`（オフライン等）は従来通り返す

## 技術的考慮事項

- **判定順序**: `fetch` → `merge-base --is-ancestor @{u} HEAD`（up-to-date 判定） → `merge-base --is-ancestor HEAD @{u}`（behind 判定） → どちらも該当しなければ `diverged`。`fetch` 失敗時は判定前に `fetch-failed` で短絡
- **ステータス値の後方互換**: 既存呼び出し側（`01-setup.md` 以外）で `diverged` を `behind` と同等に扱うコードが残らないよう、全参照箇所をチェックする
- **`force-with-lease` 推奨の理由**: `--force` は他者のコミットも上書きしてしまうため、squash 後の push では `--force-with-lease` を推奨
- **コマンド例の具体性**: 案内文言には `<remote>` と `<branch>` のプレースホルダーを含め、ユーザーが自分の環境に合わせてコピー＆ペーストできる形にする

## 関連Issue

- #574（部分対応）

## 実装優先度

High

## 見積もり

**M（Medium）** - `operations-release.sh` のロジック追加と `01-setup.md` 分岐追加が中心。`diverged` ステータスの全呼び出し箇所の整合確認が必要だが、変更範囲は Unit 001 より小さい。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
