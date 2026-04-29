#!/usr/bin/env bats
# Unit 004: 観点 K - 契約スキーマ参照検証（単一ソース）

load helpers/setup

@test "K1: retrospective-schema.yml が存在し、6 キー / 禁止語 4 種 / quote_min_length=10 / valid_feedback_modes 3 値が dasel で読み出せる" {
  [ -f "${SCHEMA_PATH}" ]
  if ! command -v dasel >/dev/null 2>&1; then
    skip "dasel not installed"
  fi

  # 6 キー
  run bash -c "dasel query -i yaml 'retrospective_schema.skill_caused_judgment.keys' < '${SCHEMA_PATH}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"q1_answer"* ]]
  [[ "$output" == *"q1_quote"* ]]
  [[ "$output" == *"q2_answer"* ]]
  [[ "$output" == *"q2_quote"* ]]
  [[ "$output" == *"q3_answer"* ]]
  [[ "$output" == *"q3_quote"* ]]

  # 禁止語 4 種
  run bash -c "dasel query -i yaml 'retrospective_schema.skill_caused_judgment.quote_forbidden_words' < '${SCHEMA_PATH}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"該当"* ]]
  [[ "$output" == *"あり"* ]]
  [[ "$output" == *"該当箇所"* ]]
  [[ "$output" == *"あります"* ]]

  # quote_min_length
  run bash -c "dasel query -i yaml 'retrospective_schema.skill_caused_judgment.quote_min_length' < '${SCHEMA_PATH}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"10"* ]]

  # valid_feedback_modes
  run bash -c "dasel query -i yaml 'retrospective_schema.valid_feedback_modes' < '${SCHEMA_PATH}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"silent"* ]]
  [[ "$output" == *"mirror"* ]]
  [[ "$output" == *"disabled"* ]]
}

@test "K2: テンプレートのコメント内質問文がスキーマの questions と一字一句一致する" {
  if ! command -v dasel >/dev/null 2>&1; then
    skip "dasel not installed"
  fi
  local q1 q2 q3
  q1="$(dasel query -i yaml 'retrospective_schema.skill_caused_judgment.questions.q1' < "${SCHEMA_PATH}" | sed 's/^"//; s/"$//')"
  q2="$(dasel query -i yaml 'retrospective_schema.skill_caused_judgment.questions.q2' < "${SCHEMA_PATH}" | sed 's/^"//; s/"$//')"
  q3="$(dasel query -i yaml 'retrospective_schema.skill_caused_judgment.questions.q3' < "${SCHEMA_PATH}" | sed 's/^"//; s/"$//')"

  grep -F "$q1" "${TEMPLATE_PATH}"
  grep -F "$q2" "${TEMPLATE_PATH}"
  grep -F "$q3" "${TEMPLATE_PATH}"
}
