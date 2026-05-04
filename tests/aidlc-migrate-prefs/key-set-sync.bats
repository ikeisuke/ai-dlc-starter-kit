#!/usr/bin/env bats
# Unit 003: 観点 K - Unit 001 SoT との集合一致 (1 ケース)
# K1: migrate-relocate-prefs.sh 内ハードコード 7 キー = Unit 001 SoT の 7 キー（対称差 = 0）

load helpers/setup

# Unit 001 SoT は tests/config-defaults/helpers/setup.bash の b1_expected_for で定義された 7 キー集合
readonly UNIT001_KEYS=(
  "rules.reviewing.mode"
  "rules.reviewing.tools"
  "rules.automation.mode"
  "rules.git.squash_enabled"
  "rules.git.ai_author"
  "rules.git.ai_author_auto_detect"
  "rules.linting.enabled"
)

@test "K1: migrate-relocate-prefs.sh 内ハードコード 7 キー集合 = Unit 001 SoT 集合 (対称差 = 0)" {
  # script 内の INDIVIDUAL_PREFERENCE_KEYS 配列を抽出
  local script_keys
  script_keys=$(awk '
    /^readonly INDIVIDUAL_PREFERENCE_KEYS=\(/ { in_arr = 1; next }
    in_arr && /^\)/ { exit }
    in_arr {
      gsub(/[" ]/, "")
      if (length($0) > 0) print
    }
  ' "${SCRIPT_PATH}" | sort)

  # Unit 001 SoT 集合
  local sot_keys
  sot_keys=$(printf '%s\n' "${UNIT001_KEYS[@]}" | sort)

  # 対称差 = 0
  [ "$script_keys" = "$sot_keys" ]
}

@test "K1b: Unit 001 b1_expected_for / b2_expected_for と同一の 7 キー集合をカバーする (重複検証)" {
  # tests/config-defaults/helpers/setup.bash の b1_expected_for / b2_expected_for case 文から抽出
  # 両関数で同じ 7 キーが case 分岐を持つことを確認 (重複は uniq で除去)
  local b_keys
  b_keys=$(grep -oE '"rules\.[a-z._]+"\)' "${REPO_ROOT}/tests/config-defaults/helpers/setup.bash" \
    | sed -E 's/^"|"\)$//g' | sort -u)

  local sot_keys
  sot_keys=$(printf '%s\n' "${UNIT001_KEYS[@]}" | sort -u)

  [ "$b_keys" = "$sot_keys" ]
}
