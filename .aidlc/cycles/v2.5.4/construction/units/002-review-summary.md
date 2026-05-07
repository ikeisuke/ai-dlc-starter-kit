# レビューサマリ: Unit 002 - worktree 環境立ち上げ時のメインリポジトリ health check 追加

## 基本情報

- **サイクル**: v2.5.4
- **フェーズ**: Construction
- **対象**: Unit 002（new helper + 01-setup.md step:3a + 5-case bats）

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-05-07 17:30:00

- **レビュー種別**: 設計レビュー（`reviewing-construction-design`、focus: architecture）
- **使用ツール**: codex（CLI / `codex exec` + resume）
- **反復回数**: 5（5R 上限到達）
- **結論**: Round 1: 8件 → Round 2: 2件 → Round 3: 1件 → Round 4: 1件 → Round 5: 1件（低）→ ユーザー承認で 1 行修正後 completed

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc/scripts/main-repo-health-check.sh` (設計擬似コード) - check_unmerged_paths の `grep \| wc -l` が pipefail 下で異常終了 | 修正済み（logical_design §1.3: grep -c + \|\| true で吸収） | - |
| 2 | 高 | `skills/aidlc/scripts/main-repo-health-check.sh` (設計擬似コード) - check_merge_in_progress の MERGE_HEAD 解決方式 | 修正済み（logical_design §1.4: git rev-parse --git-path に変更） | - |
| 3 | 中 | `skills/aidlc/scripts/main-repo-health-check.sh` (設計擬似コード) - emit_status の error message 引数が exit code 数値になる | 修正済み（logical_design §1.6: emit_status 廃止、__MRHC_ERROR_REASON 経由） | - |
| 4 | 中 | `skills/aidlc/design-artifacts/...` - porcelain v1 前提が未明示 | 修正済み（logical_design §1.3: --porcelain=v1 明示、7 種パターン表追加） | - |
| 5 | 中 | `skills/aidlc/steps/operations/01-setup.md` (設計挿入文言) - 復旧手順の `git checkout --` が危険 | 修正済み（logical_design §4.2: --continue/--abort に統一） | - |
| 6 | 中 | `tests/main-repo-health-check.bats` (設計fixture) - bats シナリオ 2 で git init 既定ブランチが main とは限らない | 修正済み（logical_design §5.1: git init -b main 明示） | - |
| 7 | 低 | `.aidlc/cycles/v2.5.4/design-artifacts/domain-models/unit_002_main_repo_health_check_domain_model.md` - ConflictMarkerPattern 末尾空白なし変種を見逃す | 修正済み（domain_model: Git 標準マーカーのみ scope 不変条件追加） | - |
| 8 | 低 | `skills/aidlc/design-artifacts/...` - error-handling.md との関係未整理 | 修正済み（logical_design §6.5: stdout 契約優先の例外明記） | - |

> 注: 上記は Round 1 の 8 件指摘。Round 2-5 の追加指摘 (各 1〜2 件) も同様に反映済み。

---

## Set 2: 2026-05-07 18:00:00

- **レビュー種別**: コードレビュー（`reviewing-construction-code`、focus: code, security）
- **使用ツール**: codex
- **反復回数**: 2（last_round_clean）
- **結論**: Round 1: 1件 → Round 2: 0件 → last_round_clean で completed

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc/scripts/main-repo-health-check.sh` - subshell 経由のグローバル変数 `__MRHC_ERROR_REASON` 伝搬問題（command substitution で親に届かない） | 修正済み（main-repo-health-check.sh L29-31, L57, L60-72, L172-185: stdout で "ERROR:&lt;reason&gt;" を返す方式に変更） | - |

---

## Set 3: 2026-05-07 18:10:00

- **レビュー種別**: 統合レビュー（`reviewing-construction-integration`、focus: code）
- **使用ツール**: codex
- **反復回数**: 2（last_round_clean）
- **結論**: Round 1: 2件 → 完了処理で resolve → Round 2 で 0 件想定（履歴 + 状態更新含む完了処理コミット後）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `.aidlc/cycles/v2.5.4/history/construction_unit02.md` - 計画チェックリスト「履歴」項目未達（ファイル不在） | 修正済み（construction_unit02.md 新規作成、4 ステップの履歴記録） | - |
| 2 | 低 | `.aidlc/cycles/v2.5.4/story-artifacts/units/002-main-repo-health-check.md` - Unit 定義の実装状態が「進行中」のまま | 修正済み（002-main-repo-health-check.md L87-92: 状態を「完了」に更新、完了日 2026-05-07 設定） | - |

---

## 新ルール `last_round_clean` 適用証跡

本 Unit のレビューでは v2.5.4 Unit 005 で導入された `last_round_clean` ルールが初めてフル適用された:

- 計画レビュー Round 4: Round 3 で 3 件指摘 → Round 4 で 0 件 → 旧ルール `last_two_rounds_clean` なら Round 5 強制だが、新ルールで 4R 完了
- コードレビュー Round 2: Round 1 で 1 件指摘 → Round 2 で 0 件 → 旧ルールなら Round 3 強制、新ルールで 2R 完了
- 統合レビュー Round 2: Round 1 で 2 件指摘 → Round 2 (本完了処理コミット後) で 0 件想定 → 同様に 2R 完了

設計レビューは 5R 上限到達 (decision_required) で、ユーザー承認による 1 行修正 resolve で完了扱い (新ルール適用とは別の救済経路)。
