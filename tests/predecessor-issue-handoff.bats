#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 004: predecessor_resolve_issue() 単体テスト
# Plan / Logical Design §「優先順位表 1/1'/2/3/4」を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HOOK_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/predecessor-issue.sh"
  TMP="$(mktemp -d -t aidlc-pred.XXXXXX)"
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"

  # 重要: 実際のリポジトリ ./aidlc/cycles を破壊しないため、TMP 配下で作業する
  cd "$TMP"

  # cycle ディレクトリ構造を作成（TMP 配下）
  PREV_CYCLE="v2.5.0"
  mkdir -p ".aidlc/cycles/${PREV_CYCLE}/history" ".aidlc/cycles/${PREV_CYCLE}/operations"

  # gh shim
  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
case "$1" in
  auth)
    if [[ "$2" == "status" ]]; then
      if [[ "${GH_MOCK_AUTH_FAIL:-}" == "1" ]]; then
        exit 1
      fi
      exit 0
    fi
    ;;
  issue)
    if [[ "$2" == "list" ]]; then
      if [[ "${GH_MOCK_LIST_FAIL:-}" == "1" ]]; then
        echo "mock list failed" >&2
        exit 1
      fi
      printf '%s\n' "${GH_MOCK_LIST_RESULT:-[]}"
      exit 0
    fi
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  PATH="$SHIM_DIR:$PATH"
  export PATH

  # 多重 source ガードの reset
  unset __AIDLC_PREDECESSOR_ISSUE_SH_LOADED
  unset __AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED

  # 環境変数クリーン
  unset GH_MOCK_AUTH_FAIL
  unset GH_MOCK_LIST_FAIL
  unset GH_MOCK_LIST_RESULT
}

teardown() {
  cd "$REPO_ROOT"
  rm -rf "$TMP"
}

# ─── ヘルパ: spool ファイル作成 ─────
make_spool_with_url() {
  # $1: issue_url（partial_state.local_created に格納 / Unit 002 spool schema 整合）
  local spool_path=".aidlc/cycles/${PREV_CYCLE}/history/retrospective-spool.md"
  cat > "$spool_path" <<EOF
<!-- retrospective-spool v1 -->

\`\`\`ndjson
{"id":"abc","version":"1","cycle":"${PREV_CYCLE}","feedback_mode":"local","attempted_at":"2026-05-05T00:00:00Z","target":"local","retry_target":"local","partial_state":{"local_created":"$1","mirror_created":null},"attempt_reason":"relabel-failed-local","body_b64":"e30=","body_sha256":"x"}
\`\`\`
EOF
}

# 旧版互換 spool（issue_url キー / Unit 005 P19 で fallback parse を verify）
make_spool_with_legacy_url() {
  # $1: issue_url（旧 v2.5.0 schema / partial_state なしで .issue_url のみ）
  local spool_path=".aidlc/cycles/${PREV_CYCLE}/history/retrospective-spool.md"
  cat > "$spool_path" <<EOF
<!-- retrospective-spool v1 -->

\`\`\`ndjson
{"id":"abc","cycle":"${PREV_CYCLE}","ts":"2026-05-05T00:00:00Z","sha256":"x","issue_url":"$1","payload_b64":"e30="}
\`\`\`
EOF
}

make_compat_file() {
  local compat_path=".aidlc/cycles/${PREV_CYCLE}/operations/retrospective.md"
  echo "# Retrospective for ${PREV_CYCLE}" > "$compat_path"
}

# ─── P1: 経路 1 / 1 件 / 自動採用 ─────
@test "P1: 経路 1 / Issue 1 件で自動採用 / NDJSON resolution_path=milestone_and_label" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[{"url":"https://github.com/owner/repo/issues/100","title":"Retrospective: v2.5.0","closedAt":"2026-04-01T00:00:00Z"}]'
  export GH_MOCK_LIST_RESULT

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"milestone_and_label"* ]]
  [[ "$output" == *"issues/100"* ]]
  [[ "$stderr" == *"predecessor_resolved_milestone_label"* ]]
}

# ─── P2: 経路 1 / 複数件 / 候補リスト出力（対話起動しない） ─────
@test "P2: 経路 1 / 複数件で candidates 配列を closedAt 降順で出力 / 関数本体は対話起動しない" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[{"url":"https://github.com/owner/repo/issues/100","title":"old","closedAt":"2026-03-01T00:00:00Z"},{"url":"https://github.com/owner/repo/issues/200","title":"new","closedAt":"2026-04-01T00:00:00Z"}]'
  export GH_MOCK_LIST_RESULT

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"milestone_and_label"* ]]
  # issue_url=null（複数件時は単一値を返さない）
  [[ "$output" == *'"issue_url":null'* ]]
  # candidates 配列 / 200 が先頭（closedAt 降順）
  [[ "$output" == *"issues/200"* ]]
  [[ "$stderr" == *"predecessor_candidates_emitted"* ]]
}

# ─── P3: 経路 1 / 0 件 → 経路 2 移行 ─────
@test "P3: 経路 1 / 0 件で spool fallback に移行 / spool 内 issue_url 採用" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[]'
  export GH_MOCK_LIST_RESULT
  make_spool_with_url "https://github.com/owner/repo/issues/300"

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"spool_fallback"* ]]
  [[ "$output" == *"issues/300"* ]]
  [[ "$stderr" == *"predecessor_resolved_spool"* ]]
}

# ─── P7: 経路 2 / spool ファイル存在 / gh 不可で経路 2 直接遷移 ─────
@test "P7: gh_status=unavailable + spool 存在 → 経路 2 直接遷移" {
  source "$HOOK_LIB"

  GH_MOCK_AUTH_FAIL=1
  export GH_MOCK_AUTH_FAIL
  make_spool_with_url "https://github.com/owner/repo/issues/700"

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"spool_fallback"* ]]
  [[ "$output" == *"issues/700"* ]]
}

# ─── P8: 経路 2 / spool 不在 → 経路 3 移行 ─────
@test "P8: gh 不可 + spool 不在 + 互換ファイル存在 → 経路 3" {
  source "$HOOK_LIB"

  GH_MOCK_AUTH_FAIL=1
  export GH_MOCK_AUTH_FAIL
  make_compat_file

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"v2_5_0_compat"* ]]
  [[ "$output" == *"retrospective.md"* ]]
  [[ "$stderr" == *"predecessor_resolved_compat"* ]]
}

# ─── P9: 経路 3 / 互換ファイル存在 / gh 利用可能だが Issue 0 件 ─────
@test "P9: gh 利用可能 / Issue 0 件 + spool 不在 + 互換ファイル存在 → 経路 3" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[]'
  export GH_MOCK_LIST_RESULT
  make_compat_file

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"v2_5_0_compat"* ]]
}

# ─── P10: 経路 4 / 全経路 0 件 / warn + continue ─────
@test "P10: 全経路 0 件で warn_continue / exit 0" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[]'
  export GH_MOCK_LIST_RESULT

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn_continue"* ]]
  [[ "$stderr" == *"predecessor_no_reference"* ]]
}

# ─── P11: gh_status=unavailable で経路 1/1' をスキップ ─────
@test "P11: gh_status=unavailable で経路 1/1' をスキップ + spool 不在 + 互換ファイル不在 → 経路 4" {
  source "$HOOK_LIB"

  GH_MOCK_AUTH_FAIL=1
  export GH_MOCK_AUTH_FAIL

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn_continue"* ]]
}

# ─── P12: prev_cycle 不正で exit 2 ─────
@test "P12: prev_cycle 不正（path traversal）で exit 2" {
  source "$HOOK_LIB"

  run --separate-stderr predecessor_resolve_issue "../../etc/passwd"
  [ "$status" -eq 2 ]
  [[ "$stderr" == *"predecessor_invalid_cycle"* ]]
}

@test "P12b: prev_cycle 引数欠落で exit 2" {
  source "$HOOK_LIB"

  run --separate-stderr predecessor_resolve_issue
  [ "$status" -eq 2 ]
}

# ─── P14: テンプレ削除確認（物理削除済） ─────
@test "P14: skills/aidlc/templates/predecessor_retrospective.md が存在しない" {
  [ ! -f "${REPO_ROOT}/skills/aidlc/templates/predecessor_retrospective.md" ]
}

# ─── P15: 純粋関数 _pure_classify_resolution_path ─────
@test "P15: _pure_classify_resolution_path 各経路への分類が正しい" {
  source "$HOOK_LIB"

  # 経路 1
  run _pure_classify_resolution_path "available" "true" "1" "false" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == "milestone_and_label" ]]

  # 経路 1'
  run _pure_classify_resolution_path "available" "false" "1" "false" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == "label_fallback" ]]

  # 経路 2: gh × milestone × 0 件 + spool 存在
  run _pure_classify_resolution_path "available" "true" "0" "true" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == "spool_fallback" ]]

  # 経路 2: gh 不可 + spool 存在
  run _pure_classify_resolution_path "unavailable" "true" "-1" "true" "true"
  [ "$status" -eq 0 ]
  [[ "$output" == "spool_fallback" ]]

  # 経路 3: 全 0 件 + 互換ファイルのみ
  run _pure_classify_resolution_path "available" "true" "0" "false" "true"
  [ "$status" -eq 0 ]
  [[ "$output" == "v2_5_0_compat" ]]

  # 経路 4: すべて 0 件
  run _pure_classify_resolution_path "available" "true" "0" "false" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == "warn_continue" ]]
}

# ─── P16: 純粋関数 _pure_format_query_args ─────
@test "P16: _pure_format_query_args が milestone_enabled で分岐する" {
  source "$HOOK_LIB"

  run _pure_format_query_args "v2.5.0" "true"
  [[ "$output" == *"--milestone v2.5.0"* ]]
  [[ "$output" == *"--label retrospective"* ]]

  run _pure_format_query_args "v2.5.0" "false"
  [[ "$output" != *"--milestone"* ]]
  [[ "$output" == *"--label retrospective"* ]]
}

# ─── P19: spool fallback で partial_state.local_created を参照（Unit 005 コードレビュー P1 対応） ─────
@test "P19: spool fallback / partial_state.local_created に URL あり → 正しく抽出" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[]'
  export GH_MOCK_LIST_RESULT
  make_spool_with_url "https://github.com/owner/repo/issues/900"  # partial_state.local_created に格納

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"spool_fallback"* ]]
  [[ "$output" == *"issues/900"* ]]
}

# ─── P20: spool fallback / 旧 issue_url キーへの fallback parse（v2.5.0 互換） ─────
@test "P20: spool fallback / 旧 v2.5.0 schema (.issue_url) でも fallback で URL 抽出" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_RESULT='[]'
  export GH_MOCK_LIST_RESULT
  make_spool_with_legacy_url "https://github.com/owner/repo/issues/901"

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"spool_fallback"* ]]
  [[ "$output" == *"issues/901"* ]]
}

# ─── P18: __pred_gh_query 内部関数 / label fallback で prev_cycle title 絞り込み ─────
@test "P18: __pred_gh_query label fallback / 他 cycle の Issue を除外（v2.5.0 と v2.5.0-rc1 共存時）" {
  source "$HOOK_LIB"

  # 3 cycle 分の retrospective Issue を gh shim で返す
  GH_MOCK_LIST_RESULT='[
    {"url":"https://github.com/owner/repo/issues/100","title":"Retrospective: v2.5.0","closedAt":"2026-04-01T00:00:00Z"},
    {"url":"https://github.com/owner/repo/issues/101","title":"Retrospective: v2.5.0-rc1","closedAt":"2026-03-01T00:00:00Z"},
    {"url":"https://github.com/owner/repo/issues/102","title":"Retrospective: v2.4.0","closedAt":"2026-02-01T00:00:00Z"}
  ]'
  export GH_MOCK_LIST_RESULT

  # milestone_enabled=false を直接渡して __pred_gh_query を実行
  run __pred_gh_query "v2.5.0" "false"
  [ "$status" -eq 0 ]
  # 100 のみ採用 / rc1 と v2.4.0 は除外
  [[ "$output" == *"issues/100"* ]]
  [[ "$output" != *"issues/101"* ]]
  [[ "$output" != *"issues/102"* ]]
}

# ─── P17: 純粋関数 _pure_sort_by_closed_at_desc ─────
@test "P17: _pure_sort_by_closed_at_desc が closedAt 降順でソートする" {
  source "$HOOK_LIB"

  local input='[{"url":"a","closedAt":"2026-01-01"},{"url":"b","closedAt":"2026-03-01"},{"url":"c","closedAt":"2026-02-01"}]'
  run bash -c "source '$HOOK_LIB' && printf '%s' '$input' | _pure_sort_by_closed_at_desc"
  [ "$status" -eq 0 ]
  # 先頭が b (2026-03-01)
  local first_url
  first_url=$(printf '%s' "$output" | jq -r '.[0].url')
  [ "$first_url" = "b" ]
}
