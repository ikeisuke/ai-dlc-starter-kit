# Unit 006 Review Summary - GitHub Projects (ProjectsV2) フル移行

## 設計レビュー（reviewing-construction-design / codex / 6 rounds）

**反復回数**: 6
**完了条件**: last_round_clean (R6 で 0 件 = completed)
**codex セッション ID**: 019e0f51-1077-7290-a0ae-ce91263c1e01

| 指摘 # | 重要度 | 内容 | 対応 | バックログ |
|--------|--------|------|------|----------|
| R1 #1 | 高 | `domain-models/...domain_model.md`: ドメイン層に `enableWorkflow(WorkflowId)` / `apply_strategy` などインフラ知識が漏れ | 修正済み（`unit_006_github_projects_migration_domain_model.md`: Project.markWorkflowEnabled に縮退、ApplyStrategy をドメイン層から削除） | - |
| R1 #2 | 中 | `logical-designs/...logical_design.md`: SoT 方針不明瞭（spec.yaml と config.toml [github_projects] の境界曖昧） | 修正済み（spec=desired state / config.toml=runtime binding 表を両ファイルに追加 + ensure-project 専用書き込み主体明記） | - |
| R1 #3 | 中 | `domain-models/...domain_model.md`: Type 軸の扱い API/構造で揺れ | 修正済み（ProjectView を project_field_axes と label_axes に分離、Type は label_axes 専用に統一） | - |
| R1 #4 | 中 | `logical-designs/...logical_design.md`: audit に `--dry-run` の意味なし | 修正済み（共通契約 「`--dry-run` の意味」セクション新設、audit から削除） | - |
| R1 #5 | 低 | `logical-designs/...logical_design.md`: exit code が粗く `exit 2` に複数原因混在 | 修正済み（共通契約 exit code 規約 0/1/2/3/4/5/6/7 + error_type JSON 必須化） | - |
| R2 #1 | 中 | `domain-models/...domain_model.md`: `ProjectRepository.createView` が ApplyStrategy 引数を残存 | 修正済み（リポジトリ層から ApplyStrategy 引数削除、アプリケーション層 `ProjectReconciler` の責務に明記） | - |
| R2 #2 | 低 | `domain-models/...domain_model.md`: ProjectSpec Aggregate 不変条件が分離前の表現 | 修正済み（`views[*].project_field_axes ⊆ fields[*].name` + `label_axes[*].label_prefix` の妥当性検証に書き換え） | - |
| R2 #3 | 低 | `logical-designs/...logical_design.md`: gh-project-cli.sh のオプション仕様が共通記述で audit と矛盾 | 修正済み（サブコマンド別オプション表 + audit に `--dry-run` 指定時 exit 1 + args_invalid 契約化） | - |
| R3 #1 | 中 | `domain-models/...domain_model.md`: クラス図 ProjectView に `+ApplyStrategy apply_strategy` 残存 | 修正済み（クラス図から削除、project_field_axes / label_axes の表示に変更） | - |
| R3 #2 | 低 | `logical-designs/...logical_design.md`: probe の `--dry-run` が章間で不一致 | 修正済み（コンポーネント詳細・コマンド両セクションに `--dry-run` 明記） | - |
| R4 #1 | 低 | `logical-designs/...logical_design.md`: probe の dry-run 出力契約が二択で曖昧 | 修正済み（probe-evidence.json 共通スキーマ固定、dry_run フラグ + would_create プレースホルダ） | - |
| R5 #1 | 低 | `logical-designs/...logical_design.md`: probe の stdout 契約が章間でまだ不一致 | 修正済み（completed/cleanup-failed/would-run の 3 ケースを章間統一） | - |

合計: 12 件（高 1 / 中 4 / 低 7）/ R6 で 0 件 → completed

## コードレビュー（reviewing-construction-code / codex / 4 rounds）

**反復回数**: 4
**完了条件**: last_round_clean (R4 で 0 件 = completed)
**codex セッション ID**: 019e0f64-0633-7ec3-a685-014af4f7a8cd

| 指摘 # | 重要度 | 内容 | 対応 | バックログ |
|--------|--------|------|------|----------|
| R1 #1 | 高 | `bin/gh-project-cli.sh`: `if ! cmd; then exit $?` で失敗時 $? が 0 化（_load_spec_or_exit / _subcmd_ensure_project） | 修正済み（`cmd \|\| rc=$?; exit $rc` に統一） | - |
| R1 #2 | 高 | `bin/gh-project-cli.sh`: apply 系 (`ensure-fields/views/sync-items`) で `\|\| true` 失敗握りつぶしし `field:created` 等を出力 | 修正済み（`\|\| true` 排除、失敗時 `gh_api_error` で exit 3） | - |
| R1 #3 | 高 | `bin/gh-project-cli.sh`: audit デフォルトモードが strict のまま（設計は soft / CI で strict 明示） | 修正済み（`_MODE_EXPLICIT` フラグ + subcmd==audit ならデフォルト soft） | - |
| R1 #4 | 高 | 全スクリプト (`bin/migrate-issue-524.sh`, `bin/lib/gh-project-repo.sh` 他): エラー JSON details 未エスケープで JSON 注入リスク | 修正済み（全 `_emit_error` を `jq -n --arg ...` 構築に統一、details を素リテラル文字列化） | - |
| R1 #5 | 中 | `bin/probe-github-project.sh`: heredoc 直書き JSON で `project_owner` 等の引数注入リスク | 修正済み（`jq -n --arg/--argjson` で構築、apply / dry-run 両経路） | - |
| R1 #6 | 中 | `bin/audit-github-project.sh`: SLA 30s 判定未実装、`Status==Done` のみで判定 | 修正済み（bash 純正 BASH_REMATCH + date で `closed_at` から経過秒数算出、within_sla / sla_exceeded / unknown 分岐） | - |
| R1 #7 | 低 | 対象 10 スクリプトで `$()` / バッククォート使用が CLAUDE.md ルール違反 | N/A: CLAUDE.md「`$()` 禁止」は Bash ツール実行時のコマンド生成が対象。シェルスクリプト本体は対象外（プロジェクトの check-bash-substitution.sh も skills/aidlc/steps/*.md のみ対象） | - |
| R1 #8 | 低 | 全スクリプト: `IFS` 明示なしで空白含み入力時の単語分割事故リスク | 修正済み（全スクリプトに `IFS=$'\n\t'` を `set -euo pipefail` 直後に追加） | - |
| R2 #1 | 高 | `bin/audit-github-project.sh`: `python3 -c` への `closed_at` 直埋め込み = 任意 Python 実行リスク | 修正済み（python3 依存を排除し bash 純正 BASH_REMATCH + BSD/GNU date で epoch 変換） | - |
| R2 #2 | 高 | `bin/audit-github-project.sh`: SLA 判定が python3 依存、非搭載環境で `Status=Done` でも fail | 修正済み（python3 排除、`Status=Done && sla=unknown` は warn (return 0) 扱い） | - |
| R2 #3 | 中 | `bin/lib/gh-project-repo.sh`: `gh_project_repo_add_field_option` で `\|\| true` 残存 | 修正済み（除去、失敗時 `gh_api_error` で return 3） | - |
| R2 #4 | 中 | `bin/gh-project-cli.sh` / `bin/audit-github-project.sh` / `bin/probe-github-project.sh`: --check / --spec / --probe の値欠落で set -u 異常終了 | 修正済み（`[[ $# -lt 2 ]] \|\| [[ "${2:-}" == --* ]]` で検証、欠落時 args_invalid + exit 1） | - |
| R2 #5 | 低 | `bin/setup-github-project.sh`: エラー出力が JSON エスケープ統一外 | 修正済み（`_emit_error` ヘルパー追加、jq エスケープ統一） | - |
| R3 #1 | 中 | `bin/audit-github-project.sh`: `status:"warn"` で `return 0` のため stdout は `pass` 表示で不整合 | 修正済み（main 部で out から `.{check}.status` 抽出し pass / warn / drift / fail を分岐） | - |
| R3 #2 | 低 | `bin/gh-project-cli.sh`: `_write_runtime_binding` の `dasel put \|\| true` で握りつぶし | 修正済み（失敗時 `evidence_missing` / `runtime_binding_write_failed` で return 5、ensure-project で wb_rc チェック） | - |

合計: 15 件（高 6 / 中 5 / 低 4）/ R4 で 0 件 → completed

## 統合レビュー（reviewing-construction-integration / codex / 1 round）

**反復回数**: 1
**完了条件**: 1R で defer 化承認済み（5R 上限内で OUT_OF_SCOPE 化）

| 指摘 # | 重要度 | 内容 | 対応 | バックログ |
|--------|--------|------|------|----------|
| R1 #1 | 高 | `bin/gh-project-cli.sh`: `sync-items` が Item 追加のみで Status/Priority/Cycle 初期値設定未実装 | 修正済み（最小実装 / B 案ユーザー承認: Status=Backlog のみ実装、Priority/Cycle は別 Issue defer） | - |
| R1 #2 | 中 | `bin/gh-project-cli.sh`, `bin/lib/gh-project-repo.sh`: ensure-fields の options 差分同期未実装 | OUT_OF_SCOPE（B 案ユーザー承認: 初回作成は影響なし、運用時に必要） | #682 |
| R1 #3 | 中 | `bin/tests/gh-project/*.bats`, plan: 副作用テスト網羅不足（setup/migrate/probe/audit の本体動作テスト未整備） | OUT_OF_SCOPE（B 案ユーザー承認: gh API モック整備が必要、別 Unit でフレームワーク + テスト整備） | #683 |
| R1 #4 | 低 | `bin/audit-github-project.sh`, spec.yaml: spec-conformance が field 名のみで views/workflows/manual_actions/cycle_map 未監査 | OUT_OF_SCOPE（B 案ユーザー承認: 拡張機能として後追い） | #684 |

合計: 4 件（高 1 / 中 2 / 低 1）/ #1 修正済 + #2/#3/#4 defer Issue 化（スコープ縮小ユーザー承認済）

### スコープ保護確認（rules-core.md スコープ保護ルール）

統合レビュー指摘 #2/#3/#4 は Intent v2.6.0 「含まれるもの」（Unit 006 責務「Item 一括投入と初期値セット」「冪等性」「テスト整備」）に該当する要件の縮小。`automation_mode=semi_auto` でも常時必須のユーザー確認を AskUserQuestion で実施し、B 案（#1 最小実装 + #2/#3/#4 defer）をユーザー承認済。
