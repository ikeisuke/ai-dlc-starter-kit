# Unit 005 論理設計: #616 マージ前 write-history 追加コミット漏れガード

## 1. 公開インターフェース

### 1.1 `cmd_merge_pr`（既存 / 改修）

`operations-release.sh` 内の関数。改修内容:

```bash
cmd_merge_pr() {
    local pr_number=""
    local method=""
    local skip_checks=0
    local dry_run=0
    # ... 既存引数 parse（変更なし）...

    # ===== 新規 pre-flight check =====
    if [[ $skip_checks -eq 0 ]]; then
        if ! __operations_release_pre_flight_check; then
            return 1
        fi
    fi

    # ===== 既存 dry-run early return（reorder で pre-flight 後に配置）=====
    if [[ $dry_run -eq 1 ]]; then
        printf 'merge-pr:dry-run:pre-flight-pass\n'
        return 0
    fi

    # ===== 実マージ実行（既存ロジック）=====
    # gh pr merge ...
}
```

**重要**: `--skip-checks` 指定時は pre-flight 自体を skip（既存 escape hatch 規約踏襲）。`--dry-run` 指定時でも pre-flight は必ず実行する（I2 / 構造的検証の信頼性）。

### 1.2 `__operations_release_pre_flight_check`（新規 / 内部関数）

```text
入力: なし（git working tree のみ参照）
戻り値:
  0 = ok / error / unknown（続行可 / システムエラーで誤停止しない）
  1 = warning（未コミット差分検出 / 停止 / 既に stderr 診断出力済）
副作用:
  validate-git.sh uncommitted 呼出 / stderr 診断出力
```

```bash
__operations_release_pre_flight_check() {
    local uncommitted_output
    # exit code は使用しない（v2 系で warning も exit 0 / shellcheck SC2034 回避のため変数キャプチャしない）
    uncommitted_output=$("$SCRIPT_DIR/validate-git.sh" uncommitted 2>&1) || true

    local uncommitted_status
    uncommitted_status=$(printf '%s\n' "$uncommitted_output" | awk -F':' '/^status:/ {print $2; exit}')
    [[ -z "$uncommitted_status" ]] && uncommitted_status="unknown"

    case "$uncommitted_status" in
        ok)
            return 0
            ;;
        warning)
            printf 'error\tpre-merge-uncommitted-detected\t%s\n' "$uncommitted_output" >&2
            return 1
            ;;
        error|unknown|*)
            printf 'warn\tpre-merge-uncommitted-unknown\tvalidate-git.sh status undecidable: %s\n' "$uncommitted_output" >&2
            return 0
            ;;
    esac
}
```

**設計上の注意（Round 1 P3 対応）**: `validate-git.sh` の exit code は捕捉しない（`|| true` で握りつぶす）。理由:
- v2 系契約で `warning` 時も exit 0 / `error` 時のみ exit 2
- ガード判定は `status:` 行 parse のみで完結（exit code 二重検査は冗長）
- `local var=$(cmd) || rc=$?` パターンは `local` の return が cmd を上書きするバグ既知 / 本実装は単純化のため変数キャプチャ自体を回避

## 2. stderr 診断コード表

| 診断コード | level | exit code | 発火条件 |
|-----------|-------|-----------|---------|
| `pre-merge-uncommitted-detected` | error | 1 | `validate-git.sh uncommitted` が `status:warning` を返した（未コミット差分検出 / **Round 1 P1 対応 / 旧 dirty 表記から修正**）|
| `pre-merge-uncommitted-unknown` | warn | 0（続行）| `validate-git.sh uncommitted` の `status:` 行が `error` または parse 不能（システムエラーで誤停止しない）|
| `post-merge-history-write-forbidden:<reason>:<diag>` | error | 3 | 既存 #579 / Unit 002 / DR-001（影響なし） |

stderr フォーマットは `<level>\t<code>\t<detail>` を遵守（既存 retrospective-issue.sh / Unit 002-004 と整合）。

## 3. 制御フロー（merge-pr 内部）

```text
[cmd_merge_pr 起動]
  ↓
{引数 parse}
  ├── --pr <NUM> 必須
  ├── --method <M>（merge|squash|rebase）
  ├── --skip-checks（既存）
  └── --dry-run（既存）
  ↓
{skip_checks=0?}
  ├── 1（true）→ [pre-flight skip] ──┐
  └── 0（false）                    │
       ↓                            │
       __operations_release_pre_flight_check
       ↓                            │
       {return value}                │
       ├── 0（ok / error / unknown）┤
       └── 1（warning）→ [exit 1]   │
                                    │
[pre-flight pass / skip]            │
  ↓ ←─────────────────────────────┘
{dry_run=1?}
  ├── true → [printf "merge-pr:dry-run:pre-flight-pass" + exit 0]
  └── false → [既存 gh pr merge 実装]
```

## 4. 改修対象ファイル詳細

### 4.1 `skills/aidlc/scripts/operations-release.sh`

**改修箇所**:
- L527 付近 `cmd_merge_pr` 関数の引数 parse 直後に pre-flight check 呼出を挿入
- 既存 `--dry-run` early return の前に pre-flight が実行されるよう reorder
- 新規関数 `__operations_release_pre_flight_check` を `cmd_merge_pr` 直前に追加

**変更しない箇所**:
- `cmd_verify_git`（既存 verify-git の出力フォーマット維持）
- `cmd_pr_ready` / `cmd_version_check`
- `validate-git.sh` 本体（境界外 / 既存契約利用のみ）

### 4.2 `skills/aidlc/steps/operations/operations-release.md`

**改修箇所**:
- §7.12 末尾に「verify-git 再実行案内」追加（AI エージェント手順 / 補助 = Option A）
- §7.13 冒頭または「マージ実行確認」直前に「`merge-pr` pre-flight check により dirty 時 exit 1 で停止」を明記
- 既存 `.aidlc/config.toml` 特化ガード（§7.13 内 #601 案 B）との併存ルールを明記

**変更しない箇所**:
- §7.13 既存マージ実行ロジック / `.aidlc/config.toml` 特化ガード本体
- §7.9-7.11 verify-git 既存案内

### 4.3 `skills/aidlc/steps/common/review-flow.md`

**改修箇所**:
- L50 「(2) レビュー後コミット」を「(2a) 修正コミット / (2b) 履歴記録 (`/write-history`) / (2c) 履歴コミット」の三段階に分割明示
- 適用範囲は既存「パス 1/2 完了時」を維持（パス 3 ユーザー主導は既存仕様踏襲）

### 4.4 `tests/operations-uncommitted-detection.bats`（新規）

```bash
#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# Unit 005: pre-merge uncommitted detection guard 単体テスト
# Plan §6 / Design §1.2 を verify する。

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TMP="$(mktemp -d -t aidlc-u5.XXXXXX)"
  cd "$TMP"

  # 独立 git リポ
  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "test"
  printf 'init\n' > README.md
  git add README.md
  git commit -q -m "init"

  # operations-release.sh + validate-git.sh をシムする（テストでは実 gh は呼ばない）
  # operations-release.sh 内部で SCRIPT_DIR=dirname(BASH_SOURCE) を使う
  RELEASE_SH="${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"
}

teardown() {
  cd "$REPO_ROOT"
  rm -rf "$TMP"
}

# U1: 実行系 / dirty 状態で merge-pr --dry-run → exit 1
@test "U1: dirty 状態 + --dry-run で pre-flight が exit 1 + stderr pre-merge-uncommitted-detected" {
  printf 'modified\n' >> README.md  # 未コミット差分作成

  run --separate-stderr "$RELEASE_SH" merge-pr --pr 1 --method squash --dry-run
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"pre-merge-uncommitted-detected"* ]]
}

# U2: 実行系 / clean 状態で merge-pr --dry-run → exit 0 + pre-flight pass 表示
@test "U2: clean 状態 + --dry-run で pre-flight pass + exit 0" {
  run "$RELEASE_SH" merge-pr --pr 1 --method squash --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"pre-flight-pass"* ]]
}

# U3: 実行系 / dirty + --skip-checks で escape hatch
@test "U3: dirty 状態 + --skip-checks で pre-flight skip（escape hatch / dry-run pass）" {
  printf 'modified\n' >> README.md

  run "$RELEASE_SH" merge-pr --pr 1 --method squash --dry-run --skip-checks
  [ "$status" -eq 0 ]
  [[ "$output" != *"pre-merge-uncommitted-detected"* ]]
}

# U4: 文書 / review-flow.md L50 の三段階フロー
@test "U4: review-flow.md L50 が三段階フロー（修正コミット → 履歴記録 → 履歴コミット）を含む" {
  local review_flow="${REPO_ROOT}/skills/aidlc/steps/common/review-flow.md"
  grep -F "(2a)" "$review_flow"
  grep -F "(2b)" "$review_flow"
  grep -F "(2c)" "$review_flow"
}

# U5: 文書 / operations-release.md §7.12 / §7.13
@test "U5: operations-release.md §7.12 verify-git 再実行案内 + §7.13 merge-pr pre-flight 記述" {
  local ops_release="${REPO_ROOT}/skills/aidlc/steps/operations/operations-release.md"
  grep -F "verify-git" "$ops_release"
  grep -F "pre-merge-uncommitted-detected" "$ops_release"
}

# U6: 回帰 / #579 post-merge write-history exit 3 ガード（実動作テスト / Round 1 P3 対応）
@test "U6: write-history.sh post-merge ガード（exit 3）が実動作で発火" {
  # post-merge stage で write-history を呼ぶと exit 3 が返る
  local write_history="${REPO_ROOT}/skills/aidlc/scripts/write-history.sh"

  # 最小ダミー履歴ファイル
  mkdir -p .aidlc/cycles/v0.0.1/history
  printf '## 2026-05-05T00:00:00+09:00\n\n- test\n' > /tmp/u6-event.md

  run "$write_history" --cycle v0.0.1 --phase operations --operations-stage post-merge --event-file /tmp/u6-event.md
  [ "$status" -eq 3 ]
  rm -f /tmp/u6-event.md
}

# U7: 境界値 / status:error 時の挙動（warn + 続行 / Round 1 P2 対応）
@test "U7: validate-git.sh が status:error を返した場合 warn + 続行（誤停止しない）" {
  # SCRIPT_DIR への shim で validate-git.sh を error に固定
  local shim_dir="$TMP/shim-error"
  mkdir -p "$shim_dir/skills/aidlc/scripts"
  cat > "$shim_dir/skills/aidlc/scripts/validate-git.sh" <<'SHIM'
#!/usr/bin/env bash
echo "status:error"
exit 2
SHIM
  chmod +x "$shim_dir/skills/aidlc/scripts/validate-git.sh"

  # operations-release.sh は SCRIPT_DIR を BASH_SOURCE で計算するため、本テストは
  # __operations_release_pre_flight_check のロジック単体検証として skip 扱い相当
  # （実動作 shim は実装後に統合テストで補完）
  skip "T05: __operations_release_pre_flight_check の error 経路は実装後に統合テストで網羅"
}

# U8: 境界値 / status: 行欠落時の挙動（unknown 扱いで warn + 続行）
@test "U8: validate-git.sh 出力に status: 行が無い場合 unknown 扱いで続行" {
  # 設計時点では skip / 実装後に統合テストで補完
  skip "T05 と同様、実装後に shim 統合テストで補完"
}
```

**注**: U7 / U8 は実装後（Phase 2）に shim を整備した実動作テストへ昇格する（実装と同時に skip 解除）。設計時点では U1-U6（実装可能なもの）を中心に検証し、境界値網羅は P3 reviewer 要件として実装フェーズで完成させる。

## 5. 影響範囲

### 5.1 既存契約への影響

- `merge-pr --dry-run` 動作: clean 時は従来通り（pre-flight pass + exit 0 / `pre-flight-pass` 文字列追加）/ dirty 時は新たに exit 1
- `merge-pr --skip-checks`: 動作不変（pre-flight 完全 skip / 既存規約踏襲）
- `verify-git` / `validate-git.sh`: 不変
- `write-history.sh`: 不変（#579 post-merge ガードに影響なし）
- 既存 §7.13 `.aidlc/config.toml` 特化ガード（#601 案 B）: 不変（併存 / 競合なし）

### 5.2 ユーザー影響

- 既存ユーザー: dirty 状態で `merge-pr` を実行している場合 exit 1 で停止する → 修正の上 retry 必要
- escape hatch: `--skip-checks` で従来動作復元可能
- AI エージェント: `merge-pr` 構造的ガードに任せられるため、手順ミスがあっても破壊的結果に至らない

### 5.3 テスト影響

- 新規 BATS: `tests/operations-uncommitted-detection.bats` 6 件
- 既存 BATS: 305 件（Unit 004 完了時）に変更なし / 全 pass 維持必須
- migration-tests.yml: PATHS_REGEX に `operations-release\.sh` + 新規 BATS 追加 / bats 実行リスト更新

## 6. exit code 規約整理

| exit code | 意味 | 発火源 |
|-----------|------|--------|
| 0 | success（warn 含む） | clean / `--skip-checks` / unknown 続行 |
| 1 | runtime error / dirty 検出 | `pre-merge-uncommitted-detected`（本 Unit 新規）/ 既存 verify-git 異常 |
| 2 | argument error | 既存 / 不変 |
| 3 | post-merge ガード | 既存 #579 `write-history.sh` / 不変 |

`guides/exit-code-convention.md` に完全準拠。

## 7. 実装チェックリスト

- [ ] `operations-release.sh` に `__operations_release_pre_flight_check` 追加
- [ ] `cmd_merge_pr` に pre-flight check 呼出 + dry-run reorder 反映
- [ ] `operations-release.md` §7.12 / §7.13 改修
- [ ] `review-flow.md` L50 三段階分割
- [ ] `tests/operations-uncommitted-detection.bats` 新規作成（U1-U6）
- [ ] `.github/workflows/migration-tests.yml` PATHS_REGEX + bats list 更新
- [ ] shellcheck warning 0
- [ ] `bin/check-bash-substitution.sh skills/aidlc/steps/` 違反 0
- [ ] 全 BATS pass（既存 305 + 新規 6 = 311 件）
