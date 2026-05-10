# 論理設計: squash-unit.sh の CI 構造チェック opt-in 化

## 概要

`skills/aidlc/scripts/squash-unit.sh:983-996` の 3 種 CI 構造チェック（check-skill-references / check-bash-substitution / check-test-isolation）を、「**チェックスクリプトの存在を opt-in シグナルとして扱う**」汎用論理に変更する。本体スクリプトに「starter kit / consumer 判定」のドッグフーディング特殊処理は埋め込まない（CLAUDE.md「設計原則」§ ドッグフーディング特殊処理を本体に埋めない 準拠）。

## アーキテクチャパターン

- **opt-in by Presence**: 各チェックスクリプト `bin/${check}.sh` の存在自体を opt-in シグナルとして扱う
- **抽出関数化**: 該当ロジックを squash-unit.sh 内で `run_internal_ci_checks_or_skip()` 関数に切り出す。bats テストは当該関数を直接呼び出して検証する
- **環境非依存**: 関数内に「リポジトリ種別判定」を持たない。挙動は引数で渡された `repo_root` 配下のファイル存在のみで決まる
- **Single Responsibility**: 判定ロジックは squash-unit.sh 内の関数に閉じる（外部スクリプト化しない）

## コンポーネント構成

### 修正対象ファイル

| ファイル | 修正内容 | 行数 |
|---------|---------|------|
| `skills/aidlc/scripts/squash-unit.sh` | `run_internal_ci_checks_or_skip()` 関数化 + opt-in 個別判定 + 末尾 `main "$@"` ガード化 | +18〜25 行 |

### 新規追加ファイル

| ファイル | 用途 | 行数 |
|---------|------|------|
| `bin/tests/squash-unit/internal_ci_checks_optin.bats` | 全揃い / 全不在 / 部分存在 / starter kit 3 種揃い保証 の 4 ケース bats テスト | +110〜130 行 |
| `CLAUDE.md` | プロジェクトルール（ドッグフーディング特殊処理禁止）の SoT | +40 行（別 Issue で先行作成済み） |

## インターフェース設計

### 抽出関数のシグネチャ

```bash
# 関数名: run_internal_ci_checks_or_skip
# 入力:
#   $1: repo_root_for_checks（絶対パス）
# 副作用:
#   - bin/${check}.sh が存在する個別 check のみ実行
#   - 全 check が不在の場合のみ集約 info ログ + 安定トークン出力
# 出力:
#   - stdout: 機械可読トークン（fail 時 `squash:error:*` / 全 skip 時 `squash:info:internal-ci-checks-skipped`）
#   - stderr: 人間向け文言（`Error: ...` / `info: ...`）/ 各チェックの実行ログ
# return code（関数内 exit 禁止）:
#   - 0: 成功（1 つ以上実行され全 pass / または全 skip）
#   - 2: チェック失敗（実行された check のいずれかが fail）
# 呼び出し側の責務:
#   - return 非 0 を受けたら呼び出し側で `exit 1` する（exit 規約は既存維持）
```

### 既存ロジック（修正前）

```text
# squash-unit.sh 983-996（インライン / 全 check fail-closed）
local check_script
for check_script in check-skill-references check-bash-substitution check-test-isolation; do
    if [[ ! -f "${repo_root_for_checks}/bin/${check_script}.sh" ]]; then
        echo "Error: required check script not found: bin/${check_script}.sh" >&2
        echo "squash:error:${check_script}-script-missing"
        exit 1
    fi
    if ! bash "${repo_root_for_checks}/bin/${check_script}.sh" >&2; then
        echo "squash:error:${check_script}-failed"
        exit 1
    fi
done
```

### 修正後ロジック（opt-in / 関数化 / return-only / 疑似コード）

```bash
# squash-unit.sh の関数定義（main() の前方に配置）
run_internal_ci_checks_or_skip() {
    local repo_root="$1"
    local check_script
    local executed_count=0

    for check_script in check-skill-references check-bash-substitution check-test-isolation; do
        # opt-in シグナル: スクリプトが存在しない場合は無音で skip（個別 skip）
        if [[ ! -f "${repo_root}/bin/${check_script}.sh" ]]; then
            continue
        fi
        executed_count=$((executed_count + 1))
        if ! bash "${repo_root}/bin/${check_script}.sh" >&2; then
            echo "squash:error:${check_script}-failed"
            return 2
        fi
    done

    # 集約: 全 check が skip された場合のみ info ログ + 安定トークン
    if [[ $executed_count -eq 0 ]]; then
        echo "info: no internal CI check scripts present in bin/ (skipping)" >&2
        echo "squash:info:internal-ci-checks-skipped"
    fi
    return 0
}

# 呼び出し（既存 983-996 を以下で置換）
# 関数は return-only。非 0 を受けたら exit 1（既存挙動維持）
if ! run_internal_ci_checks_or_skip "${repo_root_for_checks}"; then
    exit 1
fi
```

### 既存実装からの主な変更点

1. **個別 skip**: チェックスクリプト不在時に「Error + exit 1」ではなく「無音 continue」に変更
2. **集約 skip**: 全 check が skip された場合のみ集約レベルで info ログを出力
3. **`script-missing` トークン廃止**: ファイル不在は opt-in 不在として正常系扱いするため、`squash:error:${check}-script-missing` トークンは出力されない（破壊的変更）
4. **return-only**: 関数内で `exit` しない / 呼び出し側で `exit 1` 判定

### 判定ポリシー

| 条件（個別 check） | 個別挙動 |
|-----------------|---------|
| `${repo_root}/bin/${check}.sh` 存在 + 実行 pass | stderr に実行ログ / 関数継続 |
| 同上 + 実行 fail | stdout `squash:error:${check}-failed` + 関数 return 2 |
| 同上 不在 | 無音 continue（個別 skip） |

| 集約条件 | 関数 return | 集約 stdout | 集約 stderr |
|---------|------------|------------|-----------|
| `executed_count >= 1` ∧ 全 pass | 0 | （なし） | （なし） |
| `executed_count >= 1` ∧ 1 つ以上 fail | 2 | `squash:error:${check}-failed`（fail した check） | （実行ログ） |
| `executed_count == 0` | 0 | `squash:info:internal-ci-checks-skipped` | `info: no internal CI check scripts present in bin/ (skipping)` |

## API 設計（squash-unit.sh の標準出力契約）

既存 squash-unit.sh の規約に揃える:

- **stdout**: `squash:` プレフィックス機械可読トークン専用（`squash:error:*` / `squash:info:*` / `squash:skipped:*` / `squash:dry-run:*` 等）
- **stderr**: 人間向け文言（`Error: ...` / `info: ...`）・各チェックの実行ログ
- **exit code**: 既存規約維持（チェック失敗時は呼び出し側で exit 1 / opt-in 不在時は exit せず後続処理へ）
- **stdout 安定トークン規約**:
  - 新設: `squash:info:internal-ci-checks-skipped`（集約レベルの全 skip 通知）
  - **廃止**: `squash:error:${check}-script-missing`（破壊的変更 / 既存テストでこのトークンに依存している箇所があれば併せて修正）
  - 既存 `squash:error:*` と `info:` プレフィックスで namespace 分離

### 後方互換性 / 移行契約（破壊的変更）

`squash:error:${check}-script-missing` トークンは v2.6.0 で廃止する。これは「チェックスクリプト不在は opt-in 不在として正常系扱いする」という設計変更の必然帰結である。

**移行契約**:

| 項目 | 内容 |
|-----|------|
| 廃止タイミング | v2.6.0 リリース時に即時廃止 |
| 中間互換トークン | 採用しない（`squash:warn:script-missing-deprecated` 併記は opt-in 設計と矛盾するため不採用） |
| CHANGELOG 記載 | 必須。「破壊的変更（Breaking Change）」セクションに本トークン廃止 + 移行手順を明記 |
| 影響範囲 | starter kit / consumer プロジェクト双方で本トークンに依存する CI / 監視ルール / ドキュメント |
| 代替トークン | 全 skip 時 → `squash:info:internal-ci-checks-skipped`（新設） / 実行失敗時 → 既存の `squash:error:${check}-failed` |
| 実装時手順 | `git grep -n "squash:error:.*-script-missing" -- ':!.aidlc/cycles/v2.6.0/'` で依存箇所を確認し、bats テスト・運用スクリプト・ドキュメントを併せて修正 |

**外部利用者向け移行手順**（CHANGELOG に転記）:

1. CI / 監視ルールで `squash:error:${check}-script-missing` を grep / 検出している箇所がある場合は除去
2. 全 skip シナリオを検出したい場合は新トークン `squash:info:internal-ci-checks-skipped` を監視対象に追加
3. 実行失敗を検出したい場合は既存の `squash:error:${check}-failed` を引き続き利用

## テスト戦略

### 実行方式（1 案に確定）

**採用方式**: squash-unit.sh の末尾 `main "$@"` を `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"` ガードに置換し、bats から `source "${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"` で関数定義のみロードして直接呼び出す。

選定根拠:

- 最小変更（1 行修正）で既存挙動と完全互換（`bash squash-unit.sh ...` 直接実行時はガード true で main 起動）
- bats からの `source` 時はガード false で main をスキップし、関数定義のみが現在シェルに登録される

### bats テストケース構造

```bash
# file: bin/tests/squash-unit/internal_ci_checks_optin.bats

setup_file() {
    export REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

setup() {
    TMP="$(mktemp -d)"
    cd "$TMP"
    git init --quiet
    git config user.email test@example.com
    git config user.name Test
    # squash-unit.sh を source（main "$@" ガード追加済みなので自動実行されない）
    source "${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"
}

teardown() {
    rm -rf "$TMP"
}

@test "全 check スクリプトが存在し全 pass: 3 種チェックが必須実行される" {
    mkdir -p bin
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/
    cp "${REPO_ROOT}/bin/check-bash-substitution.sh" bin/
    cp "${REPO_ROOT}/bin/check-test-isolation.sh" bin/
    cp "${REPO_ROOT}/bin/check-test-isolation.allowlist" bin/
    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 集約 skip トークンは出力されない
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
}

@test "全 check スクリプトが不在: 集約 skip + 安定トークン + info ログ" {
    # bin/ も作らない（または bin/ はあるが check-*.sh は無い）
    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # stdout に集約 skip トークン
    [[ "$output" == *"squash:info:internal-ci-checks-skipped"* ]]
    # stderr に集約 info 文言
    [[ "$stderr" == *"info: no internal CI check scripts present in bin/ (skipping)"* ]]
}

@test "部分存在（一部の check スクリプトのみあり）: 存在分のみ実行 / 個別 skip は無音" {
    mkdir -p bin
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/
    # 他 2 種は配置しない
    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 部分存在では集約 skip トークンも個別 skip ログも出ない
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
    [[ "$stderr" != *"no internal CI check scripts present"* ]]
}

@test "starter kit 自身の 3 種揃い保証: REPO_ROOT/bin/check-*.sh が 3 ファイルすべて存在する" {
    # GATE-8 境界契約: starter kit 自身が 3 種チェックスクリプトを欠落させないことを保証する
    # 1 つでも欠ければ本テストが fail し、全件 bats 実行（pre-commit / GitHub Actions）でブロックされる
    [ -f "${REPO_ROOT}/bin/check-skill-references.sh" ]
    [ -f "${REPO_ROOT}/bin/check-bash-substitution.sh" ]
    [ -f "${REPO_ROOT}/bin/check-test-isolation.sh" ]
}
```

**契約事項（CI 再現性のため固定）**:

- bats 実行は `bats-core >= 1.5` を前提とする（リポジトリ現行バージョンは 1.13.0 で要件充足）
- **コマンド実行の stdout/stderr を検証するケース**では `run --separate-stderr <cmd>` 形式を使用し、stdout は `$output`、stderr は `$stderr` で分離アサートする（ケース 1〜3 が該当）
- `$output` への統合検証や `--separate-stderr` 未使用の混在パターンは採用しない
- **ファイル存在の静的アサートのみを行うケース**（ケース 4「starter kit 3 種揃い保証」）は `run` を介さず `[ -f ... ]` で直接アサートする（外部コマンド起動を伴わない検証は `run` 不要）

### 既存テストへの影響確認

- `bin/tests/squash-unit/` 配下の既存テストが pass を維持
- `bin/tests/gh-project/` の Unit 006 由来 28 件が pass を維持
- 既存テストや CI で `squash:error:${check}-script-missing` トークンに依存している箇所があれば併せて修正（実装時に grep で確認）

## starter kit 側「3 種揃い保証」の境界契約

opt-in シグナル方式では、本体スクリプト `squash-unit.sh` が「自リポジトリに 3 種チェックスクリプトが揃っているか」を検査しない。これは「ドッグフーディング特殊処理を本体に埋めない」原則の必然帰結である。代わりに以下の境界契約で保証する:

| 項目 | 内容 |
|-----|------|
| 保証主体 | `bin/tests/squash-unit/internal_ci_checks_optin.bats` のテストケース「starter kit 自身の 3 種揃い保証」 |
| 検査内容 | `${REPO_ROOT}/bin/check-skill-references.sh` / `${REPO_ROOT}/bin/check-bash-substitution.sh` / `${REPO_ROOT}/bin/check-test-isolation.sh` の 3 ファイル存在を `[ -f ... ]` で個別アサート |
| 失敗条件 | いずれか 1 つでも不在の場合に bats ケースが fail（exit 1） |
| 実行タイミング | 全件 bats 実行時に必ず実行される。具体的には pre-commit hook / GitHub Actions（既存 workflow がある場合）/ 開発者手動 `bats bin/tests/squash-unit/` |
| ブロック範囲 | 失敗時は当該 bats job が fail → CI / pre-commit が PR 進行をブロック |
| 責務分離 | 本体 `squash-unit.sh` は「自リポジトリの 3 種揃い保証」を行わない。当該保証は本 bats テストの責務（GATE-8） |
| consumer プロジェクトでの扱い | 本テストは starter kit リポジトリ内でのみ実行されるため、consumer プロジェクトには影響しない |

これにより、starter kit が誤って `bin/check-*.sh` の 1 つを欠いた場合でも、本体スクリプト経由ではなく bats テスト経由でブロックされる構造になる。境界契約は本体スクリプトに環境判定を持ち込まずに保証を達成する。

## エラーハンドリング設計

| ケース | 関数 return | プロセス挙動 |
|------|------------|-------------|
| 全 check 存在 + 全 pass | 0 | 後続処理へ |
| 1 つ以上の check が fail | 2 + stdout `squash:error:${check}-failed` + stderr 実行ログ | 呼び出し側で exit 1 |
| 全 check 不在 | 0 + stdout `squash:info:internal-ci-checks-skipped` + stderr `info: no internal CI check scripts present in bin/ (skipping)` | exit せず後続処理へ |
| 部分存在 + 存在分が全 pass | 0（無音） | exit せず後続処理へ |
| 部分存在 + 存在分のいずれかが fail | 2 + 該当 check の `squash:error:${check}-failed` | 呼び出し側で exit 1 |
| `bin/${check}.sh` が実行権限なし | bash 起動時のエラー → 実行 fail 扱い（既存挙動と同じ） | 呼び出し側で exit 1 |
| `bin/${check}.sh` がディレクトリ | `[[ -f ... ]]` で false → 個別 skip | 後続処理へ |

## 既存ガイド照合

- `guides/exit-code-convention.md`: stdout/stderr 分離規約に準拠
- `guides/error-handling.md`: opt-in シグナル方式の妥当性は CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則で確定
- 安定トークン命名規約: 既存 `squash:error:*` と整合する `squash:info:*` を新設 / 不要になった `squash:error:${check}-script-missing` は廃止

## 実装手順（Phase 2 で参照）

1. squash-unit.sh の該当ブロック（983-996 行付近）を関数 `run_internal_ci_checks_or_skip()` に切り出し（main 関数の前方に定義）
2. 関数内で各 check ループを「`[[ ! -f ... ]]` なら `continue`」に変更（個別 skip）
3. 関数内に `executed_count` ローカル変数を追加し、ループ後に `[[ $executed_count -eq 0 ]]` で集約 info 出力
4. 既存ループの `exit 1` を `return 2` に置換、関数末尾は `return 0`
5. 元のループ位置を `if ! run_internal_ci_checks_or_skip "${repo_root_for_checks}"; then exit 1; fi` に置換
6. squash-unit.sh 末尾の `main "$@"` を `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"` に変更（bats source 対応）
7. `squash:error:${check}-script-missing` トークンへの依存を repo 全体で grep し、依存箇所があれば修正
8. `bin/tests/squash-unit/internal_ci_checks_optin.bats` を新規作成（4 ケース: 全揃い / 全不在 / 部分存在 / starter kit 3 種揃い保証 / `--separate-stderr`）
9. bats 全件実行で regression 確認
10. starter kit 自身の squash-unit.sh 実機動作は Unit 007 完了処理時に自然検証される
