# ドメインモデル: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加

## 概要

`scripts/operations-release.sh pr-ready` における PR 本文更新オペレーションのドメイン。`gh pr edit --body-file` がトークンスコープ不足（`read:org` / `read:discussion` / GraphQL field error 等）で失敗する事象を観測・分類し、REST PATCH 直叩きで回避する fallback 経路を提供する責務を扱う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2 で行います。

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| PR 本文更新オペレーション | Operations 7.8 で `pr-ready` サブコマンドが `gh pr edit <PR> --body-file <PATH>` を呼び出す処理 |
| gh CLI 経路 | `gh pr edit --body-file` を直接呼び出す経路（通常パス） |
| REST PATCH 経路 | `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` を呼び出す経路（fallback パス） |
| スコープ不足エラー | gh CLI の内部 GraphQL クエリが `read:org` / `read:discussion` 等のトークンスコープ不足で失敗する現象 |
| 非スコープエラー | スコープ不足以外の失敗（ネットワークエラー / API rate limit / PR 不在 等）。fallback 対象外 |
| エラー判別 grep パターン | gh CLI 経路の stderr から「スコープ不足」を検出する正規表現集合 |
| fallback 発動シグナル | fallback 経路の実行を観測者に伝える stderr メッセージ（`pr-ready:fallback:rest-patch:<pr_number>`） |
| 二段階失敗 | gh CLI 経路で失敗 → REST PATCH 経路でも失敗の連鎖（DR-003 補足観測対象） |
| 二段階失敗ログキー | 二段階失敗時に追加出力する観測点（`pr-ready:fallback:rest-patch:failed:<pr_number>:<exit_code>`） |
| ヘルパー関数 | `gh_pr_edit_body_with_fallback` の関数名。2 引数受付（`$1` PR 番号 / `$2` body_file パス）+ 内部で 2 経路（gh CLI → REST PATCH）を順次試行 |

## 値オブジェクト（Value Object）

### PRBodyUpdateRequest

- **属性**:
  - `pr_number: String` — 対象 PR 番号（既存の `$pr_number` / `$existing_pr_number` 変数。非負整数の文字列だが本ヘルパー関数では型検証しない）
  - `body_file: String` — 本文ファイルパス（既存の `$body_file` 変数。存在性は本ヘルパー関数では検証しない）
- **前提条件（caller 側責務）**: `pr_number` が gh CLI で受理可能な PR 番号であり、`body_file` がローカルに存在する。本ヘルパー関数は両条件の検証を行わず、不正値は元の `gh pr edit` の挙動（PR 番号不正 / ファイル不在エラー）に委譲する（後方互換性維持のため、既存呼び出しサイトの `cmd_pr_ready` 関数が責任を持つ）
- **不変性**: 1 リクエスト処理中に変化しない

### GhCliExitResult

- **属性**:
  - `exit_code: Integer` — `gh pr edit` の終了コード
  - `stderr: String` — `gh pr edit` の標準エラー出力全体
- **不変性**: 同一コマンド実行で取得した結果は不変
- **判定対象性**: `exit_code != 0` かつ `stderr` が「エラー判別 grep パターン」のいずれかを含む場合のみ fallback 対象

### ScopeInsufficientPatternSet

- **属性**: `patterns: List<Regex>` — 以下 4 パターン固定
  - `read:org`
  - `read:discussion`
  - `Could not resolve to a User`
  - `requires.*scope`
- **不変性**: 本 Unit 完了時点で固定。新パターン追加は将来 Issue で扱う（OUT_OF_SCOPE）
- **マッチ判定**: `grep -qE "<pattern1>|<pattern2>|<pattern3>|<pattern4>"` 形式の OR 結合
- **fixture 更新トリガー（DR-001）**: gh CLI バージョン更新でエラー文言が変化した場合、bats fixture が失敗することで気付ける運用ルールを履歴に記録

### ErrorClassification

- **属性**: `kind: Enum { scope_insufficient, other_error }`
- **判定規則**:

  | GhCliExitResult | 判定条件 | ErrorClassification |
  |-----------------|---------|--------------------|
  | `exit_code == 0` | - | （成功・分類対象外） |
  | `exit_code != 0` ∧ stderr が `ScopeInsufficientPatternSet` のいずれかにマッチ | grep 1 件以上 hit | `scope_insufficient` |
  | `exit_code != 0` ∧ stderr が `ScopeInsufficientPatternSet` にマッチしない | grep 0 件 | `other_error` |

- **不変性**: 同一 `(stderr, exit_code)` 入力に対して同一結果（純粋関数）
- **不変条件**: `other_error` は **絶対に fallback 経路で握り潰さない**（後方互換テストで保証）

### FallbackOutcome

- **属性**:
  - `case: Enum { gh_cli_success, fallback_success, fallback_failed, non_recoverable }`
  - `final_exit_code: Integer`
- **構造規則**:

  | case | 経路 | 観測点（stderr） | final_exit_code |
  |------|------|----------------|-----------------|
  | `gh_cli_success` | gh CLI のみ | （なし） | 0 |
  | `fallback_success` | gh CLI 失敗 → REST PATCH 成功 | `pr-ready:fallback:rest-patch:<pr>` | 0 |
  | `fallback_failed` | gh CLI 失敗 → REST PATCH も失敗（DR-003） | `pr-ready:fallback:rest-patch:<pr>` + `pr-ready:fallback:rest-patch:failed:<pr>:<exit>` | REST PATCH の exit code |
  | `non_recoverable` | gh CLI が non-scope エラーで失敗 | gh CLI の元 stderr 透過 | gh CLI の exit code |

- **不変性**: 観測点ログキーの直列出現順序（fallback 発動 → 失敗）は固定

## ドメインサービス

### ScopeErrorDetector

- **責務**: `GhCliExitResult` を入力に `ErrorClassification` を判定する
- **操作**: `classify(result: GhCliExitResult) -> ErrorClassification`
- **実装契約**: `ScopeInsufficientPatternSet` を `grep -qE` で評価。grep が exit 0（マッチ）なら `scope_insufficient`、それ以外なら `other_error`
- **冪等性**: 純粋関数（同一入力 → 同一出力）

### RestPatchExecutor

- **責務**: REST PATCH 経路を実行し、`GhCliExitResult` 相当の結果を返す
- **操作**: `execute(req: PRBodyUpdateRequest) -> GhCliExitResult`
- **実装契約**: `gh api -X PATCH /repos/{owner}/{repo}/pulls/${pr_number} -F body=@${body_file}` を実行。`{owner}/{repo}` は `gh api` が自動補完するため明示解決は不要
- **エラー条件**: REST PATCH も失敗した場合は exit code を保持して返す（fallback_failed への遷移）

### PrBodyUpdateOrchestrator（= ヘルパー関数 `gh_pr_edit_body_with_fallback`）

- **責務**: PRBodyUpdateRequest を受け取り、以下のフローで `FallbackOutcome` を決定する
  1. gh CLI 経路を実行 → `GhCliExitResult`
  2. exit_code == 0 なら `gh_cli_success` で終了
  3. `ScopeErrorDetector.classify(result)` を呼び分類
  4. `scope_insufficient` なら `pr-ready:fallback:rest-patch:<pr>` を stderr 出力 → `RestPatchExecutor.execute(req)` 実行
     - 成功 → `fallback_success`
     - 失敗 → `pr-ready:fallback:rest-patch:failed:<pr>:<exit>` を stderr 出力 → `fallback_failed`
  5. `other_error` なら gh CLI の stderr を透過し `non_recoverable`
- **操作**: `update(req: PRBodyUpdateRequest) -> FallbackOutcome`
- **冪等性**: 副作用は `gh` / `gh api` 呼び出しに外部化。同一 PR・同一 body_file での再実行は GitHub 側の冪等性に依存
- **後方互換契約**: `other_error` 経路は既存挙動を完全に維持（fallback で握り潰さない）。後方互換性 bats テストで保証

### dry-run モードでの振る舞い

- **責務**: `DRY_RUN=1` 時は実際の `gh` / `gh api` を呼び出さず、`log_dry_run` 経由で「fallback 候補」コメントを含む 2 経路を出力する
- **fallback 経路の dry-run 表記**: `# fallback (when scope-insufficient): gh api -X PATCH /repos/{owner}/{repo}/pulls/${pr_number} -F body=@${body_file}` を gh pr edit dry-run 行の直後に追加

## エンティティ（Entity）

このドメインは「シェルスクリプト関数による外部コマンド呼び出し」のため、永続的なエンティティは存在しない（状態は GitHub 側 PR 本文に外部化される）。

## 集約（Aggregate）

`PrBodyUpdateOrchestrator` の 1 リクエスト処理は、`PRBodyUpdateRequest` を集約ルートとする閉じた処理単位として扱える。同一サイクル内で 2 つの `gh pr edit` 呼び出し位置（line 391 / 438）はいずれも独立した集約として扱い、1 つの呼び出しの失敗は他の呼び出しに波及しない。

## ドキュメント不変条件（コード SoT + テスト SoT）

実装後、以下を「ドメイン不変条件」として `operations-release.sh` と bats テストに組み込む:

1. **エラー判別 4 パターン必須**: `ScopeInsufficientPatternSet` の 4 パターンを **すべて** ヘルパー関数内の grep に記載（欠落不可）
2. **2 箇所適用必須**: `gh pr edit "$pr_number" --body-file "$body_file"`（line 391）と `gh pr edit "$existing_pr_number" --body-file "$body_file"`（line 438）の **両方** をヘルパー関数呼び出しに置換
3. **`gh pr create` 不変**: line 451 の `gh pr create` は変更しない（Unit 境界）
4. **fallback シグナル必須**: `fallback_success` / `fallback_failed` の各遷移で stderr ログキーが直列出現する
5. **後方互換**: `other_error` 経路は fallback を発動せず、元 stderr と exit code を完全透過する（後方互換性 bats テストで保証）
6. **bats 4 ケース必須**: 通常成功 / read:org fallback / GraphQL fallback / 非スコープエラー透過 の 4 シナリオが `tests/operations-release-pr-edit-fallback.bats` に実装される

## ドリフト検知（クエリセット SoT）

**本セクションは Unit 005 のドリフト検知クエリセットの SoT である**。計画書 §「ドリフト検知（grep 検証クエリ）」および論理設計 §「ドリフト検知」は本セクション（9 クエリ）を **そのまま参照する**（番号・期待 hit を含めて同一）。

文書 / コード / テスト追加後の検証用 grep クエリ。各クエリは少なくとも期待 hit 数を満たすことを期待値とする:

| # | 責務 | 検証クエリ | 期待 hit |
|---|------|----------|---------|
| 1 | 不変条件 1 | `grep -nE 'read:org\|read:discussion\|requires.*scope\|Could not resolve to a User' skills/aidlc/scripts/operations-release.sh` | ≥ 1 |
| 2 | 不変条件 2（DRY 化） | `grep -nE 'gh_pr_edit_body_with_fallback' skills/aidlc/scripts/operations-release.sh` | ≥ 3（定義 1 + 呼び出し 2） |
| 3 | 不変条件 3 | `grep -nE 'gh pr create' skills/aidlc/scripts/operations-release.sh` | ≥ 1（既存記述が残ること） |
| 4 | 不変条件 4 発動 | `grep -nE 'pr-ready:fallback:rest-patch' skills/aidlc/scripts/operations-release.sh` | ≥ 1 |
| 5 | 不変条件 4 失敗 | `grep -nE 'pr-ready:fallback:rest-patch:failed' skills/aidlc/scripts/operations-release.sh` | ≥ 1 |
| 6 | 不変条件 4 PATCH | `grep -nE 'gh api -X PATCH .*/repos/' skills/aidlc/scripts/operations-release.sh` | ≥ 1 |
| 7 | 結合検証（不変条件 1 + 4） | `awk '/^gh_pr_edit_body_with_fallback\(\)/,/^}/' skills/aidlc/scripts/operations-release.sh` の出力に `gh pr edit` と `gh api -X PATCH` の **両方** が出現 | 両方 hit |
| 8 | 不変条件 5（後方互換） | `grep -nE '後方互換\|backward.compat\|other.*error\|network.*error' tests/operations-release-pr-edit-fallback.bats` | ≥ 1 |
| 9 | 不変条件 6 | `grep -nE '@test' tests/operations-release-pr-edit-fallback.bats` | ≥ 4 |

各クエリが期待 hit 数を満たせば、ドメイン不変条件 1〜6 がコード / テストに組み込まれていることを機械的に確認できる。Unit 履歴に各クエリの hit 件数を記録すること。

## 新規指摘の配置ルール（Round 4+ 新領域分類）

本 Unit の改修は以下 3 領域にまたがる。Round 4+ 新領域指摘の自動 backlog 化フロー（`steps/common/review-flow.md`）の境界判定で参照する:

| 領域キー | 該当パス | 想定指摘タイプ |
|---------|---------|--------------|
| `scripts` | `skills/aidlc/scripts/operations-release.sh`（ヘルパー関数 / 呼び出し置換 / dry-run 経路） | コード品質 / シェル構文 / shellcheck |
| `tests` | `tests/operations-release-pr-edit-fallback.bats`, `tests/fixtures/gh-pr-edit-fallback/` | テストカバレッジ / fixture 妥当性 / bats 構文 |
| `cycle-artifacts` | `.aidlc/cycles/v2.5.5/plans/`, `.aidlc/cycles/v2.5.5/design-artifacts/`, `.aidlc/cycles/v2.5.5/history/` | 計画 / 設計 / 履歴の整合性 |

3 領域以外への指摘（例: `steps/common/` / `templates/` 配下）は Unit 005 のスコープ外として `Round 4+ 新領域 backlog 化フロー` で自動 Issue 起票し、本サイクル内では対応しない。
