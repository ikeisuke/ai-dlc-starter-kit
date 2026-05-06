#!/usr/bin/env bats
# Unit 003: retrospective_update_hook() 単体テスト
# Plan / Logical Design §「retrospective_update_hook」を verify する。
#
# gh コマンドはモック shim で挙動制御:
#   GH_MOCK_BODY                     - gh issue view が返す本文
#   GH_MOCK_COMMENT_FAIL=1            - gh issue comment を失敗させる
#   GH_MOCK_EDIT_FAIL=1               - gh issue edit --body-file を失敗させる
#   GH_MOCK_LABEL_FAIL=1              - gh issue edit --add-label を失敗させる
#   GH_MOCK_VIEW_FAIL=1               - gh issue view を失敗させる
#   GH_MOCK_LOG=<path>                - 呼出ログ出力先

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  HOOK_LIB="${REPO_ROOT}/skills/aidlc/scripts/lib/retrospective-human-review.sh"
  TMP="$(mktemp -d -t aidlc-retro-hr.XXXXXX)"
  SHIM_DIR="$TMP/shim"
  mkdir -p "$SHIM_DIR"
  GH_MOCK_LOG="$TMP/gh-calls.log"
  : > "$GH_MOCK_LOG"

  # gh shim
  cat > "$SHIM_DIR/gh" <<'SHIM'
#!/usr/bin/env bash
echo "$@" >> "${GH_MOCK_LOG:-/dev/null}"
case "$1" in
  issue)
    sub="$2"
    shift 2
    case "$sub" in
      view)
        if [[ "${GH_MOCK_VIEW_FAIL:-}" == "1" ]]; then
          echo "mock view failed" >&2
          exit 1
        fi
        # --json body --jq '.body' が要求された前提で本文を返す
        printf '%s\n' "${GH_MOCK_BODY:-}"
        exit 0
        ;;
      comment)
        if [[ "${GH_MOCK_COMMENT_FAIL:-}" == "1" ]]; then
          echo "mock comment failed" >&2
          exit 1
        fi
        exit 0
        ;;
      edit)
        # --add-label を含むかどうかで判定
        for arg in "$@"; do
          if [[ "$arg" == "--add-label" ]]; then
            if [[ "${GH_MOCK_LABEL_FAIL:-}" == "1" ]]; then
              exit 1
            fi
            exit 0
          fi
          if [[ "$arg" == "--body-file" ]]; then
            if [[ "${GH_MOCK_EDIT_FAIL:-}" == "1" ]]; then
              exit 1
            fi
            exit 0
          fi
        done
        exit 0
        ;;
    esac
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"
  PATH="$SHIM_DIR:$PATH"
  export GH_MOCK_LOG

  # 多重 source ガードの reset
  unset __AIDLC_RETROSPECTIVE_HUMAN_REVIEW_SH_LOADED

  unset AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH
}

teardown() {
  cd "$BATS_TMPDIR"
  rm -rf "$TMP"
}

# ─── 本文サンプル ─────
# 注: human_reviewed marker は末尾 ```yaml ... ``` フェンス内のキーのみを正解とする
# （codex review P2 / Unit 003 領域）。本文上部の Markdown 展開やコードブロック例示は
# 誤検出されない設計のため、フィクスチャも末尾フェンス込みの形式で生成する。
make_body_with_false_marker() {
  cat <<'EOF'
# Retrospective: v2.5.1

## Problem 1

skill_caused_judgment:
  q1_answer: "yes"

mirror_state:
  state: "created"

```yaml
human_reviewed: false
```
EOF
}

make_body_with_true_marker() {
  cat <<'EOF'
# Retrospective: v2.5.1

skill_caused_judgment:
  q1_answer: "yes"

mirror_state:
  state: "created"

```yaml
human_reviewed: true
```
EOF
}

# ─── H1: 差分なし → 本文 marker のみ更新 ─────
@test "H1: FINAL_PATH 未設定 / 既存 false → gh issue edit のみ呼ばれる" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  export GH_MOCK_BODY

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]

  # gh issue comment は呼ばれていない
  ! grep -qE '^issue comment ' "$GH_MOCK_LOG"
  # gh issue edit --body-file は呼ばれている
  grep -qE 'issue edit .* --body-file' "$GH_MOCK_LOG"
}

# ─── H2: 差分あり → comment → edit --body-file → edit --add-label ─────
@test "H2: FINAL_PATH 設定 + 差分あり → comment / edit / add-label の順" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  export GH_MOCK_BODY

  local final_path="$TMP/final.yaml"
  cat > "$final_path" <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: "product"
EOF
  AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH="$final_path"

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]

  # 順序検証: comment < edit --body-file < edit --add-label
  local comment_line
  local body_edit_line
  local label_line
  comment_line=$(grep -nE '^issue comment ' "$GH_MOCK_LOG" | head -1 | cut -d: -f1)
  body_edit_line=$(grep -nE 'issue edit .* --body-file' "$GH_MOCK_LOG" | head -1 | cut -d: -f1)
  label_line=$(grep -nE 'issue edit .* --add-label' "$GH_MOCK_LOG" | head -1 | cut -d: -f1)
  [ -n "$comment_line" ]
  [ -n "$body_edit_line" ]
  [ -n "$label_line" ]
  [ "$comment_line" -lt "$body_edit_line" ]
  [ "$body_edit_line" -lt "$label_line" ]
}

# ─── H3: コメント追記失敗時は本文 update / ラベルをスキップ ─────
@test "H3: gh issue comment 失敗時は edit --body-file / add-label 呼ばれない" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  GH_MOCK_COMMENT_FAIL=1
  export GH_MOCK_BODY GH_MOCK_COMMENT_FAIL

  local final_path="$TMP/final.yaml"
  echo "data" > "$final_path"
  AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH="$final_path"

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]

  # gh issue edit --body-file が呼ばれていない
  ! grep -qE 'issue edit .* --body-file' "$GH_MOCK_LOG"
  # gh issue edit --add-label も呼ばれていない
  ! grep -qE 'issue edit .* --add-label' "$GH_MOCK_LOG"
}

# ─── H4: 本文 update 失敗時はラベル付与をスキップ ─────
@test "H4: gh issue edit --body-file 失敗時は --add-label 呼ばれない" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  GH_MOCK_EDIT_FAIL=1
  export GH_MOCK_BODY GH_MOCK_EDIT_FAIL

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]

  # gh issue edit --add-label が呼ばれていない
  ! grep -qE 'issue edit .* --add-label' "$GH_MOCK_LOG"
}

# ─── H5: ラベル付与失敗は warn のみで継続 ─────
@test "H5: gh issue edit --add-label 失敗で warn のみ exit 0" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  GH_MOCK_LABEL_FAIL=1
  export GH_MOCK_BODY GH_MOCK_LABEL_FAIL

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]
}

# ─── H6: 既に true の冪等 skip ─────
@test "H6: 既存 human_reviewed: true で全 gh 呼び出しなし / exit 0" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_true_marker)"
  export GH_MOCK_BODY

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]

  # comment / edit --body-file / edit --add-label のいずれも呼ばれていない
  ! grep -qE 'issue comment ' "$GH_MOCK_LOG"
  ! grep -qE 'issue edit .* --body-file' "$GH_MOCK_LOG"
  ! grep -qE 'issue edit .* --add-label' "$GH_MOCK_LOG"
}

# ─── H7: issue_url == "" は no-op skip ─────
@test "H7: issue_url 空文字列で no-op skip / exit 0" {
  source "$HOOK_LIB"

  run retrospective_update_hook "" "v2.5.1"
  [ "$status" -eq 0 ]

  # gh コマンドは呼ばれていない
  [ ! -s "$GH_MOCK_LOG" ]
}

# ─── H8: issue_url 形式不正は exit 2 ─────
@test "H8: issue_url が ftp:// で exit 2" {
  source "$HOOK_LIB"

  run retrospective_update_hook "ftp://invalid/issues/123" "v2.5.1"
  [ "$status" -eq 2 ]
}

@test "H8b: issue_url が gitlab.com で exit 2（GitHub 限定）" {
  source "$HOOK_LIB"

  run retrospective_update_hook "https://gitlab.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 2 ]
}

# ─── H9: 引数欠落は exit 2 ─────
@test "H9: 引数 < 2 で exit 2" {
  source "$HOOK_LIB"

  run retrospective_update_hook "https://github.com/owner/repo/issues/123"
  [ "$status" -eq 2 ]
}

@test "H9b: 引数 0 個で exit 2" {
  source "$HOOK_LIB"

  run retrospective_update_hook
  [ "$status" -eq 2 ]
}

# ─── H10: FINAL_PATH の I/O エラーは exit 1 ─────
@test "H10: FINAL_PATH 指定 / ファイル不在で exit 1" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  export GH_MOCK_BODY

  AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH="$TMP/nonexistent.yaml"

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 1 ]
}

# ─── H11: 順序固定（comment が edit --body-file より前 / 既に H2 で確認済 / 別ケース）─────
@test "H11: 差分なしでもコメント追記なしで本文 update のみ実行" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  export GH_MOCK_BODY

  # FINAL_PATH 未設定 = 差分なし
  unset AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]

  # comment は呼ばれない
  ! grep -qE '^issue comment ' "$GH_MOCK_LOG"
  # edit --body-file は呼ばれる
  grep -qE 'issue edit .* --body-file' "$GH_MOCK_LOG"
}

# ─── H12: [llm-diff] コメント本文に final_path の内容が含まれる + 本文は human_reviewed のみ更新 ─────
@test "H12: FINAL_PATH 設定 + 差分あり → コメントに final_text が記録 / 本文は human_reviewed のみ更新" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  export GH_MOCK_BODY

  local final_path="$TMP/final.yaml"
  cat > "$final_path" <<'EOF'
problem_drafts:
  - problem_id: 1
    primary_cause: "product"
    primary_cause_reason: "仕様起因"
EOF
  AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH="$final_path"

  # comment 本文 / edit body の中身を別ログに保存する shim
  local comment_log="$TMP/comment-content.log"
  local body_log="$TMP/edit-body-content.log"
  cat > "$SHIM_DIR/gh" <<SHIM
#!/usr/bin/env bash
echo "\$@" >> "${GH_MOCK_LOG:-/dev/null}"
case "\$1" in
  issue)
    sub="\$2"
    shift 2
    case "\$sub" in
      view)
        printf '%s\n' "\${GH_MOCK_BODY:-}"
        exit 0
        ;;
      comment)
        # --body-file - で stdin から読む想定
        cat > "$comment_log"
        exit 0
        ;;
      edit)
        for ((i=1; i<=\$#; i++)); do
          if [[ "\${!i}" == "--body-file" ]]; then
            j=\$((i+1))
            if [[ -f "\${!j}" ]]; then
              cat "\${!j}" > "$body_log"
            fi
            break
          fi
        done
        exit 0
        ;;
    esac
    ;;
esac
exit 0
SHIM
  chmod +x "$SHIM_DIR/gh"

  run retrospective_update_hook "https://github.com/owner/repo/issues/123" "v2.5.1"
  [ "$status" -eq 0 ]
  [ -f "$comment_log" ]
  [ -f "$body_log" ]

  # コメント本文に final_path の内容（primary_cause: "product"）が含まれる
  grep -qE 'primary_cause:[[:space:]]*"product"' "$comment_log"
  # コメント本文に [llm-diff] マーカーが含まれる
  grep -qE '\[llm-diff\]' "$comment_log"
  # 本文 update では human_reviewed: true に更新されている
  grep -qE '^human_reviewed:[[:space:]]*true' "$body_log"

  # 差分が human_reviewed 行のみであることを assert（marker 更新以外は不変）
  local before_path="$TMP/before-body.txt"
  local after_path="$TMP/after-body.txt"
  printf '%s\n' "$GH_MOCK_BODY" > "$before_path"
  cp "$body_log" "$after_path"
  # diff が出る行は human_reviewed のみ（< false 行 / > true 行の 2 行）
  local diff_lines
  diff_lines=$(diff "$before_path" "$after_path" | grep -cE '^[<>] human_reviewed:' || true)
  # < human_reviewed: false / > human_reviewed: true の 2 行
  [ "$diff_lines" -eq 2 ]
  # mirror_state 行は不変
  grep -qE '^mirror_state:' "$after_path"
  grep -qE 'state: "created"' "$after_path"
}

# ─── H13: __retro_hr_has_diff の規約検証（FINAL_PATH 未設定 → 差分なし）─────
@test "H13: __retro_hr_has_diff 戻り値: FINAL_PATH 未設定で 1 / 設定+空で 1 / 設定+非空で 0" {
  source "$HOOK_LIB"

  local rc

  # 未設定 → 差分なし（return 1）
  rc=0
  __retro_hr_has_diff "" || rc=$?
  [ "$rc" -eq 1 ]

  # 不在 → 差分なし（return 1）
  rc=0
  __retro_hr_has_diff "$TMP/nonexistent.yaml" || rc=$?
  [ "$rc" -eq 1 ]

  # 空ファイル → 差分なし（return 1）
  : > "$TMP/empty.yaml"
  rc=0
  __retro_hr_has_diff "$TMP/empty.yaml" || rc=$?
  [ "$rc" -eq 1 ]

  # 非空ファイル → 差分あり（return 0）
  echo "data" > "$TMP/data.yaml"
  rc=99
  __retro_hr_has_diff "$TMP/data.yaml" && rc=0 || rc=$?
  [ "$rc" -eq 0 ]
}

# ─── H14: __retro_hr_owner_repo: GitHub Issue URL から owner/repo 抽出 ─────
@test "H14: __retro_hr_owner_repo は URL から owner/repo を返す" {
  source "$HOOK_LIB"

  run __retro_hr_owner_repo "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/100"
  [ "$status" -eq 0 ]
  [ "$output" = "ikeisuke/ai-dlc-starter-kit" ]

  # 末尾スラッシュあり
  run __retro_hr_owner_repo "https://github.com/owner/repo/issues/123/"
  [ "$status" -eq 0 ]
  [ "$output" = "owner/repo" ]
}

# ─── H15: gh コマンドに --repo が必ず付与される（codex review P1 / Unit 003 領域）─────
@test "H15: gh issue view/edit/comment に --repo が必ず付く（mirror リポ対応）" {
  source "$HOOK_LIB"

  GH_MOCK_BODY="$(make_body_with_false_marker)"
  : > "$TMP/final.yaml"
  echo "problem_drafts: []" > "$TMP/final.yaml"
  AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH="$TMP/final.yaml"
  export GH_MOCK_BODY AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH

  run retrospective_update_hook "https://github.com/ikeisuke/ai-dlc-starter-kit/issues/200" "v2.5.1"
  [ "$status" -eq 0 ]

  # view / comment / edit いずれも --repo ikeisuke/ai-dlc-starter-kit を持つ
  grep -qE 'issue view 200 --repo ikeisuke/ai-dlc-starter-kit' "$GH_MOCK_LOG"
  grep -qE 'issue comment 200 --repo ikeisuke/ai-dlc-starter-kit' "$GH_MOCK_LOG"
  grep -qE 'issue edit 200 --repo ikeisuke/ai-dlc-starter-kit --body-file' "$GH_MOCK_LOG"
  grep -qE 'issue edit 200 --repo ikeisuke/ai-dlc-starter-kit --add-label' "$GH_MOCK_LOG"
}

# ─── H16: 末尾 YAML フェンス内のみで human_reviewed を判定（codex review P2 / Unit 003 領域）─────
@test "H16: 本文上部の human_reviewed: true 例示は誤検出されず、末尾フェンス内 false が正解" {
  source "$HOOK_LIB"

  # 本文上部にコードブロック例示で human_reviewed: true を含むが、末尾フェンス内は false
  GH_MOCK_BODY="$(cat <<'EOF'
# Retrospective: v2.5.1

## レビュー手順

確認後、末尾の human_reviewed を以下のように更新してください:

```yaml
human_reviewed: true
```

## Problem 一覧

skill_caused_judgment:
  q1_answer: "yes"

```yaml
human_reviewed: false
```
EOF
)"
  export GH_MOCK_BODY

  run retrospective_update_hook "https://github.com/owner/repo/issues/300" "v2.5.1"
  [ "$status" -eq 0 ]

  # 末尾 YAML フェンス内が false なので、edit が呼ばれる（H6 のように skip されない）
  grep -qE 'issue edit 300 --repo owner/repo --body-file' "$GH_MOCK_LOG"
}
