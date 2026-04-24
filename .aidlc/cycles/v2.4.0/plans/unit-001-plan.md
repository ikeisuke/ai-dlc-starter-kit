# Unit 001 計画: pr-ops.sh の空配列展開 bug 修正

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/001-pr-ops-empty-list-fix.md`
- **担当ストーリー**: ストーリー 7（pr-ready の closes_list 空配列 bug 修正）
- **関連 Issue**: #588（[Bug] pr-ready が関連Issueなしの場合に closes_list の空配列で失敗する）
- **依存 Unit**: なし
- **見積もり**: 0.5〜1 時間
- **実装優先度**: High

## 課題と修正方針

### 課題

`skills/aidlc/scripts/pr-ops.sh` の `cmd_get_related_issues` 関数（L207-L253）において、関連 Issue がない場合に L245 の `local -a all_list=("${closes_list[@]}" "${relates_list[@]}")` で `set -u` 環境下の空配列展開が `unbound variable` エラーを起こす。

bash 4.4 未満（macOS 標準 bash 3.2 含む）では、宣言済み空配列の `"${arr[@]}"` 展開が未定義変数として扱われる。

### 修正方針

L245 の空配列展開を `set -u` 安全化する。選択肢:

1. **インライン形式**: `local -a all_list=("${closes_list[@]:-}" "${relates_list[@]:-}")` — 簡潔だが空配列時に空文字列要素が混入
2. **ガード形式**: 各 list を個別にガードしてから結合 — 既存パターン（L237/L240/L246 で `${#xxx[@]} -gt 0` を既に使用）と一貫
3. **空ガード優先**: `local -a all_list=(); [[ ${#closes_list[@]} -gt 0 ]] && all_list+=("${closes_list[@]}"); [[ ${#relates_list[@]} -gt 0 ]] && all_list+=("${relates_list[@]}")` — 空要素混入なし、既存スタイル踏襲

**採用方針**: 選択肢 3（空ガード優先）。理由:

- 既存コード L237/L240/L246 で `${#xxx[@]} -gt 0` ガードパターンが一貫採用されている
- 選択肢 1 は空文字列要素が `sort -u | tr '\n' ','` で空エントリとして残る可能性があり副作用リスクがある
- bash 3.2 / 4.x / 5.x すべてで動作する

### 変更箇所

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `skills/aidlc/scripts/pr-ops.sh` | L245-L248 | `all_list` の構築を空ガード形式に変更 |

### 追加テスト

#### 単体テスト: `skills/aidlc/scripts/tests/test_pr_ops_get_related_issues_empty.sh`（新規）

- ケース1: Unit 定義に関連 Issue 0 件 → `issues:none / closes:none / relates:none` を出力し exit 0
- ケース2: Unit 定義の「## 関連Issue」セクションに `- #123` 1 件 → `issues:#123 / closes:#123 / relates:none`
- ケース3: Unit 定義に `- #456（部分対応）` 1 件 → `issues:#456 / closes:none / relates:#456`
- ケース4: 複数 Unit / 複数 Issue 混在（重複・部分対応混在）→ 重複除去・ソート確認

**入力境界**: テスト fixture の Unit 定義は実際の `001-pr-ops-empty-list-fix.md:46-48` で使用されている記法（`- #NNN` または `- #NNN（部分対応）`）に統一する。`Closes #NNN` 等の PR 本文記法は本関数の入力境界外（`pr-ops.sh:227-231` の正規表現は `\#([0-9]+)` のみマッチする緩い実装だが、Unit 定義テストでは標準記法に絞る）。

#### 回帰テスト: `skills/aidlc/scripts/tests/test_operations_release_pr_ready_no_related_issues.sh`（新規、Codex P1 対応）

orchestration 経由（`operations-release.sh pr-ready`）が関連 Issue 0 件サイクルでも `exit 0` で完走し、PR 本文更新まで実行されることを自動検証。`gh` をスタブ化（`test_operations_release_merge_pr_empty_args.sh:22-33` のスタブパターンに倣う）し、スタブ内で呼び出し履歴を記録ファイルに追記する形で検証する:

- pre-condition: 関連 Issue 0 件の Unit 定義のみを含むサイクル fixture を一時 dir に作成、PR 本文ファイル（一時 tmpfile）も用意
- 実行: `operations-release.sh pr-ready --cycle <cycle> --pr <number> --body-file <tmpfile>`（`pr-ops.sh` 実体 + `gh` スタブ）
- 期待:
  - exit code 0
  - stdout に `pr:<number>:ready` が含まれる
  - `unbound variable` エラーが出ない
  - **`gh` スタブの呼び出し履歴に `pr ready <number>` と `pr edit <number> --body-file <tmpfile>` が各 1 回ずつ記録される**（PR Ready 化と本文更新の両経路を検証）

注: 実際の `operations-release.sh pr-ready` の引数体系・呼び出しフローは実装フェーズで確認し、必要に応じてテスト手順を `operations-release.sh` の実装に合わせて調整する。

既存テスト `test_pr_ops_merge_skip_checks.sh` のスタイル（一時 dir + assert ヘルパー + counter）に倣う。

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [ ] `skills/aidlc/scripts/pr-ops.sh:216-245` 周辺の Bash 配列展開が `set -u` 環境で安全化されている（`closes_list[@]` / `relates_list[@]` の空配列展開で `unbound variable` を出さない）
- [ ] 関連 Issue 0 件 / 1 件 / 複数件の各ケースで期待出力（`issues:` / `closes:` / `relates:` 行）が正しく出る
- [ ] 空配列ケースの fixture テストが `skills/aidlc/scripts/tests/` 配下に追加されている

### Issue #588 受け入れ基準由来

- [ ] 関連 Issue がない場合に `pr-ops.sh get-related-issues <cycle>` が `issues:none / closes:none / relates:none` を出力し exit 0 で終了する（単体テストで自動検証）
- [ ] `operations-release.sh pr-ready` 経由で関連 Issue 0 件のサイクルでも PR Ready 化と PR 本文更新が完結する（手動 `gh pr ready` / `gh pr edit` 回避策が不要になる）— **`gh` スタブ化した orchestration 回帰テスト `test_operations_release_pr_ready_no_related_issues.sh` で自動検証**

### 境界（Unit 定義「境界」由来）

- [ ] `set -euo pipefail` 自体は解除しない（配列展開側のみで対処）
- [ ] `gh pr ready` / `gh pr edit` の置換ロジック自体は変更しない
- [ ] 他の `pr-ops.sh` 関数や `operations-release.sh` の変更を含まない

### 非機能要件（NFR）由来

- [ ] bash 3.2+（macOS 標準）/ GNU bash（Linux）両対応の構文を使用している（`"${arr[@]:-}"` / `${#arr[@]}` のみ使用、bash 4+ 専用構文不使用）
- [ ] **macOS `/bin/bash`（3.2.57）で新規テストを実行し pass する**（実機 3.2 互換性検証）
- [ ] 既存テスト（`test_pr_ops_merge_skip_checks.sh` 等）が引き続き通る
- [ ] スクリプト処理時間に有意な悪化がない

## 設計フェーズ計画

`depth_level=standard` のため Phase 1（設計）を実施。本 Unit は「単一関数の bash 配列展開ガード追加 + 単体テスト + 回帰テスト追加」という局所的な修正のため、設計成果物は最小粒度に絞る:

- ドメインモデル: `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_001_pr_ops_empty_list_fix_domain_model.md`
  - 内容: `cmd_get_related_issues` のドメイン責務（Unit 定義 → Issue 番号集合の純粋関数）と入力境界（`#NNN` / `#NNN（部分対応）` 記法）の明文化のみ。詳細フローは省略
- 論理設計: `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_001_pr_ops_empty_list_fix_logical_design.md`
  - 内容: `closes_list` / `relates_list` / `all_list` の 3 配列の状態遷移表（両配列空 / 片側空 / 両側非空）と、各状態での出力期待値の対応表
  - シーケンス図・状態遷移図等は省略（局所修正のため過剰）

## 実装フェーズ計画

1. `pr-ops.sh:245-248` の空ガード形式への置換
2. 単体テストファイル `test_pr_ops_get_related_issues_empty.sh` 新規作成（4 ケース）
3. 回帰テストファイル `test_operations_release_pr_ready_no_related_issues.sh` 新規作成（orchestration 経由検証）
4. 新規テスト実行:
   - `bash skills/aidlc/scripts/tests/test_pr_ops_get_related_issues_empty.sh`
   - `bash skills/aidlc/scripts/tests/test_operations_release_pr_ready_no_related_issues.sh`
5. 既存関連テストの regression 確認（集約スクリプトは存在しないため個別実行）:
   - `bash skills/aidlc/scripts/tests/test_pr_ops_merge_skip_checks.sh`
   - `bash skills/aidlc/scripts/tests/test_operations_release_merge_pr_empty_args.sh`
   - 余裕があれば `for f in skills/aidlc/scripts/tests/test_*.sh; do bash "$f" || echo "FAIL: $f"; done` で全テストを順次実行
6. **bash 3.2 実機互換性検証**: macOS `/bin/bash`（3.2.57）で新規テスト 2 本を実行:
   - `/bin/bash skills/aidlc/scripts/tests/test_pr_ops_get_related_issues_empty.sh`
   - `/bin/bash skills/aidlc/scripts/tests/test_operations_release_pr_ready_no_related_issues.sh`
7. 手動シナリオ検証: 関連 Issue 0 件の Unit 定義ファイルで `pr-ops.sh get-related-issues` を実行し期待出力を確認

## 完了処理計画

1. Unit 定義ファイル `001-pr-ops-empty-list-fix.md` の「実装状態」を「完了」（状態・完了日・担当・適格性）に更新
2. `.aidlc/cycles/v2.4.0/history/construction_unit01.md` への履歴追記（`/write-history` スキル経由）
3. `construction/progress.md` の以下 3 セクションを一貫更新:
   - Unit 一覧テーブル: Unit 001 行の「状態」を「完了」、「完了日」を記入
   - 「現在の Unit」セクション: Unit 001 完了 → 次の実行可能 Unit（Unit 002 / 004 / 005 / 006）の自動選択候補へ更新
   - 「完了済み Unit」セクション: Unit 001 を追記
4. squash 統合（`/aidlc:squash-unit cycle=v2.4.0 unit=001`）
5. PR #599 へのコミット push（Unit ブランチは無効: `unit_branch_enabled=false` のためサイクルブランチへ直接コミット）
6. Issue #588 ステータス更新方針: **サイクル PR マージ時に `Closes #588` で自動 close** とする（`pr-ops.sh get-related-issues` が #588 を `closes` に分類するため、PR 本文に自動付与される）。Unit 完了時点では Issue ステータスを変更しない

## リスク・注意事項

- **配列 3 形態の出力安定性**: `closes_list` / `relates_list` の組み合わせで「両配列空 / 片側のみ空 / 両側非空」の 3 形態が存在。既存出力契約（`issues:<csv>` の重複除去・ソート、`closes:none` / `relates:none` フォールバック）を壊さないことを論理設計で表形式で明示し、テスト 4 ケースで全パターンをカバーする
- **`issues:` 後方互換**: L244-L248 は `closes_list + relates_list` の重複除去後 csv を `issues:` 行として出力する後方互換ロジック。修正後も同 csv の内容が変化しないこと（特にソート順）を確認
- **bash 互換性検証方針**: 開発環境は GNU bash 5.3 だが、本番では macOS 標準 bash 3.2 で実行される可能性がある。修正は既存コード L237/L240/L246 と同一の `${#arr[@]} -gt 0` ガード形式を踏襲し、bash 4+ 専用構文を導入しない。**実機 3.2 検証は macOS の `/bin/bash`（3.2.57）で新規テスト 2 本を実行することで担保する**（実装フェーズ計画ステップ 6 参照）
- `cmd_get_related_issues` は他のサブコマンド（merge / find-draft 等）に副作用を持たない純粋関数なので、本修正での回帰リスクは限定的
- テストファイル名は既存の `test_pr_ops_*.sh` / `test_operations_release_*.sh` 命名規約に合わせる
