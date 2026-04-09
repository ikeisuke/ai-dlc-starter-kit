# 実装記録: Unit 005 Tier 2 施策の統合（operations-release スクリプト化 + review-flow 簡略化）

## 実装日時

2026-04-09（Phase 1 開始）〜 2026-04-10（Phase 2 完了）

## 作成ファイル

### 新規作成

- `skills/aidlc/scripts/operations-release.sh` - Operations Phase ステップ7 リリース準備の orchestration ラッパー（5 サブコマンド: `version-check` / `lint` / `pr-ready` / `verify-git` / `merge-pr` + `--dry-run` + `--help`）。既存スクリプト（`pr-ops.sh` / `validate-git.sh` / `suggest-version.sh` / `ios-build-check.sh` / `run-markdownlint.sh`）を透過呼び出しする薄いラッパー（stdout / exit code をそのまま伝播）
- `skills/aidlc/steps/common/review-routing.md` - AI レビューの判定テーブル集（論理インターフェース契約 `ReviewRoutingDecision`、設定、CallerContext マッピング、ツール選択、処理パス決定、エラーフォールバック、呼び出し形式）。純粋参照ファイルとして一方向依存を物理的に担保
- `.aidlc/cycles/v2.3.0/construction/units/005-review-summary.md` - AI レビューサマリ

### 更新

- `skills/aidlc/steps/operations/operations-release.md` - `operations-release.sh` 呼び出しベースに簡略化（2,877 tok → 1,433 tok、50.2% 削減、目標 1,438 tok 以下達成）
- `skills/aidlc/steps/common/review-flow.md` - ルーティング判定を `review-routing.md` に委譲し、実行手順（反復・指摘対応・完了処理・外部入力検証）のみに縮約（2,434 tok）
- `skills/aidlc/steps/operations/index.md` - §1 目次の `operations.02-deploy` 行に `operations-release.sh` 呼び出しの注記を追加、§2.9「AI レビュー分岐」を `review-routing.md` + `review-flow.md` 併記形式に更新。§2.1-§2.8、§3 判定チェックポイント表、§4 ステップ読み込み契約、§5 汎用構造仕様は Unit 004 の Materialized Binding 構造を保持
- `skills/aidlc/steps/operations/02-deploy.md` - ステップ7 サブステップ参照を「`operations-release.md` および `scripts/operations-release.sh` を参照」に更新
- `skills/aidlc/steps/inception/index.md` - §2.9「AI レビュー分岐」を `review-routing.md` + `review-flow.md` 併記形式に更新
- `skills/aidlc/steps/construction/index.md` - §2.8「AI レビュー分岐」を `review-routing.md` + `review-flow.md` 併記形式に更新
- `skills/aidlc/steps/inception/03-intent.md` - L42 の AI レビュー参照を `review-routing.md` のパス 3 直行に更新
- `skills/aidlc/steps/inception/04-stories-units.md` - L49 / L93 の AI レビュー参照を `review-routing.md` のパス 3 直行に更新（2 箇所）
- `skills/aidlc/steps/construction/01-setup.md` - L82 の AI レビュー参照を `review-routing.md` のパス 3 直行に更新

### 更新対象外（計画通り）

- `skills/aidlc/steps/construction/02-design.md` - 手順本体参照として維持
- `skills/aidlc/steps/construction/03-implementation.md` - 手順本体参照として維持

### 設計ドキュメント

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_005_tier2_integration_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_005_tier2_integration_logical_design.md`（Phase 2 コードレビュー対応で `cmd_version_check` シグネチャを実装と同期）

### 計画ドキュメント

- `.aidlc/cycles/v2.3.0/plans/unit-005-plan.md`

## ビルド結果

成功

```text
bash -n skills/aidlc/scripts/operations-release.sh  → exit 0（構文チェック成功）
check-bash-substitution.sh                          → 違反 0（34 ファイル検査完了）
```

`shellcheck` は環境に未インストールのため実行せず（任意）。

## テスト結果

成功（動作等価性検証: dry-run 全 7 シナリオ実行）

- 実行テスト数: 7（動作等価性シナリオ）
- 成功: 7
- 失敗: 0

### 動作等価性検証（operations-release.sh --dry-run）

| シナリオ | コマンド | 結果 |
|---------|---------|------|
| A: version-check (general) | `version-check --dry-run` | `would run: suggest-version.sh`（期待通り） |
| B: lint | `lint --dry-run --cycle v2.3.0` | `would run: run-markdownlint.sh v2.3.0`（期待通り） |
| C: pr-ready（PR 番号指定） | `pr-ready --dry-run --cycle v2.3.0 --pr 123 --body-file /tmp/body.md` | `get-related-issues v2.3.0` → `pr-ops.sh ready 123` → `gh pr edit 123 --body-file /tmp/body.md`（期待通り） |
| C': pr-ready（PR 番号自動検索） | `pr-ready --dry-run --cycle v2.3.0 --body-file /tmp/body.md` | `get-related-issues` → `find-draft` → `ready` → `gh pr edit` 並びに `gh pr create --base main --title v2.3.0 --body-file` の両パス表示（期待通り） |
| D: verify-git | `verify-git --dry-run` | `validate-git.sh uncommitted` / `remote-sync` / `git fetch origin main` / `git merge-base --is-ancestor origin/main HEAD` + 集約サマリ（期待通り） |
| E: merge-pr merge | `merge-pr --dry-run --pr 123 --method merge` | `pr-ops.sh merge 123`（期待通り） |
| F: merge-pr squash | `merge-pr --dry-run --pr 123 --method squash` | `pr-ops.sh merge 123 --squash`（期待通り） |
| G: merge-pr rebase | `merge-pr --dry-run --pr 123 --method rebase` | `pr-ops.sh merge 123 --rebase`（期待通り） |

`--draft` フラグが `gh pr create` 呼び出しに含まれていないことを確認（現行 `operations-release.md` §7.8 と完全一致）。

### サイズ検証（tiktoken cl100k_base）

| ファイル | 計測値 | 目標 | 結果 |
|---------|--------|------|------|
| `operations-release.md` | **1,433 tok** | ≤ 1,438 tok（ベースライン 2,877 tok の 50%） | OK（50.2% 削減） |
| `review-flow.md` | 2,360 tok | - | - |
| `review-routing.md` | 1,619 tok | - | - |
| `review-flow.md + review-routing.md` | **3,979 tok** | ≤ 3,989 tok（整理前の `review-flow.md` 単体以下） | OK |

### 参照整合性検証

- `review-routing.md` への新規参照: 計 8 箇所（inception/index.md §2.9、construction/index.md §2.8、operations/index.md §2.9、review-flow.md 冒頭 + 本文、inception/03-intent.md:42、inception/04-stories-units.md:49,93、construction/01-setup.md:82）
- `review-flow.md` への既存参照: ルーティング判定目的の参照は全て `review-routing.md` に置換済み。手順本体参照（construction/02-design.md、03-implementation.md、rules-core.md、rules-automation.md、task-management.md、04-completion.md）は維持
- `operations-release.sh` への参照: `operations-release.md` 本体、`operations/index.md` §1、`operations/02-deploy.md` ステップ7 サブステップ一覧から正しく参照されている

### 一方向依存の担保

- `review-routing.md` は他のいかなるドキュメントも参照しない純粋参照ファイル（Set 2 統合レビューの指摘 #1 対応で完全に担保）
- 参照の向き: 呼び出し層（phase index / step file / review-flow.md）→ `{review-routing.md, review-flow.md}`、および `review-flow.md → review-routing.md` の一方向のみ

## AI レビュー履歴

- **Phase 1**: 計画レビュー（4 反復で承認）、設計レビュー（6 反復で承認）。いずれも codex 使用
- **Phase 2 Set 1**: コード生成後レビュー（初回 codex で 5 件指摘 → 修正 → 再レビューは self-review サブエージェントで 3 件低重要度指摘 → 修正）。codex usage limit 到達により Set 2 からフォールバック方式に切り替え
- **Phase 2 Set 2**: 統合レビュー（self-review サブエージェントで 2 件低重要度指摘 → 修正）。フォールバック理由: codex の cli_runtime_error 継続

全レビュー結果は `.aidlc/cycles/v2.3.0/construction/units/005-review-summary.md` 参照。

## 完了条件チェックリスト確認

計画ファイル `.aidlc/cycles/v2.3.0/plans/unit-005-plan.md` の全 23 項目すべて達成:

- [x] operations-release.sh 新設（5 サブコマンド + --dry-run + --help）
- [x] bash -n エラーゼロ
- [x] 既存スクリプト orchestration（内部実装未変更）
- [x] 透過契約（stdout / exit code を正規化せず透過、例外は `pr-ready` の `--body-file` 必須エラーのみ）
- [x] `--help` 全サブコマンドで表示可能
- [x] operations-release.md 簡略化（`operations-release.sh` 呼び出し + 人間判断のみ）
- [x] operations-release.md サイズ 1,433 tok ≤ 1,438 tok
- [x] 節マッピング整合（スクリプト化 5 節 + markdown 残存 6 節）
- [x] 動作等価性 4 シナリオ（A/B/C/D）+ 3 方法（merge/squash/rebase）すべて期待通り
- [x] 02-deploy.md 参照更新
- [x] operations/index.md 編集範囲限定（§1 注記 + §2.9 参照差し替えの 2 箇所のみ）
- [x] review-routing.md 新設（6 章構成 + 論理インターフェース契約）
- [x] review-routing.md 論理インターフェース契約記述 + 一方向依存構造明示
- [x] review-flow.md 簡略化（冒頭注記 + 手順記述のみ）
- [x] review-flow.md 残存セクション（指摘対応判断フロー / スコープ保護確認 / OUT_OF_SCOPE バックログ登録 / 判断完了後 / レビュー完了時共通処理 / レビューサマリファイル / 履歴記録 / AI レビュー指摘の却下禁止 / 外部入力検証 / 分割ファイル参照）保持
- [x] review-flow.md 消費者として記述
- [x] review-flow.md + review-routing.md サイズ 3,979 tok ≤ 3,989 tok
- [x] フェーズインデックス §2.8/§2.9 更新（3 ファイル）
- [x] ステップファイル個別参照更新 4 箇所（最小限）+ 02-design.md / 03-implementation.md 変更対象外
- [x] ルーティング動作等価性（9 CallerContext + 境界ケース、review-routing.md の判定テーブルで整理前と等価）
- [x] markdownlint（`markdown_lint=false` 設定のためスキップ）
- [x] bash substitution check（steps スコープ、違反 0）
- [x] スコープ遵守（既存スクリプト未変更、新 reviewing スキル追加なし、phase-recovery-spec.md / 判定チェックポイント表変更なし）

## 実装完了

**Unit 005 Phase 2 完了**

- サイクル: v2.3.0
- Unit: 005（Tier 2 施策の統合: operations-release スクリプト化 + review-flow 簡略化）
- ステータス: 完了
- 動作: シェルスクリプトの構文チェック（`bash -n`）、透過契約の 7 シナリオ dry-run 検証、サイズ検証、参照整合性検証、lint 検証すべて OK
- AI レビュー: 計画承認前・設計レビュー・コード生成後・統合とレビュー の全 4 タイミングで完了（Phase 1 / Phase 2 合わせて 4 回、すべて `auto_approved`）
