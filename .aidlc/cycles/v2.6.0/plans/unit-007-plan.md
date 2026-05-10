# Unit 007 計画: squash-unit.sh の CI 構造チェック opt-in 化

## Unit 概要

`skills/aidlc/scripts/squash-unit.sh:985-996` の 3 種 CI 構造チェック（check-skill-references / check-bash-substitution / check-test-isolation）が「ファイル不在 → 即 exit 1」で必須化されており、starter kit 自身のソースツリー前提の検査が consumer プロジェクトで常時 fail する問題を修正する。

各 `bin/${check}.sh` の存在自体を opt-in シグナルとして扱い、存在すれば実行 / 不在なら skip する汎用論理に変更する。本体スクリプトに「starter kit / consumer 判定」のドッグフーディング特殊処理は埋め込まない（CLAUDE.md「設計原則」§ ドッグフーディング特殊処理を本体に埋めない 準拠）。

- 関連: visitory v1.16.2 サイクル Unit 005 で発生（manual squash 回避が必要だった）
- 依存 Unit: なし
- 見積もり: 60〜90 分（CLAUDE.md 新設 + 設計再構築含む）
- 割り込み分類: 2「別 Unit 追加」（Construction Phase 中に発生 / ユーザー指示）

## 依存関係

- **依存元**: なし
- **被依存**: なし

## Phase 1 意思決定ゲート（完了条件の前提）

> **設計レビュー Round 4 後の方針転換**: ユーザー指示「ドッグフーディング特殊処理を本体に埋めない」により、starter kit / consumer 判定方式から **opt-in シグナル方式**（個別チェックスクリプトの存在で自動分岐）に切り替えた。CLAUDE.md「設計原則」に SoT を新設。

| ゲート | 論点 | 採用案 |
|------|------|-------|
| GATE-1 | リポジトリ種別判定 | **採用案: 判定しない（opt-in シグナル方式）**。本体スクリプトに「starter kit / consumer」の概念を持たせず、各 `bin/${check}.sh` の存在を opt-in シグナルとして個別判定する。CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」準拠 |
| GATE-2 | 全 skip 時の info ログ仕様 | **採用案**: 集約レベルでのみ info を出力。stderr に `info: no internal CI check scripts present in bin/ (skipping)`、stdout に安定トークン `squash:info:internal-ci-checks-skipped`。個別 skip は無音 |
| GATE-3 | starter kit 自身での挙動 | **採用案: 完全互換維持**（3 種チェックは bin/ に揃っているため自然に全実行 → 既存挙動と同じ）。後方互換性は opt-in 方式で副次的に達成される |
| GATE-4 | 個別チェックの skip 化 | **採用案: 個別 skip を無音で許容**。opt-in 方式の必然帰結。部分存在ケース（starter kit が誤って 1 個欠けた等）は本体スクリプトでは検査せず、starter kit 側 CI の bats スイート（具体契約は GATE-8 参照）で「3 種揃いの保証」を別途行う責務とする |
| GATE-5 | bats テストの構造 | **採用案: 全揃い / 全不在 / 部分存在 + starter kit 自身の 3 種揃い保証 の 4 ケース**。`mktemp -d` で各構造を擬装し、`run --separate-stderr` で stdout / stderr を分離アサート |
| GATE-6 | 修正範囲 | **採用案: `skills/aidlc/scripts/squash-unit.sh:985-996` 関数化 + 末尾 `main "$@"` ガード化 + bats 新設 + CLAUDE.md 新設 + CHANGELOG 追記**。他の squash-unit.sh 内チェック（commit count / merge conflict 等）は対象外 |
| GATE-7 | `squash:error:${check}-script-missing` トークン廃止 | **採用案: 廃止（破壊的変更）**。opt-in 方式では「ファイル不在」は正常系として扱うため、本トークンは出力されない。互換方針は「即時廃止 + CHANGELOG に破壊的変更として明記 + repo 全体 grep + 移行手順記載」。代替トークン併記（`squash:warn:script-missing-deprecated`）は採用しない（「不在 = 警告」が opt-in 設計の意図と矛盾するため） |
| GATE-8（新設） | starter kit 側「3 種揃い保証」の境界契約 | **採用案**: 専用 bats ケース「starter kit repo に bin/check-skill-references.sh / bin/check-bash-substitution.sh / bin/check-test-isolation.sh がすべて存在する」を `bin/tests/squash-unit/internal_ci_checks_optin.bats` に新設し、`bin/tests/run-all-tests.sh` 等の全件 bats 実行（CI / pre-commit）で必ず実行される。3 種のうち 1 つでも欠けた場合は当該 bats が fail し、PR / push が止まる。既存 GitHub Actions workflow があれば bats 実行ジョブが本テストを自然にカバーする |

## 完了条件チェックリスト

### Phase 1 ゲート由来

- [ ] GATE-1〜GATE-8 すべての論点が確定し、設計に反映されている

### Unit 定義「責務」由来（opt-in 方式に再定義）

- [ ] **本体スクリプトに opt-in シグナル方式実装**: 各 `bin/${check}.sh` の個別存在で自動分岐
- [ ] **集約 info ログ仕様**: 全 skip 時のみ stdout に `squash:info:internal-ci-checks-skipped` / stderr に `info: no internal CI check scripts present in bin/ (skipping)`
- [ ] **bats テスト追加**: 全揃い / 全不在 / 部分存在 / starter kit 3 種揃い保証 の 4 ケース最小構成
- [ ] **CLAUDE.md 新設**: プロジェクトルート直下に「ドッグフーディング特殊処理を本体に埋めない」設計原則を SoT として追記
- [ ] **CHANGELOG 追記**: `squash:error:${check}-script-missing` トークン廃止を破壊的変更として記載 + 移行手順

### 横断要件

- [ ] starter kit 自身の `bin/check-bash-substitution.sh` / `bin/check-skill-references.sh` / `bin/check-test-isolation.sh` 実行が従来通り動作（squash-unit.sh 経由で 3 種チェックが pass）
- [ ] consumer プロジェクト擬装（`bin/check-*.sh` 全不在の `mktemp -d`）で squash-unit.sh が exit 1 にならず info ログ + 後続処理に進む
- [ ] `squash:error:${check}-script-missing` トークンへの依存箇所を repo 全体で grep し、依存があれば併せて修正
- [ ] codex によるコード AI レビュー実施
- [ ] 既存 28 件 bats テスト（Unit 006 由来）+ その他既存 bats がすべて pass を維持

## 実装スコープ

### 含む

#### Phase 別工程

1. **工程 A: 修正実装**（〜15 分）
    - `skills/aidlc/scripts/squash-unit.sh:985-996` を関数 `run_internal_ci_checks_or_skip()` に切り出し
    - opt-in シグナル方式（個別 `[[ -f ... ]]` で continue）+ 集約 skip 判定（`executed_count`）
    - `exit 1` を `return 2`（fail）/ `return 0`（成功・全 skip）に置換
    - 末尾 `main "$@"` を `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"` に変更（bats source 対応）
    - 呼び出し側を `if ! run_internal_ci_checks_or_skip "${repo_root_for_checks}"; then exit 1; fi` に置換
    - `squash:error:${check}-script-missing` トークン依存を repo 全体 grep し、依存があれば修正

2. **工程 B: テスト追加**（〜25 分）
    - `bin/tests/squash-unit/internal_ci_checks_optin.bats` を新規作成
    - ケース 1: 全揃い（`bin/check-*.sh` 3 種コピー / 全 pass / 集約 skip トークン非出力）
    - ケース 2: 全不在（`bin/` 空 / status 0 / stdout に集約 skip トークン / stderr に集約 info ログ）
    - ケース 3: 部分存在（`check-skill-references.sh` のみコピー / status 0 / 集約 skip 非出力 / 個別 skip 無音）
    - ケース 4: starter kit 自身の 3 種揃い保証（`REPO_ROOT/bin/check-*.sh` 3 ファイル存在検証 / 1 つでも欠ければ fail / GATE-8 境界契約）

3. **工程 C: ドキュメント更新 + AI レビュー + 完了処理**（〜25 分）
    - CLAUDE.md 新設（プロジェクトルート / ドッグフーディング特殊処理禁止原則）
    - CHANGELOG.md に破壊的変更として `squash:error:${check}-script-missing` 廃止を記載 + 移行手順
    - codex でコードレビュー（`reviewing-construction-code`）
    - 履歴記録 + squash + commit

### 含まない

- consumer プロジェクト用の代替チェック追加（別 Unit）
- 3 種チェック自体の振る舞い変更（GATE-6）
- starter kit 自身での挙動変更（GATE-3 / 既存挙動と完全互換）
- `squash:warn:script-missing-deprecated` 等の中間互換トークン併記（GATE-7）

## 設計考慮事項

### 1. 判定ロジックの実装位置

```bash
# squash-unit.sh:983 の直前あたりに関数定義を配置
run_internal_ci_checks_or_skip() {
    local repo_root="$1"
    local check_script
    local executed_count=0

    for check_script in check-skill-references check-bash-substitution check-test-isolation; do
        # opt-in シグナル: スクリプトが存在しない場合は無音 continue（個別 skip）
        if [[ ! -f "${repo_root}/bin/${check_script}.sh" ]]; then
            continue
        fi
        executed_count=$((executed_count + 1))
        if ! bash "${repo_root}/bin/${check_script}.sh" >&2; then
            echo "squash:error:${check_script}-failed"
            return 2
        fi
    done

    if [[ $executed_count -eq 0 ]]; then
        echo "info: no internal CI check scripts present in bin/ (skipping)" >&2
        echo "squash:info:internal-ci-checks-skipped"
    fi
    return 0
}
```

### 2. bats テスト構造（4 ケース）

詳細は `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_007_squash_unit_fail_open_logical_design.md` の「bats テストケース構造」を参照。

### 3. 互換方針 / 移行契約（GATE-7 反映）

- **即時廃止**: v2.6.0 リリースで `squash:error:${check}-script-missing` トークンを完全廃止。中間互換トークン併記は採用しない
- **CHANGELOG 記載**: 「破壊的変更（Breaking Change）」セクションに以下を追記:
  - `squash-unit.sh` の CI 構造チェックを opt-in 方式に変更
  - `squash:error:${check}-script-missing` トークンを廃止
  - 影響範囲: starter kit / consumer プロジェクト双方で本トークンに依存する CI / 監視ルール / ドキュメント
  - 移行手順: 廃止トークンを監視している箇所があれば、新トークン `squash:info:internal-ci-checks-skipped`（全 skip 時）と `squash:error:${check}-failed`（実行失敗時）に置換する
- **repo 内 grep**: 実装時に `git grep "squash:error:.*-script-missing"` で依存箇所を確認し、bats テスト・ドキュメント・運用スクリプトを併せて更新

### 4. starter kit 側「3 種揃い保証」の境界契約（GATE-8 反映）

- **保証の主体**: `bin/tests/squash-unit/internal_ci_checks_optin.bats` のケース 4「starter kit 3 種揃い保証」
- **検査内容**: `REPO_ROOT/bin/check-skill-references.sh` / `REPO_ROOT/bin/check-bash-substitution.sh` / `REPO_ROOT/bin/check-test-isolation.sh` の 3 ファイル存在確認
- **失敗条件**: いずれかが不在の場合に bats が fail
- **実行タイミング**: 全件 bats 実行時（pre-commit / GitHub Actions / 手動 `bats bin/tests/squash-unit/`）
- **責務分離**: 本体 `squash-unit.sh` は「自リポジトリの 3 種揃い保証」を行わない。当該保証は別契約（bats テスト）の責務

### 5. 既存ガイド照合

- `guides/exit-code-convention.md`: squash-unit.sh の exit code 規約（既存維持）
- `guides/error-handling.md`: opt-in シグナル方式の妥当性は CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則で確定

## レビュー戦略

- **設計レビュー**: codex で `reviewing-construction-design`（opt-in 方式の妥当性 / 破壊的変更の影響 / 境界契約）
- **コードレビュー**: codex で `reviewing-construction-code`（シェル安全性 / opt-in 判定ロジック / 集約 skip 判定 / 関数 return 規約 / BASH_SOURCE ガード）

## リスク・トレードオフ

| リスク | 軽減策 |
|------|------|
| `squash:error:${check}-script-missing` トークン廃止による既存依存の破壊 | repo 内 grep で依存箇所特定 + CHANGELOG に破壊的変更として明記 + 移行手順記載 |
| starter kit が誤って `bin/check-*.sh` の 1 つを欠いた場合の silent skip | bats ケース 4「3 種揃い保証」が fail することで PR / push がブロックされる（GATE-8 境界契約） |
| 部分存在ケースが consumer プロジェクトで意図せず発生 | consumer プロジェクトでは通常 `bin/check-*.sh` を持たないため発生しない。仮に持つ場合は当該 check のみ実行される（汎用論理として妥当） |
| 既存 28 件 bats への影響 | 修正は squash-unit.sh の 1 関数 + 末尾 `main "$@"` ガード化のみで他テストに影響なし。bats 全件実行で確認 |

## 検証コマンド

```bash
# 新規 bats テスト
bats bin/tests/squash-unit/internal_ci_checks_optin.bats

# 既存テスト regression 確認（全件）
bats bin/tests/gh-project/
bats bin/tests/squash-unit/      # 既存があれば
bats bin/tests/check-test-isolation/

# squash-unit.sh の実機動作確認（starter kit 自身）
# （実環境で squash-unit.sh が常用されているため Unit 007 完了処理時に自然に検証される）

# 構文チェック
bash -n skills/aidlc/scripts/squash-unit.sh

# 廃止トークン依存箇所確認
git grep -n "squash:error:.*-script-missing" -- ':!.aidlc/cycles/v2.6.0/'
```
