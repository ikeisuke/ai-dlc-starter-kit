# レビューサマリ: Unit 005 gh-project 副作用 bats テスト整備（gh API モックフレームワーク）

## 基本情報

- **サイクル**: v2.6.2
- **フェーズ**: Construction
- **対象**: Unit 005 (gh-project 副作用 bats テスト整備 / Issue #683)

---

## Set 1: 2026-05-12 設計レビュー

- **レビュー種別**: 設計レビュー（domain model + logical design / focus=architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（Round 3 で `last_round_clean=true` → completed）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_005_gh_project_side_effect_bats_domain_model.md`, `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md` - ApiSelector dispatch 表が 4 スクリプト + `bin/lib/` 経由の実コール呼出を網羅しておらず、`gh project view-list` / `view-create` / `field-create` / `edit` / `gh issue close` / `issue list` が欠落。設計どおり実装すると正当な経路でも `unmocked` (exit 99) になる | 修正済み（`domain_model.md` dispatch 表に 6 API を追加、各 fixture key + per-api FailureFlag を 1 対 1 で明記。`logical_design.md` の fixtures 一覧・スキーマ表・bats 依存にも反映） | - |
| 2 | 中 | `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_005_gh_project_side_effect_bats_domain_model.md`, `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md` - fixture キー / ファイル名の命名が文書間で不整合（dispatch 表 `issue-view` vs スキーマ表 `issue-view-body.json` 等） | 修正済み（`domain_model.md` dispatch 表を SoT として明示、`logical_design.md` の全箇所を 1 対 1 命名で統一: `issue-view.json` / `project-item-add.json` / `project-field-list-default.json` 等。R2 で残存していた L97 / L104 / L257 も修正） | - |
| 3 | 中 | `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md` - Phase 2 audit bats ケース表に `--check all` の集約検証ケースが欠落（計画書 §「含まれるもの §8」の要件取りこぼし） | 修正済み（`logical_design.md` audit ケース表に ケース 6 を追加: 2 系統結果集約 / overall_exit 優先順位 / strict=3 / soft=0 を明示、5 ケース → 6 ケース、Phase 2 新規合計 17 件 → 18 件相当） | - |
| 4 | 中 | `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md` - migrate --dry-run ケース期待が実装と不一致（`bin/migrate-issue-524.sh` L63 は dry-run でも `gh issue view 524` を実行してバックアップを作成する） | 修正済み（`logical_design.md` migrate ケース 1: `gh issue edit 0 回 + gh issue view 1 回` のアサート + `issue-524:backup-saved` 行の期待を追加） | - |
| 5 | 中 | `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md` - R2 残存指摘: `probe-github-project.bats` 依存セクション L104 で旧命名 `item-add.json` が残存 | 修正済み（R3 修正対象、`project-item-add.json` + `issue-close.json` に統一、setup() 標準パターンの fixture コピー例も `project-field-list-default.json` に修正） | - |

### シグナル

- `review_detected=true`
- `resolved_count=5`
- `deferred_count=0`
- `unresolved_count=0`
- `rounds=3`（R1: 4 件 / R2: 残存 1 + 新規 1 / R3: 0 件 → completed）

### セッション ID

- R1: `cdr-20260512-001`
- R2: `20260512-verify-unit005-r1-followup`
- R3: `c2f57a`

### セミオートゲート判定

- `auto_approved`（automation_mode=semi_auto / unresolved_count=0 / フォールバック非該当）

---

## Set 2: 2026-05-12 コードレビュー

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus=code+security）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘 0 件（Round 3 で `last_round_clean=true` → completed）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 (code) | `bin/tests/gh-project/setup-github-project.bats` Case 4 の `--dry-run` 除去検証が `gh` 呼出ログの欠落のみを見ており、`--dry-run` は元々 `gh` 直引数ではないため false-positive で通る余地がある | 修正済み（R1 反映: `audit:spec-conformance:` 行と `audit-summary:` 行の必須アサーションを追加し、`audit-github-project.sh` の完走を直接検証する形に強化） | - |
| 2 | 中 (security) | `bin/tests/gh-project/_helpers.bash` の `--jq` 適用ロジックで fixture が JSON parse 不可の場合に `cat` フォールバックする実装は、parse 失敗を silent に隠す mock false-positive リスクがある | 修正済み（R1 反映: `--jq` 指定時は valid JSON 必須化、parse 失敗で `exit 97`。`issue-view.json` を raw text から `{body: ...}` JSON に変換し contract に整合） | - |
| 3 | 低 (code) | `bin/tests/gh-project/_helpers.bash` の `_dispatch_api` で nth-call 判定に `grep -E "^${key} "` を使用しており、`key` に正規表現メタ文字が入った場合の誤カウント保守リスクがある | 修正済み（R1 反映 → R2 で再指摘 → R2 反映: 最終的に `awk -v k="${key} " 'index($0,k)==1{c++}'` に変更し、正規表現メタ文字非依存で行頭境界を厳密判定） | - |

### シグナル

- `review_detected=true`
- `resolved_count=3`
- `deferred_count=0`
- `unresolved_count=0`
- `rounds=3`（R1: 0 件 / R1 後: 3 件指摘（中:2 低:1）/ R2: 1 件指摘（低: nth-call 行頭境界）/ R3: 0 件 → completed）

### セッション ID

- R1: `019e19d7-2265-7d82-867e-69b131607cf5`（初回）
- R2 / R3: 同セッション resume

### セミオートゲート判定

- `auto_approved`（automation_mode=semi_auto / unresolved_count=0 / フォールバック非該当）

---

## Set 3: 2026-05-12 統合レビュー

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus=architecture+code）
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘 0 件（Round 5 で `last_round_clean=true` → completed）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 (architecture/code) | Phase 2 完了マーカーの artifact (Unit 定義「実装状態」) が diff に未反映で完了証跡として未クローズ | 修正済み（R3 反映: `.aidlc/cycles/v2.6.2/story-artifacts/units/005-gh-project-side-effect-bats.md` の実装状態を「完了」に更新、完了日 2026-05-12） | - |
| 2 | 低 (code) | `gh_project_assert_gh_call_count` が `grep -E` ERE 前提のため正規表現メタ文字混入の保守リスクがある（codex R2 で初出 → R3 で行内一致リスク再指摘 → R4 で互換性懸念） | 修正済み（R2 反映: 固定文字列用途として `gh_project_assert_gh_call_count_fixed` 新規追加。R3 反映: `grep -cFx` で行全体一致に強化。R4 反映: `_helpers_self_test.bats` に契約検証 2 ケース追加（行全体一致 / 部分一致 false-negative）） | - |
| 3 | 低 (documentation) | テスト作法 README/規約に `_fixed` の完全一致専用契約が明文化されていない | deferred（inline 関数 doc が canonical な契約定義であり、別ドキュメントへの重複は維持コスト増 / 真偽の二重管理リスクが高いと判断。bats 内の契約確認ケース（R4 #1 反映）が機械検証として機能し、誤用は即時 fail で検出可能） | PENDING_MANUAL（将来の保守性向上として README 追記検討候補。代替として inline doc の運用維持） |

### シグナル

- `review_detected=true`
- `resolved_count=3`（R3 #1 中 / R2 + R3 + R4 で fix された低 1 件 / R4 #1 低）
- `deferred_count=1`（R4 #2 低 / README 明文化）
- `unresolved_count=0`
- `rounds=5`（R1: 2件 → R2: 2件 → R3: 2件 → R4: 2件 → R5: 0件 → completed）

### セッション ID

- 複数セッションにわたり inline diff 渡しで実施（codex sandbox-exec 制約のため）

### セミオートゲート判定

- `auto_approved`（automation_mode=semi_auto / unresolved_count=0 / フォールバック非該当 / deferred は明示的に判断記録済み）

### 検出した subject bug（即時 fix）

統合過程で `bin/setup-github-project.sh` の audit step の `--dry-run` 除去ロジック `"${_OPTS[@]/--dry-run/}"` が空文字列要素を残し、下位 CLI が `unknown_option:` で exit 1 する bug を検出。Unit 005 計画の「含まれないもの: 4 スクリプト本体の挙動変更」と緊張関係にあるが、設計書の Phase 2 ケース表 #1 (`--dry-run で 5 subcommand 順次完了`) を成立させるために必須な修正のため、CLAUDE.md「即時実装優先ルール」適用で即時 fix（配列フィルタに置換）。fix 範囲 5 行 + 修正コメントで本体スクリプトに記録、設計書ケース表との整合を回復。
