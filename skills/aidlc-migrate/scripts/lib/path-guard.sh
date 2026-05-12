#!/usr/bin/env bash
#
# lib/path-guard.sh - aidlc-migrate manifest 由来パスのトラバーサル検証ライブラリ
#
# 公開 API:
#   _aidlc_migrate_path_guard_init                       起動時1回呼び出して境界を解決
#   _aidlc_migrate_validate_path <raw> <field> <script>  検証実行（init 済み前提）
#   _aidlc_migrate_realpath <input> [base]               テスト用に公開する shim
#
# 終了コード（戻り値）:
#   0 検証成功（accepted）
#   1 検証失敗（rejected / バリデーションエラー）
#   2 システムエラー（init 失敗 / realpath 失敗等）
#
# エラー出力（stderr / tab 区切り 4 フィールド）:
#   error\t<script_id>:path-traversal\t<offending_path>\treason=<code>
#   error\t<script_id>:realpath-system-error\t<offending_path>\treason=<system_code>
#   error\tpath-guard:init-failed\t<value_or_unset>\treason=<system_code>
#
# 実装方針:
#   - 新規導入の本ファイル内ではコマンド置換 $(...) を使用しない（Unit 002 Intent 制約）
#   - 中間結果は process substitution <(...) + read で直接受信（一時ファイル不使用 / TOCTOU 回避 / CWE-59/CWE-377 対策）
#   - エラー出力は tab 区切り 4 フィールド固定。第4フィールド内に `;field=<name>` を含めることで診断精度を上げる

# Guard against double source
if [[ -n "${_AIDLC_MIGRATE_PATH_GUARD_SOURCED:-}" ]]; then
  return 0
fi
_AIDLC_MIGRATE_PATH_GUARD_SOURCED=1

# 内部状態
_AIDLC_MIGRATE_PATH_GUARD_ROOT=""
_AIDLC_MIGRATE_PATH_GUARD_REALPATH_M_SUPPORTED=""

# tab 区切り 4 フィールド stderr 出力
# 第4フィールド形式: reason=<code> または reason=<code>;field=<name>（フィールド数は常に 4 を維持）
_aidlc_migrate_path_guard_emit_error() {
  local kind="$1"
  local script_id="$2"
  local offending_path="$3"
  local reason_code="$4"
  local field_name="${5:-}"
  if [[ -n "$field_name" ]]; then
    printf 'error\t%s:%s\t%s\treason=%s;field=%s\n' "$script_id" "$kind" "$offending_path" "$reason_code" "$field_name" >&2
  else
    printf 'error\t%s:%s\t%s\treason=%s\n' "$script_id" "$kind" "$offending_path" "$reason_code" >&2
  fi
}

# realpath -m サポート判定（初回のみ評価しキャッシュ）
_aidlc_migrate_path_guard_detect_realpath_m() {
  if [[ -n "$_AIDLC_MIGRATE_PATH_GUARD_REALPATH_M_SUPPORTED" ]]; then
    return 0
  fi
  if command -v realpath >/dev/null 2>&1 && realpath -m / >/dev/null 2>&1; then
    _AIDLC_MIGRATE_PATH_GUARD_REALPATH_M_SUPPORTED=1
  else
    _AIDLC_MIGRATE_PATH_GUARD_REALPATH_M_SUPPORTED=0
  fi
}

# realpath shim 第一選択: realpath -m
# 引数: $1=result_var_name, $2=input
# 一時ファイル不使用（process substitution + read で直接受信 / TOCTOU 回避）
_aidlc_migrate_path_guard_realpath_m_into() {
  local _result_var="$1"
  local _input="$2"
  # NOTE: 呼出側 (`_aidlc_migrate_realpath` / `_aidlc_migrate_path_guard_init`) が
  # `_resolved` というローカル名で結果を受けるため、本関数内で同名ローカルを宣言すると
  # bash の dynamic scope で `printf -v "_resolved"` が**本関数のローカル**を書き換え、
  # 呼出側の `_resolved` は空のままになる（v2.6.2 CI で表面化、Unit 002 / #680 残課題）。
  # ローカルは別名 `_local_m_resolved` を使用し、shadowing を防ぐ。
  local _local_m_resolved=""
  if ! IFS= read -r _local_m_resolved < <(realpath -m -- "$_input" 2>/dev/null); then
    return 2
  fi
  if [[ -z "$_local_m_resolved" ]]; then
    return 2
  fi
  printf -v "$_result_var" '%s' "$_local_m_resolved"
  return 0
}

# pure bash cd -P フォールバック
# 引数: $1=result_var_name, $2=input, $3=base (絶対パス)
_aidlc_migrate_path_guard_realpath_fallback_into() {
  local _result_var="$1"
  local _input="$2"
  local _base="$3"

  # ステップ 1: 絶対化
  local _candidate
  if [[ "${_input:0:1}" == "/" ]]; then
    _candidate="$_input"
  else
    _candidate="${_base%/}/${_input}"
  fi

  # 末尾スラッシュ正規化（ルート以外は剥がす）
  while [[ "${#_candidate}" -gt 1 && "${_candidate: -1}" == "/" ]]; do
    _candidate="${_candidate%/}"
  done

  # ステップ 2: 末尾から実在ディレクトリを探す（実体不在 path も親方向に遡って解決）
  local _probe="$_candidate"
  local _tail=""
  while true; do
    if [[ -d "$_probe" ]]; then
      break
    fi
    if [[ "$_probe" == "/" || -z "$_probe" ]]; then
      _probe="/"
      break
    fi
    local _segment="${_probe##*/}"
    _tail="/${_segment}${_tail}"
    if [[ "$_probe" == */* ]]; then
      _probe="${_probe%/*}"
      if [[ -z "$_probe" ]]; then
        _probe="/"
      fi
    else
      _probe="/"
    fi
  done

  # ステップ 3: 物理解決（process substitution + read / TOCTOU 回避）
  local _resolved_parent=""
  if ! IFS= read -r _resolved_parent < <( cd -P "$_probe" 2>/dev/null && pwd -P ); then
    return 2
  fi
  if [[ -z "$_resolved_parent" ]]; then
    return 2
  fi

  # ステップ 4: tail を論理結合し、'.' / '..' を辞書的に解決
  # _tail が空ならそのまま _resolved_parent
  if [[ -z "$_tail" ]]; then
    printf -v "$_result_var" '%s' "$_resolved_parent"
    return 0
  fi

  # _tail を / で分割（先頭 / を除いた後）
  local _normalized="$_resolved_parent"
  local _rest="${_tail#/}"
  local _segment=""
  while [[ -n "$_rest" ]]; do
    if [[ "$_rest" == */* ]]; then
      _segment="${_rest%%/*}"
      _rest="${_rest#*/}"
    else
      _segment="$_rest"
      _rest=""
    fi
    case "$_segment" in
      ""|".") : ;;
      "..")
        if [[ "$_normalized" == "/" ]]; then
          : # ルートで .. は no-op
        else
          _normalized="${_normalized%/*}"
          if [[ -z "$_normalized" ]]; then
            _normalized="/"
          fi
        fi
        ;;
      *)
        if [[ "$_normalized" == "/" ]]; then
          _normalized="/${_segment}"
        else
          _normalized="${_normalized}/${_segment}"
        fi
        ;;
    esac
  done

  printf -v "$_result_var" '%s' "$_normalized"
  return 0
}

# 公開関数: realpath shim
# 引数: $1=result_var_name (出力先), $2=input, $3=base (任意、デフォルトは現 PWD)
# 戻り値: 0 成功 / 2 システムエラー
_aidlc_migrate_realpath() {
  local _result_var="$1"
  local _input="$2"
  local _base="${3:-}"
  if [[ -z "$_base" ]]; then
    if ! IFS= read -r _base < <(pwd -P 2>/dev/null); then
      return 2
    fi
    if [[ -z "$_base" ]]; then
      return 2
    fi
  fi

  _aidlc_migrate_path_guard_detect_realpath_m
  if [[ "$_AIDLC_MIGRATE_PATH_GUARD_REALPATH_M_SUPPORTED" == "1" ]]; then
    # realpath -m は base を考慮しないため、相対パスは先に絶対化する
    local _abs_input
    if [[ "${_input:0:1}" == "/" ]]; then
      _abs_input="$_input"
    else
      _abs_input="${_base%/}/${_input}"
    fi
    _aidlc_migrate_path_guard_realpath_m_into "$_result_var" "$_abs_input"
    return $?
  fi

  _aidlc_migrate_path_guard_realpath_fallback_into "$_result_var" "$_input" "$_base"
  return $?
}

# 公開関数: 初期化
# AIDLC_PROJECT_ROOT 環境変数を物理解決し _AIDLC_MIGRATE_PATH_GUARD_ROOT に保持する
# 戻り値: 0 成功 / 2 システムエラー
_aidlc_migrate_path_guard_init() {
  if [[ -z "${AIDLC_PROJECT_ROOT:-}" ]]; then
    _aidlc_migrate_path_guard_emit_error "init-failed" "path-guard" "(unset)" "aidlc_project_root_unset"
    return 2
  fi
  local _resolved=""
  if ! _aidlc_migrate_realpath _resolved "$AIDLC_PROJECT_ROOT" "/"; then
    _aidlc_migrate_path_guard_emit_error "init-failed" "path-guard" "$AIDLC_PROJECT_ROOT" "aidlc_project_root_resolution_failed"
    return 2
  fi
  _AIDLC_MIGRATE_PATH_GUARD_ROOT="$_resolved"
  return 0
}

# 内部: path components のいずれかが '..' リテラルか判定
_aidlc_migrate_path_guard_has_parent_segment() {
  local _path="$1"
  local _rest="$_path"
  local _segment=""
  # 先頭の連続スラッシュを取り除く
  while [[ "${_rest:0:1}" == "/" ]]; do
    _rest="${_rest:1}"
  done
  while [[ -n "$_rest" ]]; do
    if [[ "$_rest" == */* ]]; then
      _segment="${_rest%%/*}"
      _rest="${_rest#*/}"
    else
      _segment="$_rest"
      _rest=""
    fi
    if [[ "$_segment" == ".." ]]; then
      return 0
    fi
  done
  return 1
}

# 公開関数: パス検証本体
# 引数: $1=raw_path, $2=field_name, $3=script_id
# 戻り値: 0 accepted / 1 rejected (validation) / 2 system error
_aidlc_migrate_validate_path() {
  local _raw_path="$1"
  local _field_name="$2"
  local _script_id="$3"

  # ステップ 1: 絶対パス判定
  if [[ "${_raw_path:0:1}" == "/" ]]; then
    _aidlc_migrate_path_guard_emit_error "path-traversal" "$_script_id" "$_raw_path" "absolute_path" "$_field_name"
    return 1
  fi

  # ステップ 2: 親参照判定（リテラル '..' 検出 / realpath より前に短絡）
  if _aidlc_migrate_path_guard_has_parent_segment "$_raw_path"; then
    _aidlc_migrate_path_guard_emit_error "path-traversal" "$_script_id" "$_raw_path" "parent_traversal" "$_field_name"
    return 1
  fi

  # ステップ 3: 境界初期化確認
  if [[ -z "${_AIDLC_MIGRATE_PATH_GUARD_ROOT:-}" ]]; then
    _aidlc_migrate_path_guard_emit_error "realpath-system-error" "$_script_id" "$_raw_path" "init_required" "$_field_name"
    return 2
  fi

  # ステップ 4: 物理解決
  local _resolved=""
  if ! _aidlc_migrate_realpath _resolved "$_raw_path" "$_AIDLC_MIGRATE_PATH_GUARD_ROOT"; then
    _aidlc_migrate_path_guard_emit_error "realpath-system-error" "$_script_id" "$_raw_path" "realpath_failed" "$_field_name"
    return 2
  fi

  # ステップ 5: 配下判定
  local _root="$_AIDLC_MIGRATE_PATH_GUARD_ROOT"
  if [[ "$_resolved" == "$_root" || "$_resolved" == "$_root"/* ]]; then
    return 0
  fi

  # 配下外: 論理パス（symlink 解決なし / '.' '..' のみ辞書解決）と物理パスの差で symlink_escape を判定
  local _logical_only=""
  _aidlc_migrate_path_guard_normalize_logical_only _logical_only "$_raw_path" "$_root"

  if [[ "$_logical_only" == "$_root" || "$_logical_only" == "$_root"/* ]]; then
    # 論理パスは配下、物理パスは配下外 → symlink 経由脱出
    _aidlc_migrate_path_guard_emit_error "path-traversal" "$_script_id" "$_raw_path" "symlink_escape" "$_field_name"
  else
    # 安全装置（defense-in-depth）: 論理パスも物理パスも配下外。
    # raw_path レベルでは absolute_path / parent_traversal で短絡されるため通常到達しない。
    # AIDLC_PROJECT_ROOT が予期せぬ移動をした場合等の fail-closed 用バックストップ
    _aidlc_migrate_path_guard_emit_error "path-traversal" "$_script_id" "$_raw_path" "outside_project_root" "$_field_name"
  fi
  return 1
}

# 内部: 純粋な論理パス正規化（symlink 解決なし / '.' '..' のみ辞書解決）
# 引数: $1=result_var, $2=input, $3=base (絶対パス)
_aidlc_migrate_path_guard_normalize_logical_only() {
  local _result_var="$1"
  local _input="$2"
  local _base="$3"

  local _candidate
  if [[ "${_input:0:1}" == "/" ]]; then
    _candidate="$_input"
  else
    _candidate="${_base%/}/${_input}"
  fi

  local _normalized="/"
  local _rest="${_candidate#/}"
  local _segment=""
  while [[ -n "$_rest" ]]; do
    if [[ "$_rest" == */* ]]; then
      _segment="${_rest%%/*}"
      _rest="${_rest#*/}"
    else
      _segment="$_rest"
      _rest=""
    fi
    case "$_segment" in
      ""|".") : ;;
      "..")
        if [[ "$_normalized" != "/" ]]; then
          _normalized="${_normalized%/*}"
          if [[ -z "$_normalized" ]]; then
            _normalized="/"
          fi
        fi
        ;;
      *)
        if [[ "$_normalized" == "/" ]]; then
          _normalized="/${_segment}"
        else
          _normalized="${_normalized}/${_segment}"
        fi
        ;;
    esac
  done

  printf -v "$_result_var" '%s' "$_normalized"
}
