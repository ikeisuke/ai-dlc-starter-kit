# 実装記録: Unit 002 — main-repo-health-check の fixture 誤検出除外（B / #670）

## 実装日時

2026-05-09 開始 〜 2026-05-09 完了（同日内、見積もり 0.3 日）

## 作成ファイル

### ソースコード

- `skills/aidlc/scripts/main-repo-health-check.sh:145` - `check_conflict_marker()` の `git grep` 呼び出しに pathspec `:(exclude)` 2 件を追加（fixture/docs 除外）

### テスト

- `tests/main-repo-health-check.bats` - 冒頭コメント更新 + 受け入れテスト 2 件追加:
  - `@test "exclusion: tests/.bats and design-artifacts paths are not flagged as warning (Unit 002 / #670)"` - 除外 path に conflict marker を含むファイルがあっても warning にならない
  - `@test "warning: conflict marker in non-excluded tracked path is still detected (Unit 002 / #670)"` - 除外対象外 path（`docs/`）に conflict marker を含むファイルを作成すると warning として検出される（除外/非除外混在ケース）

### CI wiring

- `.github/workflows/migration-tests.yml` - PATHS_REGEX に `tests/main-repo-health-check\.bats` および `skills/aidlc/scripts/main-repo-health-check\.sh` を追加、bats 実行行（line 66）末尾に `tests/main-repo-health-check.bats` を追加

### 設計ドキュメント

- `.aidlc/cycles/v2.5.6/design-artifacts/domain-models/unit_002_health_check_fixture_exclusion_domain_model.md`
- `.aidlc/cycles/v2.5.6/design-artifacts/logical-designs/unit_002_health_check_fixture_exclusion_logical_design.md`

### 計画・履歴・レビューサマリ

- `.aidlc/cycles/v2.5.6/plans/unit-002-plan.md`
- `.aidlc/cycles/v2.5.6/history/construction_unit02.md`
- `.aidlc/cycles/v2.5.6/construction/units/002-review-summary.md`

## ビルド結果

成功（bash スクリプト + bats / yaml のため compilation 概念なし）

## テスト結果

成功（bats 7/7 PASS）

- 実行テスト数: 7
- 成功: 7
- 失敗: 0

```text
1..7
ok 1 healthy: clean repo returns exit 0 + status:ok
ok 2 warning: unmerged paths detected returns exit 0 + status:warning
ok 3 warning: MERGE_HEAD exists returns exit 0 + status:warning
ok 4 warning: conflict marker残骸 (v2.5.3 reproduction) returns exit 0 + status:warning
ok 5 system error: invalid git context returns exit 2 + status:error
ok 6 exclusion: tests/.bats and design-artifacts paths are not flagged as warning (Unit 002 / #670)
ok 7 warning: conflict marker in non-excluded tracked path is still detected (Unit 002 / #670)
```

実環境検証（main worktree）:

```text
$ bash skills/aidlc/scripts/main-repo-health-check.sh
health-check:unmerged-paths:ok:count=0
health-check:merge-in-progress:ok:files=none
health-check:conflict-marker:ok:count=0
status:ok
```

v2.5.5 Operations 開始時に観測されていた `conflict-marker:warning:count=12` が `ok:count=0` に解消（fixture 6 件 + docs 6 件の誤検出除外）。

## コードレビュー結果

- [x] セキュリティ: OK（pathspec は文字列リテラル、command injection 余地なし）
- [x] コーディング規約: OK（既存スクリプトの shell スタイルに整合、コメント 1 行追加）
- [x] エラーハンドリング: OK（既存の `grep_ec` 分岐は不変、出力フォーマット維持）
- [x] テストカバレッジ: OK（除外動作 + 非除外検出の双方向テスト追加、既存 5 シナリオ regression なし）
- [x] ドキュメント: OK（ドメインモデル / 論理設計 / 計画 / 履歴 / レビューサマリ完備）

## 技術的な決定事項

- **アーキテクチャパターン**: Filter Pipeline（git native pathspec exclude を活用）。代替案（`git ls-files` 列挙 + 別途 grep）と heredoc 連結 escape は不採用
- **bats fixture 戦略**: `mktemp -d` 等の追加リソース不要、既存 `FIXTURE_REPO=${BATS_TEST_TMPDIR}/fake-main-repo` を再利用。fixture repo 内に `tests/main-repo-health-check.bats` という同名 path を作成する（実 bats ファイル本体とは別物、衝突なし）
- **CI wiring**: 既存 `migration-tests` job への追記方式を採用（重複セットアップ回避 + Required status check 設定への影響回避）。job 名変更は本 Unit 境界外
- **計画段階での仕様改訂**（Round 1 codex 指摘 #1 対応）: 計画当初は「既存 CI で自動的に拾われる」前提で記述したが、サブエージェント検証で `migration-tests.yml` が明示列挙方式と判明したため、Unit スコープに CI wiring 追加を含める形に修正

## 課題・改善点

- 将来 `tests/main-repo-health-check-*.bats` のような派生テストファイルが増えた場合、PATHS_REGEX の wildcard 化を検討する余地あり（本 Unit では現状必要分のみで対応）
- `migration-tests` job 名と実態のズレ（migration 以外も実行）は本サイクル内では許容、将来サイクルで命名見直しを検討する場合は別 Unit で対応

## 状態

**完了**

## 備考

- AI レビュー結果（4 種類）の累計:
  - 計画レビュー: 2R（1R 指摘 2 件 → 2R 0 件で完了）
  - 設計レビュー: 1R（1R clean 特例）
  - コードレビュー: 2R（1R 指摘 1 件 → 2R 0 件で完了）
  - 統合レビュー: 1R（1R clean 特例 + 自己検証 PASS）
- defer 化指摘: 0 件（バックログ Issue 起票なし）
- Codex セッション ID: `019e0a7a-222b-73f3-90d8-a81abc7c680f`（全 4 レビュー同セッション継続）
