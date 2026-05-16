# Unit 006 論理設計: write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化

## 概要

本論理設計は共通ヘルパ関数 `_resolve_history_filepath_in_repo` のインターフェース契約・実装パターン・
caller 側の改修方針を確定する。挙動の等価性維持 + dynamic scope shadowing バグ予防 + helper の単一
責務維持を目標とする。

## コンポーネント構成

| コンポーネント | 役割 | 変更有無 |
|---------------|------|---------|
| `skills/aidlc/scripts/write-history.sh` 内 helper `_resolve_history_filepath_in_repo`（新規） | symlink 解決 + repo-root 取得 + 相対パス算出 を result-out 形式で提供 | **新規追加** |
| `check_history_staged_status`（行 545〜） | helper 呼び出しに置換し、silent return 0 挙動を維持 | **変更**（ステップ 0 / 1 / 2 を helper 呼び出し 1 行に圧縮） |
| `_commit_operations_round_history`（行 622〜） | helper 呼び出しに置換し、exit code 別 warning 文言を維持 | **変更**（ステップ 0 / 1 / 2 を helper 呼び出し 1 行 + exit code case 文 に圧縮） |
| 既存 bats テスト群 | caller 挙動の検証 | 非変更（回帰確認用） |
| 新規 bats テスト | helper 自体の exit code 4 経路（0/1/2/3）と stdout / stderr 非出力検証 | **新規追加必須**（一本化方針）|

## helper のインターフェース契約（明示）

### シグネチャ

```text
_resolve_history_filepath_in_repo <filepath> <repo_root_out_var> <rel_path_out_var>
```

### 入力

| 引数 | 説明 |
|------|------|
| `$1 filepath` | 履歴ファイルパス（絶対 / 相対どちらでも可。dirname / basename で分解する） |
| `$2 repo_root_out_var` | 成功時に repo-root の絶対パスを書き込む先の変数名 |
| `$3 rel_path_out_var` | 成功時に repo-root 相対パスを書き込む先の変数名 |

### 出力（result-out 方式）

成功時のみ、`$2` / `$3` で指定された変数に `printf -v "$var" '%s' "$value"` 形式で書き込む。
失敗時は変数を書き込まない（呼び出し元側で初期化済 local が空のまま残る）。

### 戻り値（exit code）

| code | 意味 | caller 側の典型対応 |
|------|------|-------------------|
| 0 | 成功（`repo_root` / `rel_path` 書き込み済） | 通常処理続行 |
| 1 | symlink 解決失敗（`cd $(dirname filepath) && pwd -P` 失敗 or 空） | check: silent return 0 / commit: `warning: cannot resolve history file directory, skipping auto-commit: <filepath>` + return 0 |
| 2 | git リポジトリ外（`git rev-parse --show-toplevel` 失敗 or 空） | check: silent return 0 / commit: `warning: not inside a git repository, skipping auto-commit: <filepath>` + return 0 |
| 3 | filepath が repo 配下でない（接頭辞除去失敗 / `rel_path == filepath_real`） | check: silent return 0 / commit: `warning: history file is outside repository, skipping auto-commit: <filepath>` + return 0 |

### 副作用

helper 自身は stdout / stderr に一切出力しない（caller の警告責務を侵さない）。

## 内部実装パターン

### printf -v 系 result-out 関数の local 命名規約適用

CLAUDE.md「printf -v 系 result-out 関数の local 命名規約」に従い、helper 内部の作業用 local 宣言は
`_local_rhf_*` プレフィックスで namespace 化する（`rhf` = resolve history filepath の略）。

| 内部用途 | local 変数名 |
|---------|------------|
| 親ディレクトリ実体パス（`pwd -P` 経由） | `_local_rhf_dir` |
| filepath 実体パス（`${_local_rhf_dir}/$(basename filepath)`） | `_local_rhf_real` |
| repo-root 絶対パス | `_local_rhf_repo_root` |
| repo-root 相対パス | `_local_rhf_rel` |

`$2` / `$3` は変数名そのものを保持するため local 宣言は行わず、`printf -v "$2" ...` / `printf -v "$3" ...`
で直接書き込む（caller の `repo_root` / `rel_path` への dynamic scope 書き込みが保証される）。

### 実装骨格（擬似コード）

```text
_resolve_history_filepath_in_repo() {
    # $1: filepath
    # $2: repo_root_out_var
    # $3: rel_path_out_var

    local _local_rhf_dir _local_rhf_real
    local _local_rhf_repo_root _local_rhf_rel

    # ステップ 0: filepath の symlink 解決
    if ! _local_rhf_dir=$(cd "$(dirname -- "$1")" 2>/dev/null && pwd -P 2>/dev/null); then
        return 1
    fi
    if [ -z "$_local_rhf_dir" ]; then
        return 1
    fi
    _local_rhf_real="${_local_rhf_dir}/$(basename -- "$1")"

    # ステップ 1: repo-root 取得
    if ! _local_rhf_repo_root=$(git -C "$_local_rhf_dir" rev-parse --show-toplevel 2>/dev/null); then
        return 2
    fi
    if [ -z "$_local_rhf_repo_root" ]; then
        return 2
    fi

    # ステップ 2: 相対パス化
    _local_rhf_rel="${_local_rhf_real#${_local_rhf_repo_root}/}"
    if [ "$_local_rhf_rel" = "$_local_rhf_real" ]; then
        return 3
    fi

    # 成功: result-out で書き込み
    printf -v "$2" '%s' "$_local_rhf_repo_root"
    printf -v "$3" '%s' "$_local_rhf_rel"
    return 0
}
```

**注**: 上記コードブロック内の `$(...)` はシェルスクリプトの構文要素（command substitution）として
実装ファイルに記載される。これは AI エージェントが Bash ツールへ引数文字列として渡す経路ではなく、
シェルスクリプトファイル内の正規表現的な構文であるため、CLAUDE.md「コマンド置換禁止」規約の対象外
（CLAUDE.md「AI エージェント Bash ツール経由の安全パターン」は AI エージェント呼び出し時の引数経路
が対象）。

## caller 側の改修方針

### `check_history_staged_status`（行 545〜）

```text
before:
  local filepath_real_dir filepath_real
  local repo_root rel_path staged_files
  if ! filepath_real_dir=$(cd ... && pwd -P ...); then return 0; fi
  if [ -z "$filepath_real_dir" ]; then return 0; fi
  filepath_real="${filepath_real_dir}/$(basename ...)"
  if ! repo_root=$(git -C ... rev-parse --show-toplevel ...); then return 0; fi
  if [ -z "$repo_root" ]; then return 0; fi
  rel_path="${filepath_real#${repo_root}/}"
  if [ "$rel_path" = "$filepath_real" ]; then return 0; fi
  # ステップ 3 以降（既存ロジック: git diff --cached + grep -Fxq）

after:
  local repo_root rel_path filepath_real staged_files
  if ! _resolve_history_filepath_in_repo "$filepath" repo_root rel_path; then
      # 全失敗ケースで silent return 0（既存挙動を維持）
      return 0
  fi
  filepath_real="${repo_root}/${rel_path}"
  # ステップ 3 以降（既存ロジック）
```

### `_commit_operations_round_history`（行 622〜）

```text
before:
  local filepath_real_dir filepath_real repo_root rel_path
  if ! filepath_real_dir=$(cd ... && pwd -P ...); then
      echo "warning: cannot resolve history file directory, skipping auto-commit: $filepath" >&2
      return 0
  fi
  if [ -z "$filepath_real_dir" ]; then 同上 echo + return 0; fi
  filepath_real="${filepath_real_dir}/$(basename ...)"
  if ! repo_root=$(git ...); then
      echo "warning: not inside a git repository, skipping auto-commit: $filepath" >&2
      return 0
  fi
  if [ -z "$repo_root" ]; then 同上 echo + return 0; fi
  rel_path="${filepath_real#${repo_root}/}"
  if [ "$rel_path" = "$filepath_real" ]; then
      echo "warning: history file is outside repository, skipping auto-commit: $filepath" >&2
      return 0
  fi
  # ガード 2 以降（既存ロジック）

after:
  local repo_root rel_path filepath_real
  local _rc

  _resolve_history_filepath_in_repo "$filepath" repo_root rel_path
  _rc=$?
  case "$_rc" in
      0) : ;;
      1) echo "warning: cannot resolve history file directory, skipping auto-commit: $filepath" >&2
         return 0 ;;
      2) echo "warning: not inside a git repository, skipping auto-commit: $filepath" >&2
         return 0 ;;
      3) echo "warning: history file is outside repository, skipping auto-commit: $filepath" >&2
         return 0 ;;
      *) # fail-safe: helper 契約逸脱（想定外 exit code）→ 未初期化値の使用を避けて skip
         echo "warning: unexpected helper exit code ($_rc), skipping auto-commit: $filepath" >&2
         return 0 ;;
  esac
  filepath_real="${repo_root}/${rel_path}"
  # ガード 2 以降（既存ロジック）
```

## テスト設計

### 既存 bats（回帰）

- `tests/write-history-history-staged-warning.bats`（3 ケース: unstaged / staged / git 外）
- `tests/write-history-modes.bats`（mode 別動作）
- `tests/write-history-operations-round-commit.bats`（auto-commit + ガード経路）

→ 全 pass 維持。helper 経由化は等価変換のため、caller 観点の挙動は変わらない。

### 新規 bats（helper 単独 stdout/stderr 非出力検証 / **必須**）

- 「**helper 単独呼び出しで stdout / stderr が空、exit code が 0/1/2/3 の各パスで正しい**」ことを
  **必須**の bats テストで検証する（テスト方針は本 Unit で「helper 単独テスト必須化」に一本化）
  - 配置: `tests/write-history-resolve-helper.bats`（新規）
  - 検証ケース:
    - 成功（valid filepath in repo） → exit 0 + stdout 空 + stderr 空 + 変数書き込み済み
    - exit 1（symlink 解決失敗を `cd` 失敗で再現） → exit 1 + stdout 空 + stderr 空
    - exit 2（git 外 directory） → exit 2 + stdout 空 + stderr 空
    - exit 3（repo 外 absolute path） → exit 3 + stdout 空 + stderr 空
  - 想定外 exit code が caller 側でブロックされること（`_commit_operations_round_history` 側の
    `*)` fail-safe 分岐）の確認は caller 側 bats テストで補完する
  - bats 内部で `write-history.sh` を source する代わりに、helper 関数を直接定義 export し
    呼び出す方法、または subprocess で `bash -c 'source ...; _resolve_history_filepath_in_repo ...'`
    を起動して stdout / stderr / exit を assert する方法のいずれかを採用（実装時に確定）

### 静的検査

- `bash -n skills/aidlc/scripts/write-history.sh`（構文チェック）
- `shellcheck skills/aidlc/scripts/write-history.sh`（既存警告との差分を確認、新規警告 0 件）

## 既存記述との整合

- `write-history.sh` ヘッダコメント内に、新規 helper のインターフェース契約 + printf -v 命名規約への
  参照を追加
- `check_history_staged_status` / `_commit_operations_round_history` の冒頭コメントで「symlink 解決
  + repo-root 取得 + 相対パス化は `_resolve_history_filepath_in_repo` に集約」と明示
- 既存 warning 契約 SoT（`.aidlc/cycles/v2.5.5/plans/unit-003-plan.md` § warning 契約）への参照は
  維持（変更しない）

## 参照

- 計画: `.aidlc/cycles/v2.6.3/plans/unit-006-plan.md`
- ドメインモデル: `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_006_write_history_helper_refactor_domain_model.md`
- 改修対象: `skills/aidlc/scripts/write-history.sh` の `check_history_staged_status`（行 545〜）と
  `_commit_operations_round_history`（行 622〜）
- 関連 Issue: #702
