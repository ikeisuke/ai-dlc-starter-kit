# 実装記録: Unit 001 pr-ops 空配列展開 bug 修正

## 実装日時

2026-04-23（計画作成 → 設計 → 実装まで同日完結）

## 作成ファイル

### ソースコード

- `skills/aidlc/scripts/pr-ops.sh`（修正） - L244-L255 周辺の空配列展開を `set -u` 安全化（`closes_list` / `relates_list` を個別ガードしてから `all_list` に追加）

### テスト

- `skills/aidlc/scripts/tests/test_pr_ops_get_related_issues_empty.sh`（新規） - 単体テスト 4 ケース（配列状態 4 形態 A/B/C/D を網羅）
- `skills/aidlc/scripts/tests/test_operations_release_pr_ready_no_related_issues.sh`（新規） - orchestration 回帰テスト 1 ケース（gh スタブで `pr ready` / `pr edit` の各 1 回呼び出しと順序検証）

### 設計ドキュメント

- `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_001_pr_ops_empty_list_fix_domain_model.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_001_pr_ops_empty_list_fix_logical_design.md`

## ビルド結果

成功（bash スクリプトのため明示的なビルドステップなし、構文チェックは bash 実行時に確認）

## テスト結果

成功

| テストファイル | bash 5.3 | bash 3.2.57 | アサーション数 |
|---------------|----------|-------------|--------------|
| test_pr_ops_get_related_issues_empty.sh（新規） | PASS | PASS | 8 |
| test_operations_release_pr_ready_no_related_issues.sh（新規） | PASS | PASS | 7 |
| test_pr_ops_merge_skip_checks.sh（既存） | PASS | - | 21 |
| test_operations_release_merge_pr_empty_args.sh（既存） | PASS | - | 4 |

**合計**: 新規 15 アサーション PASS、既存 25 アサーション PASS（regression なし）

```text
=== pr-ops.sh get-related-issues 空配列展開テスト ===
[Case 1] 形態 A: 関連 Issue 0 件 → PASS x2
[Case 2] 形態 B: closes 1 件のみ → PASS x2
[Case 3] 形態 C: relates 1 件のみ → PASS x2
[Case 4] 形態 D: 複数 Unit / 複数 Issue 混在 → PASS x2
PASS: 8 / FAIL: 0

=== operations-release.sh pr-ready 関連 Issue 0 件 regression テスト ===
[Case 1] 関連 Issue 0 件 + --pr 明示 + --body-file 指定
  PASS: exit 0 完走 / pr ready 出力 / unbound variable 不在
  PASS: get-related-issues 完走
  PASS: gh pr ready 呼び出し回数（厳密 1 回）
  PASS: gh pr edit 呼び出し回数（厳密 1 回）
  PASS: 呼び出し順序（pr ready → pr edit）
PASS: 7 / FAIL: 0
```

注: 既存の test_detect_phase / test_kiro_merge / test_parse_gh_error / test_resolve_remote / test_root_commit_helpers / test_wildcard_detection の 6 本は git stash で本 Unit 修正を退避した状態でも同じ exit code で失敗するため、本 Unit の regression ではない（既存スコープ外の別問題）。

## コードレビュー結果

- [x] セキュリティ: OK（入力エスケープ・サニタイズに変更なし、既存正規表現マッチを維持）
- [x] コーディング規約: OK（既存 L237/L240/L246 の `${#xxx[@]} -gt 0` ガードパターンと完全一貫）
- [x] エラーハンドリング: OK（`set -euo pipefail` を維持、空配列展開の安全化のみ）
- [x] テストカバレッジ: OK（4 形態 A/B/C/D 網羅、orchestration 経路も検証）
- [x] ドキュメント: OK（既存スクリプトコメントを保持、計画/設計と整合）

AI レビュー: codex 2 反復
- 反復 1: P2×1 指摘（回帰テストで gh pr ready / pr edit の呼び出し回数が contains 検証だけで重複検知不能）→ grep -cF + assert_eq '1' で各 1 回を厳密検証、grep -nF で順序検証 (assertion 7) を追加
- 反復 2: 指摘 0 件、auto_approved 適格

## 技術的な決定事項

1. **空ガード形式の採用**: 既存 L237/L240/L246 の `${#xxx[@]} -gt 0` ガードパターンを踏襲し、`closes_list` / `relates_list` を個別ガードしてから `all_list` に追加する形式を採用。インライン形式 `"${arr[@]:-}"` は空文字列要素混入リスクがあるため不採用
2. **bash 互換性検証**: 開発環境 bash 5.3 に加え、macOS `/bin/bash` 3.2.57 でも全テスト実行し pass 確認。bash 4+ 専用構文（`mapfile` / `readarray` / 連想配列等）は不使用
3. **テスト fixture の入力境界**: Unit 定義の標準記法（`- #NNN` / `- #NNN（部分対応）`）のみをサポート対象とし、`Closes #NNN` 等の自由記述は緩い実装上動作するがテスト境界外として扱う
4. **bug の影響範囲再評価**: 修正前は形態 A（両配列空）だけでなく形態 B/C（片方のみ空）でも `unbound variable` で失敗することが codex レビューで判明。本修正は B/C の未顕在化 bug も同時に救済する設計とした
5. **回帰テストの厳密性**: 計画書の「各 1 回ずつ呼ばれる」要件を満たすため、grep -cF で件数検証 + 順序検証を追加

## 課題・改善点

なし（Unit スコープは完了。既存スコープ外の 6 本のテスト失敗は別 Unit / 別サイクルで対応）。

## 状態

**完了**

## 備考

- Issue #588 の解消方法: サイクル PR (#599) マージ時に `Closes #588` で自動 close される（pr-ops.sh get-related-issues が #588 を closes 分類するため、PR 本文に自動付与される）
- 影響範囲は `cmd_get_related_issues` 関数のみ（他のサブコマンド merge / find-draft / ready は変更なし）
- リスクレベル: Low（局所修正、既存スタイル踏襲、bash 3.2 / 5.x 両対応確認済み）
