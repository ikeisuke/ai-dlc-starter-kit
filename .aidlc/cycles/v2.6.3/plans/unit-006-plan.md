# Unit 006 実装計画: write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化

## 対象 Unit

- **Unit**: 006 - write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化
- **関連 Issue**: #702
- **優先度**: Low
- **depth_level**: standard

## 背景・目的

`skills/aidlc/scripts/write-history.sh` の `check_history_staged_status()`（行 545 以降）と
`_commit_operations_round_history()`（行 622 以降）に「filepath の symlink 解決 → repo-root 取得 →
repo-root 相対パス正規化」の 4 ステップ（ステップ 0 / 1 / 2 共通）が重複している。

v2.6.2 Unit 003（#677 fix）の Codex コードレビュー Round 1 LOW #2 指摘が起点。共通ヘルパ化は当時の
Unit 003 スコープ外（refactor）のため #702 として別 Issue 起票され、本 Unit で対応する。

本 Unit は共通ヘルパ関数を導入し、両関数が同一ヘルパを呼ぶよう改修して、片側だけ修正される保守
リスクを排除する。挙動は等価維持（入出力契約は変更しない）。

## スコープ

### 含まれるもの（責務）

- `skills/aidlc/scripts/write-history.sh` に共通ヘルパ関数を追加する
  - 関数名: `_resolve_history_filepath_in_repo`（既存命名規約: `_` プレフィックスの内部関数）
  - シグネチャ: `_resolve_history_filepath_in_repo <filepath> <repo_root_out_var> <rel_path_out_var>`
  - 入力: filepath（履歴ファイルパス。絶対 / 相対どちらでも可）
  - 出力（result-out 方式）: `repo_root_out_var` に repo-root の絶対パス、
    `rel_path_out_var` に repo-root 相対パスを `printf -v` で書き込む
  - 戻り値: 0=成功、1=symlink 解決失敗（親ディレクトリにアクセス不能）、
    2=git リポジトリ外、3=repo 配下でない（接頭辞除去失敗）
  - ヘルパ自体は warning を出力しない（呼び出し元が exit code に応じて適切な warning を出力する責務）
- `check_history_staged_status()` を共通ヘルパ経由に改修
  - 重複していた「ステップ 0 / ステップ 1 / ステップ 2」を共通ヘルパ呼び出し 1 回に置き換え
  - 既存挙動を維持（**いずれの失敗ケースでも silent return 0**、stderr warning は出力しない）
  - 既存の warning 契約「unstaged 時の stderr 出力（"warning: history file unstaged: <呼び出し元が
    渡した filepath / 現運用では絶対パス>"）」と exit 0 は完全互換
- `_commit_operations_round_history()` を共通ヘルパ経由に改修
  - 同じく重複処理を共通ヘルパ呼び出し 1 回に置き換え
  - 既存の warning 文言を exit code に応じて分岐して維持
    - exit 1 → `warning: cannot resolve history file directory, skipping auto-commit: <filepath>`
    - exit 2 → `warning: not inside a git repository, skipping auto-commit: <filepath>`
    - exit 3 → `warning: history file is outside repository, skipping auto-commit: <filepath>`
  - return 0（既存の skip 挙動を維持）
- `filepath_real` の再構築: 共通ヘルパ呼び出し後、必要な場合は呼び出し元で `"${repo_root}/${rel_path}"`
  として再構築する
- CLAUDE.md「printf -v 系 result-out 関数の local 命名規約」に準拠
  - 共通ヘルパ内部の作業用 local は `_local_rhf_*` 形式（`rhf` = resolve history filepath の略）で
    namespace 化する
  - `_result_var` / `_input` などの標準パラメータバインディング名は慣例名のまま許容
- 既存 bats テスト群（`write-history-history-staged-warning.bats` / `write-history-modes.bats` /
  `write-history-operations-round-commit.bats`）が回帰なく全 pass することを確認

### 含まれないもの（境界）

- `write-history.sh` の履歴記録ロジック本体（追記処理 / モード分岐 / 引数パース）の変更は行わない
- パス解決の挙動自体の変更は行わない（重複コードの共通化のみ、入出力は等価）
- 外部公開インターフェース（コマンドライン引数 / stdout 契約 / exit code 契約）の変更は行わない
- 共通ヘルパの配置先を `bootstrap.sh` / 別 lib に移すリファクタは含まない（Unit 定義「技術的考慮事項」で
  「配置先（write-history.sh 内のローカル関数 / bootstrap.sh / 別 lib）は設計時に確定する」と
  あり、本計画では **write-history.sh 内のローカル関数** として配置する。理由は下記「実装方針」参照）
- 新規 bats テストの追加は最小限とする（既存テスト群で双方の caller の挙動を間接的に検証可能）

## 実装方針

### Phase 1: 設計

#### 配置先の確定（write-history.sh 内のローカル関数）

| 候補 | 採用可否 | 理由 |
|------|---------|------|
| `write-history.sh` 内のローカル関数（**採用**） | ○ | 影響範囲が `write-history.sh` 内に閉じる / 既存テスト群がそのまま使える / `bootstrap.sh` を介さず読みやすい / 本 Unit は「重複の解消」がスコープであり配置最適化は別 Issue 候補 |
| `bootstrap.sh` 内の共通関数 | × | `bootstrap.sh` 利用側全てへの影響を再評価する必要があり、Low 優先度の本 Unit のスコープを超える |
| 専用 lib（`scripts/lib/history-path.sh` 等） | × | 同上、追加ファイルの分だけ単純度が下がる |

将来 `bootstrap.sh` 配置が望ましい根拠が出た場合は別 Issue として再評価する（現時点では出ていない）。

#### 共通ヘルパのインターフェース契約

```text
関数: _resolve_history_filepath_in_repo
シグネチャ: _resolve_history_filepath_in_repo <filepath> <repo_root_out_var> <rel_path_out_var>

入力:
  $1: filepath（履歴ファイルパス）
  $2: repo_root 書き込み先変数名
  $3: rel_path 書き込み先変数名

出力（result-out 方式）:
  $2 で指定された変数に repo-root の絶対パス（pwd -P 経由で symlink 解決済み）を書き込む
  $3 で指定された変数に repo-root 相対パスを書き込む

戻り値（exit code）:
  0: 成功
  1: symlink 解決失敗（cd "$(dirname filepath)" || pwd -P が失敗、または空文字）
  2: git リポジトリ外（git rev-parse --show-toplevel が失敗、または空文字）
  3: filepath が repo 配下でない（rel_path == filepath_real、接頭辞除去失敗）

副作用:
  なし（stderr 出力なし / stdout 出力なし / 変数書き込みのみ）
  warning は呼び出し元の責務
```

#### printf -v 系 result-out 関数の命名規約適用

CLAUDE.md「printf -v 系 result-out 関数の local 命名規約」に従い、関数内部の作業用 local 宣言は
関数固有プレフィックス `_local_rhf_*` で namespace 化する。

| 用途 | local 変数名 |
|------|------------|
| 親ディレクトリ実体パス | `_local_rhf_dir` |
| filepath 実体パス | `_local_rhf_real` |
| repo-root 絶対パス | `_local_rhf_repo_root` |
| repo-root 相対パス | `_local_rhf_rel` |
| パラメータ受け取り（標準名は許容） | `_result_repo_root_var` / `_result_rel_path_var`（または `$2` / `$3` を直接使う） |

caller 同名 local による dynamic scope shadowing バグ（v2.6.2 da212aea で停止した実例）を予防する。

#### caller 側の改修（before → after）

##### check_history_staged_status

```text
before:
  local filepath_real_dir filepath_real
  local repo_root rel_path staged_files
  
  if ! filepath_real_dir=$(cd "$(dirname -- "$filepath")" 2>/dev/null && pwd -P 2>/dev/null); then
      return 0
  fi
  if [ -z "$filepath_real_dir" ]; then
      return 0
  fi
  filepath_real="${filepath_real_dir}/$(basename -- "$filepath")"
  
  if ! repo_root=$(git -C "$filepath_real_dir" rev-parse --show-toplevel 2>/dev/null); then
      return 0
  fi
  if [ -z "$repo_root" ]; then
      return 0
  fi
  
  rel_path="${filepath_real#${repo_root}/}"
  if [ "$rel_path" = "$filepath_real" ]; then
      return 0
  fi
  
  # ステップ 3 以降（既存ロジック）

after:
  local repo_root rel_path filepath_real staged_files
  
  if ! _resolve_history_filepath_in_repo "$filepath" repo_root rel_path; then
      # 全失敗ケースで silent return 0（既存挙動を維持）
      return 0
  fi
  filepath_real="${repo_root}/${rel_path}"
  
  # ステップ 3 以降（既存ロジック）
```

##### _commit_operations_round_history

```text
before:
  local filepath_real_dir filepath_real repo_root rel_path
  
  # 3 ステップ × 2 ガード = 重複コード（warning 文言は途中で 3 種類）
  ...

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

#### ドキュメント設計

- `write-history.sh` ヘッダのコメントブロック内に、新規ヘルパ関数の説明コメント（インターフェース契約 +
  printf -v 命名規約への参照）を追加
- `check_history_staged_status` / `_commit_operations_round_history` の冒頭コメントで「symlink 解決 +
  repo-root 取得 + 相対パス化は `_resolve_history_filepath_in_repo` に集約」と明示

#### テスト設計

- **新規 bats テスト追加（必須）**:
  - 共通ヘルパは内部関数（`_` プレフィックス）だが、stdout / stderr 非出力 + exit code 4 経路の
    正しさを検証するため `tests/write-history-resolve-helper.bats` を新規追加する
  - 双方の caller（`check_history_staged_status` / `_commit_operations_round_history`）の挙動は
    既存 bats テスト群（回帰確認用）+ 想定外 exit code の `*)` fail-safe 動作 1 ケース追加で検証する
- 既存 bats 全 pass を確認
  - `tests/write-history-history-staged-warning.bats`（3 ケース）
  - `tests/write-history-modes.bats`
  - `tests/write-history-operations-round-commit.bats`
- shellcheck で新規 warning が出ないことを確認（`bash -n` + shellcheck）

### Phase 2: 実装

1. **共通ヘルパ関数追加**
   - `write-history.sh` の `check_history_staged_status` の直前（行 545 付近）に
     `_resolve_history_filepath_in_repo` を追加
   - インターフェース契約コメント + printf -v 命名規約コメントを冒頭に記載
2. **`check_history_staged_status` を共通ヘルパ経由に置き換え**
   - 重複ステップ 0 / 1 / 2 を共通ヘルパ 1 回呼び出しに圧縮
   - 失敗時は silent return 0（既存挙動）を維持
3. **`_commit_operations_round_history` を共通ヘルパ経由に置き換え**
   - exit code に応じて既存 warning 文言を分岐して維持
4. **bats 回帰テスト実行**
   - `bats tests/write-history-history-staged-warning.bats`
   - `bats tests/write-history-modes.bats`
   - `bats tests/write-history-operations-round-commit.bats`
5. **静的検査**
   - `bash -n skills/aidlc/scripts/write-history.sh`
   - `shellcheck skills/aidlc/scripts/write-history.sh`（既存警告との差分を確認、新規警告 0 件）
6. **markdownlint 実行**（cycle scope）
   - `bash skills/aidlc/scripts/run-markdownlint.sh v2.6.3` で新規エラー 0 件

## 完了条件チェックリスト

### #702 受け入れ基準

- [x] 共通ヘルパ関数 `_resolve_history_filepath_in_repo` が追加され `(repo_root, rel_path)` の
      result-out インターフェースになっている
- [x] `check_history_staged_status` と `_commit_operations_round_history` の双方が共通ヘルパを使用して
      いる（重複コードの解消）
- [x] パス解決失敗時のスキップ挙動が caller 別に維持されている:
  - `check_history_staged_status`: silent return 0
  - `_commit_operations_round_history`: stderr warning + return 0（既存 3 文言を exit code 別に維持）
- [x] 既存 bats テスト群が回帰なく全 pass する（25 / 25 ケース）
- [x] **新規 bats テスト `tests/write-history-resolve-helper.bats` で**、helper を成功 / 失敗（exit 1
      / 2 / 3）の各経路で呼び、stdout / stderr が空であることと exit code が期待値であることを assert
      する（テスト方針は「helper 単独テスト必須化」に一本化）
- [x] caller 側 bats（新規 `write-history-resolve-helper.bats` Case (e)）で、`_commit_operations_round_history`
      の `*)` fail-safe 分岐（想定外 exit code 時の skip 経路）動作を最小限のケースで確認する

### 共通

- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い実施されている
- [x] CLAUDE.md「printf -v 系 result-out 関数の local 命名規約」に準拠（共通ヘルパ内部の作業用 local が
      `_local_rhf_*` 形式で namespace 化されている）
- [x] CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」「コマンド置換禁止」「codex exec の
      stdin 待ちガード」規約に違反しない
- [x] `bash -n` / `shellcheck` で新規警告 0 件（SC2295 件数: 2 → 1 改善）
- [x] cycle scope markdownlint で新規 violation を導入していない（run-markdownlint.sh v2.6.3 = 0 error）

## リスク・考慮事項

- **dynamic scope shadowing 再発**: caller 同名 local（`repo_root` / `rel_path`）を helper 内部にも
  宣言すると `printf -v "$result_var"` が caller の変数ではなく helper 内 local に書き込まれて
  caller 側が空のまま残るバグが発生する（v2.6.2 da212aea で実証済）。本計画では `_local_rhf_*`
  namespace で予防する
- **exit code semantics の caller 側ハンドリング差異**: `check_history_staged_status` は silent
  return 0、`_commit_operations_round_history` は warning 出力 + return 0。両者の差を helper 側に
  寄せず caller 側で分岐させることで helper の単一責務を保つ
- **挙動の等価性**: refactor の前後で「symlink 解決 + repo-root 取得 + 相対パス化」の入出力が等価で
  あることを既存 bats テスト群で検証する
- **将来の配置最適化**: `bootstrap.sh` 配置 / 別 lib 化は本 Unit のスコープ外。必要時に別 Issue で
  評価する
- **全作業で Bash ツール経由のコマンド置換（`$(...)` / backtick）を引数文字列に含めない**
  （CLAUDE.md「AI エージェント Bash ツール経由の安全パターン」準拠）
- **codex exec の stdin 待ちガード**: AI レビュー実行時は `</dev/null` または stdin リダイレクト経由で
  呼び出す（CLAUDE.md「codex exec の stdin 待ちガード」規約準拠）
