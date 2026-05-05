# Unit 005 ドメインモデル: #616 マージ前 write-history 追加コミット漏れガード

## 1. ユビキタス言語

| 用語 | 説明 |
|------|------|
| MergePrCommand | `operations-release.sh merge-pr` コマンド本体。PR を GitHub 上でマージする責務 |
| PreFlightCheck | `merge-pr` 実行直後に走る事前検証群。本 Unit で `uncommitted_check` を新規追加 |
| UncommittedCheck | `validate-git.sh uncommitted` を呼出し、ワーキングツリー / index に未コミット差分があるかを判定する検査 |
| WorkingTreeStatus | `ok`（差分なし）/ `warning`（差分あり = 未コミット）/ `error`（システムエラー / 判定不能）。**`validate-git.sh uncommitted` の実契約に完全一致**（Round 1 P1 対応 / 旧称 clean/dirty/unknown は廃止）|
| SkipChecksFlag | `merge-pr --skip-checks` フラグ。pre-flight check 全体を明示バイパスする escape hatch（既存規約 / 緊急時用） |
| DryRunMode | `merge-pr --dry-run` フラグ。実マージは実行せず、pre-flight check の結果のみ検証可能 |
| PreMergeUncommittedDetected | dirty 検出時の診断コード（stderr 出力に使用） |
| PostMergeWriteHistoryGuard | 既存 #579 / Unit 002 / DR-001 で導入済の `write-history.sh` post-merge 拒否（exit 3） |

## 2. 集約 / 値オブジェクト / エンティティ

### 2.1 PreFlightCheckResult（値オブジェクト）

```text
PreFlightCheckResult {
  uncommitted_status: WorkingTreeStatus  # ok | warning | error
  exit_code: 0 | 1
  stderr_diagnostic: Option<String>  # warning 時のみ Some("pre-merge-uncommitted-detected")
}
```

### 2.2 WorkingTreeStatus（値オブジェクト / validate-git.sh canonical）

```text
enum WorkingTreeStatus {
  OK,       # validate-git.sh uncommitted exit 0 + status:ok（差分なし / マージ可）
  WARNING,  # validate-git.sh uncommitted exit 0 + status:warning（未コミット差分あり / マージ停止）
  ERROR,    # validate-git.sh uncommitted exit 2 + status:error（システムエラー / git status 失敗等）
}
```

**重要**: `validate-git.sh` 既存契約に完全一致。`warning` が「未コミット差分検出」を意味し、exit code は 0（v2 系で warning も continue 扱い）。本 Unit 新規ガードは `warning` 検出時に `merge-pr` 自体を exit 1 で停止する責務を担う。

### 2.3 MergePrInvocation（エンティティ / merge-pr 1 回の呼出を表現）

```text
MergePrInvocation {
  pr_number: Int
  method: String  # merge | squash | rebase
  skip_checks: Bool  # --skip-checks 指定有無
  dry_run: Bool  # --dry-run 指定有無
  pre_flight: Option<PreFlightCheckResult>  # skip_checks=true 時は None
}
```

## 3. ドメインサービス

### 3.1 PreFlightChecker（公開 / 純ロジック + I/O）

```text
__operations_release_pre_flight_check() -> PreFlightCheckResult
```

`validate-git.sh uncommitted` を呼出し、`status:` 行を parse して WorkingTreeStatus を確定する。

**副作用**: `validate-git.sh` 実行 / stderr 診断出力。

### 3.2 MergePrCommand（既存 / 改修）

```text
cmd_merge_pr(--pr <NUM> [--method <M>] [--skip-checks] [--dry-run]) -> ExitCode
```

**改修内容**: 以下の制御フロー reorder（**計画 §8 リスク対応**）:

```text
1. 引数 parse
2. SkipChecksFlag=false なら PreFlightChecker.__operations_release_pre_flight_check() 実行
   - dirty 検出 → exit 1 + stderr `error\tpre-merge-uncommitted-detected\t...` + return（dry_run でも実マージでも early return）
   - clean / unknown → 続行
   - **重要**: SkipChecksFlag=true なら本 step を完全 skip（escape hatch）
3. DryRunMode=true なら early return（exit 0 / 実マージしない）
4. 実マージ実行
```

### 3.3 ValidateGit.uncommitted（既存 / 参照のみ）

`validate-git.sh uncommitted` の既存契約（**Round 1 P1 修正**）:

- exit 0 + `status:ok` 出力: 差分なし（マージ可）
- exit 0 + `status:warning` 出力: 未コミット差分あり（**本 Unit ガードの発火対象**）
- exit 2 + `status:error` 出力: システムエラー / git 操作失敗（warn + 続行）

## 4. 状態遷移

```text
[merge-pr 起動]
  ↓
{引数 parse}
  ↓
{skip_checks?}
  ├── true → [pre-flight skip] → {dry_run?}
  │                                ├── true → [exit 0]
  │                                └── false → [実マージ]
  └── false → [pre-flight: __operations_release_pre_flight_check]
              ↓
              {WorkingTreeStatus?}
              ├── WARNING → [stderr `pre-merge-uncommitted-detected` + exit 1]
              ├── OK → {dry_run?}
              │         ├── true → [exit 0]
              │         └── false → [実マージ]
              └── ERROR → [warn + 続行]（既存 verify-git の error 扱いと整合 / システムエラーで誤停止しない）
```

## 5. 不変条件 (Invariant)

- I1: `--skip-checks` 指定時は pre-flight check が完全 skip される（既存 escape hatch 規約踏襲 / 緊急時の人的判断を尊重）
- I2: `--dry-run` 指定時でも pre-flight check は必ず実行される（テスト容易性 + 構造的検証の信頼性）
- I3: dirty 検出時は exit 1 で停止し、実マージは絶対に実行しない
- I4: stderr 診断コードは `error\tpre-merge-uncommitted-detected\t<diagnostics>`（既存 stderr 規約踏襲 / `\t` 区切り）
- I5: 既存 #579 post-merge `write-history` exit 3 ガードへの影響なし（write-history.sh 本体不変 / 呼出順序不変）
- I6: 既存 §7.13 `.aidlc/config.toml` 特化ガード（#601 案 B）と併存（対象が異なり競合しない）
- I7: `validate-git.sh uncommitted` 出力フォーマット（`status:` 行）に依存 / 既存契約変更なし

## 6. 例外と境界

| 状態 | 分類 | 動作 | exit code |
|------|------|------|-----------|
| `status:warning`（未コミット差分検出）| ガード発火 | stderr `error\tpre-merge-uncommitted-detected\t<status>` + 即停止 | 1 |
| `--skip-checks` 指定 | escape hatch | pre-flight skip + 続行 | 0 or merge-pr 既存 exit |
| `--dry-run` 指定 + `status:ok` | 検証完了 | pre-flight pass 表示 + 続行（実マージしない） | 0 |
| `--dry-run` 指定 + `status:warning` | 検証で発火 | stderr 診断 + 停止（dry_run でも early return しない） | 1 |
| `status:error`（システムエラー）| 異常系 | warn 表示 + 続行（既存 verify-git の error 扱いと整合 / 誤停止しない）| 0（続行） |
| `status:` 欠落 / parse 失敗 | 異常系 | warn 表示 + 続行（unknown と同等扱い）| 0（続行） |
| post-merge での write-history | 既存ガード | 既存 #579 exit 3（影響なし） | 3 |

## 7. テスト容易性

- BATS U1-U6（計画 §6 と完全整合）
- TMP 配下に `git init` で独立リポジトリ構築 / 各テストで完全 setup-teardown
- `gh` shim 不要（pre-flight check は実 git のみ呼出）
- `validate-git.sh` は実装そのまま使用（境界外 / 既存契約に依存）
- 制御フロー reorder の検証: U2（dry_run + clean → exit 0）/ U1（dry_run + dirty → exit 1）/ U3（dry_run + dirty + skip_checks → exit 0）の 3 ケースで全分岐網羅
