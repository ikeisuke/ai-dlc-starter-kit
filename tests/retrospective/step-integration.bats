#!/usr/bin/env bats
# Unit 004: 観点 IS - 04-completion.md 静的検証

load helpers/setup

@test "IS1: ## 3.5. retrospective 作成 セクションが存在" {
  grep -F "### 3.5. retrospective 作成" "${STEP_FILE_PATH}"
}

@test "IS2: 安定 ID コメントアンカー guidance:id=unit004-retrospective-creation が ## 3.5 直前行に配置" {
  awk '
  /<!-- guidance:id=unit004-retrospective-creation -->/ {anchor_line=NR}
  /^### 3\.5\. retrospective 作成/ {section_line=NR}
  END {
    if (anchor_line > 0 && section_line > 0 && section_line - anchor_line <= 2) {
      exit 0
    } else {
      print "anchor_line=" anchor_line " section_line=" section_line
      exit 1
    }
  }
  ' "${STEP_FILE_PATH}"
}

@test "IS3: cycle-version-check.sh の呼び出し記述がある" {
  grep -F "cycle-version-check.sh" "${STEP_FILE_PATH}"
}

@test "IS4: retrospective-generate.sh の呼び出し記述がある" {
  grep -F "retrospective-generate.sh" "${STEP_FILE_PATH}"
}

@test "IS5: retrospective-validate.sh validate ... --apply の呼び出し記述がある" {
  grep -F "retrospective-validate.sh" "${STEP_FILE_PATH}"
  grep -F -- "--apply" "${STEP_FILE_PATH}"
}

@test "IS6: Unit 005 への引き継ぎ言及がある" {
  grep -F "Unit 005" "${STEP_FILE_PATH}"
}

@test "IS7: 既存セクション番号 4. 5. 5.5 6. 7. 8. が保持されている" {
  grep -F "### 4. 次期サイクルの計画" "${STEP_FILE_PATH}"
  grep -F "### 5. PRマージ後の手順" "${STEP_FILE_PATH}"
  grep -F "### 5.5 Milestone close" "${STEP_FILE_PATH}"
  grep -F "### 6. 完了サマリ出力" "${STEP_FILE_PATH}"
  grep -F "### 7. 次のサイクル開始" "${STEP_FILE_PATH}"
  grep -F "### 8. ライフサイクルの継続" "${STEP_FILE_PATH}"
}
