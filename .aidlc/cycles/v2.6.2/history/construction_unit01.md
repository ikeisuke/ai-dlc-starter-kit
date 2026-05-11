# Construction Phase 履歴: Unit 01

## 2026-05-11T09:03:48+09:00

- **フェーズ**: Construction Phase
- **Unit**: 01-fix-pr-ready-empty-body（pr-ready --body-file 空ファイル検証で PR 本文 null 上書き事故防止）
- **ステップ**: Unit完了
- **実行内容**: ## Unit 完了

Issue #678（pr-ready --body-file が空ファイル時に PR 本文が null に上書きされる事故）に対する案 A + 案 B 必須対応を完了。

### 主な変更

1. **検証ヘルパー追加**: `skills/aidlc/scripts/operations-release.sh` に単一 SoT 検証ヘルパー `_pr_ready_validate_body_file()` を追加。bash 組み込み `[[ -f ]]` / `[[ -s ]]` のみで「Missing（不在 or 非 regular file）/ Empty（0 バイト）/ Valid」を判定し、外部コマンド呼び出しおよびコマンド置換 `$(...)` を伴わない。
2. **Primary 経路（cmd_pr_ready）**: 引数パース直後・cycle 解決前に検証呼び出しを挿入し、`--body-file` 不正時は get-related-issues / find-draft / gh pr edit に到達する前に fail-fast。
3. **Fallback 経路（gh_pr_edit_body_with_fallback）**: 関数冒頭で再検証し、`gh pr edit` / `gh api PATCH` を発火させない二重防御。
4. **機械可読エラー出力**: tab 区切り 3 フィールド（`error<TAB><code><TAB><path>`）を stderr に出力。コードは `pr-ready:body-file-missing` / `pr-ready:body-file-empty`。Empty 時のみ人間可読の案内行を追加。ファイル内容は出力しない（情報リーク防止）。
5. **bats テスト追加**:
   - 新規 `tests/operations-release-pr-ready-body-validate.bats`（9 ケース / validator 単体 + cmd_pr_ready Primary 経路）
   - 既存 `tests/operations-release-pr-edit-fallback.bats` にケース 6-8 追加（fallback 経路の二重防御）
   - `gh` shim 呼び出し回数 = 0 のアサート（GH_MOCK_CALL_LOG 機構）で外部副作用ゼロを明示検証
6. **CI 連携**: `.github/workflows/migration-tests.yml` の PATHS_REGEX と bats 実行リストに 2 ファイルを追加。

### AI レビュー実施

- 計画レビュー（codex）: 中 2 件 → 共通ヘルパー必須化 / shim 呼び出し回数アサート追加で反映
- 設計レビュー（codex）: 高 1 + 中 2 件 → regular file 判定（[[ -f ]] 必須化）/ phase 引数削除 / [[ -e ]]+[[ -f ]]+[[ -s ]] 一本化で反映、再レビュー 0 件
- コードレビュー（codex）: 中 1 + 低 1 件 → 検証呼び出しを while ループ直後（cycle 解決前）に移動。低 1 件（bats ケース未追加）は次ステップで対応
- 統合レビュー（codex）: 0 件

### 検証結果

- bats: 17 件全 pass（既存 5 ケース回帰なし + 新規 12 ケース）
- shellcheck: 既存 SC2034 のみ、追加分は新規指摘なし
- markdownlint: 0 error

### 関連 Issue

- #678（致命的バグ / mirror 由来 feedback）

### 成果物

- `.aidlc/cycles/v2.6.2/plans/unit-001-plan.md`
- `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_001_fix_pr_ready_empty_body_domain_model.md`
- `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_001_fix_pr_ready_empty_body_logical_design.md`
- `skills/aidlc/scripts/operations-release.sh`（変更）
- `tests/fixtures/gh-pr-edit-fallback/gh`（変更）
- `tests/operations-release-pr-edit-fallback.bats`（変更）
- `tests/operations-release-pr-ready-body-validate.bats`（新規）
- `.github/workflows/migration-tests.yml`（変更）

---
