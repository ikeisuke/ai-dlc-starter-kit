# レビューサマリ: Unit 003 主因分類 LLM 下書き + 人間確認運用

## 基本情報

- **サイクル**: v2.5.1
- **フェーズ**: Construction
- **対象**: Unit 003 主因分類 LLM 下書き + 人間確認運用

---

## Set 1: 2026-05-05（計画レビュー）

- **レビュー種別**: 計画レビュー（reviewing-construction-plan）
- **使用ツール**: codex（read-only モード）
- **反復回数**: 6（指摘 5 → 3 → 1 → 1 → 1 → 0 件 / 千日手検出なし、各 round で別系統または記述漏れ箇所の指摘を順次解消）
- **結論**: 指摘 0 件 / `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | architecture | 1 | §1.5 編集主体規約違反（Intent §6.5 で §1.5 編集主体は Unit 002、Unit 003 は hook 差し込みのみ） | 修正済み（plan §「変更対象ファイル」を「編集しない（境界保護）」に変更 + §「§1.5 Step 3 / Step 6 の責務分担」テーブル + 完了条件チェックリストの境界保護項目追加） | - |
| 2 | 高 | architecture | 1 | hook 契約名の不一致（Unit 002: `retrospective_prefill_hook` / `retrospective_update_hook` vs Unit 003 plan: `retrospective_llm_draft_compose` / `retrospective_human_review_finalize`） | 修正済み（Unit 002 plan §「Unit 003 フック契約」を cross-unit 正本として採用 / 関数名・引数・stdout・exit code を完全一致に統一 / アダプタ層なし） | - |
| 3 | 中 | inception | 1 | Intent §判断 2 実行マトリクスとのズレ（Unit 003 plan の「mirror-only は CI でも動作」が Intent の「非対話/CI は skip」と矛盾） | 修正済み（mirror-only 例外削除 / CI / 非対話は常に skip に統一 / §「失敗 / fallback 経路の網羅」表を Intent §判断 2 準拠に書き直し） | - |
| 4 | 中 | code | 1 | exit code 規約矛盾（hook 失敗時 exit 1 vs リスク緩和「警告のみ exit 0」 vs `guides/exit-code-convention.md`「警告付き完了は exit 0」） | 修正済み（`retrospective_update_hook` の `gh` 失敗時も exit 0 + stderr `warn\thuman_review_gh_*_failed\t...` に統一 / 引数欠落 → exit 2 / 引数形式不正 → exit 1 のみ） | - |
| 5 | 中 | architecture | 1 | テストモック環境変数 `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` の production 侵食ガードが弱い | 修正済み（`AIDLC_TEST_MODE=1` 必須ガード追加 / production 誤設定検出 stderr `error\tllm_draft_override_in_production\t...` / BATS setup でのみ export する規約を documentation） | - |
| 6 | 高 | architecture | 2 | `retrospective_prefill_hook` の責務記述に「AskUserQuestion 起動」が残存（指摘 #1 修正の取りこぼし） | 修正済み（副作用記述を「環境変数経由のファイル読取のみ」に修正 / AskUserQuestion / subagent 起動は AI エージェント前段手順の責務として明確化） | - |
| 7 | 中 | architecture | 2 | 設計フェーズ項目に「§1.5 Step 3 / Step 6 の改修案作成」記述が残存（指摘 #1 修正の取りこぼし） | 修正済み（「Unit 002 既存改修内容との整合確認（参照のみ / Unit 003 では §1.5 ステップ本体を編集しない）」に書き換え + ギャップ判定明示） | - |
| 8 | 中 | code | 2 | `gh label add` の API 表記が不正確（Issue ラベル付与は `gh issue edit --add-label`） | 修正済み（副作用 / Step 6 責務 / 設計フロー / モック stub の 4 箇所を `gh issue edit --add-label` / `gh issue edit --body-file` / `gh issue comment` 表記に統一） | - |
| 9 | 中 | architecture | 3 | `retrospective_prefill_hook` 責務記述ゆらぎ（hook 実装と AI エージェント手順の境界が一部行で曖昧 / :30, :46） | 修正済み（提供 I/F テーブルの hook 接続記述を「subagent 起動は AI エージェント前段手順 / hook 関数自身は責務外」に修正 + テスト記述を「hook 関数本体の試験のみ」に限定） | - |
| 10 | 中 | consistency | 4 | 193 行目テスト記述の再ゆらぎ（46 行目で切り分けたが 193 行目に「subagent モック / fallback / タイムアウト」が残存） | 修正済み（193 行目を 46 行目方針に統一 / `agents/retrospective-drafter.md` documentation 検証へ切り分け） | - |
| 11 | 中 | consistency | 5 | 完了条件 228, 242 行目で AI エージェント手順の責務まで「BATS で verify」と読める記述 | 修正済み（hook 関数本体経路を BATS 検証 / AI エージェント手順経路を `agents/retrospective-drafter.md` documentation 検証 + review checklist + 目視確認に責務分離） | - |

### サマリ

- 高: 3 件（解消済 3）
- 中: 8 件（解消済 8）
- 低: 0 件
- **合計**: 11 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし（各 round で別系統または記述取りこぼしの指摘）
- 反復 6 回（review-flow.md の上限 3 回を超過した round 4-6 は指摘軽減傾向のため継続実施 / round 6 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=11`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

### 主要な合意事項（Unit 003 設計フェーズ以降への引き継ぎ）

1. **§1.5 編集主体は Unit 002 / Unit 003 は hook 関数実装と subagent 定義のみ提供**: Unit 003 commit で `skills/aidlc/steps/operations/04-completion.md` への変更は 0 件
2. **hook 契約は Unit 002 plan §「Unit 003 フック契約」が cross-unit 正本**: 関数名 `retrospective_prefill_hook(cycle, kpt_md_path)` / `retrospective_update_hook(issue_url, cycle)` を完全一致で実装
3. **責務分離（hook vs AI エージェント手順）**: hook 関数は環境変数経由のファイル読取のみ。subagent 起動 / AskUserQuestion / 30 秒タイムアウト判定は AI エージェント前段手順（`agents/retrospective-drafter.md` documentation で検証）
4. **exit code 規約**: 警告付き完了は常に exit 0 / ランタイム異常 exit 1 / 引数エラー exit 2（`guides/exit-code-convention.md` 準拠）
5. **テストモック production ガード**: `AIDLC_TEST_MODE=1` 必須 + production 誤設定時の stderr error 出力
6. **CI / 非対話は常に skip**: Intent §判断 2 厳守（mirror-only 例外なし）

---

## Set 2: 2026-05-05（設計レビュー）

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex（read-only モード）
- **反復回数**: 5（指摘 4 → 1 → 1 → 1 → 0 件 / 千日手検出なし、各 round で別系統または記述漏れ箇所の指摘を順次解消）
- **結論**: 指摘 0 件 / `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | architecture | 1 | `retrospective-verify.sh` の exit code が hook 規約（引数系=2 / ランタイム=1）と不一致（gh 不可・Milestone 不在も exit 2 扱い） | 修正済み（CLI 戻り値節 + 詳細表 + V6/V7/V10 + ドメインモデル VerificationScanner / 確定事項を全て exit 1 に統一） | - |
| 2 | 高 | architecture | 1 | `human_reviewed` 欠落判定矛盾（VerificationOutcome=unverified / VerificationStateClassifier=skipped） | 修正済み（YAML ブロック自体不在のみ skipped、human_reviewed キー欠落は unverified に統一 + V12/V13 テストケース追加） | - |
| 3 | 中 | architecture | 1 | `retrospective_update_hook` の gh 呼び出し順序記述不整合（副作用節は本文更新→コメントだが他は逆順） | 修正済み（I/F 副作用記述を comment → edit --body-file → edit --add-label の順序不変条件 + 失敗時スキップ規則として明示） | - |
| 4 | 中 | inception | 1 | §1.5 ギャップ判定の exit code 事実誤認（「常に exit 0」が異常時 exit 1/2 経路と矛盾） | 修正済み（「警告付き完了は exit 0、異常時は非 0。Unit 002 は非 0 を警告化して継続できるため互換性あり」に修正） | - |
| 5 | 中 | code | 2 | issue_url 形式不正の exit code が「引数形式不正」と書きつつ exit 1 扱いで規約「引数系 = exit 2」と不一致 | 修正済み（入力節 / 戻り値節 / stderr 仕様 / H8 テスト / ドメインモデル exit code 規約を exit 2 に統一） | - |
| 6 | 中 | code | 3 | ギャップ判定表 537 行で旧扱い「exit 1: I/O / URL 形式不正」が残存 | 修正済み（「exit 1: I/O エラー、exit 2: 引数欠落 / URL 形式不正など引数系全般」に修正） | - |
| 7 | 中 | code | 4 | URL バリデーション定義の不統一（131 行は厳密 GitHub URL / 148, 161 行は http(s) 任意 URL） | 修正済み（148 / 161 行を `https://github.com/<owner>/<repo>/issues/<N>` 厳密条件に統一 / domain model `IssueUrl` 構造制約と整合） | - |

### サマリ

- 高: 2 件（解消済 2）
- 中: 5 件（解消済 5）
- 低: 0 件
- **合計**: 7 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし（各 round で別系統または記述取りこぼしの指摘）
- 反復 5 回（review-flow.md の上限 3 回を超過した round 4-5 は指摘軽減傾向のため継続実施 / round 5 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=7`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

---

## Set 3: 2026-05-05（コードレビュー）

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus: code, security）
- **使用ツール**: codex（read-only モード）
- **反復回数**: 2（指摘 5 → 0 件 / 千日手検出なし）
- **結論**: 指摘 0 件 / `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | code | 1 | `grep -qE 'true'` 部分一致で `human_reviewed` を判定（`untrue` でも true 扱いの可能性） | 修正済み（`^human_reviewed:[[:space:]]*true[[:space:]]*$` で行全体厳密判定 / retrospective-human-review.sh:68 + retrospective-verify.sh:108） | - |
| 2 | 中 | security | 1 | `gh api ... --jq` の jq 式に `cycle` を直接埋め込み（`"` を含む入力で式破壊リスク） | 修正済み（`gh api` で raw JSON を取得 → `jq --arg cycle "$cycle" ...` の安全形式に変更 / Milestone 存在確認 + cycle 自動解決の両方を更新） | - |
| 3 | 中 | code | 1 | `trap 'rm -f -- "$tmp_body_file"' RETURN` が source 利用時に呼出元の RETURN trap 契約を壊す | 修正済み（trap RETURN を撤廃 / `edit_rc` で gh issue edit の結果を保持し直後に明示 `rm -f` で cleanup） | - |
| 4 | 低 | code | 1 | H2 テストで `comment < edit --body-file` までしか順序検証していない | 修正済み（`comment_line < body_edit_line < label_line` を assert / `--add-label` 行番号も取得） | - |
| 5 | 低 | code | 1 | V8 テストが `[ "$status" -eq 0 ] || [ "$status" -eq 1 ]` で許容幅を持っており仕様逸脱を検出できない | 修正済み（V8a: 最新 Milestone あり / Issue 0 件 → exit 0 と V8b: Milestone なし → exit 1 に分割 / シムも `0`/`1`/JSON 透過の３通りに更新） | - |

### サマリ

- 高: 1 件（解消済 1）
- 中: 2 件（解消済 2）
- 低: 2 件（解消済 2）
- **合計**: 5 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 2 回（round 2 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=5`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 検証ログ（事前 / 事後）

- Unit 003 BATS: 37/37 pass（修正前後で同数）
- 既存 BATS: 249/249 pass（退行ゼロ）
- shellcheck --severity=warning: 0 件
- bin/check-bash-substitution.sh: 違反 0

---

## Set 4: 2026-05-05（統合レビュー）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus: integration, traceability, scope, coverage, ci）
- **使用ツール**: codex（read-only モード）
- **反復回数**: 5（指摘 5 → 3 → 2 → 1 → 0 件 / 千日手検出なし、累積で hook 規約・本文構造整合・YAML パース対象限定 等のレイヤを順次収束）
- **結論**: 指摘 0 件 / `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | traceability | 1 | `__retro_hr_apply_final_drafts` が human_reviewed 置換のみで final_path 内容を本文へ反映していない | 修正 → round 2 で再検討（実 Issue 構造との不整合判明 / 後述 #6 で最終確定） | - |
| 2 | 高 | integration | 1 | `__retro_hr_has_diff` の戻り値規約と呼び出し側が逆転（FINAL_PATH 未設定でも has_diff=1） | 修正済み（戻り値を bash convention に統一: 0=差分あり / 1=差分なし、H13 で 4 通り厳密検証） | - |
| 3 | 中 | traceability | 1 | `head -n -1` が macOS BSD 非互換で stderr 形式規約 `<level>\t<code>\t<detail>` を汚染 | 修正済み（`sed '$d'` に置換 / POSIX 互換） | - |
| 4 | 中 | traceability | 1 | primary_cause / qN_answer 検証が「ダブルクォート付き文字列のみ許容」で厳しすぎ → quoted/unquoted 両対応へ | 修正 → round 2 で片側欠落 quote の不検出が発見 → 後述 #8 で最終確定 | - |
| 5 | 中 | coverage | 1 | verify CLI に末尾 YAML 抽出 + YAML パース失敗時 warn が未実装 | 修正 → round 2 で yq 全文パースの誤判定が発見 → 後述 #7 で最終確定 | - |
| 6 | 高 | integration | 2 | 実 Issue 本文は Markdown 展開（`## 問題項目（Problem）`）で `problem_drafts:` を直接保持しないため、`problem_drafts:` 起点の本文置換ロジックが効かない | 修正済み（Plan §「変更対象ファイル」を canonical source として実装と論理設計を整合化: `__retro_hr_apply_final_drafts` を `__retro_hr_update_body_marker` ラッパーに簡略化 / final_path の内容は `[llm-diff]` コメントで canonical な記録経路として保持 / 論理設計 line 432 を Plan に整合修正 / H12 をコメント本文と本文 update の責務分離検証に変更） | - |
| 7 | 中 | traceability | 2 | yq eval を Issue 本文全体に適用 → Markdown 混在で誤判定リスク | 修正済み（`__retro_verify_extract_tail_yaml` を追加 / 末尾 ```yaml フェンス抽出後に yq でパース検証 / 抽出不能時はフォールバック） | - |
| 8 | 中 | traceability | 2 | 値域 regex `"?...?"` が片側欠落 quote も許容 | 修正済み（`("(product|ai_dlc|both)"|(product|ai_dlc|both))` 形式で完全 quoted または完全 unquoted のみ許容 / L12 で片側欠落 quote の負例検証） | - |
| 9 | 中 | traceability | 3 | human_reviewed 抽出が body 全体 grep のため末尾 YAML 以外の同名行を誤検出するリスク | 修正済み（tail_yaml 抽出成功時は marker_line も tail_yaml 限定 / 抽出不能時のみ body 全体 grep にフォールバック） | - |
| 10 | 低 | coverage | 3 | H12 が「human_reviewed: true が含まれる」のみで「他行が変更されていない」検証が弱い | 修正済み（before / after の diff 行が `human_reviewed:` のみ 2 行であることを assert / mirror_state 行 + state: "created" 行の不変も検証） | - |
| 11 | 中 | traceability | 4 | tail_yaml 抽出失敗時の body 全体 grep フォールバックが残存し誤検出経路が残る | 修正済み（tail_yaml 空 → skipped に変更 / フォールバック完全廃止 / 新仕様判定（mirror_state / skill_caused_judgment）も tail_yaml 内で完結 / V17 で本文上部の misleading な human_reviewed: true 行が無視されることを assert / V1/V2/V12/V16 の body マクロを ```yaml フェンス付きに更新して実 retrospective-issue.sh 出力構造と整合） | - |

### サマリ

- 高: 3 件（解消済 3）
- 中: 6 件（解消済 6）
- 低: 2 件（解消済 2）
- **合計**: 11 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし（各 round で別系統または前 round 修正に関連する深掘り指摘）
- 反復 5 回（review-flow.md の上限 3 回を超過した round 4-5 は指摘軽減傾向のため継続実施 / round 5 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=11`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 検証ログ（事前 / 事後）

- Unit 003 BATS: 43/43 pass（V16 は yq 不在で skip / 残り 42 件 pass）
- 既存 BATS: 249/249 pass（退行ゼロ）
- shellcheck --severity=warning: 0 件
- bin/check-bash-substitution.sh: 違反 0

### 主要な合意事項（Unit 003 統合レビュー以降への引き継ぎ）

1. **本文 update 責務の最終確定**: `human_reviewed: false → true` 置換のみが hook の責務。final_path の内容は `[llm-diff]` コメントが canonical な記録経路。本文の Markdown 再生成は将来サイクルで検討（情報損失なし）
2. **verify CLI の判定境界**: 末尾 ```yaml フェンスのみが信頼できる検証対象。フェンスなし = 旧仕様 = skipped。フェンスあり + キー欠落 / 形式不正 = unverified
3. **YAML 値域 regex の厳密化**: 完全 quoted または完全 unquoted のみ許容（片側欠落 quote は YAML 不正として弾く）
4. **論理設計と Plan の canonical 関係**: Plan が canonical source。論理設計内の記述は Plan の意図に沿うように整合維持
