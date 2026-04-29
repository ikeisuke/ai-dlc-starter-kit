#!/usr/bin/env bash
# bats helper for tests/retrospective/

set -uo pipefail

HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HELPER_DIR}/../../.." && pwd)"

readonly REPO_ROOT
readonly TEMPLATE_PATH="${REPO_ROOT}/skills/aidlc/templates/retrospective_template.md"
readonly SCHEMA_PATH="${REPO_ROOT}/skills/aidlc/config/retrospective-schema.yml"
readonly DEFAULTS_TOML="${REPO_ROOT}/skills/aidlc/config/defaults.toml"
readonly STEP_FILE_PATH="${REPO_ROOT}/skills/aidlc/steps/operations/04-completion.md"
readonly CYCLE_VERSION_CHECK="${REPO_ROOT}/skills/aidlc/scripts/lib/cycle-version-check.sh"
readonly GENERATE_SCRIPT="${REPO_ROOT}/skills/aidlc/scripts/retrospective-generate.sh"
readonly VALIDATE_SCRIPT="${REPO_ROOT}/skills/aidlc/scripts/retrospective-validate.sh"
readonly FIXTURES_DIR="${REPO_ROOT}/tests/fixtures/retrospective"

# テスト用一時環境構築（generate / validate-script 用）
# AIDLC_PROJECT_ROOT を一時ディレクトリに切り替え、 plugin root を本リポの skills/aidlc にする
setup_env() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-retrospective-XXXXXX)"
  export TEST_TMPDIR

  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
  # 最低限の project config (read-config.sh が AIDLC_CONFIG を要求するため)
  echo "" >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true

  # plugin root を本リポの skills/aidlc に固定
  export AIDLC_PLUGIN_ROOT="${REPO_ROOT}/skills/aidlc"
}

teardown_env() {
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    \rm -rf "${TEST_TMPDIR}"
  fi
}

# project の .aidlc/config.toml に rules.retrospective.feedback_mode を書き込む
set_project_feedback_mode() {
  local mode="$1"
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<EOF
[rules.retrospective]
feedback_mode = "${mode}"
EOF
}

# user-global config を作成（HOME/.aidlc/config.toml 相当）
set_user_global_feedback_mode() {
  local mode="$1"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.aidlc"
  cat >"${HOME}/.aidlc/config.toml" <<EOF
[rules.retrospective]
feedback_mode = "${mode}"
EOF
}

# fixture の retrospective.md をテスト用 path にコピー
# dest_path は AIDLC_CYCLES 配下のパスを想定（apply パストラバーサル対策と整合）
copy_fixture() {
  local fixture_name="$1"
  local dest_path="$2"
  mkdir -p "$(dirname "$dest_path")"
  cp "${FIXTURES_DIR}/${fixture_name}/retrospective.md" "$dest_path"
}

# テスト用 retrospective.md パス（AIDLC_CYCLES 配下に配置）
test_retrospective_path() {
  echo "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md"
}

# cycle ガード呼び出しラッパ
run_cycle_check() {
  bash "${CYCLE_VERSION_CHECK}" "$@"
}

run_generate() {
  bash "${GENERATE_SCRIPT}" "$@"
}

run_validate() {
  bash "${VALIDATE_SCRIPT}" "$@"
}

# sha256 取得（cross-platform）
_sha256_of() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    echo "no-sha256-command" >&2
    return 1
  fi
}

snapshot_sha() {
  _sha256_of "$1"
}

assert_unchanged() {
  local file="$1"
  local before="$2"
  local after
  after="$(_sha256_of "$file")"
  if [ "$before" != "$after" ]; then
    echo "Expected file $file unchanged, but sha differs:" >&2
    echo "  before: $before" >&2
    echo "  after:  $after" >&2
    return 1
  fi
  return 0
}
