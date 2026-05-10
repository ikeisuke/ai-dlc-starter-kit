#!/usr/bin/env bats
# Unit 003 / #690 / v2.6.1
# resolve-route.sh の純関数 resolve_feedback_route の真理値表 6 行 + 入力正規化 + CLI usage エラーを網羅検証
# 真理値表 SoT: .aidlc/cycles/v2.6.1/story-artifacts/user_stories.md ストーリー 3

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  ROUTE_LIB="${REPO_ROOT}/skills/aidlc-feedback/scripts/lib/resolve-route.sh"
}

# -------- 真理値表 6 行（ストーリー 3 SoT、優先順位: TTY > 設定 > フラグ）--------

@test "truth-table row 1: setting=true / explicit_web=false / is_tty=true → web" {
  run bash "$ROUTE_LIB" resolve true false true
  [ "$status" -eq 0 ]
  [ "$output" = "web" ]
}

@test "truth-table row 2: setting=true / explicit_web=false / is_tty=false → direct (TTY 優先)" {
  run bash "$ROUTE_LIB" resolve true false false
  [ "$status" -eq 0 ]
  [ "$output" = "direct" ]
}

@test "truth-table row 3: setting=false / explicit_web=true / is_tty=true → web" {
  run bash "$ROUTE_LIB" resolve false true true
  [ "$status" -eq 0 ]
  [ "$output" = "web" ]
}

@test "truth-table row 4: setting=false / explicit_web=true / is_tty=false → direct (TTY 優先)" {
  run bash "$ROUTE_LIB" resolve false true false
  [ "$status" -eq 0 ]
  [ "$output" = "direct" ]
}

@test "truth-table row 5: setting=false / explicit_web=false / is_tty=true → direct (デフォルト)" {
  run bash "$ROUTE_LIB" resolve false false true
  [ "$status" -eq 0 ]
  [ "$output" = "direct" ]
}

@test "truth-table row 6: setting=false / explicit_web=false / is_tty=false → direct (デフォルト)" {
  run bash "$ROUTE_LIB" resolve false false false
  [ "$status" -eq 0 ]
  [ "$output" = "direct" ]
}

# -------- unset_or_invalid バリエーション（setting=未設定/エラーケース）--------

@test "setting=unset_or_invalid / explicit_web=false / is_tty=true → direct" {
  run bash "$ROUTE_LIB" resolve unset_or_invalid false true
  [ "$status" -eq 0 ]
  [ "$output" = "direct" ]
}

@test "setting=unset_or_invalid / explicit_web=true / is_tty=true → web (フラグで上書き)" {
  run bash "$ROUTE_LIB" resolve unset_or_invalid true true
  [ "$status" -eq 0 ]
  [ "$output" = "web" ]
}

@test "setting=unset_or_invalid / explicit_web=true / is_tty=false → direct (TTY 優先)" {
  run bash "$ROUTE_LIB" resolve unset_or_invalid true false
  [ "$status" -eq 0 ]
  [ "$output" = "direct" ]
}

# -------- 入力不正（exit 1 系）--------

@test "invalid input: setting=foo → exit 1 + stderr error" {
  run bash "$ROUTE_LIB" resolve foo false true
  [ "$status" -eq 1 ]
  [[ "$output" == *"error: invalid input: setting="* ]]
}

@test "invalid input: explicit_web=maybe → exit 1 + stderr error" {
  run bash "$ROUTE_LIB" resolve true maybe true
  [ "$status" -eq 1 ]
  [[ "$output" == *"error: invalid input: explicit_web="* ]]
}

@test "invalid input: is_tty=1 → exit 1 + stderr error" {
  run bash "$ROUTE_LIB" resolve true false 1
  [ "$status" -eq 1 ]
  [[ "$output" == *"error: invalid input: is_tty="* ]]
}

# -------- CLI usage エラー（設計レビュー Round 1 #4 反映）--------

@test "usage: 引数なし → exit 1 + usage" {
  run bash "$ROUTE_LIB"
  [ "$status" -eq 1 ]
  [[ "$output" == *"usage: resolve-route.sh"* ]]
}

@test "usage: 不明な subcommand → exit 1 + error + usage" {
  run bash "$ROUTE_LIB" unknown
  [ "$status" -eq 1 ]
  [[ "$output" == *"error: unknown subcommand"* ]]
  [[ "$output" == *"usage: resolve-route.sh"* ]]
}

@test "usage: resolve に引数不足 → exit 1 + error + usage" {
  run bash "$ROUTE_LIB" resolve true
  [ "$status" -eq 1 ]
  [[ "$output" == *"error: missing arguments"* ]]
  [[ "$output" == *"usage: resolve-route.sh"* ]]
}

# -------- normalize_explicit_web の真理値解釈テスト --------

@test "normalize_explicit_web: '1' → true" {
  run bash "$ROUTE_LIB" normalize-explicit-web "1"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "normalize_explicit_web: 'true' → true" {
  run bash "$ROUTE_LIB" normalize-explicit-web "true"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "normalize_explicit_web: 'yes' → true" {
  run bash "$ROUTE_LIB" normalize-explicit-web "yes"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "normalize_explicit_web: 'TRUE' → true (大文字無視)" {
  run bash "$ROUTE_LIB" normalize-explicit-web "TRUE"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "normalize_explicit_web: '  yes  ' → true (前後空白除去)" {
  run bash "$ROUTE_LIB" normalize-explicit-web "  yes  "
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "normalize_explicit_web: '0' → false" {
  run bash "$ROUTE_LIB" normalize-explicit-web "0"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "normalize_explicit_web: 'false' → false" {
  run bash "$ROUTE_LIB" normalize-explicit-web "false"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "normalize_explicit_web: '' (空文字) → false" {
  run bash "$ROUTE_LIB" normalize-explicit-web ""
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "normalize_explicit_web: 'maybe' → false (許容値外は false)" {
  run bash "$ROUTE_LIB" normalize-explicit-web "maybe"
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

# -------- ライブラリモード（source）--------

@test "library mode: source 後 resolve_feedback_route 呼出可能" {
  run bash -c "source '$ROUTE_LIB' && resolve_feedback_route true false true"
  [ "$status" -eq 0 ]
  [ "$output" = "web" ]
}

@test "library mode: source 後 normalize_explicit_web 呼出可能" {
  run bash -c "source '$ROUTE_LIB' && normalize_explicit_web '1'"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

# -------- normalize_setting（呼び出し側 setting 正規化、コードレビュー Round 1 #1 反映）--------

@test "normalize_setting: exit 0 + 'true' → setting=true / 警告なし" {
  run bash "$ROUTE_LIB" normalize-setting 0 true
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "normalize_setting: exit 0 + 'false' → setting=false / 警告なし" {
  run bash "$ROUTE_LIB" normalize-setting 0 false
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "normalize_setting: exit 0 + 型不一致値 → setting=unset_or_invalid + 警告" {
  run bash "$ROUTE_LIB" normalize-setting 0 maybe
  [ "$status" -eq 0 ]
  [[ "$output" == *"unset_or_invalid"* ]]
  [[ "$output" == *"warning: rules.feedback.open_in_browser has invalid value"* ]]
}

@test "normalize_setting: exit 1（キー不在）→ setting=unset_or_invalid / 警告なし" {
  run bash "$ROUTE_LIB" normalize-setting 1 ""
  [ "$status" -eq 0 ]
  [ "$output" = "unset_or_invalid" ]
}

@test "normalize_setting: exit 2（エラー）→ setting=unset_or_invalid + 警告" {
  run bash "$ROUTE_LIB" normalize-setting 2 ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"unset_or_invalid"* ]]
  [[ "$output" == *"warning: failed to read rules.feedback.open_in_browser (exit 2)"* ]]
}

@test "normalize_setting: 不正な exit code → exit 1" {
  run bash "$ROUTE_LIB" normalize-setting 99 ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"error: invalid input: exit_code="* ]]
}

# -------- should_warn_override（強制無効化警告判定、コードレビュー Round 1 #1 反映）--------

@test "should_warn_override: row 2 (setting=true, is_tty=false) → true" {
  run bash "$ROUTE_LIB" should-warn-override true false false
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "should_warn_override: row 4 (setting=false, explicit_web=true, is_tty=false) → true" {
  run bash "$ROUTE_LIB" should-warn-override false true false
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "should_warn_override: row 1 (setting=true, is_tty=true) → false (TTY なら警告不要)" {
  run bash "$ROUTE_LIB" should-warn-override true false true
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "should_warn_override: row 3 (setting=false, explicit_web=true, is_tty=true) → false" {
  run bash "$ROUTE_LIB" should-warn-override false true true
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "should_warn_override: row 5 (デフォルト TTY) → false" {
  run bash "$ROUTE_LIB" should-warn-override false false true
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "should_warn_override: row 6 (デフォルト 非 TTY) → false (両方 false なら警告不要)" {
  run bash "$ROUTE_LIB" should-warn-override false false false
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "should_warn_override: setting=unset_or_invalid + explicit_web=true + is_tty=false → true" {
  run bash "$ROUTE_LIB" should-warn-override unset_or_invalid true false
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "should_warn_override: setting=unset_or_invalid + explicit_web=false + is_tty=false → false" {
  run bash "$ROUTE_LIB" should-warn-override unset_or_invalid false false
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

# -------- emit_override_warning --------

@test "emit_override_warning: stderr に統一警告 1 行を出力" {
  run bash "$ROUTE_LIB" emit-override-warning
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: open_in_browser/AIDLC_FEEDBACK_WEB is overridden by non-TTY environment"* ]]
}

# -------- usage の subcommand 全列挙確認（コードレビュー Round 1 #2 反映）--------

@test "usage: 不明 subcommand のメッセージに全 subcommand を列挙" {
  run bash "$ROUTE_LIB" some-unknown-cmd
  [ "$status" -eq 1 ]
  [[ "$output" == *"normalize-explicit-web"* ]]
  [[ "$output" == *"normalize-setting"* ]]
  [[ "$output" == *"should-warn-override"* ]]
}
