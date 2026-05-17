#!/usr/bin/env bats
# Unit 004 / v2.6.4 / #710: 振り返り opt-in 基盤フラグ `rules.retrospective.auto_issue_creation` 検証
#
# 検証範囲:
#   - defaults.toml に新規キーが存在し、4 階層マージ後の値が `true` であること（デフォルト動作不変）
#   - project の config.toml で `auto_issue_creation = false` を設定すると read 経路で `false` が返ること
#   - read-config.sh の終了コード規約（0=値あり / 1=キー不在 / 2+=取得失敗）に対する手順書側の
#     opt-out 判定ロジック（retrospective.md §1.5 Step 2 末尾）が fail-open で動作すること
#   - retrospective.md §1.5 Step 2 末尾に opt-in 判定ブロックが記述されていること
#   - retrospective.md §1.5 Step 3 直前のスキップ条件が「cap 超過 OR opt-out」に拡張されていること
#
# 既存の `feedback-mode-resolution.bats` と同じ helpers/setup を使用する。

load helpers/setup

teardown() { teardown_env; }

# ─── 設定値読み取り経路 ────────────────────────────────────────

@test "OI1: defaults.toml に auto_issue_creation = true が存在する（デフォルト動作不変の保証）" {
  setup_env
  run bash "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" rules.retrospective.auto_issue_creation
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "OI2: project config で auto_issue_creation = false を設定すると false が返る" {
  setup_env
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<'EOF'
[rules.retrospective]
auto_issue_creation = false
EOF
  run bash "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" rules.retrospective.auto_issue_creation
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "OI3: project config で auto_issue_creation = true を明示しても true が返る" {
  setup_env
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<'EOF'
[rules.retrospective]
auto_issue_creation = true
EOF
  run bash "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" rules.retrospective.auto_issue_creation
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

# ─── 手順書側 opt-out 判定ロジック（retrospective.md §1.5 Step 2 末尾のコード片を bats で再現） ─

# 手順書側ロジックを bats で再現するヘルパ。retrospective.md と同一の case 分岐を実装し、
# 取得経路と fail-open の挙動を検証する。手順書のコード片を更新したら本ヘルパも同期更新する。
_eval_opt_out() {
  local out_dir="${TEST_TMPDIR}/opt-out"
  mkdir -p "$out_dir"
  set +e
  bash "${REPO_ROOT}/skills/aidlc/scripts/read-config.sh" rules.retrospective.auto_issue_creation \
    >"${out_dir}/value.txt" 2>"${out_dir}/err.txt"
  local rc=$?
  set -e
  local auto_issue
  case "$rc" in
    0)
      read -r auto_issue <"${out_dir}/value.txt"
      ;;
    1)
      auto_issue="true"
      ;;
    *)
      auto_issue="true"
      ;;
  esac
  if [[ "$auto_issue" == "false" ]]; then
    echo "opt-out=true" >"${out_dir}/opt-out.txt"
  else
    : >"${out_dir}/opt-out.txt"
  fi
  echo "rc=$rc"
  echo "auto_issue=$auto_issue"
  if [[ -s "${out_dir}/opt-out.txt" ]]; then
    echo "opt-out=true"
  else
    echo "opt-out=false"
  fi
}

@test "OI4: 手順書側ロジック - デフォルト（auto_issue_creation = true）→ opt-out=false" {
  setup_env
  run _eval_opt_out
  [ "$status" -eq 0 ]
  [[ "$output" == *"rc=0"* ]]
  [[ "$output" == *"auto_issue=true"* ]]
  [[ "$output" == *"opt-out=false"* ]]
}

@test "OI5: 手順書側ロジック - auto_issue_creation = false → opt-out=true" {
  setup_env
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<'EOF'
[rules.retrospective]
auto_issue_creation = false
EOF
  run _eval_opt_out
  [ "$status" -eq 0 ]
  [[ "$output" == *"rc=0"* ]]
  [[ "$output" == *"auto_issue=false"* ]]
  [[ "$output" == *"opt-out=true"* ]]
}

@test "OI6: 手順書側ロジック - 不正値（auto_issue_creation = \"yes\"）→ true でない値は opt-out=false 既定" {
  setup_env
  cat >"${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" <<'EOF'
[rules.retrospective]
auto_issue_creation = "yes"
EOF
  run _eval_opt_out
  [ "$status" -eq 0 ]
  # 不正値はそのまま読まれるが "false" 文字列と一致しない限り opt-out 不発火（=既存動作継続）
  [[ "$output" == *"opt-out=false"* ]]
}

# ─── 手順書埋め込みアサーション ──────────────────────────────

@test "OI7: retrospective.md §1.5 Step 2 末尾に opt-in 判定ブロックが記述されている" {
  local f="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
  grep -q "rules.retrospective.auto_issue_creation" "$f"
  grep -q "opt-in 基盤フラグ" "$f"
  grep -q "/tmp/aidlc-opt-out.txt" "$f"
}

@test "OI8: retrospective.md のスキップ条件が cap 超過 OR opt-out に拡張されている" {
  local f="${REPO_ROOT}/skills/aidlc-retrospective/steps/retrospective.md"
  grep -q "cap 超過.*opt-out\|opt-out.*cap 超過\|/tmp/aidlc-opt-out.txt" "$f"
  grep -q '! -s /tmp/aidlc-over.txt && ! -s /tmp/aidlc-opt-out.txt' "$f"
}

@test "OI9: aidlc-retrospective/SKILL.md に v2.6.4 サイクル対象外項目の defer 記載が存在する" {
  local f="${REPO_ROOT}/skills/aidlc-retrospective/SKILL.md"
  grep -q "v2.6.4 サイクル対象外項目" "$f"
  grep -q "v2.7.0+" "$f"
  grep -q "auto_issue_creation" "$f"
}

@test "OI10: defaults.toml に auto_issue_creation キー定義コメントが残っている（SoT 維持）" {
  local f="${REPO_ROOT}/skills/aidlc/config/defaults.toml"
  grep -q "auto_issue_creation = true" "$f"
  grep -q "opt-in 基盤" "$f"
}
