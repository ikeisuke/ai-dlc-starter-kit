# 論理設計: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加

## 概要

`skills/aidlc/scripts/operations-release.sh` の `cmd_pr_ready` 関数内で `gh pr edit "$pr_number" --body-file "$body_file"` を 2 箇所（line 391, 438）呼び出している既存記述を、共通ヘルパー関数 `gh_pr_edit_body_with_fallback` 経由に置換する。ヘルパー関数は gh CLI 経路の失敗時にスコープ不足エラーを grep で判別し、`gh api -X PATCH /repos/{owner}/{repo}/pulls/${pr_number} -F body=@${body_file}` の REST PATCH 直叩きで fallback する。bats テスト 4 ケース（fixture モック）で動作を検証する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成・関数シグネチャ・grep パターン・bats fixture 構造の定義のみを行います。具体的なシェル実装は Phase 2 で確定します。

## アーキテクチャパターン

**シェル関数による多経路リトライパターン**。bash の `if/else` 制御構造で 2 経路（gh CLI / REST PATCH）を順次試行し、エラー分類器（grep）で経路選択する。既存の `cmd_pr_ready` 関数の構造は維持し、`gh pr edit` の呼び出し位置のみをヘルパー関数呼び出しに置換することで DRY 化と境界遵守（line 451 の `gh pr create` 不変）を両立する。

bats fixture モックパターンで `gh` / `gh api` を差し替えてテストする（既存の `tests/fixtures/` 配下の差し替え方式を踏襲）。

## コンポーネント構成

### レイヤー構成

```text
skills/aidlc/scripts/operations-release.sh（既存スクリプト改修）
├── cmd_pr_ready 関数（既存・改修）
│   ├── ドラフト PR ready 化後の body 更新（line 391）        # ヘルパー呼び出しに置換
│   ├── 既存 Ready PR 検出時の body 更新（line 438）          # ヘルパー呼び出しに置換
│   └── 新規 PR 作成（line 451: gh pr create）               # 不変（境界遵守）
│
└── gh_pr_edit_body_with_fallback 関数（新規・cmd_pr_ready 直前に定義）
    ├── （入力検証なし。caller 責務 / ドメインモデル §「PRBodyUpdateRequest」の前提条件参照）
    ├── gh CLI 経路実行（gh pr edit "$pr" --body-file "$file" 2>stderr_capture）
    ├── 成功判定（exit_code == 0 → return 0）
    ├── ScopeErrorDetector（grep -qE "read:org|read:discussion|requires.*scope|Could not resolve to a User"）
    │   ├── マッチ → fallback シグナル出力 → REST PATCH 経路へ
    │   └── 非マッチ → stderr 透過 → return <gh_exit_code>（other_error）
    └── REST PATCH 経路（gh api -X PATCH /repos/{owner}/{repo}/pulls/${pr} -F body=@${file}）
        ├── 成功 → return 0
        └── 失敗 → fallback 失敗ログキー出力 → return <patch_exit_code>

tests/operations-release-pr-edit-fallback.bats（新規）
└── 4 @test ケース
    ├── ケース 1: 通常成功
    ├── ケース 2: read:org エラー fallback
    ├── ケース 3: GraphQL field error fallback
    └── ケース 4: 後方互換（非スコープエラー透過）

tests/fixtures/gh-pr-edit-fallback/（新規ディレクトリ）
└── gh                    # 単一 gh shim（環境変数 GH_MOCK_MODE で挙動を分岐）
```

**fixture 方式の確定**: 既存テスト（`tests/predecessor-issue-handoff.bats` 等）と統一するため、**単一 `gh` shim + 環境変数 `GH_MOCK_MODE` 分岐方式** を採用する。複数の fixture スクリプトをファイル名で切り替える方式は採用しない。

### コンポーネント詳細

#### gh_pr_edit_body_with_fallback 関数（責務 A, B）

- **配置**: `cmd_pr_ready` 関数定義の **直前**（同ファイル内、`cmd_pr_ready` のヘルパー位置）
- **シェル関数シグネチャ**:

  ```text
  Function: gh_pr_edit_body_with_fallback
  Args:
    $1: pr_number   # 既存の "$pr_number" / "$existing_pr_number"
    $2: body_file   # 既存の "$body_file"
  Returns:
    0   通常成功 / fallback 成功
    !0  非スコープエラー / fallback 失敗（元 exit code を透過）
  Side effects:
    stderr に以下を出力する場合がある:
      - 元 stderr（gh pr edit / gh api 失敗時）
      - "pr-ready:fallback:rest-patch:<pr_number>"（fallback 発動シグナル）
      - "pr-ready:fallback:rest-patch:failed:<pr_number>:<exit_code>"（fallback 失敗時の追加ログキー / DR-003 観測点）
  ```

- **DRY_RUN 動作**: `DRY_RUN=1` 時は実コマンドを実行せず、`log_dry_run` 経由で 2 経路を出力:
  - `would run: gh pr edit <pr> --body-file <file>`
  - `# fallback (when scope-insufficient): gh api -X PATCH /repos/{owner}/{repo}/pulls/<pr> -F body=@<file>`

#### grep パターン定義（責務 A）

- **形式**: 単一の `grep -qE` コマンドで OR 結合
- **パターン文字列**:

  ```text
  read:org|read:discussion|requires.*scope|Could not resolve to a User
  ```

- **マッチ対象**: gh CLI 経路の stderr 全文（ストリームを変数に capture して grep に渡す）
- **判定ロジック**: grep が exit 0（マッチ）なら `scope_insufficient` → fallback、exit 非 0 なら `other_error` → 透過
- **ドメイン不変条件 1（4 パターン必須）の遵守**: ヘルパー関数内で 4 パターンすべてが grep 引数文字列に含まれること

#### REST PATCH 経路（責務 B）

- **コマンド形式**:

  ```text
  gh api -X PATCH "/repos/{owner}/{repo}/pulls/${pr_number}" -F "body=@${body_file}"
  ```

- **owner/repo 解決**: `gh api` の自動補完に委譲（`gh repo view` 等の事前解決は不要 / 既存 `gh` 認証コンテキストに依存）
- **PATCH エンドポイント**: GitHub REST API v3 `PATCH /repos/{owner}/{repo}/pulls/{number}` の `body` フィールド更新
- **`-F` フォーム形式**: `body=@${body_file}` でファイル内容を multipart として送信。改行・特殊文字をエスケープ不要で扱える
- **gh CLI バージョン要件**: `gh api -F` の `@<file>` 構文は v2.42.0+ で確認（Unit 定義 §「外部依存」を参照）

#### 呼び出し位置の置換規則

| 既存行 | 既存内容 | 置換後 | スコープ |
|--------|----------|--------|---------|
| line 391 | `gh pr edit "$pr_number" --body-file "$body_file" \|\| return $?` | `gh_pr_edit_body_with_fallback "$pr_number" "$body_file" \|\| return $?` | IN |
| line 438 | `gh pr edit "$existing_pr_number" --body-file "$body_file" \|\| return $?` | `gh_pr_edit_body_with_fallback "$existing_pr_number" "$body_file" \|\| return $?` | IN |
| line 451 | `gh pr create --base main --title "$cycle" --body-file "$body_file" \|\| return $?` | （変更なし） | OUT |

dry-run 経路（line 356, 359, 385, 435）も同様に `log_dry_run "gh pr edit ..."` の直後に fallback 候補コメント行を 1 行追加する。

## API / インターフェース設計

### bats テストインターフェース（責務 C, D）

#### テストファイル構造

```text
tests/operations-release-pr-edit-fallback.bats
├── setup() ... PATH を fixtures ディレクトリ優先に書き換え、bats_test_tmpdir 等の準備
├── teardown() ... PATH 復元、tmpdir cleanup
├── @test "ケース 1: 通常成功 - gh pr edit が exit 0 を返す場合"
├── @test "ケース 2: スコープ不足 fallback - gh pr edit が read:org エラーで失敗、gh api PATCH が成功"
├── @test "ケース 3: GraphQL field error fallback - Could not resolve to a User エラーで fallback 発動"
└── @test "ケース 4: 後方互換 - 非スコープエラー（network error 等）は fallback 発動せず透過"
```

#### 各 @test の検証項目

各テストで `GH_MOCK_MODE` 環境変数を切り替えて単一 `gh` shim の挙動を制御する:

| ケース | `GH_MOCK_MODE` 設定 | 期待 stdout | 期待 stderr | 期待 exit code |
|--------|---------------------|------------|-----------|---------------|
| 1 | `pr-edit-success`（pr edit 成功 / api PATCH は呼ばれない） | （body 更新成功表示） | （なし） | 0 |
| 2 | `pr-edit-scope-org`（pr edit が read:org エラー → api PATCH 成功） | （body 更新成功表示） | `pr-ready:fallback:rest-patch:<PR>` を含む | 0 |
| 3 | `pr-edit-graphql-error`（pr edit が Could not resolve to a User → api PATCH 成功） | （body 更新成功表示） | `pr-ready:fallback:rest-patch:<PR>` を含む | 0 |
| 4 | `pr-edit-network-error`（pr edit が network error / 非スコープ） | （`gh pr edit` の元 stdout） | `network error: timeout` を含み、`pr-ready:fallback:rest-patch` を **含まない** | 非 0（network error の exit code を透過） |

#### 単一 `gh` shim の構造

`tests/fixtures/gh-pr-edit-fallback/gh` は **単一の bash スクリプト**で、第 1 引数（`pr` / `api`）と環境変数 `GH_MOCK_MODE` で挙動を分岐する:

```text
#!/usr/bin/env bash
# Args: gh pr edit <PR> --body-file <FILE>
#       gh api -X PATCH /repos/{owner}/{repo}/pulls/<PR> -F body=@<FILE>
case "$1" in
  pr)
    if [[ "$2" == "edit" ]]; then
      case "${GH_MOCK_MODE:-}" in
        pr-edit-success)        echo "https://github.com/owner/repo/pull/123"; exit 0 ;;
        pr-edit-scope-org)      echo "Could not resolve to a User of organization. requires read:org scope" >&2; exit 1 ;;
        pr-edit-graphql-error)  echo "Could not resolve to a User: Field 'login' doesn't exist" >&2; exit 1 ;;
        pr-edit-network-error)  echo "network error: timeout connecting to api.github.com" >&2; exit 1 ;;
        *)                      echo "unexpected GH_MOCK_MODE: ${GH_MOCK_MODE:-<unset>}" >&2; exit 99 ;;
      esac
    fi
    ;;
  api)
    if [[ "$2" == "-X" && "$3" == "PATCH" ]]; then
      case "${GH_MOCK_MODE:-}" in
        pr-edit-scope-org|pr-edit-graphql-error)  echo '{"number": 123, "body": "..."}'; exit 0 ;;
        *)                                          echo "unexpected api call in mode: ${GH_MOCK_MODE:-<unset>}" >&2; exit 99 ;;
      esac
    fi
    ;;
esac
exit 99  # 想定外の呼び出し
```

具体的な分岐記述は Phase 2 で確定するが、上記構造（単一 shim + GH_MOCK_MODE 分岐）は固定。

#### setup() / teardown() パターン

```text
setup() {
    SHIM_DIR="${BATS_TEST_DIRNAME}/fixtures/gh-pr-edit-fallback"
    export PATH="${SHIM_DIR}:${PATH}"
    # GH_MOCK_MODE は各 @test 内で個別に export
}

teardown() {
    unset GH_MOCK_MODE
    # PATH は bats の隔離スコープにより自動復元される
}
```

各 `@test` ブロック冒頭で `export GH_MOCK_MODE=<該当モード>` を実行してから `operations-release.sh pr-ready ...` を呼び出す。

## エラーハンドリング / 異常系

| 状況 | 検知方法 | 対応 |
|------|---------|------|
| `gh pr edit` がスコープ不足以外で失敗 | grep 非マッチ | 元 stderr 透過 + 元 exit code を return（fallback 発動なし） |
| `gh pr edit` がスコープ不足エラー、`gh api PATCH` も失敗（DR-003） | grep マッチ後の REST PATCH 失敗 | `pr-ready:fallback:rest-patch:<pr>` 出力後に `pr-ready:fallback:rest-patch:failed:<pr>:<exit>` を追加出力、REST PATCH の exit code を return |
| `body_file` が存在しない / 空文字 | 検証しない（caller 責務） | 元の `gh pr edit` 挙動（ファイル不在エラー）に委譲。ヘルパー関数は追加検証を行わない |
| `pr_number` が空文字 | 検証しない（caller 責務） | 元の `gh pr edit` 挙動（PR 番号不正エラー）に委譲 |
| dry-run | 関数冒頭で `DRY_RUN=1` 判定 | 実コマンド実行せず `log_dry_run` 出力のみ。fallback 候補コメント行を追加 |

## ドリフト検知（責務カバレッジ確認）

実装後の検証クエリは **ドメインモデル §「ドリフト検知（クエリセット SoT）」の 9 クエリ** をそのまま使用する。計画書側の検証クエリも同 SoT を参照する（番号・期待 hit を含めて同一）。各クエリの hit 件数を `history/construction_unit05.md` に記録。

## ドキュメント不変条件（コード SoT）

実装時に維持すべき不変条件（ドメインモデル §「ドキュメント不変条件」と同期）:

1. **エラー判別 4 パターン必須**（不変条件 1）: ヘルパー関数の grep 引数に `read:org|read:discussion|requires.*scope|Could not resolve to a User` の 4 パターンすべてが含まれる
2. **2 箇所適用必須**（不変条件 2）: line 391 / 438 の 2 箇所が `gh_pr_edit_body_with_fallback` 呼び出しに置換され、line 451 は変更されない
3. **fallback シグナル必須**（不変条件 4）: `pr-ready:fallback:rest-patch:<pr>` と `pr-ready:fallback:rest-patch:failed:<pr>:<exit>` の 2 ログキーが定義される
4. **後方互換**（不変条件 5）: 非スコープエラー時に grep が非マッチ → 元 stderr / exit code を完全透過。bats ケース 4 で保証
5. **bats 4 ケース必須**（不変条件 6）: `tests/operations-release-pr-edit-fallback.bats` に `@test` ブロックが 4 件以上、4 シナリオが網羅される

## 文書化要件

ヘルパー関数定義の直前にコメントブロックで以下を記載する（bash スクリプトの慣習）:

```text
# gh_pr_edit_body_with_fallback - gh pr edit のスコープ不足エラー時に gh api PATCH へ fallback する
#
# Args:
#   $1 pr_number   PR 番号
#   $2 body_file   PR 本文ファイル
#
# 関連 Issue: #626
# 関連 Unit: v2.5.5 Unit 005
```

簡潔に保ち、実装の意図（スコープ不足エラー回避）と参照点（Issue / Unit）を残す。

## 見積もり

- ヘルパー関数定義: 0.1 日（〜30 行のシェル関数）
- 既存 2 箇所の置換: 0.05 日（diff は最小）
- bats fixture（単一 `gh` shim + `GH_MOCK_MODE` 4 モード分岐）作成: 0.1 日
- bats @test ケース 4 件作成: 0.15 日
- ローカルテスト実行・shellcheck: 0.05 日
- **小計**: 0.45 日（実装フェーズ）。設計フェーズ + レビューフェーズと合算で 0.6 日（計画書と整合）
