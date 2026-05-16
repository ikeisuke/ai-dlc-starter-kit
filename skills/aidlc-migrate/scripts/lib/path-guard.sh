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
#
# result-out 関数の local 命名規約（v2.6.3 Unit 001 / #706）:
#   引数で結果書き込み先変数名を受け取り `printf -v "$_result_var"` で書き込む関数（result-out 関数）、
#   および result-out 関数を呼んで結果を受け取る caller 側の結果受け取り用 local は、関数固有プレフィックス
#   `_local_<関数省略名>_<名>` で namespace 化する。caller と同名 local を宣言すると bash の dynamic scope に
#   より `printf -v` が内部 local を書き換え caller 変数が空のまま残る致命的バグを招く（v2.6.2 CI 停止の原因 /
#   修正コミット da212aea）。標準パラメータバインディング `_result_var` / `_input` / `_base` 等は関数間で一貫し
#   shadowing リスクがないため慣例名のまま許容する。規約 SoT: CLAUDE.md「printf -v 系 result-out 関数の
#   local 命名規約」。

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
#
# result-out 関数: 内部 local は `_local_m_<名>` で namespace 化する（規約 SoT: CLAUDE.md
# 「printf -v 系 result-out 関数の local 命名規約」）。
_aidlc_migrate_path_guard_realpath_m_into() {
  local _result_var="$1"
  local _input="$2"
  # NOTE: 呼出側 (`_aidlc_migrate_realpath` / `_aidlc_migrate_path_guard_init`) が
  # 結果受け取り用ローカルを宣言するため、本関数内で同名ローカルを宣言すると bash の
  # dynamic scope で `printf -v` が**本関数のローカル**を書き換え、呼出側の変数は空のまま
  # になる（v2.6.2 CI で表面化、Unit 002 / #680）。ローカルは `_local_m_resolved` を使用し
  # shadowing を防ぐ（規約: result-out 関数の local 命名規約 / 上記ファイルヘッダ参照）。
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
#
# result-out 関数: 内部 local は `_local_fb_<名>` で namespace 化する（規約 SoT: CLAUDE.md
# 「printf -v 系 result-out 関数の local 命名規約」）。caller と同名 local を宣言すると
# dynamic scope shadowing で `printf -v` の書き込み先が逸脱する。
_aidlc_migrate_path_guard_realpath_fallback_into() {
  local _result_var="$1"
  local _input="$2"
  local _base="$3"

  # ステップ 1: 絶対化
  local _local_fb_candidate
  if [[ "${_input:0:1}" == "/" ]]; then
    _local_fb_candidate="$_input"
  else
    _local_fb_candidate="${_base%/}/${_input}"
  fi

  # 末尾スラッシュ正規化（ルート以外は剥がす）
  while [[ "${#_local_fb_candidate}" -gt 1 && "${_local_fb_candidate: -1}" == "/" ]]; do
    _local_fb_candidate="${_local_fb_candidate%/}"
  done

  # ステップ 2: 末尾から実在ディレクトリを探す（実体不在 path も親方向に遡って解決）
  local _local_fb_probe="$_local_fb_candidate"
  local _local_fb_tail=""
  while true; do
    if [[ -d "$_local_fb_probe" ]]; then
      break
    fi
    if [[ "$_local_fb_probe" == "/" || -z "$_local_fb_probe" ]]; then
      _local_fb_probe="/"
      break
    fi
    local _local_fb_segment="${_local_fb_probe##*/}"
    _local_fb_tail="/${_local_fb_segment}${_local_fb_tail}"
    if [[ "$_local_fb_probe" == */* ]]; then
      _local_fb_probe="${_local_fb_probe%/*}"
      if [[ -z "$_local_fb_probe" ]]; then
        _local_fb_probe="/"
      fi
    else
      _local_fb_probe="/"
    fi
  done

  # ステップ 3: 物理解決（process substitution + read / TOCTOU 回避）
  local _local_fb_resolved_parent=""
  if ! IFS= read -r _local_fb_resolved_parent < <( cd -P "$_local_fb_probe" 2>/dev/null && pwd -P ); then
    return 2
  fi
  if [[ -z "$_local_fb_resolved_parent" ]]; then
    return 2
  fi

  # ステップ 4: tail を論理結合し、'.' / '..' を辞書的に解決
  # _local_fb_tail が空ならそのまま _local_fb_resolved_parent
  if [[ -z "$_local_fb_tail" ]]; then
    printf -v "$_result_var" '%s' "$_local_fb_resolved_parent"
    return 0
  fi

  # _local_fb_tail を / で分割（先頭 / を除いた後）
  local _local_fb_normalized="$_local_fb_resolved_parent"
  local _local_fb_rest="${_local_fb_tail#/}"
  local _local_fb_segment=""
  while [[ -n "$_local_fb_rest" ]]; do
    if [[ "$_local_fb_rest" == */* ]]; then
      _local_fb_segment="${_local_fb_rest%%/*}"
      _local_fb_rest="${_local_fb_rest#*/}"
    else
      _local_fb_segment="$_local_fb_rest"
      _local_fb_rest=""
    fi
    case "$_local_fb_segment" in
      ""|".") : ;;
      "..")
        if [[ "$_local_fb_normalized" == "/" ]]; then
          : # ルートで .. は no-op
        else
          _local_fb_normalized="${_local_fb_normalized%/*}"
          if [[ -z "$_local_fb_normalized" ]]; then
            _local_fb_normalized="/"
          fi
        fi
        ;;
      *)
        if [[ "$_local_fb_normalized" == "/" ]]; then
          _local_fb_normalized="/${_local_fb_segment}"
        else
          _local_fb_normalized="${_local_fb_normalized}/${_local_fb_segment}"
        fi
        ;;
    esac
  done

  printf -v "$_result_var" '%s' "$_local_fb_normalized"
  return 0
}

# 公開関数: realpath shim
# 引数: $1=result_var_name (出力先), $2=input, $3=base (任意、デフォルトは現 PWD)
# 戻り値: 0 成功 / 2 システムエラー
#
# result-out 関数: 内部 local は `_local_rp_<名>` で namespace 化する（規約 SoT: CLAUDE.md
# 「printf -v 系 result-out 関数の local 命名規約」）。
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
    local _local_rp_abs_input
    if [[ "${_input:0:1}" == "/" ]]; then
      _local_rp_abs_input="$_input"
    else
      _local_rp_abs_input="${_base%/}/${_input}"
    fi
    _aidlc_migrate_path_guard_realpath_m_into "$_result_var" "$_local_rp_abs_input"
    return $?
  fi

  _aidlc_migrate_path_guard_realpath_fallback_into "$_result_var" "$_input" "$_base"
  return $?
}

# 公開関数: 初期化
# AIDLC_PROJECT_ROOT 環境変数を物理解決し _AIDLC_MIGRATE_PATH_GUARD_ROOT に保持する
# 戻り値: 0 成功 / 2 システムエラー
#
# result-out 関数の caller: `_aidlc_migrate_realpath` へ渡す結果受け取り用 local は
# `_local_init_<名>` で namespace 化する（規約 SoT: CLAUDE.md「printf -v 系 result-out
# 関数の local 命名規約」）。
_aidlc_migrate_path_guard_init() {
  if [[ -z "${AIDLC_PROJECT_ROOT:-}" ]]; then
    _aidlc_migrate_path_guard_emit_error "init-failed" "path-guard" "(unset)" "aidlc_project_root_unset"
    return 2
  fi
  local _local_init_resolved=""
  if ! _aidlc_migrate_realpath _local_init_resolved "$AIDLC_PROJECT_ROOT" "/"; then
    _aidlc_migrate_path_guard_emit_error "init-failed" "path-guard" "$AIDLC_PROJECT_ROOT" "aidlc_project_root_resolution_failed"
    return 2
  fi
  _AIDLC_MIGRATE_PATH_GUARD_ROOT="$_local_init_resolved"
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
#
# result-out 関数の caller: `_aidlc_migrate_realpath` /
# `_aidlc_migrate_path_guard_normalize_logical_only` へ渡す結果受け取り用 local は
# `_local_vp_<名>` で namespace 化する（規約 SoT: CLAUDE.md「printf -v 系 result-out
# 関数の local 命名規約」）。
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
  local _local_vp_resolved=""
  if ! _aidlc_migrate_realpath _local_vp_resolved "$_raw_path" "$_AIDLC_MIGRATE_PATH_GUARD_ROOT"; then
    _aidlc_migrate_path_guard_emit_error "realpath-system-error" "$_script_id" "$_raw_path" "realpath_failed" "$_field_name"
    return 2
  fi

  # ステップ 5: 配下判定
  local _local_vp_root="$_AIDLC_MIGRATE_PATH_GUARD_ROOT"
  if [[ "$_local_vp_resolved" == "$_local_vp_root" || "$_local_vp_resolved" == "$_local_vp_root"/* ]]; then
    return 0
  fi

  # 配下外: 論理パス（symlink 解決なし / '.' '..' のみ辞書解決）と物理パスの差で symlink_escape を判定
  local _local_vp_logical_only=""
  _aidlc_migrate_path_guard_normalize_logical_only _local_vp_logical_only "$_raw_path" "$_local_vp_root"

  if [[ "$_local_vp_logical_only" == "$_local_vp_root" || "$_local_vp_logical_only" == "$_local_vp_root"/* ]]; then
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
#
# result-out 関数: 内部 local は `_local_nlo_<名>` で namespace 化する（規約 SoT: CLAUDE.md
# 「printf -v 系 result-out 関数の local 命名規約」）。
_aidlc_migrate_path_guard_normalize_logical_only() {
  local _result_var="$1"
  local _input="$2"
  local _base="$3"

  local _local_nlo_candidate
  if [[ "${_input:0:1}" == "/" ]]; then
    _local_nlo_candidate="$_input"
  else
    _local_nlo_candidate="${_base%/}/${_input}"
  fi

  local _local_nlo_normalized="/"
  local _local_nlo_rest="${_local_nlo_candidate#/}"
  local _local_nlo_segment=""
  while [[ -n "$_local_nlo_rest" ]]; do
    if [[ "$_local_nlo_rest" == */* ]]; then
      _local_nlo_segment="${_local_nlo_rest%%/*}"
      _local_nlo_rest="${_local_nlo_rest#*/}"
    else
      _local_nlo_segment="$_local_nlo_rest"
      _local_nlo_rest=""
    fi
    case "$_local_nlo_segment" in
      ""|".") : ;;
      "..")
        if [[ "$_local_nlo_normalized" != "/" ]]; then
          _local_nlo_normalized="${_local_nlo_normalized%/*}"
          if [[ -z "$_local_nlo_normalized" ]]; then
            _local_nlo_normalized="/"
          fi
        fi
        ;;
      *)
        if [[ "$_local_nlo_normalized" == "/" ]]; then
          _local_nlo_normalized="/${_local_nlo_segment}"
        else
          _local_nlo_normalized="${_local_nlo_normalized}/${_local_nlo_segment}"
        fi
        ;;
    esac
  done

  printf -v "$_result_var" '%s' "$_local_nlo_normalized"
}
