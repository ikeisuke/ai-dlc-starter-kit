# Unit: pr-ops.sh の空配列展開 bug 修正

## 概要

`skills/aidlc/scripts/pr-ops.sh` 内で、関連 Issue を含まない PR 本文を扱う際に `closes_list[@]` / `relates_list[@]` の空配列展開が `set -u` 環境で `unbound variable` エラーを起こす問題を修正する。修正後はスクリプト経由で `operations-release.sh pr-ready` が完結し、`gh pr ready` / `gh pr edit` の手動回避策が不要になる。

## 含まれるユーザーストーリー

- ストーリー 7: pr-ready の closes_list 空配列 bug 修正（#588）

## 責務

- `skills/aidlc/scripts/pr-ops.sh:216-245` の Bash 配列展開を `set -u` 環境で安全化（`"${closes_list[@]:-}"` 形式または `[[ ${#closes_list[@]} -gt 0 ]]` ガードで囲む）
- 関連 Issue 0 件 / 1 件 / 複数件の各ケースで期待出力（`issues:` / `closes:` / `relates:` 行）が正しく出ることを保証する
- 空配列ケースの fixture テストを追加する（既存テストランナー `skills/aidlc/scripts/tests/` 配下に該当があれば追従、なければ新規作成）

## 境界

- `set -euo pipefail` 自体の解除は行わない（安全性のため、配列展開側で対処）
- `gh pr ready` / `gh pr edit` の置換ロジック自体は変更しない（呼び出し前の入力整形のみ修正）
- 他の `pr-ops.sh` 関数や `operations-release.sh` の変更はスコープ外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- bash 3.2+（macOS 標準）/ GNU bash（Linux）両対応の配列空展開構文を選択すること
- 既存テストランナー: `skills/aidlc/scripts/tests/` 配下のテストを実行する仕組み（あれば追従、なければ最小限の bash assertion テストを追加）

## 非機能要件（NFR）

- **パフォーマンス**: bash スクリプト処理時間は変更前と同等（配列展開ガード追加分のオーバーヘッドのみ、無視できるレベル）
- **セキュリティ**: 入力文字列のエスケープ・サニタイズに変更なし
- **スケーラビリティ**: 関連 Issue 数（0〜100 件想定）に対する処理時間は線形を維持
- **可用性**: 既存スクリプト経由のフロー（`operations-release.sh pr-ready`）の成功率を 100% に近づける（関連 Issue 0 件ケースの失敗を解消）

## 技術的考慮事項

- bash 配列空展開の安全化パターンは 2 通り選択肢あり: (1) `"${arr[@]:-}"` 形式（インライン）、(2) `[[ ${#arr[@]} -gt 0 ]] && echo "${arr[@]}"` ガード形式。可読性と既存コードスタイルに合わせて Construction Phase 設計時に選択する
- 既存テストランナーが test_*.sh を `bash` 直接実行する形式か、専用フレームワーク（bats 等）か、Construction Phase 設計時に確認

## 関連Issue

- #588

## 実装優先度

High（Operations フローの基盤 bug、他 Unit の試験にも影響しうる）

## 見積もり

0.5〜1 時間（修正 + fixture 1-2 ケース追加）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
