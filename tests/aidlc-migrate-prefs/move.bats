#!/usr/bin/env bats
# Unit 003: 観点 B - move サブコマンド (6 ケース)
# B1: project から削除
# B2: user-global に追記
# B3: 配列値の完全置換
# B4: user-global ファイル不在時の新規作成
# B5: --overwrite 未指定で既存キー → warn + skip
# B6: --overwrite 指定で既存キー → 上書き

load helpers/setup

teardown() { teardown_env; }

@test "B1: move rules.reviewing.mode → project から該当キー行が削除される" {
  setup_env "p-all7-keys" "u-empty"
  run run_move "rules.reviewing.mode"
  [ "$status" -eq 0 ]
  # 出力確認
  echo "$output" | grep -F -- $'move\trules.reviewing.mode\trequired\tfrom_project\tto_user_global'
  # project から削除されている
  run assert_key_absent_in_project "rules.reviewing.mode"
  [ "$status" -eq 0 ]
}

@test "B2: move rules.reviewing.mode → user-global に追記される" {
  setup_env "p-all7-keys" "u-empty"
  run run_move "rules.reviewing.mode"
  [ "$status" -eq 0 ]
  # user-global に追記
  run assert_key_present_in_user_global "rules.reviewing.mode" '"required"'
  [ "$status" -eq 0 ]
}

@test "B3: move rules.reviewing.tools (配列値) → user-global に同形式で書き出される" {
  setup_env "p-all7-keys" "u-empty"
  run run_move "rules.reviewing.tools"
  [ "$status" -eq 0 ]
  # user-global の値を読み出し（dasel が解釈可能な形式）
  run bash -c "source skills/aidlc/scripts/lib/toml-reader.sh && aidlc_read_toml '$AIDLC_USER_GLOBAL_PATH' rules.reviewing.tools"
  [ "$status" -eq 0 ]
  # dasel 出力で claude が含まれる
  [[ "$output" == *"claude"* ]]
}

@test "B4: user-global ファイル不在 → move 実行で最小ヘッダ付き新規作成 + キー追記" {
  setup_env "p-all7-keys" "none"
  [ ! -f "${AIDLC_USER_GLOBAL_PATH}" ]
  run run_move "rules.linting.enabled"
  [ "$status" -eq 0 ]
  # ファイル新規作成
  [ -f "${AIDLC_USER_GLOBAL_PATH}" ]
  # ヘッダコメント存在
  grep -F "AI-DLC user-global config" "${AIDLC_USER_GLOBAL_PATH}"
  # キー追記
  run assert_key_present_in_user_global "rules.linting.enabled" 'true'
  [ "$status" -eq 0 ]
}

@test "B5: user-global に rules.reviewing.mode 既存 + --overwrite 未指定 → warn + skip + project 不変" {
  setup_env "p-all7-keys" "u-with-key"
  local project_before
  project_before=$(snapshot_sha "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml")
  local ug_before
  ug_before=$(snapshot_sha "${AIDLC_USER_GLOBAL_PATH}")

  run bash skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh move rules.reviewing.mode
  [ "$status" -eq 0 ]
  # stderr に warn:user-global-key-exists が出る
  [[ "$output" == *"warn:user-global-key-exists:rules.reviewing.mode"* ]]

  # project / user-global いずれも変更なし
  run assert_unchanged "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" "$project_before"
  [ "$status" -eq 0 ]
  run assert_unchanged "${AIDLC_USER_GLOBAL_PATH}" "$ug_before"
  [ "$status" -eq 0 ]
}

# ─── セキュリティ: 不正値 reject ─────────

@test "B7: 不正な enum 値（rules.automation.mode = 'malicious_value'）→ error:invalid-value で reject + project 不変" {
  setup_env "p-all7-keys" "u-empty"
  # project の rules.automation.mode を不正値に書き換え
  sed -i.bak 's/^mode = "full_auto"$/mode = "malicious_value"/' "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  rm -f "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml.bak"
  local project_before
  project_before=$(snapshot_sha "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml")
  local ug_before
  ug_before=$(snapshot_sha "${AIDLC_USER_GLOBAL_PATH}")

  run bash skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh move rules.automation.mode
  [ "$status" -eq 2 ]
  [[ "$output" == *"error:invalid-value:rules.automation.mode:not-in-enum"* ]]

  # project / user-global いずれも変更なし
  run assert_unchanged "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" "$project_before"
  [ "$status" -eq 0 ]
  run assert_unchanged "${AIDLC_USER_GLOBAL_PATH}" "$ug_before"
  [ "$status" -eq 0 ]
}

@test "B8: 不正な boolean 値（rules.git.squash_enabled = 'yes'）→ error:invalid-value:expected-boolean で reject" {
  setup_env "p-all7-keys" "u-empty"
  sed -i.bak 's/^squash_enabled = true$/squash_enabled = "yes"/' "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  rm -f "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml.bak"

  run bash skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh move rules.git.squash_enabled
  [ "$status" -eq 2 ]
  [[ "$output" == *"error:invalid-value:rules.git.squash_enabled:expected-boolean"* ]]
}

@test "B9: 文字列値の TOML エスケープ（ai_author に \" を含む）→ user-global で適切にエスケープされる" {
  setup_env "p-all7-keys" "u-empty"
  # project の rules.git.ai_author を `Foo "Bar" <a@b>` に書き換え
  sed -i.bak 's|^ai_author = .*$|ai_author = "Foo \\"Bar\\" <a@b>"|' "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  rm -f "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml.bak"

  run run_move "rules.git.ai_author"
  [ "$status" -eq 0 ]
  # user-global の値が適切にエスケープされている (\" を含む)
  grep -F 'ai_author = "Foo \"Bar\" <a@b>"' "${AIDLC_USER_GLOBAL_PATH}"
}

@test "B10: タブ文字（0x09）混入の値 → error:invalid-value:control-char で reject + project 不変" {
  setup_env "p-all7-keys" "u-empty"
  # ai_author にタブを混入させる（ANSI-C quoting で \t を実タブに）
  python3 -c "
import re
p = '${AIDLC_PROJECT_ROOT}/.aidlc/config.toml'
with open(p) as f: data = f.read()
data = re.sub(r'^ai_author = .*\$', 'ai_author = \"Foo\\\\tBar\"', data, flags=re.MULTILINE)
with open(p, 'w') as f: f.write(data)
" 2>/dev/null || skip "python3 not available"
  local project_before
  project_before=$(snapshot_sha "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml")

  run bash skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh move rules.git.ai_author
  [ "$status" -eq 2 ]
  [[ "$output" == *"error:invalid-value:rules.git.ai_author:control-char"* ]]
  run assert_unchanged "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml" "$project_before"
  [ "$status" -eq 0 ]
}

@test "B11: トランザクション化 - project ファイル read-only による delete 失敗時、user-global がロールバックされる" {
  setup_env "p-all7-keys" "u-empty"
  # 事前に user-global にダミー記述（ロールバック対象を明示）
  echo "" >> "${AIDLC_USER_GLOBAL_PATH}"
  echo "# pre-existing baseline marker" >> "${AIDLC_USER_GLOBAL_PATH}"
  local ug_before
  ug_before=$(snapshot_sha "${AIDLC_USER_GLOBAL_PATH}")

  # project ファイルを read-only にして _safe_transform の `mv` を失敗させる
  chmod 444 "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
  # 親ディレクトリも read-only に（mv が動けば成功してしまうため、親を保護）
  chmod 555 "${AIDLC_PROJECT_ROOT}/.aidlc"

  run bash skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh move rules.reviewing.mode
  local rc=$status

  # 後始末: 権限を戻す
  chmod 755 "${AIDLC_PROJECT_ROOT}/.aidlc"
  chmod 644 "${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"

  # 失敗 + project-delete-failed エラー
  [ "$rc" -eq 2 ]
  [[ "$output" == *"error:project-delete-failed"* ]]
  # user-global がロールバックされている（事前 sha と一致）
  run assert_unchanged "${AIDLC_USER_GLOBAL_PATH}" "$ug_before"
  [ "$status" -eq 0 ]
}

@test "B6: user-global に rules.reviewing.mode 既存 + --overwrite 指定 → 上書き実行" {
  setup_env "p-all7-keys" "u-with-key"
  # u-with-key の既存値は "recommend"、project は "required"
  run run_move "rules.reviewing.mode" --overwrite
  [ "$status" -eq 0 ]
  # 出力確認
  echo "$output" | grep -F -- $'move\trules.reviewing.mode\trequired\tfrom_project\tto_user_global'
  # user-global の値が新値に置換されている
  run assert_key_present_in_user_global "rules.reviewing.mode" '"required"'
  [ "$status" -eq 0 ]
  # project から削除されている
  run assert_key_absent_in_project "rules.reviewing.mode"
  [ "$status" -eq 0 ]
}
