#!/usr/bin/env bats
# Unit 002 / v2.6.6 / #704:
#   retrospective_api_ensure_label の単体テスト。
#   SC-05 (selfreview-capped ラベル fail-safe) 対応。
#
# gh CLI を shim でモックして 4 ケース (ラベル既存 / 自動作成成功 / 権限不足 / gh 不在) を検証。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  API="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-api.sh"
  export AIDLC_BASE="${REPO_ROOT}/skills/aidlc"

  # PATH の前段に shim 配置用のディレクトリを用意
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-ensure-label-XXXXXX)"
  GH_SHIM_DIR="${TEST_TMPDIR}/bin"
  GH_SHIM_LOG="${TEST_TMPDIR}/gh-calls.log"
  mkdir -p "$GH_SHIM_DIR"
  export ORIGINAL_PATH="$PATH"
}

teardown() {
  cd "$BATS_TMPDIR"
  export PATH="$ORIGINAL_PATH"
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

load_api_fresh() {
  unset RETROSPECTIVE_API_SOURCED
  # shellcheck disable=SC1090
  source "$API"
}

write_gh_shim() {
  # $1: ラベル存在判定の出力（複数行 / 空文字 = 不在）
  # $2: gh label create の exit code (0=成功 / 非 0=失敗)
  local list_output="$1"
  local create_rc="$2"
  cat >"${GH_SHIM_DIR}/gh" <<EOF
#!/usr/bin/env bash
echo "\$@" >>"${GH_SHIM_LOG}"
case "\$1" in
  label)
    case "\$2" in
      list)
        printf '%s' "${list_output}"
        exit 0
        ;;
      create)
        exit ${create_rc}
        ;;
    esac
    ;;
esac
exit 0
EOF
  chmod +x "${GH_SHIM_DIR}/gh"
  export PATH="${GH_SHIM_DIR}:${ORIGINAL_PATH}"
}

@test "LBL1: ラベル既存 -> exit 0 + gh label create 呼ばれない" {
  write_gh_shim "selfreview-capped" 0
  load_api_fresh
  run retrospective_api_ensure_label selfreview-capped
  [ "$status" -eq 0 ]
  # gh label list は呼ばれたが create は呼ばれない
  grep -q '^label list' "${GH_SHIM_LOG}"
  ! grep -q '^label create' "${GH_SHIM_LOG}"
}

@test "LBL2: ラベル不在 + 自動作成成功 -> exit 0 + create 1 回呼ばれる" {
  write_gh_shim "" 0
  load_api_fresh
  run retrospective_api_ensure_label selfreview-capped
  [ "$status" -eq 0 ]
  grep -q '^label list' "${GH_SHIM_LOG}"
  local create_count
  create_count=$(grep -c '^label create' "${GH_SHIM_LOG}" || true)
  [ "$create_count" = "1" ]
}

@test "LBL3: ラベル不在 + 自動作成失敗 (権限不足) -> exit 2 (fail-fast) + stderr warn" {
  write_gh_shim "" 1
  load_api_fresh
  run retrospective_api_ensure_label selfreview-capped
  [ "$status" -eq 2 ]
  echo "$output" | grep -q "自動作成に失敗"
}

@test "LBL4: gh CLI 不在 -> exit 3 + stderr warn" {
  # PATH から gh を除外 (shim 配置しない)
  export PATH="${TEST_TMPDIR}/empty-bin:${ORIGINAL_PATH/$HOMEBREW_PREFIX\/bin/}/usr/bin:/bin"
  mkdir -p "${TEST_TMPDIR}/empty-bin"
  # 念のため fake "gh" がないことを確認
  if command -v gh >/dev/null 2>&1; then
    skip "PATH 操作で gh を除外できない環境 (本ケースの PATH 制御が効かない)"
  fi
  load_api_fresh
  run retrospective_api_ensure_label selfreview-capped
  [ "$status" -eq 3 ]
  echo "$output" | grep -q "gh CLI が PATH 上に存在しません"
}

@test "LBL5: ラベル名空 -> exit 2 + stderr warn" {
  write_gh_shim "" 0
  load_api_fresh
  run retrospective_api_ensure_label ""
  [ "$status" -eq 2 ]
  echo "$output" | grep -q "ラベル名が指定されていません"
}

@test "LBL6: 前方一致候補 (selfreview-capped-foo) は厳密一致しないため作成試行" {
  write_gh_shim "selfreview-capped-foo" 0
  load_api_fresh
  run retrospective_api_ensure_label selfreview-capped
  [ "$status" -eq 0 ]
  local create_count
  create_count=$(grep -c '^label create' "${GH_SHIM_LOG}" || true)
  [ "$create_count" = "1" ]
}
