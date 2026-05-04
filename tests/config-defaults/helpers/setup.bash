#!/usr/bin/env bash
# Unit 001 / config-defaults 用 共通テストヘルパ
#
# 役割:
#   - 一時ディレクトリ作成と fixture コピー
#   - AIDLC_PROJECT_ROOT 切替で 4 階層マージ動作をテスト時に再現
#   - read-config.sh / aidlc_read_toml を介した TOML 値検査ラッパ
#
# 既存 tests/migration/helpers/setup.bash の慣行に倣う。

# Resolve paths
HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "${HELPERS_DIR}/../.." && pwd)"
REPO_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
FIXTURES_DIR="${REPO_ROOT}/tests/fixtures/config-defaults"
TEMPLATE_PATH="${REPO_ROOT}/skills/aidlc-setup/templates/config.toml.template"
EXAMPLE_PATH="${REPO_ROOT}/skills/aidlc/config/config.toml.example"
DEFAULTS_PATH="${REPO_ROOT}/skills/aidlc/config/defaults.toml"
READ_CONFIG_SCRIPT="${REPO_ROOT}/skills/aidlc/scripts/read-config.sh"

# dasel v2/v3 互換の TOML 読み取りを利用するため toml-reader を source
# shellcheck disable=SC1091
source "${REPO_ROOT}/skills/aidlc/scripts/lib/toml-reader.sh"

# Unit 001 が対象とする 7 キー（user_stories.md ストーリー 1 の正規定義）
UNIT_001_KEYS=(
  "rules.reviewing.mode"
  "rules.reviewing.tools"
  "rules.automation.mode"
  "rules.git.squash_enabled"
  "rules.git.ai_author"
  "rules.git.ai_author_auto_detect"
  "rules.linting.enabled"
)

# dasel v3 の配列値出力はシングルクォート形式（例: ['codex']）。defaults.toml / fixture では
# ダブルクォート（["codex"]）で書くが、read-config.sh 経由の出力はシングルクォートに正規化される。
# 本テストでは read-config.sh の生出力を期待値とする。

# B1 期待値（既定値同等性 NFR の Source of Truth — logical_design.md と同期）
b1_expected_for() {
  case "$1" in
    "rules.reviewing.mode")           printf '%s' "recommend" ;;
    "rules.reviewing.tools")          printf '%s' "['codex']" ;;
    "rules.automation.mode")          printf '%s' "manual" ;;
    "rules.git.squash_enabled")       printf '%s' "false" ;;
    "rules.git.ai_author")            printf '%s' "" ;;
    "rules.git.ai_author_auto_detect") printf '%s' "true" ;;
    "rules.linting.enabled")          printf '%s' "false" ;;
    *) return 1 ;;
  esac
}

# B2 期待値（fixture b2-with-keys に書いた値と一致）
b2_expected_for() {
  case "$1" in
    "rules.reviewing.mode")           printf '%s' "required" ;;
    "rules.reviewing.tools")          printf '%s' "['claude']" ;;
    "rules.automation.mode")          printf '%s' "semi_auto" ;;
    "rules.git.squash_enabled")       printf '%s' "true" ;;
    "rules.git.ai_author")            printf '%s' "TestAuthor <test@example.com>" ;;
    "rules.git.ai_author_auto_detect") printf '%s' "false" ;;
    "rules.linting.enabled")          printf '%s' "true" ;;
    *) return 1 ;;
  esac
}

# --- Environment setup/teardown ---

setup_b1_environment() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-config-defaults-b1-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}"
  cp -R "${FIXTURES_DIR}/b1-no-keys/." "${TEST_TMPDIR}/"
  git -C "${TEST_TMPDIR}" init --quiet
}

setup_b2_environment() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-config-defaults-b2-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}"
  cp -R "${FIXTURES_DIR}/b2-with-keys/." "${TEST_TMPDIR}/"
  git -C "${TEST_TMPDIR}" init --quiet
}

teardown_environment() {
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
  unset AIDLC_PROJECT_ROOT
}

# --- Script runner wrappers ---

# read-config.sh を AIDLC_PROJECT_ROOT 切替で実行し、単一キーの値を取得
run_read_config_single() {
  local key="$1"
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${READ_CONFIG_SCRIPT}" "${key}"
}

# read-config.sh を --keys モードで実行し、複数キーを一括取得（key:value 形式）
run_read_config_batch() {
  AIDLC_PROJECT_ROOT="${TEST_TMPDIR}" "${READ_CONFIG_SCRIPT}" --keys "$@"
}

# template は project プレースホルダ（例: [プロジェクト名]）を含む invalid TOML のため
# dasel/aidlc_read_toml では構造解析できない。grep/awk ベースで section + leaf の存在検査を行う。

# template に [section] というセクションヘッダが存在するか検査
# 例: template_has_section "rules.linting"
template_has_section() {
  local section="$1"
  grep -Fxq "[${section}]" "${TEMPLATE_PATH}"
}

# template の指定セクション内に指定葉キーの代入行が存在するか検査
# 例: template_has_section_leaf "rules.git" "squash_enabled"
template_has_section_leaf() {
  local section="$1"
  local leaf="$2"
  awk -v sec="[${section}]" -v lf="${leaf}" '
    BEGIN { in_section = 0; found = 0 }
    $0 == sec { in_section = 1; next }
    /^\[/ { in_section = 0 }
    in_section && $0 ~ "^[[:space:]]*"lf"[[:space:]]*=" { found = 1; exit 0 }
    END { exit (found ? 0 : 1) }
  ' "${TEMPLATE_PATH}"
}

# example は valid TOML のため aidlc_read_toml で構造解析可能
# 戻り値: 0=存在 / 非0=不在
example_has_key() {
  aidlc_read_toml "${EXAMPLE_PATH}" "$1" >/dev/null 2>&1
}
