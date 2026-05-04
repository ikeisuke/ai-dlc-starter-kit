#!/usr/bin/env bats
# Unit 004 + Unit 007: 観点 IS - 04-completion.md 静的検証

load helpers/setup

@test "IS1: §1.5 自動生成フロー セクションが存在（Unit 007 で §3.5 → §1.5 に再配置）" {
  grep -F "#### 1.5 自動生成フロー" "${STEP_FILE_PATH}"
}

@test "IS2: 安定 ID コメントアンカー guidance:id=unit004-retrospective-creation が #### 1.5 直前行に配置" {
  awk '
  /<!-- guidance:id=unit004-retrospective-creation -->/ {anchor_line=NR}
  /^#### 1\.5 自動生成フロー/ {section_line=NR}
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

@test "IS3: cycle-version-check ガードが撤廃されている（Issue #625 fix）" {
  ! grep -F "cycle-version-check.sh" "${STEP_FILE_PATH}"
  ! grep -F "starter-kit-version-check.sh" "${STEP_FILE_PATH}"
  # 撤廃理由が文書化されている
  grep -F "Issue #625 fix" "${STEP_FILE_PATH}"
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

@test "IS7: 既存セクション番号 §2-§7 が保持されている（Unit 007 で §3-§8 → §2-§7 に繰り上げ）" {
  grep -F "### 2. バックログ記録" "${STEP_FILE_PATH}"
  grep -F "### 3. 次期サイクルの計画" "${STEP_FILE_PATH}"
  grep -F "### 4. PRマージ後の手順" "${STEP_FILE_PATH}"
  grep -F "### 4.5 Milestone close" "${STEP_FILE_PATH}"
  grep -F "### 5. 完了サマリ出力" "${STEP_FILE_PATH}"
  grep -F "### 6. 次のサイクル開始" "${STEP_FILE_PATH}"
  grep -F "### 7. ライフサイクルの継続" "${STEP_FILE_PATH}"
}

@test "IS8: Unit 007 で導入された KPT + 主因切り分け + 3 分岐ガイドが §1 に存在" {
  grep -F "### 1. 振り返り（retrospective）" "${STEP_FILE_PATH}"
  grep -F "#### 1.1 KPT テンプレ" "${STEP_FILE_PATH}"
  grep -F "#### 1.2 主因切り分け" "${STEP_FILE_PATH}"
  grep -F "#### 1.3 格納先の選択" "${STEP_FILE_PATH}"
  grep -F "#### 1.4 write-history.sh ガード" "${STEP_FILE_PATH}"
  grep -F "predecessor_retrospective.md" "${STEP_FILE_PATH}"
}

@test "IS9: Unit 007 で導入された feedback_mode ベースの opt-out スイッチが §1.0 に存在" {
  grep -F "#### 1.0 実施判定" "${STEP_FILE_PATH}"
  grep -F "feedback_mode" "${STEP_FILE_PATH}"
  grep -F "全体スキップ" "${STEP_FILE_PATH}"
  grep -F "disabled" "${STEP_FILE_PATH}"
  grep -F "opt-out" "${STEP_FILE_PATH}"
}
