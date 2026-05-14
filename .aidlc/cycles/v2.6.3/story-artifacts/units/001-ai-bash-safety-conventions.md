# Unit: AI エージェント Bash 実行の安全規約整備

## 概要

AI エージェントが Bash ツール経由でシェル/スクリプトを実行する際の安全規約を 2 軸で整備する。(1) `printf -v` 系 result-out 関数の local 命名規約を規約 SoT に追記し `path-guard.sh` を予防的にリファクタする（#706）、(2) `codex exec` の `</dev/null` 必須運用を SoT に明文化する（#703）。両者は既存の「AI エージェント Bash ツール経由の安全パターン」という同一テーマに属する。

## 含まれるユーザーストーリー

- ストーリー 1: result-out 関数の local 命名規約整備と path-guard.sh の予防的リファクタ（#706）
- ストーリー 2: codex exec の `</dev/null` 必須運用の明文化（#703）

## 責務

- `printf -v "$result_var"` パターンを使う result-out 関数の local 命名規約を規約 SoT（CLAUDE.md または `bash-tool-safety.md`）に追記
- `skills/aidlc-migrate/scripts/lib/path-guard.sh` の result-out 関数群の内部 local を `_local_<関数省略名>_<名>` 形式で namespace 統一 + docstring メモ追加
- `reviewing-common-base`（正本）の `codex exec` / `codex exec resume` コマンド例に `</dev/null` を追加し、「非対話 subprocess 環境では `</dev/null` 必須」セクションを新設
- `CLAUDE.md` / `AGENTS.md` の Codex 連携記述に `</dev/null` 必須の横断ルールを追記
- reviewing-common-base 正本の変更を同期コピーへ伝播

## 境界

- `path-guard.sh` の外部公開関数シグネチャの変更は行わない（リファクタは内部 local のみ）
- `codex exec` の `</dev/null` 欠落を検出する自動 lint ルールの新規実装は行わない（誤検知リスク・docs スコープ超過のため。正本網羅確認 + 同期 verify で代替）
- `aidlc-migrate` スキルの path-guard 以外のロジック変更は行わない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `tests/migration` の既存 bats（49 件）— 回帰確認に使用
- reviewing-common-base 同期スクリプト / CI 同期 verify ジョブ

## 非機能要件（NFR）

- **パフォーマンス**: 規約・ドキュメント追記およびリファクタのため性能影響なし
- **セキュリティ**: dynamic scope shadowing による result-out 関数の致命的バグ（v2.6.2 CI 停止の原因）の再発防止
- **スケーラビリティ**: 規約は配布物 baseline として全 consumer プロジェクトに適用される
- **可用性**: 該当なし

## 技術的考慮事項

- 規約本文は単一の SoT に置き他ドキュメントは参照に留める（配布物 baseline 規約の重複回避）
- `CLAUDE.md` の追記先は #706（「AI エージェント Bash ツール経由の安全パターン」内の新規サブセクション）と #703（Codex 連携記述）で相互に分離しており、同一箇所の競合は発生しない
- reviewing-common-base は正本 1 箇所修正 → 9 コピーへ同期伝播する構造。正本のみ編集する
- shellcheck SC2030/SC2031 は本クラスの dynamic scope shadowing を捕捉しないため、規約による予防が主防御線

## 関連Issue

- #706
- #703

## 実装優先度

High

## 見積もり

中（規約 doc 追記 + path-guard.sh リファクタ + reviewing-common-base 正本修正 + 同期伝播 + bats 回帰確認）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
