#!/usr/bin/env bats
# Unit 002: aidlc-setup ウィザードの個人好み推奨案内
# 観点 A (構造) / B (代表 3 キー) / C (非対話モード対応) / D (冪等性 + スコープ)
# の静的検証を行う。

load helpers/setup

readonly ANCHOR_9B='## 9b.'

# ─── 観点 A: セクション存在 + 構造 ───────────────────────

@test "A1: ## 9b. 個人好み user-global 推奨案内 ヘッダが 1 回のみ存在する" {
  run assert_section_exists "${ANCHOR_9B}"
  [ "$status" -eq 0 ]
  run assert_section_count '^## 9b\.' 1
  [ "$status" -eq 0 ]
}

@test "A2: ## 9b. が ## 9. と ## 10. の間に配置される" {
  run assert_section_between "9" "9b" "10"
  [ "$status" -eq 0 ]
}

@test "A3: ## 9b 本文に ~/.aidlc/config.toml の文字列が含まれる" {
  run assert_body_contains_token "${ANCHOR_9B}" '~/.aidlc/config.toml'
  [ "$status" -eq 0 ]
}

# ─── 観点 B: 代表 3 キーの例示 ──────────────────────────

@test "B1: ## 9b 本文に rules.reviewing.mode が含まれる" {
  run assert_body_contains_token "${ANCHOR_9B}" 'rules.reviewing.mode'
  [ "$status" -eq 0 ]
}

@test "B2: ## 9b 本文に rules.automation.mode が含まれる" {
  run assert_body_contains_token "${ANCHOR_9B}" 'rules.automation.mode'
  [ "$status" -eq 0 ]
}

@test "B3: ## 9b 本文に rules.linting.enabled が含まれる" {
  run assert_body_contains_token "${ANCHOR_9B}" 'rules.linting.enabled'
  [ "$status" -eq 0 ]
}

# ─── 観点 C: 非対話モード対応指示 ────────────────────────

@test "C1: ## 9b 本文に --non-interactive (フォワード互換) が含まれる" {
  run assert_body_contains_token "${ANCHOR_9B}" '--non-interactive'
  [ "$status" -eq 0 ]
}

@test "C2: ## 9b 本文に stderr または >&2 のいずれかが含まれる (2 段判定)" {
  run assert_body_contains_any "${ANCHOR_9B}" '>&2' 'stderr'
  [ "$status" -eq 0 ]
}

@test "C3: ## 9b 本文に 初回セットアップ + automation_mode + 3 モードが全て含まれる" {
  run assert_body_contains_token "${ANCHOR_9B}" '初回セットアップ'
  [ "$status" -eq 0 ]
  run assert_body_contains_token "${ANCHOR_9B}" 'automation_mode'
  [ "$status" -eq 0 ]
  run assert_body_contains_token "${ANCHOR_9B}" 'manual'
  [ "$status" -eq 0 ]
  run assert_body_contains_token "${ANCHOR_9B}" 'semi_auto'
  [ "$status" -eq 0 ]
  run assert_body_contains_token "${ANCHOR_9B}" 'full_auto'
  [ "$status" -eq 0 ]
}

# ─── 観点 D: 冪等性とスコープ限定 ────────────────────────

@test "D1: ## 9b 見出しが STEP_FILE 内で 1 回のみ出現する (冪等性)" {
  run assert_section_count '^## 9b\.' 1
  [ "$status" -eq 0 ]
}

@test "D2: ## 9b 本文に 初回セットアップ 文字列を固定で含む (スコープ限定)" {
  run assert_body_contains_token "${ANCHOR_9B}" '初回セットアップ'
  [ "$status" -eq 0 ]
}

@test "D3: 01-detect.md / 02-generate-config.md に rules.reviewing.mode が含まれない (単一ソース)" {
  run assert_other_files_no_token 'rules.reviewing.mode'
  [ "$status" -eq 0 ]
}

@test "D3b: 01-detect.md / 02-generate-config.md に ~/.aidlc/config.toml 推奨案内が重複しない" {
  run assert_other_files_no_token 'rules.automation.mode'
  [ "$status" -eq 0 ]
  run assert_other_files_no_token 'rules.linting.enabled'
  [ "$status" -eq 0 ]
}

# ─── 回帰テスト: 既存セクション破壊検出 ──────────────────

@test "R1: ## 9. Git コミット セクションが残存している" {
  run assert_section_exists '## 9. Git コミット'
  [ "$status" -eq 0 ]
}

@test "R2: ## 10. 完了メッセージと次のステップ セクションが残存している" {
  run assert_section_exists '## 10. 完了メッセージと次のステップ'
  [ "$status" -eq 0 ]
}

# ─── 安定 ID 契約: HTML コメントアンカー ─────────────────

@test "S1: stable_id HTML コメントアンカー guidance:id=unit002-user-global が ## 9b. の直前行に配置される" {
  local line_comment line_9b
  line_comment="$(grep -n -F -- '<!-- guidance:id=unit002-user-global -->' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  line_9b="$(grep -n -- '^## 9b\.' "${STEP_FILE_PATH}" | head -1 | cut -d: -f1)"
  [ -n "${line_comment}" ]
  [ -n "${line_9b}" ]
  # コメント行 + 1 == 9b 行 (空行を許さない直前配置)
  [ "$((line_comment + 1))" -eq "${line_9b}" ]
}

@test "S2: stable_id HTML コメントアンカーが STEP_FILE 内で 1 回のみ出現する (一意性)" {
  local count
  count="$(grep -c -F -- '<!-- guidance:id=unit002-user-global -->' "${STEP_FILE_PATH}")"
  [ "${count}" -eq 1 ]
}
