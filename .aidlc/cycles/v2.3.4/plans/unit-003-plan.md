# Unit 003 計画: Operations Phase リモート同期チェック追加

## 対象Unit

- Unit 003: Operations Phase リモート同期チェック追加
- 関連Issue: #571

## 概要

Operations Phase開始時にリモート同期チェックを追加し、リモートの未取得コミットがある状態で作業を進めるリスクを低減する。`setup-branch.sh` の `check_main_freshness()` と同等のアプローチで、inline git操作（`git fetch` + `git rev-list HEAD..@{u}`）によりチェックする。併せて取り込み漏れの原因調査を実施し、設計ドキュメントに記録する。

## 修正対象ファイル

- `steps/operations/01-setup.md` — リモート同期チェックステップの追加
- `.aidlc/cycles/v2.3.4/construction/units/` 配下 — 原因調査・対策方針の設計ドキュメント

## 前提・依存関係

- Unit 002（推奨・提案応答確保ルール追加）完了済み — チェック結果表示後の応答確保ルールはUnit 002で定義済み
- `scripts/validate-git.sh remote-sync` は未pushコミット検出（ローカル→リモート方向）であり、本Unitの目的（リモート→ローカル方向の未取得コミット検出）には使用しない
- `scripts/setup-branch.sh` の `check_main_freshness()` が同等のチェック方向（`merge-base --is-ancestor`）を先行実装
- Inception Phase `01-setup.md` ステップ9-3に `main_status` パターン（behind/up-to-date/fetch-failed）の先行実装あり
- Operations Phase `operations-release.md` 7.9〜7.11 で `verify-git` が既に使用されている（リリース準備段階）

## 設計方針

1. **チェック挿入箇所**: `steps/operations/01-setup.md` のステップ6（進捗管理ファイル確認）の後、ステップ6a（タスクリスト作成）の前に新ステップとして追加
2. **チェック方式**: inline git操作（`git fetch` + `git rev-list HEAD..@{u} --count`）で未取得コミットを検出し、正規化状態に変換してから分岐
3. **severity**: warn（ブロッカーではない）— オフライン環境でスキップ可能
4. **behind検出時**: AskUserQuestion で「取り込む / スキップして続行」を提示
5. **fetch失敗・upstream未設定時**: 警告表示してスキップ（続行）
6. **原因調査**: 既存フローでOperations Phase開始前にリモート同期チェックが無いこと自体が原因。7.9〜7.11のverify-gitはリリース準備段階であり、Phase開始時のチェックポイントが欠落していた

### 正規化状態モデル

inline git操作の結果を以下の正規化済み状態に変換してから分岐する。Inception Phase ステップ9-3 の `main_status` と一貫した命名規則を採用。

| 正規化状態 | git操作結果 | 手順層の動作 |
|-----------|-----------|-------------|
| `up-to-date` | fetch成功 + rev-list = 0 | 情報表示して続行 |
| `behind` | fetch成功 + rev-list > 0 | AskUserQuestion で「取り込む / スキップして続行」 |
| `skipped` | fetch失敗 / upstream未設定 / detached HEAD | 警告表示してスキップ（続行） |

### 責務境界（障害伝播）

| 層 | 責務 |
|----|------|
| git操作（inline） | `git fetch` + `git rev-list HEAD..@{u}` を実行し、raw結果を返す |
| 手順層（`01-setup.md`） | raw結果を正規化状態に変換し、分岐を実行。fetch失敗等を `skipped`（advisory warning）に吸収する |

**注**: `operations-release.sh verify-git` は未pushコミット検出（ローカル→リモート方向）であり、本ステップの未取得コミット検出（リモート→ローカル方向）とは補完関係。両者は異なるフェーズで異なる目的に使用される

## 完了条件チェックリスト

- [x] `steps/operations/01-setup.md` にリモート同期チェックステップが追加されている
- [x] behind件数が1以上の場合、AskUserQuestionで「取り込む / スキップして続行」を表示する仕様が定義されている
- [x] `git fetch` 失敗時・upstream未設定時のスキップ処理と警告表示が定義されている
- [x] 取り込み漏れの原因調査結果が設計ドキュメントに記録されている
- [x] inline git操作（`git fetch` + `git rev-list HEAD..@{u}`）による正しいチェック方向（リモート→ローカル）が定義されている
- [x] Inception Phase ステップ9-3の `main_status` パターンとの一貫性が確保されている

## 実装アプローチ

1. **Phase 1（設計）**: リモート同期チェックのフロー設計、inline git操作によるチェック方式の定義、原因調査結果の記録
2. **Phase 2（実装）**: `steps/operations/01-setup.md` への新ステップ追加

## スコープ外

- `operations-release.sh` スクリプト本体の変更（既存機能の再利用のみ）
- Operations Phase以外のフェーズへのリモート同期チェック追加
