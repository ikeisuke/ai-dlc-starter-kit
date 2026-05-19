#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 004 (v2.6.6): predecessor_resolve_issue() 新動作経路テスト
# 既存 5 経路すべて 0 件のときのみ評価される
# t_issue_milestone_scope / t_issue_label_fallback の 2 サブ分岐を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HOOK_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/predecessor-issue.sh"
  TMP="$(mktemp -d -t aidlc-pred-tloop.XXXXXX)"
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"
  cd "$TMP"

  PREV_CYCLE="v2.6.5"
  mkdir -p ".aidlc/cycles/${PREV_CYCLE}/history" ".aidlc/cycles/${PREV_CYCLE}/operations"

  # gh shim: 呼び出し位置（4 番目の引数）と GH_MOCK_*_RESULT で結果を分岐
  # gh issue list --milestone <ms> --label retrospective ...  → MILESTONE 結果
  # gh issue list --label retrospective ...                    → LABEL 結果
  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
case "$1" in
  auth)
    [[ "$2" == "status" ]] && exit 0
    ;;
  issue)
    if [[ "$2" == "list" ]]; then
      # --milestone があれば MILESTONE 結果、なければ LABEL 結果
      has_milestone=0
      for arg in "$@"; do
        if [[ "$arg" == "--milestone" ]]; then
          has_milestone=1
          break
        fi
      done
      if [[ "$has_milestone" -eq 1 ]]; then
        printf '%s\n' "${GH_MOCK_LIST_MILESTONE:-[]}"
      else
        printf '%s\n' "${GH_MOCK_LIST_LABEL:-[]}"
      fi
      exit 0
    fi
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  PATH="$SHIM_DIR:$PATH"
  export PATH

  unset __AIDLC_PREDECESSOR_ISSUE_SH_LOADED
  unset GH_MOCK_LIST_MILESTONE
  unset GH_MOCK_LIST_LABEL
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# ─── T1: 新動作 t_issue_milestone_scope ─────
@test "T1: 既存 5 経路 0 件 + 同 milestone 内 T Issue 3 件 → resolution_path=t_issue_milestone_scope / candidates ≥ 1" {
  source "$HOOK_LIB"

  # 既存 5 経路は全 0 件（集約 Retrospective: が 0）
  # MILESTONE 経由クエリは T Issue 3 件を返す（[Retrospective: v2.6.5] prefix）
  GH_MOCK_LIST_MILESTONE='[
    {"url":"https://github.com/owner/repo/issues/801","title":"[Retrospective: v2.6.5] Try A","closedAt":"2026-04-01T00:00:00Z","number":801},
    {"url":"https://github.com/owner/repo/issues/802","title":"[Retrospective: v2.6.5] Try B","closedAt":"2026-04-02T00:00:00Z","number":802},
    {"url":"https://github.com/owner/repo/issues/803","title":"[Retrospective: v2.6.5] Try C","closedAt":"2026-04-03T00:00:00Z","number":803}
  ]'
  export GH_MOCK_LIST_MILESTONE

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"t_issue_milestone_scope"* ]]
  # candidates 配列が 3 件
  local count
  count=$(printf '%s' "$output" | jq '.candidates | length')
  [ "$count" -eq 3 ]
  # issue_url は null（候補集合のみ / 単一値は返さない）
  [[ "$output" == *'"issue_url":null'* ]]
  # source_milestone が PREV_CYCLE
  [[ "$output" == *'"source_milestone":"v2.6.5"'* ]]
}

# ─── T2: 新動作 t_issue_label_fallback ─────
@test "T2: 既存 5 経路 0 件 + milestone 集計 0 件 + label 経由で T Issue 2 件 → resolution_path=t_issue_label_fallback" {
  source "$HOOK_LIB"

  # MILESTONE 結果 0 件、LABEL 結果に T Issue 2 件
  GH_MOCK_LIST_MILESTONE='[]'
  GH_MOCK_LIST_LABEL='[
    {"url":"https://github.com/owner/repo/issues/901","title":"[Retrospective: v2.6.5] Try X","closedAt":"2026-04-10T00:00:00Z","number":901},
    {"url":"https://github.com/owner/repo/issues/902","title":"[Retrospective: v2.6.5] Try Y","closedAt":null,"number":902}
  ]'
  export GH_MOCK_LIST_MILESTONE GH_MOCK_LIST_LABEL

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"t_issue_label_fallback"* ]]
  local count
  count=$(printf '%s' "$output" | jq '.candidates | length')
  [ "$count" -eq 2 ]
  # source_milestone は null（label fallback のため）
  [[ "$output" == *'"source_milestone":null'* ]]
}

# ─── T3: closedAt null 安全ソート（OPEN 混在）─────
@test "T3: t_issue 経路で closedAt=null（OPEN T Issue）が末尾に配置される" {
  source "$HOOK_LIB"

  # OPEN（closedAt=null）と CLOSED 混在
  GH_MOCK_LIST_MILESTONE='[
    {"url":"https://github.com/owner/repo/issues/701","title":"[Retrospective: v2.6.5] Try OPEN","closedAt":null,"number":701},
    {"url":"https://github.com/owner/repo/issues/702","title":"[Retrospective: v2.6.5] Try CLOSED-OLD","closedAt":"2026-03-01T00:00:00Z","number":702},
    {"url":"https://github.com/owner/repo/issues/703","title":"[Retrospective: v2.6.5] Try CLOSED-NEW","closedAt":"2026-04-01T00:00:00Z","number":703}
  ]'
  export GH_MOCK_LIST_MILESTONE

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  # 最初は CLOSED-NEW (issues/703)、最後が OPEN (issues/701)
  local first_url last_url
  first_url=$(printf '%s' "$output" | jq -r '.candidates[0].url')
  last_url=$(printf '%s' "$output" | jq -r '.candidates[-1].url')
  [[ "$first_url" == *"issues/703"* ]]
  [[ "$last_url" == *"issues/701"* ]]
}

# ─── T4: 旧サイクル維持（集約 1 件あり） ─────
@test "T4: 旧サイクル fixture (Retrospective: <cycle> 集約 Issue 1 件あり) → milestone_and_label 維持 / 新経路に到達しない" {
  source "$HOOK_LIB"

  # 集約 Issue（"Retrospective: v2.6.5" / [ なし） + T Issue が混在
  # milestone_enabled=true（既定）で MILESTONE 経由クエリが集約 1 件を返す
  GH_MOCK_LIST_MILESTONE='[
    {"url":"https://github.com/owner/repo/issues/500","title":"Retrospective: v2.6.5","closedAt":"2026-04-01T00:00:00Z","number":500}
  ]'
  GH_MOCK_LIST_LABEL='[
    {"url":"https://github.com/owner/repo/issues/500","title":"Retrospective: v2.6.5","closedAt":"2026-04-01T00:00:00Z","number":500},
    {"url":"https://github.com/owner/repo/issues/801","title":"[Retrospective: v2.6.5] Try A","closedAt":null,"number":801}
  ]'
  export GH_MOCK_LIST_MILESTONE GH_MOCK_LIST_LABEL

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  # 既存経路 1 で resolve（milestone_and_label）/ 新経路に入らない
  [[ "$output" == *"milestone_and_label"* ]]
  [[ "$output" != *"t_issue_milestone_scope"* ]]
  [[ "$output" != *"t_issue_label_fallback"* ]]
  [[ "$output" == *"issues/500"* ]]
}

# ─── T5: 既存 5 経路 0 件 + 新経路 0 件 → warn_continue ─────
@test "T5: 既存 5 経路 0 件 + T Issue 集計 milestone 0 件 + label 0 件 → warn_continue 維持" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_MILESTONE='[]'
  GH_MOCK_LIST_LABEL='[]'
  export GH_MOCK_LIST_MILESTONE GH_MOCK_LIST_LABEL

  run --separate-stderr predecessor_resolve_issue "$PREV_CYCLE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn_continue"* ]]
  [[ "$output" != *"t_issue_milestone_scope"* ]]
  [[ "$output" != *"t_issue_label_fallback"* ]]
}

# ─── T6: 純粋関数 _pure_classify_resolution_path 新経路 ─────
@test "T6: _pure_classify_resolution_path 新引数 6/7 で t_issue 経路に分類される" {
  source "$HOOK_LIB"

  # 既存 5 経路 0 件 + t_milestone_count=1
  run _pure_classify_resolution_path "available" "true" "0" "false" "false" "1" "0"
  [ "$status" -eq 0 ]
  [[ "$output" == "t_issue_milestone_scope" ]]

  # 既存 5 経路 0 件 + t_milestone=0 + t_label=2
  run _pure_classify_resolution_path "available" "true" "0" "false" "false" "0" "2"
  [ "$status" -eq 0 ]
  [[ "$output" == "t_issue_label_fallback" ]]

  # 既存 5 経路 0 件 + 両 0 件 → warn_continue
  run _pure_classify_resolution_path "available" "true" "0" "false" "false" "0" "0"
  [ "$status" -eq 0 ]
  [[ "$output" == "warn_continue" ]]

  # gh_status=unavailable で t_milestone_count があっても新経路に入らない（gh available 条件）
  run _pure_classify_resolution_path "unavailable" "true" "-1" "false" "false" "5" "5"
  [ "$status" -eq 0 ]
  [[ "$output" == "warn_continue" ]]

  # 既存 5 経路（milestone_and_label）がヒット → 新経路の引数があっても既存優先
  run _pure_classify_resolution_path "available" "true" "1" "false" "false" "10" "10"
  [ "$status" -eq 0 ]
  [[ "$output" == "milestone_and_label" ]]
}

# ─── T7: _pure_sort_by_closed_at_desc_null_safe null 末尾 ─────
@test "T7: _pure_sort_by_closed_at_desc_null_safe が null を末尾に配置する" {
  source "$HOOK_LIB"

  local input='[{"url":"a","closedAt":null},{"url":"b","closedAt":"2026-03-01"},{"url":"c","closedAt":"2026-04-01"},{"url":"d","closedAt":null}]'
  run bash -c "source '$HOOK_LIB' && printf '%s' '$input' | _pure_sort_by_closed_at_desc_null_safe"
  [ "$status" -eq 0 ]
  # 先頭: c (2026-04-01) → b (2026-03-01) → a/d (null) 末尾
  local first
  first=$(printf '%s' "$output" | jq -r '.[0].url')
  [ "$first" = "c" ]
  local last_closed
  last_closed=$(printf '%s' "$output" | jq -r '.[-1].closedAt')
  [ "$last_closed" = "null" ]
}

# ─── T8: __pred_gh_query_t_issue が集約 Issue を除外（prefix [ で判別） ─────
@test "T8: __pred_gh_query_t_issue が 'Retrospective: ' 集約 Issue を除外し '[Retrospective: ]' T Issue のみ返す" {
  source "$HOOK_LIB"

  GH_MOCK_LIST_MILESTONE='[
    {"url":"https://github.com/owner/repo/issues/500","title":"Retrospective: v2.6.5","closedAt":"2026-04-01T00:00:00Z","number":500},
    {"url":"https://github.com/owner/repo/issues/801","title":"[Retrospective: v2.6.5] Try A","closedAt":"2026-04-02T00:00:00Z","number":801},
    {"url":"https://github.com/owner/repo/issues/802","title":"[Retrospective: v2.6.4] Try Other","closedAt":"2026-04-03T00:00:00Z","number":802}
  ]'
  export GH_MOCK_LIST_MILESTONE

  run __pred_gh_query_t_issue "v2.6.5" "true"
  [ "$status" -eq 0 ]
  # 集約 Issue (500) は除外
  [[ "$output" != *"issues/500"* ]]
  # 別 cycle の T Issue (802) も除外
  [[ "$output" != *"issues/802"* ]]
  # 対象 cycle の T Issue (801) のみ
  [[ "$output" == *"issues/801"* ]]
  local count
  count=$(printf '%s' "$output" | jq 'length')
  [ "$count" -eq 1 ]
}
