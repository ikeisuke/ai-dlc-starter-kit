# Construction Phase 履歴: Unit 03

## 2026-05-05T13:50:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-llm-draft-and-human-review（主因分類 LLM 下書き + 人間確認運用）
- **ステップ**: Unit 完了
- **実行内容**: # Construction Unit 003 履歴: 主因分類 LLM 下書き + 人間確認運用

## 概要

Unit 002 が起票する retrospective Issue に対して、(1) 主因分類 + `skill_caused_judgment` の LLM 下書きを生成して prefill する経路、(2) 人間確認後に `human_reviewed: false → true` 更新と `[llm-diff]` コメント追記を行う経路、(3) `human_reviewed` の機械検証 CLI、の 3 つを提供。境界保護として `04-completion §1.5` 本体への変更は 0 件、Unit 001/002 ライブラリへの変更も 0 件。Unit 003 は hook 関数 + subagent 定義 + verify CLI の追加のみで完結。

## Phase 1: 設計

- ドメインモデル: LLMDraftSchemaValidator（純粋関数）/ HumanReviewIssueWriter（差分検出 → コメント生成 → gh 更新の Pipeline Pattern）/ IssueBodyRepository / IssueCommentRepository / IssueLabelRepository（gh CLI への薄い Adapter）/ VerificationStateClassifier（純粋関数）
- 論理設計: hook 関数 I/F を Unit 002 plan §「Unit 003 フック契約」と完全一致（`retrospective_prefill_hook(cycle, kpt_md_path)` / `retrospective_update_hook(issue_url, cycle)`）/ 順序不変条件 `comment → edit --body-file → edit --add-label` を Pipeline Pattern として明文化
- 責務分離: subagent 起動 / AskUserQuestion / 30 秒タイムアウト判定は AI エージェント前段手順の責務 / hook 関数自身は環境変数経由のファイル読取 + スキーマ検証 + skip 判定 + I/O のみ
- production 侵食ガード: テストモック環境変数 `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` は `AIDLC_TEST_MODE=1` 必須 / 誤設定時に stderr `error\tllm_draft_override_in_production\t...`
- exit code 規約: `guides/exit-code-convention.md` 準拠（警告付き完了 = exit 0 / ランタイム異常 = exit 1 / 引数エラー = exit 2）/ `gh` 失敗時も exit 0 + stderr `warn\thuman_review_gh_*_failed\t...` で §1.5 継続性を保証
- URL 厳密検証: `^https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/issues/[0-9]+/?$` で GitHub Issue URL 限定（domain model `IssueUrl` 構造制約と整合）
- 計画レビュー: codex 6 round / 11 件指摘（高 3 / 中 8）→ 全件解消 / `auto_approved`
- 設計レビュー: codex 5 round / 7 件指摘（高 2 / 中 5）→ 全件解消 / `auto_approved`

## Phase 2: 実装

- 新規: `skills/aidlc/agents/retrospective-drafter.md`（subagent 定義 + 呼び出し例 + 30 秒タイムアウト fallback documentation）
- 新規: `skills/aidlc/scripts/lib/retrospective-llm-draft.sh`（`retrospective_prefill_hook` / `__retro_llm_validate_schema` / `__retro_llm_resolve_source_path` + production guard / quoted/unquoted 両対応スキーマ検証）
- 新規: `skills/aidlc/scripts/lib/retrospective-human-review.sh`（`retrospective_update_hook` / 順序不変条件 comment → edit --body-file → edit --add-label / `__retro_hr_validate_url` / `__retro_hr_compose_diff_comment` / 戻り値規約 `0=差分あり / 1=差分なし` の bash convention）
- 新規: `skills/aidlc/scripts/retrospective-verify.sh`（`--cycle` / `--strict` / `--dry-run` / `--help` / 末尾 ```yaml フェンス抽出関数 `__retro_verify_extract_tail_yaml` で誤検出経路を完全廃止 / yq オプショナル化）
- セキュリティ強化: jq 式に `--arg` で cycle を渡す形式に変更（コマンドインジェクション対策）/ `head -n -1` を `sed '$d'` に変更（macOS BSD 互換）
- 値域検証の厳密化: `("(product|ai_dlc|both)"|(product|ai_dlc|both))` 形式で完全 quoted または完全 unquoted のみ許容（片側欠落 quote は YAML 不正として弾く）

## テスト

- tests/retrospective-llm-draft.bats: 新規 13 件（L1-L12 / hook 関数本体の失敗 / fallback 経路網羅 / production guard / quoted-unquoted / 片側欠落 quote 検出）
- tests/retrospective-human-review.bats: 新規 15 件（H1-H13 / 順序不変条件 / gh 失敗時 warn 継続 / `__retro_hr_has_diff` 戻り値規約 4 通り / `[llm-diff]` コメントに final_text + マーカー含有 / before/after diff 行が `human_reviewed:` のみ 2 行）
- tests/retrospective-verify.bats: 新規 15 件（V1-V17 / 末尾 ```yaml フェンス抽出ベース判定 / 本文上部の misleading な human_reviewed 行が無視されることを assert / yq 不在時 V16 skip）
- 既存テスト退行ゼロ: 249/249 pass

## レビュー

- 計画レビュー: codex 6 round / 11 件指摘 → 0 件 → `auto_approved`
- 設計レビュー: codex 5 round / 7 件指摘 → 0 件 → `auto_approved`
- コードレビュー: codex 2 round / 5 件指摘 → 0 件 → `auto_approved`（`grep -qE 'true'` 部分一致 → `^human_reviewed:[[:space:]]*true[[:space:]]*$` 厳密化、jq --arg 化、trap RETURN 撤廃）
- 統合レビュー: codex 5 round / 11 件指摘 → 0 件 → `auto_approved`（`__retro_hr_has_diff` 戻り値規約反転、final_path 反映を Plan 整合のため hook 簡略化 + コメント canonical 化、tail_yaml 抽出ベース判定への完全移行、`__retro_verify_extract_tail_yaml` 追加、本文上部 misleading marker の誤検出排除）
- 反復: 計 18 round / 34 件指摘解消 / 千日手検出なし

## 意思決定記録（v2.5.1 サイクル decisions.md に追記候補）

- DR-016: 本文 update 責務を `human_reviewed: false → true` 置換のみに限定。final_path の内容差分は `[llm-diff]` コメントが canonical な記録経路。本文の Markdown 再生成は将来サイクルで検討（情報損失なし）
- DR-017: verify CLI の判定境界を「末尾 ```yaml フェンスのみが信頼できる検証対象」に厳密化。フェンスなし = 旧仕様 = skipped / フェンスあり + キー欠落 / 形式不正 = unverified / body 全体 grep フォールバックは廃止
- DR-018: YAML 値域 regex を完全 quoted または完全 unquoted のみ許容（`("(product|ai_dlc|both)"|(product|ai_dlc|both))` 形式）に厳密化。片側欠落 quote は YAML 不正として弾く
- DR-019: hook 関数の責務分離を「環境変数経由のファイル読取 + スキーマ検証 + skip 判定 + I/O のみ」に確定。subagent 起動 / AskUserQuestion / タイムアウト判定は AI エージェント前段手順の責務（`agents/retrospective-drafter.md` documentation で検証）

## 完了条件達成

Unit 責務（subagent 提供 / hook I/F 統一 / verify CLI / 境界保護）+ Intent 主要設計判断 2 / 6.3 / 6.4 + 成功基準（LLM 下書き prefilled）+ リスク 2 緩和（machine verify）+ NFR（応答性 / 観測性 / 学習可能性 / 冪等性 / CI 互換）+ 逆方向非依存検証 = すべて達成。境界保護: `git diff main` で `04-completion.md` / `retrospective-issue.sh` / `retrospective-resend.sh` / `feedback-mode.sh` / `feedback-mode-wizard.sh` / `retrospective_template.md` への変更が現サイクルブランチで Unit 003 範囲外であることを確認済。

## 関連 Issue

- なし（Issue #590 partial / #592 partial は Unit 002 で消化済）

## 検証ログ

- Unit 003 BATS: 43/43 pass（V16 は yq 不在で skip / 残り 42 件 pass）
- 既存 BATS: 249/249 pass（退行ゼロ）
- shellcheck --severity=warning: 0 件
- bin/check-bash-substitution.sh: 違反 0（34 ファイル検証）

---
