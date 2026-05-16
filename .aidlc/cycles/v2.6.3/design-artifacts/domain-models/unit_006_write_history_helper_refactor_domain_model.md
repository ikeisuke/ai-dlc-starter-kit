# Unit 006 ドメインモデル: write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化

## 概要

本 Unit は `skills/aidlc/scripts/write-history.sh` 内に閉じた **重複コードの共通化（refactor）** が
責務で、挙動の等価性を維持しつつ「symlink 解決 + repo-root 取得 + repo-root 相対パス化」の 4 ステップ
を共通ヘルパに集約する。本ドメインモデルは関係する要素を最小限で記述する。

## ドメイン要素

### エンティティ

| 名称 | 責務 |
|------|------|
| 履歴ファイルパス（`filepath`） | 呼び出し元から渡される履歴ファイルの絶対 / 相対パス |
| repo-root 絶対パス（`repo_root`） | filepath を含む git リポジトリのルート（pwd -P 経由で symlink 解決済み） |
| repo-root 相対パス（`rel_path`） | repo_root を接頭辞除去した相対パス（git diff --cached --name-only との比較対象） |
| 共通ヘルパ関数 `_resolve_history_filepath_in_repo` | 上記 3 要素のうち `repo_root` と `rel_path` を result-out 変数経由で算出する **書き込み副作用なしの read-only helper**（実体は `cd` / `pwd -P` / `git rev-parse` に依存する I/O 読み取り関数。stdout / stderr / global 変数への書き込みは行わず、`printf -v` で result-out 変数にのみ書き込む） |
| 呼び出し元関数 1: `check_history_staged_status` | base モード完了時の履歴 staged 判定。失敗時は silent return 0 |
| 呼び出し元関数 2: `_commit_operations_round_history` | operations-round モード完了後の auto-commit。失敗時は exit code 別 stderr warning + return 0 |

### 値オブジェクト

| 名称 | 表現 |
|------|------|
| 解決失敗理由（exit code） | 1=symlink 解決失敗 / 2=git リポジトリ外 / 3=repo 配下でない |
| warning 文言（caller 別） | `check_history_staged_status` は silent / `_commit_operations_round_history` は 3 種類の文言（解決失敗 / git 外 / 配下外） |

### ドメインサービス

本 Unit にドメインサービスは存在しない（refactor のみ）。

## 不変条件（refactor 前後で維持される契約）

1. **入出力等価性**: refactor 前後で、同一 `filepath` 入力に対し `repo_root` / `rel_path` の値が等価
2. **caller 別 warning 挙動の維持**:
   - `check_history_staged_status`: いかなる解決失敗ケースでも silent return 0（stderr 出力なし）
   - `_commit_operations_round_history`: 解決失敗ケースごとに既存の 3 種類の warning 文言を stderr に出力し return 0
3. **helper の単一責務**: helper 自身は stdout / stderr に出力しない（出力は caller の責務）
4. **既存 bats テスト群が全 pass**: `tests/write-history-history-staged-warning.bats` /
   `tests/write-history-modes.bats` / `tests/write-history-operations-round-commit.bats`
4b. **helper 単独 bats テストが全 pass（必須）**: `tests/write-history-resolve-helper.bats`（新規）
    で helper 単独呼び出しの exit code 4 経路（0/1/2/3）+ stdout/stderr が空であることを assert
5. **printf -v 系 result-out 関数の local 命名規約準拠**: helper 内部作業用 local は
   `_local_rhf_*` 形式で namespace 化（dynamic scope shadowing バグ予防）

## 外部システム / 依存コンテキスト（非変更）

| 名称 | 役割 | 本 Unit での扱い |
|------|------|----------------|
| `git rev-parse --show-toplevel` | repo-root 取得の標準コマンド | 非変更（helper 内部で呼ぶ） |
| `cd ... && pwd -P` | symlink 解決の標準パターン（macOS の `/tmp` → `/private/tmp` 等） | 非変更（helper 内部で呼ぶ） |
| `git diff --cached --name-only` | staged 状態判定 | 非変更（caller 側で従来どおり呼ぶ） |
| `bootstrap.sh` | 共通初期化スクリプト | 非変更（本 Unit のスコープ外 / 将来配置最適化の余地） |

## 境界（含まないもの）

- `write-history.sh` の履歴記録ロジック本体（追記処理 / モード分岐 / 引数パース）
- パス解決の挙動自体の変更（refactor のみで挙動等価）
- 外部公開インターフェース（CLI 引数 / stdout 契約 / exit code 契約）
- 共通ヘルパの `bootstrap.sh` / 別 lib への移設（将来の別 Issue 候補）

## 参照

- Unit 定義: `.aidlc/cycles/v2.6.3/story-artifacts/units/006-write-history-helper-refactor.md`
- 計画: `.aidlc/cycles/v2.6.3/plans/unit-006-plan.md`
- 改修対象: `skills/aidlc/scripts/write-history.sh` の `check_history_staged_status`（行 545〜）と
  `_commit_operations_round_history`（行 622〜）
- 関連 Issue: #702
- 関連経緯: v2.6.2 Unit 003（#677 fix）Codex Round 1 LOW #2 指摘
