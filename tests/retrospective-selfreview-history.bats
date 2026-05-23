#!/usr/bin/env bats
# Unit 002 / v2.6.6 / #704:
#   retrospective_api_record_selfreview の単体テスト。
#   SC-05 (history/operations.md 追記 + 公開契約 §2/§3 整合) 対応。
#
# write-history.sh は実呼び出し (AIDLC_PROJECT_ROOT モックの実 cycle ディレクトリへ書き込み) で検証。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  API="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-api.sh"
  export AIDLC_BASE="${REPO_ROOT}/skills/aidlc"

  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-selfreview-history-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.6.6/history"
  echo "" >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true
}

teardown() {
  cd "$BATS_TMPDIR"
  if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

load_api_fresh() {
  unset RETROSPECTIVE_API_SOURCED
  # shellcheck disable=SC1090
  source "$API"
}

@test "REC1: pass + selfreview_capped=false -> history/operations.md 書き込み成功" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 1 pass false '[]'
  [ "$status" -eq 0 ]
  local history="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.6.6/history/operations.md"
  [ -f "$history" ]
  grep -q "確定 verdict: pass" "$history"
  grep -q "selfreview_capped: false" "$history"
}

@test "REC2: capped + selfreview_capped=true -> 書き込み成功" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 2 capped true '[]'
  [ "$status" -eq 0 ]
  local history="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.6.6/history/operations.md"
  grep -q "確定 verdict: capped" "$history"
  grep -q "selfreview_capped: true" "$history"
}

@test "REC3: undecidable + selfreview_capped=false -> 書き込み成功" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 3 undecidable false '[]'
  [ "$status" -eq 0 ]
  local history="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.6.6/history/operations.md"
  grep -q "確定 verdict: undecidable" "$history"
  grep -q "selfreview_capped: false" "$history"
}

@test "REC4: 引数不足 -> return 1 + stderr warn" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 1 pass
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "必須引数"
}

@test "REC5: verdict 不正 (bogus) -> return 1 + stderr warn" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 1 bogus false '[]'
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "verdict 不正"
}

@test "REC6: selfreview_capped 不正 (not_bool) -> return 1 + stderr warn" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 1 pass not_bool '[]'
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "selfreview_capped 不正"
}

@test "REC7: 相関不整合 (pass + true) -> return 1 + stderr warn" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 1 pass true '[]'
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "相関不整合"
}

@test "REC8: 相関不整合 (capped + false) -> return 1 + stderr warn" {
  load_api_fresh
  run retrospective_api_record_selfreview v2.6.6 1 capped false '[]'
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "相関不整合"
}

@test "REC9: 応答 JSON 末尾要素から観点 A/B/C を yes/no 文字列に変換して記録" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq 不在 (本ケースは jq 利用前提)"
  fi
  load_api_fresh
  local responses='[{"a":true,"b":false,"c":false},{"a":false,"b":true,"c":false}]'
  run retrospective_api_record_selfreview v2.6.6 1 rebuttal false "$responses"
  [ "$status" -eq 0 ]
  local history="${AIDLC_PROJECT_ROOT}/.aidlc/cycles/v2.6.6/history/operations.md"
  grep -q "観点 A 応答: no" "$history"
  grep -q "観点 B 応答: yes" "$history"
  grep -q "観点 C 応答: no" "$history"
  grep -q "差し戻し回数: 1" "$history"
}

@test "REC10: §1.2.5 セクション参照: steps/retrospective.md に新セクションが存在 (SC-05 doc check)" {
  local steps_md="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
  grep -q '^## 1.2.5 Try 構造性セルフレビュー' "$steps_md"
}

@test "REC11: §1.2.5 → try_classification_guide.md 参照リンク存在 (SC-06 doc check)" {
  local steps_md="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
  grep -q 'try_classification_guide.md' "$steps_md"
}

@test "REC12: try_classification_guide.md に 3 問固定 (再発性 / 対象レイヤ / 再入余地) 存在 (SC-06)" {
  local guide_md="${REPO_ROOT}/skills/aidlc-retrospective/templates/try_classification_guide.md"
  [ -f "$guide_md" ]
  grep -q '質問 1: 再発性' "$guide_md"
  grep -q '質問 2: 対象レイヤ' "$guide_md"
  grep -q '質問 3: 再入余地' "$guide_md"
}
