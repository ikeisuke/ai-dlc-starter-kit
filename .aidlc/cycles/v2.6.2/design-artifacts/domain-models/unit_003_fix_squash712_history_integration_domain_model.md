# ドメインモデル: Unit 003 — Operations §7.12.5 squash-712 と write-history operations-round の整合性

## 概要

Operations Phase §7.12 PR レビュー反映フローにおいて「履歴 append → 履歴 commit → squash-712 統合」の連鎖を構造的に保証するためのドメイン責務とコマンド境界を定義する。本 Unit はシェルスクリプトと git/CI フローの改修であり、伝統的な OO ドメインモデルというよりは「コマンド責務とその不変条件」を中心に記述する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

**採用案**: **A + B 併用**（ユーザー確定済）。

---

## ドメイン概念

### 概念 1: HistoryAppendEvent（履歴追記イベント）

- **定義**: `write-history.sh` 呼び出し 1 回で `.aidlc/cycles/<cycle>/history/operations.md` 等に追記される 1 ブロック
- **属性**:
  - `filepath`: 追記対象ファイル絶対パス
  - `mode`: `base` / `unit-complete-short-note` / `operations-round`
  - `cycle`: 対象サイクル名
  - `is_new_file`: 新規作成 / append
  - `staged_at_append`: 追記直後の git index 状態（true=staged / false=unstaged）
- **不変条件**:
  - mode = `operations-round` のとき `phase` は必ず `operations`
  - 追記内容は append-only（既存履歴の書き換えなし）

### 概念 2: WorkingTreeHistoryState（作業ツリー上の history 差分状態）

- **定義**: ある時点での git working tree における `history/operations.md` の git 差分状態
- **属性**:
  - `cycle`: 対象サイクル名
  - `filepath`: `.aidlc/cycles/<cycle>/history/operations.md`
  - `state`: `clean` / `staged_only` / `unstaged_only` / `mixed`
- **不変条件**:
  - squash-712 起動の事前条件は `state == clean`（A+B 併用方針）
  - `state != clean` での squash-712 起動は構造エラーとして fail-fast 対象

### 概念 3: ReleasePrepCommit（リリース準備 commit anchor）

- **定義**: `§7.7` Operations Phase 完了 commit の SHA。`progress.md` の HTML コメント独立スロット（`<!-- release_prep_commit: <40 桁 SHA> -->`）に記録される
- **属性**:
  - `sha`: 40 桁 SHA
  - `cycle`: 対象サイクル名
- **不変条件**:
  - squash-712 はこの anchor から HEAD までを 1 commit に統合する
  - anchor 不在時 squash-712 は skip（既存契約）

### 概念 4: SquashIntegration（squash 統合動作）

- **定義**: `release_prep_commit..HEAD` の commit 群を 1 commit に統合する操作
- **属性**:
  - `target_count`: 統合対象 commit 数
  - `dry_run`: `--dry-run` 指定の有無
- **不変条件**（本 Unit で追加）:
  - 統合実行直前に WorkingTreeHistoryState が `clean` でなければならない（案 B fail-fast の事前条件）
  - 統合後の HEAD には history/operations.md の差分が含まれる（integration テスト観測点）

---

## コマンド責務

### コマンド 1: `write-history.sh --mode operations-round`

- **追加責務**（案 A）:
  - 追記成功後、対象 filepath を **git add + commit** する（auto-commit）
  - commit message フォーマット: `chore: [<cycle>] §7.12 レビュー round <round> 履歴記録`
  - **オプション `--no-commit` で auto-commit を skip**（opt-out で append のみの旧挙動）
  - dry-run 時は append も commit も実行せず would-* ログ出力のみ
- **責務範囲外**:
  - mode = `base` / `unit-complete-short-note` の auto-commit 化（変更しない）
- **環境ガード**（Round 1 HIGH 指摘 #3 対応）:
  - **git リポジトリ外実行**: `git rev-parse --show-toplevel` で git 配下判定し、git 外の場合は auto-commit を skip + stderr warning（exit 0 維持）。これにより非 git 環境（既存テスト `write-history-history-staged-warning.bats` case (c) 等）の挙動を破壊しない
  - **事前 staged 状態**: 対象 filepath が auto-commit 開始前に既に staged の場合は auto-commit を skip + stderr warning（呼び出し側が手動 commit 管理中の前提として尊重）
  - これら 2 ガードは「破壊的変更なし」NFR を担保する責務

### コマンド 2: `operations-release.sh squash-712`

- **追加責務**（案 B）:
  - 既存 Step 1（squash_enabled 取得）の直後・Step 2（release_prep_commit パース）の前に **dirty 検出ガード**を実行
  - 対象パターン: `.aidlc/cycles/<cycle>/history/operations.md`（cycle は `--cycle` 引数から導出）
  - dirty 検出時: exit 1 + tab 区切り stderr + 推奨コマンド案内
  - dry-run 時もガード実行（事前検証目的）
- **責務範囲外**:
  - history 以外のファイル（成果物 / progress.md）の dirty 検出（既存 §7.13 pre-flight の責務）
  - escape hatch（`--allow-dirty-history` 等）の提供（運用ミス検出が目的のため意図的に提供しない）

---

## 不変条件の責務マッピング

| 不変条件 | 責任を持つコマンド | 検証手段 |
|---------|------------------|---------|
| 「append 後は必ず commit 状態に到達する」 | `write-history.sh --mode operations-round`（案 A） | auto-commit の事後状態を bats で `git status --porcelain` 検証 |
| 「squash-712 起動時の WorkingTreeHistoryState は clean」 | `operations-release.sh squash-712`（案 B） | dirty/clean ケースを bats で網羅 |
| 「squash 統合 commit に history 差分が含まれる」 | 上記 2 つの連鎖（integration） | integration テストで `git show --stat HEAD` 検証 |
| 「`--no-commit` 経路でも検知層が存在する」 | 案 B が代替検知層 / §7.13 pre-flight が最終層 | 案 A `--no-commit` + 案 B 経路の bats で fail-fast 確認 |

---

## エラーコード境界

機械可読出力フォーマットは既存規約（tab 区切り `error\t<code>\t<context>`）を踏襲。

| コマンド | エラーコード | 発生条件 | 出力 |
|---------|------------|---------|------|
| write-history.sh（案 A） | `failed-auto-commit-operations-round` | auto-commit 内部の `git add` または `git commit` が失敗 | **既存 `emit_error` 契約に従い** `error:failed-auto-commit-operations-round:<reason>` を stdout + stderr にミラー（既存規約踏襲、tab 区切り単独 stderr は採用しない）。Round 1 HIGH 指摘 #1 対応 |
| operations-release.sh squash-712（案 B） | `squash-712:uncommitted-history` | history dirty 状態で squash-712 起動 | stderr に tab 区切り `error\tsquash-712:uncommitted-history\t<path>` + 推奨コマンド `recommended_command:git add <path> && git commit -m "<履歴記録メッセージ>" の後に再実行`（既存 `operations-release.sh` 規約踏襲。dirty 検出時点で round 番号は持たないため commit message は placeholder のみ）|

---

## ユビキタス言語

- **history append**: `write-history.sh` が `history/operations.md` 等にエントリを追記する操作
- **history commit**: append 後の git add + git commit による履歴ファイル変更の永続化
- **squash 統合 commit**: `§7.12.5` `squash-712` が `release_prep_commit..HEAD` を 1 commit に圧縮した結果の commit
- **dirty 状態**: working tree 上に staged または unstaged の git 差分が存在する状態
- **検知層**: 構造エラー（dirty で squash-712 起動 等）を実行時に止める仕組み。本 Unit では「案 A 単独 / 案 B / §7.13 pre-flight」の 3 層を多重化する
- **opt-out 経路**: 案 A の `--no-commit` フラグで append のみの旧挙動に戻す経路。緊急時 / consumer プロジェクトの既存ワークフロー保護用

---

## 不明点と質問（設計中に記録）

[Question] auto-commit の commit message フォーマットは「`chore: [<cycle>] §7.12 レビュー round <round> 履歴記録`」で確定してよいか？ 既存 Construction Phase の Unit 完了 commit message との衝突は無いか？

[Answer] 既存 Construction Phase Unit 完了 commit は `feat:` / `fix:` プレフィックスで Unit 名を含むため、`chore: [<cycle>] §7.12 レビュー round <round> 履歴記録` は衝突しない。`round` 番号は `--round` 引数（1-5 整数）から導出する。確定。

[Question] 案 B の dirty 検出時に exit 1 を返すが、`squash:failed:reason=...` のサフィックスで `dirty_history` を追加すべきか？ 既存 `git_op_failed:%d` パターンとの整合性は？

[Answer] 既存サフィックスパターン（`squash:failed:reason=git_op_failed:%d`）と整合させ、`squash:failed:reason=dirty_history` を新規追加する。stdout 機械可読出力として明示。

[Question] integration テストの形式は bats / 専用シェルスクリプトのどちら？

[Answer] 既存テスト構成（`tests/operations-release-*.bats`）と整合させるため bats 形式とする。一時 git リポジトリ生成は既存 `setup()` パターンを踏襲。
