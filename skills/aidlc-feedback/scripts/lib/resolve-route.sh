#!/usr/bin/env bash
# resolve-route.sh - feedback Issue 起票経路の純関数判定ヘルパー
#
# Unit 003 / #690 / v2.6.1
# 詳細仕様: .aidlc/cycles/v2.6.1/design-artifacts/logical-designs/unit_003_aidlc_feedback_web_opt_in_logical_design.md
#
# 真理値表 SoT: .aidlc/cycles/v2.6.1/story-artifacts/user_stories.md ストーリー 3
# 優先順位: TTY 状態 > 設定 > フラグ

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: resolve-route.sh <subcommand> [args...]

subcommands:
  resolve <setting> <explicit_web> <is_tty>
    <setting>      : true / false / unset_or_invalid
    <explicit_web> : true / false
    <is_tty>       : true / false
  normalize-explicit-web <raw_env_value>
    Normalize a value (stdin-style) of AIDLC_FEEDBACK_WEB to "true" / "false".
  normalize-setting <exit_code> <raw_value>
    Normalize a (exit_code, stdout) pair from read-config.sh into one of
    "true" / "false" / "unset_or_invalid". Emits a warning on stderr when
    invalid type or read-config.sh error (exit 2) is detected.
  should-warn-override <setting> <explicit_web> <is_tty>
    Print "true" if WarningEmitter should emit the non-TTY override warning
    (is_tty=false && (setting=true || explicit_web=true)), otherwise "false".
EOF
}

# resolve_feedback_route - 経路判定純関数
# 引数:
#   $1: setting       (true / false / unset_or_invalid)
#   $2: explicit_web  (true / false)
#   $3: is_tty        (true / false)
# 出力: stdout に "web" または "direct"
# 終了コード: 0=成功 / 1=入力不正
resolve_feedback_route() {
  local setting="${1:-}"
  local explicit_web="${2:-}"
  local is_tty="${3:-}"

  case "$setting" in
    true|false|unset_or_invalid) ;;
    *)
      printf 'error: invalid input: setting=%q (expected: true / false / unset_or_invalid)\n' "$setting" >&2
      return 1
      ;;
  esac

  case "$explicit_web" in
    true|false) ;;
    *)
      printf 'error: invalid input: explicit_web=%q (expected: true / false)\n' "$explicit_web" >&2
      return 1
      ;;
  esac

  case "$is_tty" in
    true|false) ;;
    *)
      printf 'error: invalid input: is_tty=%q (expected: true / false)\n' "$is_tty" >&2
      return 1
      ;;
  esac

  # 真理値表（user_stories.md ストーリー 3 SoT）
  if [[ "$is_tty" == "false" ]]; then
    printf 'direct\n'
    return 0
  fi

  if [[ "$setting" == "true" ]]; then
    printf 'web\n'
    return 0
  fi

  # setting in {false, unset_or_invalid} かつ is_tty == true
  if [[ "$explicit_web" == "true" ]]; then
    printf 'web\n'
    return 0
  fi

  printf 'direct\n'
  return 0
}

# normalize_explicit_web - 環境変数 AIDLC_FEEDBACK_WEB を boolean 文字列に正規化
# 引数: $1: 環境変数値（呼び出し側で ${AIDLC_FEEDBACK_WEB:-} 等を渡す）
# 出力: stdout に "true" または "false"
# 真理値解釈: 1 / true / yes（大小文字無視、前後空白除去後）→ true / それ以外 → false
normalize_explicit_web() {
  local raw="${1:-}"
  local trimmed="$raw"
  # 前後空白除去
  trimmed="${trimmed#"${trimmed%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  local lower
  lower="$(printf '%s' "$trimmed" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    1|true|yes) printf 'true\n' ;;
    *)          printf 'false\n' ;;
  esac
}

# normalize_setting - read-config.sh の (exit_code, stdout) ペアを setting 3 値に正規化
# 引数:
#   $1: exit_code (read-config.sh の終了コード: 0 / 1 / 2)
#   $2: raw_value  (read-config.sh の stdout、exit 1/2 時は空)
# 出力: stdout に "true" / "false" / "unset_or_invalid"
# 副作用: 型不一致 (exit 0 + 想定外値) または exit 2 のとき stderr に警告 1 行
# 終了コード: 0=成功、1=入力不正（exit_code が 0/1/2 以外）
normalize_setting() {
  local exit_code="${1:-}"
  local raw_value="${2:-}"

  case "$exit_code" in
    0|1|2) ;;
    *)
      printf 'error: invalid input: exit_code=%q (expected: 0 / 1 / 2)\n' "$exit_code" >&2
      return 1
      ;;
  esac

  if [[ "$exit_code" == "1" ]]; then
    # 未設定の正常ケース（警告なし）
    printf 'unset_or_invalid\n'
    return 0
  fi

  if [[ "$exit_code" == "2" ]]; then
    printf 'warning: failed to read rules.feedback.open_in_browser (exit 2); falling back to direct route\n' >&2
    printf 'unset_or_invalid\n'
    return 0
  fi

  # exit_code == 0
  case "$raw_value" in
    true)  printf 'true\n' ;;
    false) printf 'false\n' ;;
    *)
      printf 'warning: rules.feedback.open_in_browser has invalid value; falling back to direct route\n' >&2
      printf 'unset_or_invalid\n'
      ;;
  esac
}

# should_warn_override - 非 TTY 強制無効化警告の発火判定（純関数）
# 引数:
#   $1: setting       (true / false / unset_or_invalid)
#   $2: explicit_web  (true / false)
#   $3: is_tty        (true / false)
# 出力: stdout に "true" または "false"
# 終了コード: 0=成功、1=入力不正
# 発火条件: is_tty=false ∧ (setting=true ∨ explicit_web=true)
should_warn_override() {
  local setting="${1:-}"
  local explicit_web="${2:-}"
  local is_tty="${3:-}"

  case "$setting" in
    true|false|unset_or_invalid) ;;
    *)
      printf 'error: invalid input: setting=%q (expected: true / false / unset_or_invalid)\n' "$setting" >&2
      return 1
      ;;
  esac

  case "$explicit_web" in
    true|false) ;;
    *)
      printf 'error: invalid input: explicit_web=%q (expected: true / false)\n' "$explicit_web" >&2
      return 1
      ;;
  esac

  case "$is_tty" in
    true|false) ;;
    *)
      printf 'error: invalid input: is_tty=%q (expected: true / false)\n' "$is_tty" >&2
      return 1
      ;;
  esac

  if [[ "$is_tty" == "false" ]] && { [[ "$setting" == "true" ]] || [[ "$explicit_web" == "true" ]]; }; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
  return 0
}

# emit_override_warning - 強制無効化警告 1 行を stderr に出力
# 引数なし。呼び出し側が should_warn_override の判定結果を見て呼ぶ。
emit_override_warning() {
  printf 'warning: open_in_browser/AIDLC_FEEDBACK_WEB is overridden by non-TTY environment; using direct route\n' >&2
}

# CLI モード（テスト便宜のため提供。通常は source して関数呼出が推奨）
# 直接実行された場合のみ subcommand 解決を行う
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  subcommand="$1"
  shift

  case "$subcommand" in
    resolve)
      if [[ $# -lt 3 ]]; then
        printf 'error: missing arguments for %q\n' "resolve" >&2
        usage
        exit 1
      fi
      resolve_feedback_route "$1" "$2" "$3"
      ;;
    normalize-explicit-web)
      # テスト便宜: 環境変数値の正規化結果を確認する補助 subcommand
      normalize_explicit_web "${1:-}"
      ;;
    normalize-setting)
      if [[ $# -lt 2 ]]; then
        printf 'error: missing arguments for %q\n' "normalize-setting" >&2
        usage
        exit 1
      fi
      normalize_setting "$1" "$2"
      ;;
    should-warn-override)
      if [[ $# -lt 3 ]]; then
        printf 'error: missing arguments for %q\n' "should-warn-override" >&2
        usage
        exit 1
      fi
      should_warn_override "$1" "$2" "$3"
      ;;
    emit-override-warning)
      emit_override_warning
      ;;
    *)
      printf "error: unknown subcommand: %q (expected: resolve / normalize-explicit-web / normalize-setting / should-warn-override / emit-override-warning)\n" "$subcommand" >&2
      usage
      exit 1
      ;;
  esac
fi
