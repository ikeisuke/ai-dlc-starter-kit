#!/usr/bin/env bash
#
# migrate-v3-config.sh - v2 config.toml → v3 config.toml 変換（plan / apply）
#
# 使用方法:
#   ./migrate-v3-config.sh --plan  [--source <v2-config>] [--target <v3-config>]
#   ./migrate-v3-config.sh --apply [--source <v2-config>] [--target <v3-config>]
#
# 既定: --source / --target とも .aidlc/config.toml
# --source / --target は project root からの相対パスのみ受理する
# （絶対パス / `..` / symlink 脱出は lib/path-guard.sh により拒否 / exit 1）
#
# 出力（stdout / 行指向）:
#   keep:<key>=<value>      v2 config で明示され v3 に引き継ぐ値（維持 7 キー）
#   default:<key>=<value>   v2 に無い / 不正のため v3 既定値を適用（新規キー含む）
#   warn:<code>:<detail>    警告（invalid-value 等 / エラーにしない）
#   drop:<key>              v3 で未サポートのため移行しないキー（警告のみ / エラーにしない）
#   status:planned          --plan 完了
#   status:applied          --apply 完了（target を atomic replace 済み）
#
# 終了コード:
#   0: 成功
#   1: 入力・検証エラー（引数不正 / source 不在）
#   2: システムエラー（git リポジトリ外 / mktemp・書き込み失敗）
#
# 変換規則の正本: docs/v3/migration.md §3.1（維持 7 キー + 新規 1 キー + drop 警告）
# 変換先 schema の正本: docs/v3/data-model.md §11（8 キー終端集合）
#

set -euo pipefail

usage() {
  echo "usage: migrate-v3-config.sh --plan|--apply [--source <file>] [--target <file>]" >&2
}

MODE=""
SOURCE=""
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan) MODE="plan" ;;
    --apply) MODE="apply" ;;
    --source) shift; SOURCE="${1:-}" ;;
    --target) shift; TARGET="${1:-}" ;;
    *) usage; exit 1 ;;
  esac
  shift
done
if [ -z "$MODE" ]; then
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AIDLC_PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
  echo "error:project-root-not-found" >&2; exit 2
}
# 環境変数override時の安全性検証: gitリポジトリであることを確認
if ! git -C "$AIDLC_PROJECT_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "error:invalid-project-root:$AIDLC_PROJECT_ROOT" >&2; exit 2
fi

# パス境界検証（絶対パス / `..` / symlink 脱出を拒否）
# shellcheck source=lib/path-guard.sh
source "${SCRIPT_DIR}/lib/path-guard.sh"
_aidlc_migrate_path_guard_init || exit 2

SOURCE="${SOURCE:-.aidlc/config.toml}"
TARGET="${TARGET:-.aidlc/config.toml}"

_validate_rel_path() {
  local raw="$1" field="$2" rc=0
  _aidlc_migrate_validate_path "$raw" "$field" "migrate-v3-config" || rc=$?
  if [ "$rc" -eq 1 ]; then
    echo "error:path-rejected:${field}:${raw}" >&2
    exit 1
  elif [ "$rc" -ne 0 ]; then
    echo "error:path-validation-failed:${field}:${raw}" >&2
    exit 2
  fi
}

_validate_rel_path "$SOURCE" "source"
_validate_rel_path "$TARGET" "target"
SOURCE="${AIDLC_PROJECT_ROOT}/${SOURCE}"
TARGET="${AIDLC_PROJECT_ROOT}/${TARGET}"

if [ ! -f "$SOURCE" ]; then
  echo "error:source-not-found:$SOURCE" >&2
  exit 1
fi
# target がディレクトリの場合、mv がディレクトリ内への移動として成功してしまうため事前拒否
if [ -d "$TARGET" ]; then
  echo "error:target-is-directory:$TARGET" >&2
  exit 1
fi

# テスト時刻固定（state-init.sh の AIDLC_STATE_NOW と同型の契約）
MIGRATED_AT="${AIDLC_MIGRATE_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

# --- v2 config の終端キー抽出 -------------------------------------------------
# 「セクション追跡型の最小 TOML 抽出」: <section>.<key><TAB><raw value> を行単位で出力する。
# 維持 7 キーの実型（string / bool / 単一行 array of string）のみ解釈対象とし、
# 汎用 TOML パーサは実装しない（複数行 array の継続行はキー行に一致せず自然に無視される）。
_extract_terminal_keys() {
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*\[/ {
      line = $0
      sub(/^[[:space:]]*\[/, "", line)
      sub(/\].*$/, "", line)
      section = line
      next
    }
    /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=/ {
      line = $0
      key = line
      sub(/^[[:space:]]*/, "", key)
      sub(/[[:space:]]*=.*$/, "", key)
      val = line
      sub(/^[^=]*=[[:space:]]*/, "", val)
      if (section != "") {
        printf "%s.%s\t%s\n", section, key, val
      } else {
        printf "%s\t%s\n", key, val
      }
    }
  ' "$1"
}

# --- 値パースヘルパー ----------------------------------------------------------

_parse_string_value() {
  local raw="$1" v
  case "$raw" in
    \"*)
      v="${raw#\"}"
      case "$v" in
        *\"*) printf '%s' "${v%%\"*}"; return 0 ;;
      esac
      ;;
  esac
  return 1
}

_parse_bool_value() {
  local tok
  tok="$(printf '%s\n' "$1" | awk '{print $1}')"
  case "$tok" in
    true|false) printf '%s' "$tok"; return 0 ;;
  esac
  return 1
}

# 単一行 array of string のみ対応（["a", "b"] / []）。それ以外は不正として fallback。
_parse_array_value() {
  local raw="$1" v
  case "$raw" in
    \[*\]*)
      v="${raw%\]*}]"
      if printf '%s\n' "$v" | grep -Eq '^\[[[:space:]]*("[^"]*"([[:space:]]*,[[:space:]]*"[^"]*")*[[:space:]]*)?\]$'; then
        printf '%s' "$v"
        return 0
      fi
      ;;
  esac
  return 1
}

_is_enum() {
  local v="$1" e
  shift
  for e in "$@"; do
    if [ "$v" = "$e" ]; then
      return 0
    fi
  done
  return 1
}

# --- 8 キーの解決値（v3 既定値で初期化 / 正本: data-model.md §11） -------------

V_DEPTH="standard";    O_DEPTH="default"
V_AUTOMATION="manual"; O_AUTOMATION="default"
V_RMODE="recommend";   O_RMODE="default"
V_RTOOLS='["codex"]';  O_RTOOLS="default"
V_REXCL='[]';          O_REXCL="default"
V_CHANGELOG="false";   O_CHANGELOG="default"
V_VTAG="false";        O_VTAG="default"

WARNS=()
DROPS=()

TAB="$(printf '\t')"
while IFS="$TAB" read -r key raw; do
  case "$key" in
    rules.depth_level.level)
      if v="$(_parse_string_value "$raw")" && _is_enum "$v" minimal standard comprehensive; then
        V_DEPTH="$v"; O_DEPTH="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_DEPTH}")
      fi
      ;;
    rules.automation.mode)
      if v="$(_parse_string_value "$raw")" && _is_enum "$v" manual semi_auto; then
        V_AUTOMATION="$v"; O_AUTOMATION="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_AUTOMATION}")
      fi
      ;;
    rules.reviewing.mode)
      if v="$(_parse_string_value "$raw")" && _is_enum "$v" required recommend disabled; then
        V_RMODE="$v"; O_RMODE="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_RMODE}")
      fi
      ;;
    rules.reviewing.tools)
      if v="$(_parse_array_value "$raw")"; then
        V_RTOOLS="$v"; O_RTOOLS="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_RTOOLS}")
      fi
      ;;
    rules.reviewing.exclude_patterns)
      if v="$(_parse_array_value "$raw")"; then
        V_REXCL="$v"; O_REXCL="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_REXCL}")
      fi
      ;;
    rules.release.changelog)
      if v="$(_parse_bool_value "$raw")"; then
        V_CHANGELOG="$v"; O_CHANGELOG="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_CHANGELOG}")
      fi
      ;;
    rules.release.version_tag)
      if v="$(_parse_bool_value "$raw")"; then
        V_VTAG="$v"; O_VTAG="keep"
      else
        WARNS+=("warn:invalid-value:${key}:fallback=${V_VTAG}")
      fi
      ;;
    rules.release.required_ci_zero_fallback)
      # v3 新規キー: v2 側の値は引き継がず既定 false を適用する（migration.md §3.1）
      WARNS+=("warn:not-carried-over:${key}:v3 新規キーのため既定 false を適用")
      ;;
    *)
      DROPS+=("drop:${key}")
      ;;
  esac
done < <(_extract_terminal_keys "$SOURCE")

# --- プラン出力 -----------------------------------------------------------------

_emit_plan() {
  printf '%s:rules.depth_level.level=%s\n' "$O_DEPTH" "$V_DEPTH"
  printf '%s:rules.automation.mode=%s\n' "$O_AUTOMATION" "$V_AUTOMATION"
  printf '%s:rules.reviewing.mode=%s\n' "$O_RMODE" "$V_RMODE"
  printf '%s:rules.reviewing.tools=%s\n' "$O_RTOOLS" "$V_RTOOLS"
  printf '%s:rules.reviewing.exclude_patterns=%s\n' "$O_REXCL" "$V_REXCL"
  printf '%s:rules.release.changelog=%s\n' "$O_CHANGELOG" "$V_CHANGELOG"
  printf '%s:rules.release.version_tag=%s\n' "$O_VTAG" "$V_VTAG"
  printf 'default:rules.release.required_ci_zero_fallback=false\n'
  local w d
  for w in ${WARNS[@]+"${WARNS[@]}"}; do
    printf '%s\n' "$w"
  done
  for d in ${DROPS[@]+"${DROPS[@]}"}; do
    printf '%s\n' "$d"
  done
}

# --- v3 config 生成 --------------------------------------------------------------

_generate_config() {
  cat <<EOF
# AI-DLC v3 プロジェクト設定
# aidlc-migrate（v2 → v3 migration）により生成 / generated_at: ${MIGRATED_AT}
# schema 正本: docs/v3/data-model.md §11（終端 8 キー）

[rules.depth_level]
level = "${V_DEPTH}"

[rules.automation]
mode = "${V_AUTOMATION}"

[rules.reviewing]
mode = "${V_RMODE}"
tools = ${V_RTOOLS}
exclude_patterns = ${V_REXCL}

[rules.release]
changelog = ${V_CHANGELOG}
version_tag = ${V_VTAG}
required_ci_zero_fallback = false
EOF
}

_emit_plan

if [ "$MODE" = "plan" ]; then
  echo "status:planned"
  exit 0
fi

# --apply: 同一ディレクトリ mktemp + mv による atomic replace
target_dir="$(dirname "$TARGET")"
if ! mkdir -p "$target_dir"; then
  echo "error:target-dir-create-failed:$target_dir" >&2
  exit 2
fi
tmp="$(mktemp "${target_dir}/.migrate-v3-config.XXXXXX")" || {
  echo "error:mktemp-failed" >&2
  exit 2
}
if ! _generate_config > "$tmp"; then
  rm -f "$tmp"
  echo "error:write-failed" >&2
  exit 2
fi
if ! mv "$tmp" "$TARGET"; then
  rm -f "$tmp"
  echo "error:replace-failed:$TARGET" >&2
  exit 2
fi

echo "status:applied"
