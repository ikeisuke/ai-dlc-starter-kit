# Unit 005 計画: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加

## 概要

`scripts/operations-release.sh pr-ready` の `gh pr edit <PR> --body-file <PATH>` 失敗時に、grep でスコープ不足エラー（`read:org` / `read:discussion` / GraphQL field error 等）を検出し、`gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` で REST PATCH を直叩きする fallback 経路を組み込む。スコープ不足以外のエラーは従来通り上位伝播させ、fallback で握り潰さない。

## 関連 Issue

- #626（`gh pr edit --body-file` がトークンスコープ不足(read:org 等)で失敗する事象）

## スコープ確定（Unit 定義からの抽出）

Unit 定義の責務 4 項目を SoT とする。

| 項目 | スコープ判定 | 備考 |
|------|------------|------|
| A. `gh pr edit --body-file` 失敗時のスコープ不足エラー grep 検出分岐追加 | IN | Unit 定義「責務」1 項目 |
| B. REST PATCH (`gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>`) fallback 経路追加 | IN | Unit 定義「責務」2 項目 |
| C. bats テスト 1 件以上で fallback 動作確認 | IN | Unit 定義「責務」3 項目 |
| D. 後方互換テスト（スコープ不足以外のエラー上位伝播） | IN | Unit 定義「責務」4 項目 |
| E. `gh pr edit` の他オプション（`--add-reviewer` 等）の fallback 化 | OUT | Unit 定義「境界」 |
| F. grep パターンの将来 gh バージョン対応 | OUT | Unit 定義「境界」（fixture 失敗で気付ける運用ルールのみ） |
| G. 二段階失敗（gh pr edit + REST PATCH も失敗）の bats 検証 | OPT | DR-003 により補足扱い、必須要件ではない（実装者裁量） |

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/operations-release.sh` | 改修（責務 A, B） | `cmd_pr_ready` 内の `gh pr edit "$pr_number" --body-file "$body_file"` **2 箇所**（line 391, 438）に fallback 経路を追加。共通ヘルパー関数 `gh_pr_edit_body_with_fallback` を新規導入し DRY 化。**line 451 の `gh pr create` は変更対象外（参照のみ・境界遵守）** |
| `tests/operations-release-pr-edit-fallback.bats` | 新規作成（責務 C, D） | bats テスト 4 ケース（後述）。**単一 `gh` shim + `GH_MOCK_MODE` 環境変数分岐方式** で `gh` / `gh api` をモック |
| `tests/fixtures/gh-pr-edit-fallback/gh` | 新規作成 | 単一 shim スクリプト（4 モード分岐）。詳細は論理設計 §「単一 `gh` shim の構造」を参照 |
| `.aidlc/cycles/v2.5.5/history/construction_unit05.md` | 新規作成 | Unit 005 進捗履歴 + DR-001 fixture 更新トリガー記録 |

設計成果物（Phase 1）:

- `design-artifacts/domain-models/unit_005_gh_pr_edit_rest_patch_fallback_domain_model.md`: PR 本文更新オペレーションのドメインモデル（`gh pr edit` / `gh api PATCH` / fallback 判定 / エラー分類）、エラー分類語彙（`scope_insufficient` / `other_error`）
- `design-artifacts/logical-designs/unit_005_gh_pr_edit_rest_patch_fallback_logical_design.md`: ヘルパー関数 `gh_pr_edit_body_with_fallback` のシグネチャ・呼び出し位置・grep パターン定義・REST PATCH 構築手順・bats fixture 構造

## ヘルパー関数設計（責務 A, B のマッピング）

### 関数シグネチャ

```bash
# Args:
#   $1 pr_number  PR 番号
#   $2 body_file  本文ファイルパス（既存の "$body_file" 変数）
# Returns:
#   0  成功（gh pr edit 成功 or fallback 成功）
#   非0 失敗（gh pr edit 非スコープエラー or fallback 失敗）
# Side effect:
#   失敗時は元コマンドの stderr を透過、fallback 発動時は "pr-ready:fallback:rest-patch:<pr>" を stderr に出力
gh_pr_edit_body_with_fallback() {
    local pr_number="$1"
    local body_file="$2"
    # 実装は logical design に従う
}
```

### grep 検出パターン（スコープ不足判定）

以下 4 パターンのいずれかを stderr に含む場合のみ fallback を発動する:

| パターン | 検出対象 | 由来 |
|---------|---------|------|
| `read:org` | OAuth scope 不足エラー | gh CLI 公式メッセージ |
| `read:discussion` | OAuth scope 不足エラー | gh CLI 公式メッセージ |
| `Could not resolve to a User` | GraphQL field error | gh CLI 内部 GraphQL クエリ失敗 |
| `requires.*scope` | 一般的な scope 不足 | gh CLI / GitHub API の汎用文言 |

`grep -qE "read:org|read:discussion|Could not resolve to a User|requires.*scope"` で評価する。

### REST PATCH fallback コマンド

```bash
gh api -X PATCH "/repos/{owner}/{repo}/pulls/${pr_number}" -F "body=@${body_file}"
```

`{owner}/{repo}` は `gh api` が自動補完するため、明示的に解決する必要はない（ただし設計レビューで確認）。明示解決が必要な場合は `gh repo view --json owner,name --jq '.owner.login + "/" + .name'` を使用。

### 呼び出し位置（既存 2 箇所への適用 + 参照 1 箇所）

| 位置 | コンテキスト | 元の呼び出し | 本 Unit のスコープ |
|------|------------|------------|------------------|
| `operations-release.sh:391` | ドラフト PR ready 化後の body 更新 | `gh pr edit "$pr_number" --body-file "$body_file"` | **IN**（fallback 適用対象） |
| `operations-release.sh:438` | 既存 Ready PR 検出時の body 更新 | `gh pr edit "$existing_pr_number" --body-file "$body_file"` | **IN**（fallback 適用対象） |
| `operations-release.sh:451` | 新規 PR 作成 | `gh pr create --base main --title "$cycle" --body-file "$body_file"` | **OUT**（参照のみ・変更しない） |

**重要判定**: `gh pr create` の fallback 化は本 Unit のスコープ外（Unit 境界「`gh pr edit` の他のオプション」と同じ精神）。**`gh pr create` は対象外、`gh pr edit` の 2 箇所のみを置き換える**。

dry-run 経路（`operations-release.sh:356, 359, 385, 435`）は `log_dry_run` 出力のみで実行しないため、fallback 経路の追加表示も含めて文書化（`# fallback (when scope-insufficient): gh api -X PATCH ...`）。

## bats テスト設計（責務 C, D）

`tests/operations-release-pr-edit-fallback.bats` に 4 ケース必須:

| # | ケース名 | 入力 | 期待結果 |
|---|---------|------|---------|
| 1 | 通常成功 | `gh pr edit` が exit 0 | exit 0、`gh api PATCH` 呼ばれない |
| 2 | スコープ不足 fallback | `gh pr edit` が `read:org` エラーで exit 1、`gh api PATCH` が exit 0 | exit 0、stderr に `pr-ready:fallback:rest-patch:<pr>` |
| 3 | GraphQL field error fallback | `gh pr edit` が `Could not resolve to a User` で exit 1、`gh api PATCH` が exit 0 | exit 0、fallback 発動 |
| 4 | 後方互換（非スコープエラー） | `gh pr edit` が `network error: timeout` で exit 1 | exit 1（fallback 発動せず元エラー透過） |

### fixture 構造

```text
tests/fixtures/gh-pr-edit-fallback/
└── gh                   # 単一 gh shim（GH_MOCK_MODE 環境変数で挙動を分岐）
```

既存テスト（`tests/predecessor-issue-handoff.bats`）と統一するため、**単一 `gh` shim + 環境変数 `GH_MOCK_MODE` 分岐方式** を採用する。`GH_MOCK_MODE` の値で挙動を切り替える:

| GH_MOCK_MODE | 挙動 |
|--------------|------|
| `pr-edit-success` | gh pr edit 成功（exit 0） |
| `pr-edit-scope-org` | read:org エラー stderr で exit 1 |
| `pr-edit-graphql-error` | Could not resolve to a User エラーで exit 1 |
| `pr-edit-network-error` | network error: timeout で exit 1（非スコープ） |

`gh api -X PATCH` は `pr-edit-scope-org` / `pr-edit-graphql-error` モード時のみ成功（exit 0）、それ以外モードで呼ばれた場合は unexpected として exit 99。詳細仕様は `design-artifacts/logical-designs/unit_005_gh_pr_edit_rest_patch_fallback_logical_design.md` §「単一 `gh` shim の構造」を参照（SoT）。

`PATH` を bats setup で `tests/fixtures/gh-pr-edit-fallback/` ディレクトリ優先に書き換えて差し替える。

## ドリフト検知（grep 検証クエリ）

実装後の検証クエリは **ドメインモデル §「ドリフト検知（クエリセット SoT）」の 9 クエリ** をそのまま使用する（番号・期待 hit を含めて同一）。本計画書では下記 9 クエリの実行と hit 件数の `history/construction_unit05.md` への記録を求める:

1. 不変条件 1（grep `read:org|read:discussion|requires.*scope|Could not resolve to a User`）
2. 不変条件 2（DRY 化、`gh_pr_edit_body_with_fallback` ≥ 3 hit）
3. 不変条件 3（`gh pr create` 残存）
4. 不変条件 4 発動（`pr-ready:fallback:rest-patch`）
5. 不変条件 4 失敗（`pr-ready:fallback:rest-patch:failed`）
6. 不変条件 4 PATCH（`gh api -X PATCH .*/repos/`）
7. 結合検証（awk でヘルパー関数体内に `gh pr edit` と `gh api -X PATCH` の両方が出現）
8. 不変条件 5（後方互換、bats 内に `後方互換|backward.compat|other.*error|network.*error`）
9. 不変条件 6（`@test` ≥ 4）

詳細クエリ文字列・期待 hit 数は SoT 参照（`design-artifacts/domain-models/unit_005_gh_pr_edit_rest_patch_fallback_domain_model.md` §「ドリフト検知（クエリセット SoT）」テーブル）。

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `gh pr edit` がスコープ不足以外で失敗 | 従来通り上位伝播（fallback 発動せず）。stderr 透過 |
| REST PATCH も失敗（DR-003） | エラーログを上位伝播。bats 検証は補足扱いで未追加（手動 fallback 可能性をログから判定） |
| `body_file` が存在しない | 既存挙動維持（`gh pr edit` 側で検出されエラー） |
| dry-run 中 | fallback 経路は実行しない。dry-run ログに「fallback 候補」コメント追記 |

### 二段階失敗時の観測点（DR-003 補足）

二段階失敗（`gh pr edit` のスコープ不足検出 → `gh api PATCH` も失敗）が発生した場合、運用者が再現追跡可能なよう以下のログキーを必ず stderr に出力する:

1. `pr-ready:fallback:rest-patch:<pr_number>`（fallback 発動を示す既出キー）
2. 直後に `pr-ready:fallback:rest-patch:failed:<pr_number>:<exit_code>`（fallback 失敗を示す追加キー、`gh api PATCH` の exit code を含む）

bats 検証は補足扱いだが、観測点としてログキー 2 つの直列出現を必須とすることで、後続の手動 fallback 切り替え判断 / Issue 起票時の証跡を残す。

## NFR

- **パフォーマンス**: 通常パス（成功）はオーバーヘッドなし。fallback パス時のみ追加で `gh api PATCH` 1 回呼び出し
- **セキュリティ**: REST PATCH 経路は `gh` 認証スコープに依存（`write:pulls` があれば PATCH 通過）
- **後方互換**: 既存の `gh pr edit` 通常成功パスは完全に未変更。bats 後方互換テスト（ケース 4）で保証

## 完了条件チェックリスト

### コード（責務 A, B）

- [x] `operations-release.sh` に `gh_pr_edit_body_with_fallback` ヘルパー関数が定義されている（line 298〜341）
- [x] ヘルパー関数内に grep パターン（`read:org` / `read:discussion` / `Could not resolve to a User` / `requires.*scope`）が記載されている（line 322）
- [x] スコープ不足検出時に `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` を実行する分岐がある（line 327）
- [x] fallback 発動時に `pr-ready:fallback:rest-patch:<pr_number>` を stderr に出力する（line 324）
- [x] fallback 失敗時に `pr-ready:fallback:rest-patch:failed:<pr_number>:<exit_code>` を stderr に出力する（line 330 / DR-003 観測点）
- [x] 既存の `gh pr edit "$pr_number" --body-file "$body_file"` 2 箇所がヘルパー関数呼び出しに置き換えられている（line 437, 485）
- [x] `gh pr create` は変更されていない（line 498 のまま、境界遵守）
- [x] dry-run 経路に fallback 候補コメントが追加されている（line 397, 401, 428, 479 の 4 箇所）
- [x] gh CLI / REST PATCH の stdout は呼び出し元へ透過される（後方互換性、Round 1 統合レビュー指摘 #1 対応）

### テスト（責務 C, D）

- [x] `tests/operations-release-pr-edit-fallback.bats` が新規作成されている
- [x] `@test` ブロックが 5 件（4 シナリオ + stdout 透過検証 1 件）
- [x] ケース 1（通常成功 + stdout 透過）/ ケース 2（read:org fallback）/ ケース 3（GraphQL fallback）/ ケース 4（後方互換）/ ケース 5（fallback 経路 stdout 透過）が含まれている
- [x] 単一 `gh` shim スクリプトが `tests/fixtures/gh-pr-edit-fallback/gh` に存在し、`GH_MOCK_MODE` で 4 モード（`pr-edit-success` / `pr-edit-scope-org` / `pr-edit-graphql-error` / `pr-edit-network-error`）に分岐する
- [x] bats 実行で全 5 テスト pass する
- [x] shellcheck を `operations-release.sh` で実行 → Unit 005 差分には新規警告なし（既存 SC2034 が 2 件残るが差分外）

### ドリフト検知 / grep 検証

- [x] ドメインモデル §「ドリフト検知（クエリセット SoT）」の **9 クエリすべて** を実行し、期待 hit 数を満たすことを履歴に記録（Q1〜Q9 すべて pass）

### 履歴

- [x] `.aidlc/cycles/v2.5.5/history/construction_unit05.md` が新規作成され、変更ファイル / レビュー round / 検証結果 / grep ログ / DR-001 fixture 更新トリガーが記録されている
- [x] DR-001: 「fixture 更新トリガー: gh CLI バージョン更新で read:org スコープ不足エラー文言が変わった場合、bats fixture が失敗することで気付ける」が 1 行以上記録されている

### 品質ゲート

- [x] AI レビュー（`reviewing-construction-design` 4R / `reviewing-construction-code` 1R / `reviewing-construction-integration` 2R）が完了条件を満たす
- [x] markdownlint が変更対象 markdown ファイルで pass

## 見積もり

- 設計フェーズ: 0.2 日（domain model / logical design / fixture 構造確定）
- 実装フェーズ: 0.3 日（ヘルパー関数追加 + 呼び出し置換 + bats テスト + fixture）
- レビューフェーズ: 0.1 日
- 合計: **0.6 日（約 4〜5 時間）**（Unit 定義の見積もり「2〜3 時間」より少し多め。bats fixture 整備分の上乗せ）
