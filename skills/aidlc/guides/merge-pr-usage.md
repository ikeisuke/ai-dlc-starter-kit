# merge-pr 利用ガイド

`scripts/operations-release.sh merge-pr`（内部で `scripts/pr-ops.sh merge` を呼び出す）の挙動リファレンスと `--skip-checks` オプションの適用条件を定義する。

## 概要

`merge-pr` は Operations Phase ステップ 7.13（PR マージ実行）で呼び出される PR マージコマンドのラッパー。CI チェック状態に応じて即時マージ / auto-merge 設定 / エラー中断を自動判定する。

`--skip-checks` オプションは、**必須 CI チェックが未設定のリポジトリ**でのみマージをバイパスする安全な経路を提供する。`failed` / `pending` / API エラー時には**バイパスされない**（安全性契約）。

## CI チェック状態の 5 分類

`pr-ops.sh` 内部の `resolve_check_status()` は `gh pr checks --required --json bucket` の結果を以下の 5 分類に写像する:

| 分類 | 判定条件 | 意味 |
|------|---------|------|
| `pass` | jq 結果が `"pass"`（exit code 非依存） | 全必須チェック通過、または必須チェック 0 件（bucket 配列が空） |
| `fail` | jq 結果が `"fail"`（exit code 非依存） | 必須チェックの一部が失敗 |
| `pending` | jq 結果が `"pending"`（`gh pr checks` は pending 時 exit 8 を返すが **exit code に関わらず優先**） | 必須チェックが実行中 |
| `no-checks-configured` | stdout が確定値を返さず、非 0 exit かつ stderr に `no checks reported` を含む | リポジトリに必須 CI チェックが**一つも設定されていない** |
| `checks-query-failed` | 上記以外（ネットワーク / API / 認証エラー等） | CI チェック状態を取得できなかった（原因不明） |

## 挙動マトリクス

| CI 状態 | `--skip-checks` なし | `--skip-checks` あり |
|---------|---------------------|---------------------|
| `pass` | 即時マージ → `pr:<N>:merged:<method>` | 同左（フラグ無視） |
| `fail` | `pr:<N>:error:checks-failed` → exit 1 | 同左（**フラグ無視、バイパス禁止**） |
| `pending` | auto-merge 設定 → `pr:<N>:auto-merge-set:<method>` | 同左（フラグ無視） |
| `no-checks-configured` | `pr:<N>:error:checks-status-unknown` + `reason:no-checks-configured` + `hint:...` → exit 1 | **即時マージ** → `pr:<N>:merged:<method>` |
| `checks-query-failed` | `pr:<N>:error:checks-status-unknown` + `reason:checks-query-failed` + `hint:...` → exit 1 | 同左（**フラグ無視、バイパス禁止**） |

## 使い分けガイダンス

### `--skip-checks` を使うべきケース

以下の**両方**を満たす場合に限り `--skip-checks` を使用する:

1. 対象リポジトリに必須 CI チェックが一つも設定されていない（例: 個人の実験リポジトリ、サンプルプロジェクト、ドキュメントのみのリポジトリ）
2. `merge-pr` の出力に `pr:<N>:reason:no-checks-configured` が含まれている

### `--skip-checks` を使ってはいけないケース

- `pr:<N>:reason:checks-query-failed` が出力された場合: 原因不明のため CI バイパスは不可。ネットワーク / API / 認証の問題を解決して再試行する
- `error:checks-failed` が出力された場合: CI チェックが実際に失敗している。`--skip-checks` は効かない（フラグ無視）。PR の CI 失敗を修正する必要がある
- 必須 CI チェックが設定されているリポジトリで CI 結果を待たずにマージしたい場合: `--skip-checks` は `no-checks-configured` 以外では効かない。CI 完了を待つか、リポジトリのブランチ保護設定を確認する

## エラーコード一覧と対応

### 成功系

| 出力 | 意味 |
|------|------|
| `pr:<N>:merged:<method>` | マージ成功（method: merge / squash / rebase） |
| `pr:<N>:auto-merge-set:<method>` | auto-merge 設定成功（CI 完了後に自動マージ） |

### エラー系

| エラーコード | 原因 | 対応 |
|------------|------|------|
| `error:checks-failed` | 必須 CI が失敗している | PR の CI 失敗を修正 |
| `error:checks-status-unknown` + `reason:no-checks-configured` | 必須チェック未設定 | `--skip-checks` で再実行または中断 |
| `error:checks-status-unknown` + `reason:checks-query-failed` | ネットワーク / API / 認証エラー | 時間を置いて再試行。`--skip-checks` は効かない |
| `error:head-sha-unavailable` | PR の head SHA を取得できない | PR の存在確認、`gh` 認証確認 |
| `error:not-found` | PR が存在しない | PR 番号の確認 |
| `error:not-mergeable` | マージ競合あり | コンフリクト解消 |
| `error:review-required` | レビュー承認が必要 | レビュー依頼 |
| `error:head-mismatch` | race condition（マージ中に push された） | PR の状態を再確認して再実行 |
| `error:auto-merge-not-enabled` | auto-merge 設定が無効 | リポジトリ設定を確認 |
| `error:permission-denied` | マージ権限なし | 権限のあるユーザーに依頼 |
| `error:gh-not-available` | `gh` CLI 未インストール | `gh` CLI のインストール |
| `error:gh-not-authenticated` | `gh` CLI 未認証 | `gh auth login` を実行 |

## 出力契約（機械可読パース用）

`error:checks-status-unknown` エラー時の出力は**順序固定**で 3 行連続で出力される:

```text
pr:<N>:error:checks-status-unknown
pr:<N>:reason:<reason_code>
pr:<N>:hint:<人間向けガイダンス>
```

呼び出し元（`operations-release.md` 7.13 節）は `reason:<reason_code>` の値を機械的にパースして分岐する。`hint:` 行は人間向けガイダンスのため機械的判定には使用しない。

`reason_code` の有効値:

- `no-checks-configured`: `--skip-checks` で再実行可能
- `checks-query-failed`: `--skip-checks` 不可、再試行または中断

## 関連ファイル

- スクリプト: `skills/aidlc/scripts/pr-ops.sh`（`cmd_merge()`, `resolve_check_status()`, `emit_checks_status_unknown_error()`）
- ラッパー: `skills/aidlc/scripts/operations-release.sh`（`cmd_merge_pr()`）
- ステップ: `skills/aidlc/steps/operations/operations-release.md`（7.13 節）
- 関連 Issue: #575
