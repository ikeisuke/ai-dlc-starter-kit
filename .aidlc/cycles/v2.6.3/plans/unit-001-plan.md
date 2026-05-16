# Unit 001 実装計画: AI エージェント Bash 実行の安全規約整備

## 対象 Unit

- **Unit**: 001 - AI エージェント Bash 実行の安全規約整備
- **関連 Issue**: #706（chore）/ #703（docs）
- **優先度**: High
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

AI エージェントが Bash ツール経由でシェル/スクリプトを実行する際の安全規約を 2 軸で整備する。

1. **#706**: `printf -v` 系 result-out 関数の local 命名規約を規約 SoT に追記し、`path-guard.sh` を予防的にリファクタする。v2.6.2 で CI を停止させた bash dynamic scope shadowing バグ（da212aea で個別修正済）の同類リスクを構造的に封じる。
2. **#703**: `codex exec` の `</dev/null` 必須運用を SoT に明文化する。非対話 subprocess 環境での stdin 待ちハング（＝セルフレビューへの無自覚な降格）を防ぐ。

両者は既存の「AI エージェント Bash ツール経由の安全パターン」という同一テーマに属し、追記先も相互に分離している（#706＝安全パターン内の新規サブセクション / #703＝Codex 連携記述）ため競合しない。

## スコープ

### 含まれるもの（責務）

- `printf -v "$result_var"` パターンを使う result-out 関数の local 命名規約を、規約 SoT である `CLAUDE.md`「AI エージェント Bash ツール経由の安全パターン」セクション内の新規サブセクションとして追記。`bash-tool-safety.md` には実装例・運用補助のみを置き「正本は CLAUDE.md 当該節」と参照で明示する
- `skills/aidlc-migrate/scripts/lib/path-guard.sh` の result-out 関数群（`_aidlc_migrate_realpath` / `_aidlc_migrate_path_guard_init` / `_aidlc_migrate_validate_path` 等）の内部 local を `_local_<関数省略名>_<名>` 形式で namespace 統一 + docstring メモ追加
- `reviewing-common-base`（正本）の `codex exec` / `codex exec resume` コマンド例に `</dev/null` を追加し、「stdin 待ちガードルール」セクションを新設。codex 非対話実行運用の正本は reviewing-common-base とする
- `CLAUDE.md` / `AGENTS.md` の Codex 連携記述に `</dev/null` 必須の横断ルールを簡潔に追記する。これは #706 の規約 SoT 単一化とは適用対象が異なる別レイヤの記述であり（#706＝安全パターン本文 / #703＝Codex 連携記述）、規範文の重複掲載は行わず各設定ファイルに必要な最小限の横断ルール + 詳細は reviewing-common-base 参照という形にする
- reviewing-common-base 正本の変更を同期スクリプト経由で同期コピーへ伝播

### 含まれないもの（境界）

- `path-guard.sh` の外部公開関数シグネチャの変更（リファクタは内部 local のみ）
- `codex exec` の `</dev/null` 欠落を検出する自動 lint ルールの新規実装（正本網羅確認 + 同期 verify で代替）
- `aidlc-migrate` スキルの path-guard 以外のロジック変更

## 実装方針

### Phase 1: 設計

- ドメインモデル: 規約 SoT の正本/参照構造、result-out 関数の命名規約モデル、reviewing-common-base の正本→同期コピー伝播構造を整理
- 論理設計: 各ファイルの具体的な追記/変更箇所を確定（path-guard.sh の対象 local 一覧、reviewing-common-base 正本パスと同期コピー一覧、CLAUDE.md/AGENTS.md の追記アンカー）

### Phase 2: 実装

1. **#706 規約追記**: `CLAUDE.md`「AI エージェント Bash ツール経由の安全パターン」セクション内に「printf -v 系 result-out 関数の local 命名規約」サブセクションを追記（正本）。`bash-tool-safety.md` は実装例・運用補助のみ（正本参照）
2. **#706 リファクタ**: `path-guard.sh` の result-out 関数群の内部 local を namespace 統一 + docstring メモ追加（外部シグネチャ不変）
3. **#703 正本修正**: reviewing-common-base 正本の `codex exec` / `codex exec resume` 例に `</dev/null` 追加 + 「stdin 待ちガードルール」セクション新設（codex 非対話実行運用の正本）
4. **#703 横断ルール**: `CLAUDE.md` / `AGENTS.md` の Codex 連携記述に `</dev/null` 必須ルールを簡潔追記（規範文の重複掲載なし、詳細は reviewing-common-base 参照）
5. **同期伝播**: reviewing-common-base 正本の変更を同期スクリプト経由で同期コピーへ伝播（同期機構の契約は下記参照）

### 同期伝播の契約（#703）

| 項目 | 内容 |
|------|------|
| 入力（正本） | reviewing-common-base 正本ファイル（具体パスは Phase 1 論理設計で確定） |
| 出力（コピー先集合） | reviewing-* スキル配下の同期コピー（具体パス一覧は Phase 1 論理設計で確定） |
| 同期機構 | 既存の同期スクリプト（`bin/sync-reviewing-common.sh`）経由のみ。コピー先を手動編集しない（正本のみ編集） |
| 検証 | `bin/sync-reviewing-common.sh --verify`（ローカル/手動実行）で正本と全 9 コピーの一致を確認する。verify 失敗時は docs 変更を未完了扱いとする。※同期 verify を実行する CI ジョブは存在しないため検証はローカル/手動実行（Phase 1 設計調査で確定） |

## 完了条件チェックリスト

### #706 受け入れ基準

- [x] `CLAUDE.md`「AI エージェント Bash ツール経由の安全パターン」セクション内に「printf -v 系 result-out 関数の local 命名規約」サブセクションが追加されている（正本）。`bash-tool-safety.md` 側は実装例・運用補助のみで規範文を重複掲載していない
- [x] `path-guard.sh` の result-out 関数すべての内部 local が namespace 統一されている
- [x] `path-guard.sh` の result-out 関数 docstring に「内部 local は namespace 化必須」メモが追加されている
- [x] `tests/migration` の既存 bats 49 件が引き続き pass する（実行証跡: `construction/units/unit_001_ai_bash_safety_conventions_implementation.md`）
- [x] `path-guard.sh` の外部公開関数シグネチャが不変

### #703 受け入れ基準

- [x] reviewing-common-base 正本の `codex exec` 例に `</dev/null` が追加されている
- [x] reviewing-common-base 正本の `codex exec resume` 例に `</dev/null` が追加されている
- [x] reviewing-common-base 正本に「stdin 待ちガードルール」セクションが新設されている
- [x] `CLAUDE.md` / `AGENTS.md` の Codex 連携記述に `</dev/null` 必須の横断ルールが簡潔に追記されている（規範文の重複掲載なし、詳細は reviewing-common-base 参照）
- [x] reviewing-common-base 正本のみを編集し、同期スクリプト経由で同期コピーへ伝播され、`bin/sync-reviewing-common.sh --verify`（ローカル/手動実行）が通過する（コピー先の手動編集なし）

### 共通

- [x] markdownlint で新規エラー 0 件
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い実施されている（設計レビュー Set 1 / コードレビュー Set 2 / 統合レビュー Set 3 すべて完了 — `001-review-summary.md` 参照）
- [x] 規約本文は単一 SoT に置かれ、他ドキュメントは参照に留まっている

## リスク・考慮事項

- shellcheck SC2030/SC2031 は本クラスの dynamic scope shadowing を捕捉しないため、規約による予防が主防御線
- reviewing-common-base は正本 1 箇所修正 → 同期コピーへ同期伝播する構造。正本のみ編集し、同期スクリプトで伝播する（正本パス・コピー先集合は Phase 1 論理設計で確定）
- #706 の規約 SoT 単一化と #703 の Codex 連携横断ルール追記は適用対象が異なる別レイヤの作業であり、計画上も分離して扱う
- 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（本リポジトリ規約）
