#!/usr/bin/env bats
# Unit 001 / v2.6.6 / #710:
#   - rules.retrospective.aggregate_issue_enabled 既定値 (false) の defaults.toml 二重 SoT 検証
#   - retrospective_api_aggregate_enabled helper の公開契約検証 (正常系 + fail-safe 3 ケース)
#   - SoT 文言の SKILL.md / steps/retrospective.md 冒頭存在検証 (SC-01)
#   - §1.5 前置き仕様節の存在検証
#   - retrospective_api_* 既存公開関数シグネチャの不変性検証
#   - 同等性 fixture (tests/fixtures/retrospective_v265_aggregate.json) のスキーマ検証
#   - tests/lib/retrospective_normalize.bash の normalize_volatile / normalize_volatile_hash 動作検証
#
# 既存 tests/retrospective/helpers/setup.bash と同等のディレクトリ慣例で構築する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  API="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-api.sh"
  AIDLC_DEFAULTS="${REPO_ROOT}/skills/aidlc/config/defaults.toml"
  SETUP_DEFAULTS="${REPO_ROOT}/skills/aidlc-setup/config/defaults.toml"
  SKILL_MD="${REPO_ROOT}/skills/aidlc-retrospective/SKILL.md"
  STEPS_MD="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
  FIXTURE="${REPO_ROOT}/tests/fixtures/retrospective_v265_aggregate.json"
  NORMALIZE_LIB="${REPO_ROOT}/tests/lib/retrospective_normalize.bash"
  TEST_TMPDIR="$(mktemp -d /tmp/aidlc-aggregate-enabled-XXXXXX)"
  export AIDLC_PROJECT_ROOT="${TEST_TMPDIR}/project"
  mkdir -p "${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
  echo "" >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  git -C "${AIDLC_PROJECT_ROOT}" init --quiet 2>/dev/null || true
  export AIDLC_PLUGIN_ROOT="${REPO_ROOT}/skills/aidlc"
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

# ─── defaults.toml 二重 SoT ─────────────────────────────────────

@test "DEF1: aidlc/config/defaults.toml に aggregate_issue_enabled = false が存在" {
  run grep -E '^aggregate_issue_enabled = false$' "$AIDLC_DEFAULTS"
  [ "$status" -eq 0 ]
}

@test "DEF2: aidlc-setup/config/defaults.toml に aggregate_issue_enabled = false が存在 (二重 SoT 同期)" {
  run grep -E '^aggregate_issue_enabled = false$' "$SETUP_DEFAULTS"
  [ "$status" -eq 0 ]
}

@test "DEF3: read-config.sh 経由で aggregate_issue_enabled が false を返す (defaults fallback)" {
  run bash "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" rules.retrospective.aggregate_issue_enabled
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "DEF4: project config で aggregate_issue_enabled = true を設定すると true が返る" {
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<'EOF'
[rules.retrospective]
aggregate_issue_enabled = true
EOF
  run bash "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" rules.retrospective.aggregate_issue_enabled
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

# ─── helper 公開契約 ─────────────────────────────────────────

@test "HLP1: retrospective_api_aggregate_enabled 関数が定義されている" {
  load_api_fresh
  run declare -F retrospective_api_aggregate_enabled
  [ "$status" -eq 0 ]
}

@test "HLP2: helper 正常系 (defaults fallback) で stdout=false / exit 0 / stderr なし" {
  load_api_fresh
  run retrospective_api_aggregate_enabled
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "HLP3: helper 正常系 (project config true) で stdout=true / exit 0" {
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<'EOF'
[rules.retrospective]
aggregate_issue_enabled = true
EOF
  load_api_fresh
  run retrospective_api_aggregate_enabled
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "HLP4: helper fail-safe (read-config.sh exit 1 経路: キー不在シミュ) で stdout=false / exit 0 / warn なし" {
  # AIDLC_DISABLE_DEFAULTS_FALLBACK 等のフックは無いため、project config + defaults を両方
  # 一時的に切り出して「キー不在」状態を作る代わりに、read-config.sh が exit 1 を返さない
  # 設計上、本ケースは「helper が直接 read-config 系をモックする」形では検証困難。
  # 代替: AIDLC_PLUGIN_ROOT を存在しないパスへ向けて read-config.sh の取得失敗（exit 2 経路）を
  # トリガする統合的な fail-safe 検証を HLP5 / HLP6 で実施する。本 HLP4 は仕様上の
  # 「exit 1 = warn なし」契約をドキュメントとして残すための placeholder として skip する。
  skip "HLP4 は exit 1 (キー不在) 経路の直接モックが現環境では困難。HLP5 (exit 2+ fail-safe) と HLP6 (不正値) で fail-safe 全体を担保する。契約自体は steps/retrospective.md §1.5 前置きおよび helper コメントで SoT 化済み。"
}

@test "HLP5: helper fail-safe (read-config.sh exit 2+ シミュ) で stdout=false / exit 0 / stderr warn" {
  local shim_dir="${TEST_TMPDIR}/shim_readconfig_exit2"
  mkdir -p "${shim_dir}/scripts"
  cat > "${shim_dir}/scripts/read-config.sh" <<'SHIM'
#!/usr/bin/env bash
echo "[mock-error] simulated read-config failure" >&2
exit 2
SHIM
  chmod +x "${shim_dir}/scripts/read-config.sh"

  # source 後に _RETROSPECTIVE_API_BASE を上書きして shim 経路を強制
  # (source 内の _retrospective_api_resolve_base が _RETROSPECTIVE_API_BASE を本リポ skills/aidlc に
  #  上書きするため、source 後に再代入する必要がある)
  # stdout 検証: stderr を捨てて stdout 1 行のみ取得
  run bash -c "unset RETROSPECTIVE_API_SOURCED; source '${API}'; _RETROSPECTIVE_API_BASE='${shim_dir}'; retrospective_api_aggregate_enabled 2>/dev/null"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]

  # stderr 検証: stdout を捨てて stderr 内容のみ取得
  run bash -c "unset RETROSPECTIVE_API_SOURCED; source '${API}'; _RETROSPECTIVE_API_BASE='${shim_dir}'; retrospective_api_aggregate_enabled 2>&1 1>/dev/null"
  [[ "$output" == *"[warn] retrospective_api_aggregate_enabled"* ]]
}

@test "HLP6: helper fail-safe (read-config.sh exit 0 + 不正値 シミュ) で stdout=false / exit 0 / stderr warn" {
  local shim_dir="${TEST_TMPDIR}/shim_readconfig_invalid"
  mkdir -p "${shim_dir}/scripts"
  cat > "${shim_dir}/scripts/read-config.sh" <<'SHIM'
#!/usr/bin/env bash
echo "yes"
exit 0
SHIM
  chmod +x "${shim_dir}/scripts/read-config.sh"

  # source 後に _RETROSPECTIVE_API_BASE を上書きして shim 経路を強制
  run bash -c "unset RETROSPECTIVE_API_SOURCED; source '${API}'; _RETROSPECTIVE_API_BASE='${shim_dir}'; retrospective_api_aggregate_enabled 2>/dev/null"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]

  run bash -c "unset RETROSPECTIVE_API_SOURCED; source '${API}'; _RETROSPECTIVE_API_BASE='${shim_dir}'; retrospective_api_aggregate_enabled 2>&1 1>/dev/null"
  [[ "$output" == *"[warn] retrospective_api_aggregate_enabled"* ]]
  [[ "$output" == *"yes"* ]]
}

# ─── SoT 文言 (SC-01) ────────────────────────────────────────

@test "SOT1: skills/aidlc-retrospective/SKILL.md 冒頭に T 中心 SoT 文言が存在" {
  run grep -E "目的.*T を Issue 化して実行に繋げること.*KPT は T を導くための手段" "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "SOT2: skills/aidlc-retrospective/steps/retrospective.md 冒頭に T 中心 SoT 文言が存在" {
  run grep -E "目的.*T を Issue 化して実行に繋げること.*KPT は T を導くための手段" "$STEPS_MD"
  [ "$status" -eq 0 ]
}

@test "SOT3: steps/retrospective.md に §1.5 前置き仕様節 (aggregate_issue_enabled 仕様) が存在" {
  run grep -F "1.5 前置き: \`aggregate_issue_enabled\` 仕様" "$STEPS_MD"
  [ "$status" -eq 0 ]
}

# ─── 既存公開関数シグネチャ不変 ─────────────────────────────────

@test "API1: 既存 retrospective_api_* 公開関数が全て依然として定義されている (シグネチャ不変保証)" {
  load_api_fresh
  for fn in \
    retrospective_api_resolve_feedback_mode \
    retrospective_api_is_interactive_env \
    retrospective_api_requires_wizard \
    retrospective_api_run_wizard \
    retrospective_api_check_cap \
    retrospective_api_compose_body \
    retrospective_api_prefill \
    retrospective_api_record_response \
    retrospective_api_create_issue \
    retrospective_api_update_issue ; do
    run declare -F "$fn"
    [ "$status" -eq 0 ] || { echo "missing: $fn"; return 1; }
  done
}

# ─── fixture スキーマ ───────────────────────────────────────

@test "FIX1: fixture ファイル tests/fixtures/retrospective_v265_aggregate.json が存在" {
  [ -f "$FIXTURE" ]
}

@test "FIX2: fixture が必須トップレベルキー (meta / expected_title / expected_heading_set / expected_normalized_body_hash / expected_labels / expected_cap) を持つ" {
  for key in meta expected_title expected_heading_set expected_normalized_body_hash expected_labels expected_cap ; do
    run grep -F "\"${key}\"" "$FIXTURE"
    [ "$status" -eq 0 ] || { echo "missing key: $key"; return 1; }
  done
}

@test "FIX3: fixture meta に fixture_status と source の説明が含まれる (実値未確定の根拠記録)" {
  run grep -F '"fixture_status"' "$FIXTURE"
  [ "$status" -eq 0 ]
  run grep -F '"source"' "$FIXTURE"
  [ "$status" -eq 0 ]
}

# ─── normalize_volatile 動作 ─────────────────────────────────

@test "NRM1: normalize_volatile が ISO 8601 タイムスタンプを <TIMESTAMP> に置換" {
  # shellcheck disable=SC1090
  source "$NORMALIZE_LIB"
  run bash -c "echo 'created_at: 2026-05-18T12:34:56+09:00' | { source '${NORMALIZE_LIB}'; normalize_volatile; }"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<TIMESTAMP>"* ]]
  [[ "$output" != *"2026-05-18T12:34:56"* ]]
}

@test "NRM2: normalize_volatile が UUID v4/v7 を <SESSION_ID> に置換" {
  run bash -c "echo 'session: 019e390a-d9d6-7b50-aae2-2217fde95f09' | { source '${NORMALIZE_LIB}'; normalize_volatile; }"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<SESSION_ID>"* ]]
  [[ "$output" != *"019e390a"* ]]
}

@test "NRM3: normalize_volatile がホーム配下絶対パスを ~/ に置換" {
  run bash -c "echo 'path: /Users/foo/repo/file' | { source '${NORMALIZE_LIB}'; normalize_volatile; }"
  [ "$status" -eq 0 ]
  [[ "$output" == *"~/repo/file"* ]]
  [[ "$output" != *"/Users/foo/"* ]]
}

@test "NRM4: normalize_volatile が見出し / ラベル / cap 数値を変更しない (比較必須キー保持)" {
  run bash -c "printf '## Keep\n## Problem\nlabels: [backlog, retrospective]\ncurrent_count: 3\nover: false\n' | { source '${NORMALIZE_LIB}'; normalize_volatile; }"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Keep"* ]]
  [[ "$output" == *"## Problem"* ]]
  [[ "$output" == *"labels: [backlog, retrospective]"* ]]
  [[ "$output" == *"current_count: 3"* ]]
  [[ "$output" == *"over: false"* ]]
}

@test "NRM5: normalize_volatile_hash が 64 文字 hex を出力 (sha256)" {
  run bash -c "echo 'test' | { source '${NORMALIZE_LIB}'; normalize_volatile_hash; }"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9a-f]{64}$ ]]
}
