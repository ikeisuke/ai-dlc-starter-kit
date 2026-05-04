#!/usr/bin/env bash
# bats helper for tests/retrospective-mirror/

set -uo pipefail

HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HELPER_DIR}/../../.." && pwd)"

readonly REPO_ROOT
readonly MIRROR_SCRIPT="${REPO_ROOT}/skills/aidlc/scripts/retrospective-mirror.sh"
readonly STEP_FILE_PATH="${REPO_ROOT}/skills/aidlc/steps/operations/04-completion.md"
readonly FIXTURES_DIR="${REPO_ROOT}/tests/fixtures/retrospective-mirror"

setup_env() {
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-mirror-test-XXXXXX)"
  export TEST_TMPDIR

  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
  echo "" >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true

  export AIDLC_PLUGIN_ROOT="${REPO_ROOT}/skills/aidlc"

  # gh モック作成（PATH 先頭に挿入してテスト中の gh コマンドをスタブ化）
  export GH_MOCK_DIR="${TEST_TMPDIR}/bin"
  mkdir -p "${GH_MOCK_DIR}"
  export PATH="${GH_MOCK_DIR}:${PATH}"
}

teardown_env() {
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    \rm -rf "${TEST_TMPDIR}"
  fi
  # /tmp に残った draft / extract / classify ファイルを掃除
  \rm -f /tmp/retrospective-mirror-draft.* /tmp/retrospective-mirror-extract.* /tmp/retrospective-mirror-classify.* /tmp/retrospective-mirror-gh-stderr.* 2>/dev/null || true
}

set_project_feedback_mode() {
  local mode="$1"
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<EOF
[rules.retrospective]
feedback_mode = "${mode}"
EOF
}

copy_fixture() {
  local fixture_name="$1"
  local dest_path="$2"
  mkdir -p "$(dirname "$dest_path")"
  cp "${FIXTURES_DIR}/${fixture_name}/retrospective.md" "$dest_path"
}

test_retrospective_path() {
  echo "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.5.0/operations/retrospective.md"
}

# gh モック設定: scenario 引数で挙動を切り替え
# - success <issue_number>      : Issue URL を返す（成功）
# - auth-fail                   : gh auth status 失敗（exit 1）
# - rate-limit                  : 起票時 rate limit エラー
# - network-error               : 起票時ネットワークエラー
# - unknown-error               : 起票時その他エラー
mock_gh() {
  local scenario="$1"
  local issue_number="${2:-700}"

  cat >"${GH_MOCK_DIR}/gh" <<EOF_OUTER
#!/usr/bin/env bash
SCENARIO="${scenario}"
ISSUE_NUMBER="${issue_number}"

case "\$1" in
  auth)
    if [ "\$2" = "status" ]; then
      if [ "\$SCENARIO" = "auth-fail" ]; then
        echo "not authenticated" >&2
        exit 1
      fi
      echo "Logged in"
      exit 0
    fi
    ;;
  issue)
    if [ "\$2" = "create" ]; then
      case "\$SCENARIO" in
        success)
          echo "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/\${ISSUE_NUMBER}"
          exit 0
          ;;
        rate-limit)
          echo "API rate limit exceeded for user. Please wait." >&2
          exit 1
          ;;
        network-error)
          echo "could not resolve host: api.github.com" >&2
          exit 1
          ;;
        unknown-error)
          echo "internal server error 500" >&2
          exit 1
          ;;
      esac
    fi
    ;;
esac
exit 0
EOF_OUTER
  chmod +x "${GH_MOCK_DIR}/gh"
}

run_mirror() {
  bash "${MIRROR_SCRIPT}" "$@"
}
