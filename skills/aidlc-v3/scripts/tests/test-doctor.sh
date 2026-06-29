#!/usr/bin/env bash
#
# test-doctor.sh - doctor.sh の領域診断と総合 exit code の契約検証
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提 / 既存テストと同方式）。
# ネットワーク非依存（実 gh を叩かず、gh は PATH 操作 / stub で再現）。
#
# 検証方針:
#   doctor.sh は依存スクリプト（state-validate.sh / state-read.sh / work-item-validate.sh /
#   read-config.sh / check-frontmatter-parse-guard.sh）を **配置基準の相対パス** で解決する。
#   そこで本テストは「自己完結フィクスチャスキルツリー」を組み立てる:
#     <fixture>/skills/aidlc-v3/scripts/    … 実 v3 スクリプト + doctor.sh をコピー
#     <fixture>/skills/aidlc/scripts/read-config.sh … 契約 stub（rc を env で制御）
#     <fixture>/bin/check-frontmatter-parse-guard.sh … 契約 stub（rc を env で制御）
#   これにより [config] / [parse-guard] / [scripts] の ERROR ケースも注入できる。
#   実 read-config.sh / parse-guard の内部ロジックは各々のテストが担保し、本テストは
#   doctor の wrap（rc/stdout → severity 写像）契約を固定する。
#
# Usage: test-doctor.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"             # skills/aidlc-v3/scripts
readonly SCRIPT_DIR SCRIPTS_DIR
readonly REAL_DOCTOR="$SCRIPTS_DIR/doctor.sh"

if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi

BASH_BIN="$(command -v bash)"
readonly BASH_BIN

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "  ok   : $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL : $1"; }

# 退避先（rm -rf 実行前にここへ cd して test-isolation cd-guard を守る）。
SAFE_DIR="$(mktemp -d)"
WORK_ROOT="$(mktemp -d)"
# cleanup は trap 経由で呼ばれる（shellcheck SC2329 は誤検知のため抑制）。
# shellcheck disable=SC2329
cleanup() {
    cd "$SAFE_DIR" 2>/dev/null || cd / 2>/dev/null || true
    chmod -R u+rwx "$WORK_ROOT" 2>/dev/null || true
    rm -rf "$WORK_ROOT" "$SAFE_DIR"
}
trap cleanup EXIT

# ============================================================
# フィクスチャ生成
# ============================================================
# 自己完結スキルツリーを <root> に組み立て、doctor へのパスを返す（標準出力）。
#   build_fixture <root>
# 生成物:
#   <root>/skills/aidlc-v3/scripts/{doctor.sh + 実 v3 スクリプト群}
#   <root>/skills/aidlc/scripts/read-config.sh   （contract stub）
#   <root>/bin/check-frontmatter-parse-guard.sh  （contract stub）
#   <root>/.aidlc/                                （診断対象 / 各テストで内容を設定）
# stub の rc は環境変数で制御する:
#   DOCTOR_TEST_READCONFIG_RC      read-config.sh の終了コード（既定 0）
#   DOCTOR_TEST_PARSEGUARD_RC      parse-guard の終了コード（既定 0）
build_fixture() {
    local root="$1"
    local v3="$root/skills/aidlc-v3/scripts"
    local aidlc="$root/skills/aidlc/scripts"
    local bin="$root/bin"
    mkdir -p "$v3/lib" "$aidlc" "$bin" "$root/.aidlc"

    # 実 v3 スクリプトをコピー（doctor が [scripts] 必須集合・wrap 先として参照）。
    cp "$SCRIPTS_DIR/doctor.sh" "$v3/doctor.sh"
    cp "$SCRIPTS_DIR/state-read.sh" "$v3/state-read.sh"
    cp "$SCRIPTS_DIR/state-write.sh" "$v3/state-write.sh"
    cp "$SCRIPTS_DIR/state-validate.sh" "$v3/state-validate.sh"
    cp "$SCRIPTS_DIR/state-init.sh" "$v3/state-init.sh"
    cp "$SCRIPTS_DIR/work-item-next.sh" "$v3/work-item-next.sh"
    cp "$SCRIPTS_DIR/work-item-validate.sh" "$v3/work-item-validate.sh"
    cp "$SCRIPTS_DIR/work-item-status.sh" "$v3/work-item-status.sh"
    cp "$SCRIPTS_DIR/lib/frontmatter.sh" "$v3/lib/frontmatter.sh"
    chmod +x "$v3"/*.sh

    # read-config.sh 契約 stub（rc を DOCTOR_TEST_READCONFIG_RC で制御 / rc0 は値を出力）。
    cat > "$aidlc/read-config.sh" <<'STUB'
#!/usr/bin/env bash
rc="${DOCTOR_TEST_READCONFIG_RC:-0}"
if [ "$rc" -eq 0 ]; then
    echo "deep"
fi
exit "$rc"
STUB
    chmod +x "$aidlc/read-config.sh"

    # parse-guard 契約 stub（rc を DOCTOR_TEST_PARSEGUARD_RC で制御）。
    cat > "$bin/check-frontmatter-parse-guard.sh" <<'STUB'
#!/usr/bin/env bash
exit "${DOCTOR_TEST_PARSEGUARD_RC:-0}"
STUB
    chmod +x "$bin/check-frontmatter-parse-guard.sh"

    # 既定で config.toml を用意する（[config] が ERROR にならないようにする / 不在テストは個別に rm）。
    echo "# config" > "$root/.aidlc/config.toml"
    # 既定で認証済み gh stub を用意する（[gh]/[pr] OK / 未認証テストは install_gh_stub で上書き）。
    install_gh_stub "$root" 0 ""

    printf '%s\n' "$v3/doctor.sh"
}

# 有効な state.json を生成する。
make_valid_state() {
    cat > "$1" <<'JSON'
{
  "schema_version": "3.0",
  "current_cycle": "v3.0.0",
  "define_completed": false,
  "release": {
    "pr_number": null,
    "ready": false,
    "merge_approved": false
  },
  "updated_at": "2026-06-04T00:00:00Z"
}
JSON
}

# 有効な work item を生成する（work-item-validate.sh が status:valid を返す最小構成）。
make_valid_work_item() {
    local path="$1" id="$2"
    cat > "$path" <<EOF
---
id: $id
status: pending
size: tiny
risk: low
assigned: null
dependencies: []
---

# work item $id

## Goal

goal

## Scope

scope

## Acceptance Criteria

- ac

## Traceability

- trace

## Size / Risk

size/risk

## Dependencies

none
EOF
}

# doctor を fixture 内で実行し、stdout を OUT / 終了コードを RC に格納する。
#   run_doctor <doctor_path> <fixture_root> [extra env assignments...]
# gh 制御: 既定では PATH から gh を外し、必要なら fixture の bin に gh stub を置く呼び出し側で制御する。
OUT=""
RC=0
run_doctor() {
    local doctor="$1"; shift
    local root="$1"; shift
    # read-config.sh は AIDLC_PROJECT_ROOT を見ないが、doctor は config.toml を cwd 相対で見る。
    # cwd を fixture root にし、git root も fixture root に一致させる（diagnose_git / parse-guard 用）。
    OUT="$(cd "$root" && env "$@" "$BASH_BIN" "$doctor" 2>/dev/null)"
    RC=$?
}

# 領域行の severity を OUT から取り出して期待値と比較する。
#   assert_area <area> <expected-severity> <desc>
assert_area() {
    local area="$1" expected="$2" desc="$3"
    local line sev
    line="$(printf '%s\n' "$OUT" | grep -E "^\[$area\][[:space:]]")"
    if [[ -z "$line" ]]; then
        fail "${desc}（領域 [$area] の行が出力にない）"
        return
    fi
    # "[area]" の後の最初のトークンが severity。
    sev="$(printf '%s\n' "$line" | sed -E "s/^\[$area\][[:space:]]+([A-Z]+).*/\1/")"
    if [[ "$sev" == "$expected" ]]; then
        pass "${desc}（[$area]=${sev}）"
    else
        fail "${desc}（[$area] expected=$expected got=$sev / line='$line'）"
    fi
}

# 総合 exit code を期待値と比較する。
assert_rc() {
    local expected="$1" desc="$2"
    if [[ "$RC" == "$expected" ]]; then
        pass "${desc}（rc=${RC}）"
    else
        fail "${desc}（expected rc=$expected, got rc=${RC}）"
    fi
}

# fixture root を git repo として初期化（コミットして clean worktree にする）。
git_init_clean() {
    local root="$1"
    (
        cd "$root" || exit 1
        git init -q
        git config user.email t@example.com
        git config user.name tester
        git config commit.gpgsign false
        git add -A
        git commit -q -m init
    )
}

# gh stub を fixture bin に置く（認証成功 / 失敗 / open PR の有無を制御）。
#   install_gh_stub <root> <auth_rc> <pr_numbers>
#     auth_rc: gh auth status の終了コード（0=認証 / 1=未認証）
#     pr_numbers: gh pr list が返す番号の JSON 配列要素（カンマ区切り文字列 / 空で 0 件）
install_gh_stub() {
    local root="$1" auth_rc="$2" pr_numbers="$3"
    cat > "$root/bin/gh" <<STUB
#!/usr/bin/env bash
case "\$1" in
  auth)
    exit $auth_rc
    ;;
  pr)
    # gh pr list --state open --json number --jq '...'
    nums="$pr_numbers"
    echo "\$nums"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
STUB
    chmod +x "$root/bin/gh"
}

# gh を含まない最小 PATH bin を構築する（[gh] の command -v gh 不在分岐を再現）。
# doctor / wrapped stub / git / jq が必要とするコマンドを system PATH から symlink する
# （gh は意図的に含めない）。標準出力に bin ディレクトリパスを返す。
make_min_path_without_gh() {
    local root="$1"
    local pbin="$root/nogh-bin"
    mkdir -p "$pbin"
    local c p
    for c in bash sh env jq git grep sed awk tr cat cut head tail sort uniq wc \
             dirname basename mktemp rm mkdir chmod cp ls printf date find xargs; do
        if p="$(command -v "$c" 2>/dev/null)"; then
            ln -sf "$p" "$pbin/$c"
        fi
    done
    printf '%s' "$pbin"
}

# ------------------------------------------------------------
echo "== 静的検査（bash -n / shellcheck） =="
if bash -n "$REAL_DOCTOR" 2>/dev/null; then pass "bash -n: doctor.sh"; else fail "bash -n: doctor.sh"; fi
if bash -n "$SCRIPT_DIR/test-doctor.sh" 2>/dev/null; then pass "bash -n: test-doctor.sh"; else fail "bash -n: test-doctor.sh"; fi
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$REAL_DOCTOR" >/dev/null 2>&1; then pass "shellcheck: doctor.sh"; else fail "shellcheck: doctor.sh"; fi
    if shellcheck "$SCRIPT_DIR/test-doctor.sh" >/dev/null 2>&1; then pass "shellcheck: test-doctor.sh"; else fail "shellcheck: test-doctor.sh"; fi
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

# 各テストは独立した fixture を使う。fixture root 配下に gh stub を置き、PATH 先頭に bin を付ける。
# PATH には jq/git/bash が必要なため、元 PATH を温存したうえで fixture bin を前置する。
mk() {
    local name="$1"
    local root="$WORK_ROOT/$name"
    mkdir -p "$root"
    DOCTOR="$(build_fixture "$root")"
    ROOT="$root"
}

# ------------------------------------------------------------
echo "== [state]: state 不在 → WARN / 総合 exit 0 =="
mk state_absent
install_gh_stub "$ROOT" 0 "10"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area state WARN "state.json 不在は [state] WARN"
assert_area cycle SKIP "state なしで [cycle] SKIP"
assert_area work-items SKIP "state なしで [work-items] SKIP"
assert_rc 0 "state 不在は総合 exit 0"

echo "== [state]: state 破損 → ERROR / 総合 exit 1 =="
mk state_broken
printf '%s' '{broken json' > "$ROOT/.aidlc/state.json"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area state ERROR "破損 state.json は [state] ERROR"
assert_rc 1 "state 破損は総合 exit 1"

echo "== [state]: 未知 schema_version → WARN / 総合 exit 0（stdout prefix 分岐） =="
mk state_unknown_schema
make_valid_state "$ROOT/.aidlc/state.json"
jq '.schema_version = "4.0"' "$ROOT/.aidlc/state.json" > "$ROOT/.aidlc/state.json.tmp"
mv "$ROOT/.aidlc/state.json.tmp" "$ROOT/.aidlc/state.json"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area state WARN "未知 schema_version は [state] WARN（rc0 + warn:* を OK 誤表示しない）"
assert_rc 0 "未知 schema_version は総合 exit 0"

# ------------------------------------------------------------
echo "== [work-items] 前提ゲート =="

echo "-- state なし → [work-items] SKIP / exit 0 --"
mk wi_no_state
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area work-items SKIP "state なしで [work-items] SKIP"
assert_rc 0 "state なしは総合 exit 0"

echo "-- cycle dir 不在 → [cycle] WARN / [work-items] SKIP / exit 0 --"
mk wi_no_cycle_dir
make_valid_state "$ROOT/.aidlc/state.json"   # current_cycle=v3.0.0 だが cycles dir なし
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area cycle WARN "cycle dir 不在は [cycle] WARN"
assert_rc 0 "cycle dir 不在は総合 exit 0"

echo "-- work-items dir 不在 → [work-items] WARN / exit 0 --"
mk wi_no_wi_dir
make_valid_state "$ROOT/.aidlc/state.json"
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0"        # cycle dir はあるが work-items dir なし
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area cycle OK "cycle dir ありで [cycle] OK"
assert_area work-items WARN "work-items dir 不在は [work-items] WARN"
assert_rc 0 "work-items dir 不在は総合 exit 0"

echo "-- work-items 0 件 → [work-items] WARN / exit 0（validator に渡さない） --"
mk wi_zero
make_valid_state "$ROOT/.aidlc/state.json"
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0/work-items"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area work-items WARN "0 件は [work-items] WARN（ERROR にしない）"
assert_rc 0 "0 件は総合 exit 0"

echo "-- work-items 1 件以上 + 正常 → [work-items] OK / exit 0 --"
mk wi_valid
make_valid_state "$ROOT/.aidlc/state.json"
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0/work-items"
make_valid_work_item "$ROOT/.aidlc/cycles/v3.0.0/work-items/001-foo.md" 001
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area work-items OK "正常 work item は [work-items] OK"
assert_rc 0 "正常 work item は総合 exit 0"

echo "-- work-items 不正 → [work-items] ERROR / exit 1 --"
mk wi_invalid
make_valid_state "$ROOT/.aidlc/state.json"
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0/work-items"
# 必須キー欠落（status なし）で validator rc1 を誘発。
cat > "$ROOT/.aidlc/cycles/v3.0.0/work-items/001-bad.md" <<'EOF'
---
id: 001
size: tiny
risk: low
assigned: null
dependencies: []
---

# bad

## Goal
g
## Scope
s
## Acceptance Criteria
a
## Traceability
t
## Size / Risk
sr
## Dependencies
d
EOF
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area work-items ERROR "不正 work item は [work-items] ERROR"
assert_rc 1 "不正 work item は総合 exit 1"

# ------------------------------------------------------------
echo "== [scripts]: 必須スクリプト不在 → ERROR / exit 1 =="
mk scripts_missing
git_init_clean "$ROOT"
# 必須集合のひとつを削除（state-init.sh）。
rm -f "$ROOT/skills/aidlc-v3/scripts/state-init.sh"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area scripts ERROR "必須スクリプト欠落は [scripts] ERROR"
assert_rc 1 "必須スクリプト欠落は総合 exit 1"

echo "== [scripts]: 全存在 → OK =="
mk scripts_ok
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area scripts OK "全必須スクリプト存在は [scripts] OK"

# ------------------------------------------------------------
echo "== [git]: dirty → WARN / clean → OK =="
mk git_clean
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area git OK "clean worktree は [git] OK"

mk git_dirty
git_init_clean "$ROOT"
echo "uncommitted" > "$ROOT/dirty.txt"   # 追跡外の新規ファイル → porcelain 非空
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area git WARN "dirty worktree は [git] WARN"
assert_rc 0 "git dirty のみは総合 exit 0"

# ------------------------------------------------------------
echo "== [gh]: 未認証 → [gh] WARN + [pr] SKIP + 他継続（exit 非 0 にしない） =="
mk gh_unauth
install_gh_stub "$ROOT" 1 ""   # auth status rc1（未認証）
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area gh WARN "未認証は [gh] WARN"
assert_area pr SKIP "未認証で [pr] SKIP"
assert_rc 0 "gh 未認証は総合 exit に影響しない（exit 0）"

echo "== [gh]/[pr]: 認証 + open PR あり → [pr] OK / 0 件 → [pr] OK =="
mk gh_pr_present
install_gh_stub "$ROOT" 0 "42"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area gh OK "認証済みは [gh] OK"
assert_area pr OK "open PR ありは [pr] OK"

mk gh_pr_absent
install_gh_stub "$ROOT" 0 ""
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area pr OK "open PR 0 件も [pr] OK（未作成）"

# ------------------------------------------------------------
echo "== [parse-guard]: 違反 → ERROR / exit 1 / なし → OK =="
mk pg_violation
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_PARSEGUARD_RC=1
assert_area parse-guard ERROR "parse-guard rc1 は [parse-guard] ERROR"
assert_rc 1 "parse-guard 違反は総合 exit 1"

mk pg_ok
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_PARSEGUARD_RC=0
assert_area parse-guard OK "parse-guard rc0 は [parse-guard] OK"

echo "-- parse-guard スクリプト不在 → SKIP（opt-in シグナル / 総合 exit 0） --"
mk pg_absent
git_init_clean "$ROOT"
rm -f "$ROOT/bin/check-frontmatter-parse-guard.sh"   # consumer プロジェクト想定（スクリプト不在）
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area parse-guard SKIP "parse-guard 不在は [parse-guard] SKIP（opt-in シグナル）"
assert_rc 0 "parse-guard 不在は総合 exit 0（diagnostic 対象外）"

# ------------------------------------------------------------
echo "== [config]: 不在 → ERROR/exit1 / 確定キー不在 → WARN/exit0 / 取得成功 → OK/exit0 =="
mk config_absent
git_init_clean "$ROOT"
rm -f "$ROOT/.aidlc/config.toml" 2>/dev/null || true   # config.toml を確実に不在へ
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area config ERROR "config.toml 不在は [config] ERROR"
assert_rc 1 "config.toml 不在は総合 exit 1"

mk config_key_absent
git_init_clean "$ROOT"
echo "# config" > "$ROOT/.aidlc/config.toml"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_READCONFIG_RC=1
assert_area config WARN "確定キー不在は [config] WARN"
assert_rc 0 "確定キー不在は総合 exit 0"

mk config_ok
git_init_clean "$ROOT"
echo "# config" > "$ROOT/.aidlc/config.toml"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_READCONFIG_RC=0
assert_area config OK "取得成功は [config] OK"
assert_rc 0 "取得成功は総合 exit 0"

echo "== [config]: dasel 不在（config あり + rc2）→ 診断不能 / exit 2 =="
mk config_dasel_missing
git_init_clean "$ROOT"
echo "# config" > "$ROOT/.aidlc/config.toml"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_READCONFIG_RC=2
assert_area config ERROR "config あり + rc2（dasel 不在）は [config] ERROR"
assert_rc 2 "dasel 不在（依存不足）は総合 exit 2"

# ------------------------------------------------------------
echo "== 全領域 OK 正常系 → exit 0 =="
mk all_ok
make_valid_state "$ROOT/.aidlc/state.json"
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0/work-items"
make_valid_work_item "$ROOT/.aidlc/cycles/v3.0.0/work-items/001-foo.md" 001
install_gh_stub "$ROOT" 0 "7"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_READCONFIG_RC=0 DOCTOR_TEST_PARSEGUARD_RC=0
assert_area config OK "正常系 [config] OK"
assert_area state OK "正常系 [state] OK"
assert_area cycle OK "正常系 [cycle] OK"
assert_area work-items OK "正常系 [work-items] OK"
assert_area git OK "正常系 [git] OK"
assert_area gh OK "正常系 [gh] OK"
assert_area pr OK "正常系 [pr] OK"
assert_area scripts OK "正常系 [scripts] OK"
assert_area parse-guard OK "正常系 [parse-guard] OK"
assert_rc 0 "全領域 OK は総合 exit 0"

# ------------------------------------------------------------
echo "== 総合 exit 優先順位: 2 > 1（診断不能が ERROR を上書き）=="
mk precedence
make_valid_state "$ROOT/.aidlc/state.json"   # state 正常
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0/work-items"
echo "# config" > "$ROOT/.aidlc/config.toml"
git_init_clean "$ROOT"
# parse-guard 違反（ERROR / exit1 候補）+ config rc2（診断不能 / exit2）→ 総合 exit2 が優先。
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_READCONFIG_RC=2 DOCTOR_TEST_PARSEGUARD_RC=1
assert_area config ERROR "[config] ERROR（rc2 診断不能）"
assert_area parse-guard ERROR "[parse-guard] ERROR（rc1 違反）"
assert_rc 2 "診断不能(2)は ERROR(1)より優先される"

echo "== 前提: jq 不在 → exit 2（診断不能） =="
mk jq_missing
git_init_clean "$ROOT"
# PATH を空にして jq を見えなくする（doctor 先頭の command -v jq を失敗させる）。
rc=0
(cd "$ROOT" && env PATH="" "$BASH_BIN" "$DOCTOR") >/dev/null 2>&1 || rc=$?
if [[ "$rc" -eq 2 ]]; then
    pass "jq 不在は exit 2（診断不能）"
else
    fail "jq 不在は exit 2（診断不能）（got rc=${rc}）"
fi

# ------------------------------------------------------------
echo "== exit 2 系（診断不能）の追加契約 + gh 不在分岐 =="

echo "-- [work-items] validator rc2 → 診断不能 / exit 2 --"
mk wi_validator_rc2
make_valid_state "$ROOT/.aidlc/state.json"
mkdir -p "$ROOT/.aidlc/cycles/v3.0.0/work-items"
make_valid_work_item "$ROOT/.aidlc/cycles/v3.0.0/work-items/001-foo.md" 001
git_init_clean "$ROOT"
# work-item-validate.sh を rc2（システムエラー相当）を返す stub に差し替える。
cat > "$ROOT/skills/aidlc-v3/scripts/work-item-validate.sh" <<'STUB'
#!/usr/bin/env bash
exit 2
STUB
chmod +x "$ROOT/skills/aidlc-v3/scripts/work-item-validate.sh"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area work-items ERROR "validator rc2 は [work-items] ERROR（診断不能）"
assert_rc 2 "work-items validator rc2 は総合 exit 2"

echo "-- [parse-guard] rc2 → 診断不能 / exit 2 --"
mk pg_rc2
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH" DOCTOR_TEST_PARSEGUARD_RC=2
assert_area parse-guard ERROR "parse-guard rc2 は [parse-guard] ERROR（診断不能）"
assert_rc 2 "parse-guard rc2 は総合 exit 2"

echo "-- git repo 外 → 診断不能 / exit 2 --"
mk git_outside
# あえて git_init_clean を呼ばない（fixture は git repo ではない）。
# WORK_ROOT が誤って git repo 配下のときのみ skip（誤検出回避）。
if (cd "$ROOT" && git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    echo "  skip : fixture が git repo 配下のため git repo 外テストを skip"
else
    run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
    assert_area git ERROR "git repo 外は [git] ERROR（診断不能）"
    assert_rc 2 "git repo 外は総合 exit 2"
fi

echo "-- gh 不在（PATH に gh なし）→ [gh] WARN + [pr] SKIP + exit 0 --"
mk gh_absent
# state.json を置かず最小構成にして wrapped validator を呼ばない（最小 PATH の影響範囲を限定）。
nogh_bin="$(make_min_path_without_gh "$ROOT")"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$nogh_bin"
assert_area gh WARN "gh 不在は [gh] WARN（command -v gh 不在分岐）"
assert_area pr SKIP "gh 不在で [pr] SKIP"
assert_rc 0 "gh 不在は総合 exit に影響しない（exit 0）"

echo "-- current_cycle が不正識別子（パストラバーサル）→ [cycle] WARN / [work-items] SKIP / exit 0 --"
mk cycle_traversal
make_valid_state "$ROOT/.aidlc/state.json"
# current_cycle に `..` を含む値を注入（state-validate は string としか検証しない）。
jq '.current_cycle = "../../etc"' "$ROOT/.aidlc/state.json" > "$ROOT/.aidlc/state.json.tmp"
mv "$ROOT/.aidlc/state.json.tmp" "$ROOT/.aidlc/state.json"
git_init_clean "$ROOT"
run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
assert_area cycle WARN "不正な current_cycle は [cycle] WARN（パス安全検証）"
assert_area work-items SKIP "不正 cycle で [work-items] SKIP"
assert_rc 0 "不正 cycle は総合 exit 0（診断は継続）"

echo "-- current_cycle が単独 '.' / 'foo/bar' → [cycle] WARN（コンテナ/サブパス参照を拒否） --"
badc_idx=0
for badc in "." "foo/bar"; do
    badc_idx=$((badc_idx + 1))
    mk "cycle_bad_${badc_idx}"
    make_valid_state "$ROOT/.aidlc/state.json"
    jq --arg c "$badc" '.current_cycle = $c' "$ROOT/.aidlc/state.json" > "$ROOT/.aidlc/state.json.tmp"
    mv "$ROOT/.aidlc/state.json.tmp" "$ROOT/.aidlc/state.json"
    git_init_clean "$ROOT"
    run_doctor "$DOCTOR" "$ROOT" PATH="$ROOT/bin:$PATH"
    assert_area cycle WARN "current_cycle='$badc' は [cycle] WARN（不正識別子）"
    assert_rc 0 "current_cycle='$badc' は総合 exit 0"
done

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
