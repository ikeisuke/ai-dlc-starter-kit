# レビューサマリ: Unit 004 - Operations Phase マージ前 CI 通過確認フローの SoT 化

## 基本情報

- **サイクル**: v2.6.3
- **フェーズ**: Construction
- **対象**: Unit 004 / 設計レビュー（ドメインモデル + 論理設計）

---

## Set 1: 2026-05-16

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex（session id: 019e2e6c-3d15-7f53-8d57-775093942ee4）
- **反復回数**: 4
- **結論**: 指摘0件（Round 4 last_round_clean、unresolved=0、defer=0）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_004_operations_premerge_ci_sot_domain_model.md` - `StructuralCheckResult` を集約に含めつつ不変条件「`exit_code ≠ 0` なら `failed_jobs` 内に `cross_unit_structural` が少なくとも 1 件」が独立事象として矛盾 | 修正済み（domain_model.md `FailedJob` に `source` 属性 (`ci_job` / `structural_check`) を追加、`StructuralCheckResult` の `FailedJob` への変換規則を追記、不変条件を「CI ジョブ起因と構造チェック起因は独立」に書き換え） | - |
| 2 | 高 | `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_004_operations_premerge_ci_sot_domain_model.md`, `.aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_004_operations_premerge_ci_sot_logical_design.md` - `RepairRouter` 優先順位 `B > C > A` で C と B 同時発生時に構造問題を未解決で「解除判断」に流れる危険 | 修正済み（domain_model.md / logical_design.md / `.aidlc/cycles/v2.6.3/plans/unit-004-plan.md` の 3 箇所で優先順位を `C > B > A` に変更、C 検出時の B AskUserQuestion 抑止ガードを明記） | - |
| 3 | 中 | `.aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_004_operations_premerge_ci_sot_logical_design.md` - §7.12.6 と §7.13 の責務境界が相互参照で曖昧化 | 修正済み（logical_design.md / plan.md の両方で §7.12.6 を「取得 + 分類 + ルーティング」に限定し、取得不能時は `ci_check_state=unknown` 明示記録で終了、最終判定権を §7.13 に一本化、依存方向を片方向に固定） | - |
| 4 | 高 | `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_004_operations_premerge_ci_sot_domain_model.md` - `PullRequestCIStatus.failed_jobs` 定義「`check_state=fail` 時のみ非空」が `source=structural_check` 統合後のモデルと矛盾 | 修正済み（domain_model.md: `failed_jobs` を「CI 起因 + structural_check 起因の和」と明記し、`check_state` との対応は `source=ci_job` サブセットに限定。`is_all_pass()` / `is_blocking()` を `source=structural_check` も考慮するよう更新） | - |
| 5 | 中 | `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_004_operations_premerge_ci_sot_domain_model.md` - 不変条件「`source=ci_job` 要素が空 ⇔ `check_state ∈ {pass, none}`」が `pending` / `unknown` を表現しにくく集約状態モデルと不整合 | 修正済み（domain_model.md: 双方向同値を片方向制約に弱め、`check_state=fail ⇒ source=ci_job 1 件以上`、`check_state=pass ⇒ source=ci_job 0 件`、`{pending, none, unknown}` は未定義と明示） | - |
| 6 | 中 | `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_004_operations_premerge_ci_sot_domain_model.md` - `failed_jobs` 属性説明と集約不変条件で `pending/none/unknown` 時の `source=ci_job` 件数表現が不整合 | 修正済み（domain_model.md: 属性側の数量制約を削除し「対応は不変条件で定義」と参照のみ、不変条件側に一本化） | - |

---

## Set 2: 2026-05-16

- **レビュー種別**: コードレビュー（reviewing-construction-code、focus: code + security）
- **使用ツール**: codex（session id: 019e2e78-64c9-7770-bfe8-2fb0a6f92976）
- **反復回数**: 2
- **結論**: 指摘0件（Round 2 last_round_clean、unresolved=0、defer=0）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc/steps/operations/operations-release.md` - §7.12.6.2「命名規約不一致時の代替手順」で `gh pr view --json headRefName` 取得情報と「補助2（HEAD SHA 起点）へ切替」が不整合 | 修正済み（operations-release.md §7.12.6.2: 3 経路 A/B/C に分解。A: `headRefName` → `--branch`、B: `headRefOid` → `--commit`、C: 取得経由せず第一推奨 / 補助1） | - |
| 2 | 低 | `skills/aidlc/steps/operations/operations-release.md` - §7.12.6.4 同 SHA リトライ運用ガードで `gh pr checks --watch` の PR 番号未指定で実行コンテキスト依存 | 修正済み（operations-release.md §7.12.6.4: `gh pr checks <PR番号> --watch` に修正、PR 番号必須を明示） | - |

---

## Set 3: 2026-05-16

- **レビュー種別**: 統合レビュー（reviewing-construction-integration、focus: code / 統合）
- **使用ツール**: codex（session id: 019e2e7a-c68d-7d41-87d0-8002364988e4）
- **反復回数**: 2
- **結論**: 指摘0件（Round 2 last_round_clean、unresolved=0、defer=0）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `.aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_004_operations_premerge_ci_sot_logical_design.md` - line 196 のテーブルセル内 `grep -E '...|...'` の `|` が markdownlint MD056 のセル区切りと衝突 | 修正済み（logical_design.md: テーブルセルを「下記コードブロックのコマンドを実行」に書き換え、`grep` コマンド本体を直後の bash コードブロックに退避。Unit 004 関連 4 ファイルで markdownlint 0 errors 達成） | - |
| 2 | 低 | `.aidlc/cycles/v2.6.3/plans/unit-004-plan.md` - line 114 の「優先順位: B > C > A」が同ファイル内 122 行および設計・実装の「C > B > A」と不整合 | 修正済み（plan.md line 114: 「優先順位: C > B > A（設計レビュー Round 1 指摘 #2 反映）」に修正、全箇所で C > B > A 一貫） | - |

---

