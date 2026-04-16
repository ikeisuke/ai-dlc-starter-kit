# ドメインモデル: Operations Phase リモート同期チェック追加

## 概要

Operations Phase開始時にリモートブランチとの同期状態をチェックし、リモートの未取得コミットがある状態で作業を進めるリスクを低減するステップを定義する。

## 値オブジェクト（Value Object）

### RemoteSyncResult

Operations Phase開始時のリモート同期チェック結果を表す正規化済み結果。

- **属性**:
  - status: enum(`up-to-date` | `behind` | `skipped`) - リモート同期状態の正規化値
  - behind_count: Integer | null - リモートにありローカルにないコミット数（`behind` 時のみ有効）
  - error_reason: String | null - スキップ理由（`skipped` 時のみ有効）
- **不変性**: チェック実行時に一度だけ生成され、以後変更されない
- **等価性**: status の値で判定

### チェック方式

`validate-git.sh remote-sync` は `remote_ref..HEAD`（ローカル→リモート方向 = 未pushコミット検出）であり、本Unitの目的（リモートの未取得コミット検出）とは逆方向のため使用しない。

代わりに、`setup-branch.sh` の `check_main_freshness()` と同等のアプローチで、追跡ブランチに対する逆方向チェックを手順層で直接実行する:

1. upstream remote を解決: `git config branch.<current_branch>.remote`（未設定時はフォールバック `origin`）
2. `git fetch <resolved_remote>`（`GIT_TERMINAL_PROMPT=0` で非対話モード）
3. `git rev-list HEAD..@{u} --count`（リモート→ローカル方向 = 未取得コミット検出）

### RemoteSyncResultMapping（変換規則）

| git操作結果 | 正規化状態 | behind_count | error_reason |
|------------|-----------|-------------|-------------|
| fetch成功 + rev-list = 0 | `up-to-date` | 0 | null |
| fetch成功 + rev-list > 0 | `behind` | N | null |
| fetch失敗 | `skipped` | null | fetch失敗理由 |
| upstream未設定（`@{u}` 解決不可） | `skipped` | null | upstream未設定 |
| detached HEAD | `skipped` | null | detached HEAD |

## ドメインサービス

### RawCheckResult（入力構造体）

normalize() の入力型。git操作の結果を構造化して保持する。

- **属性**:
  - branch_status: enum(`resolved` | `detached`) - ブランチ解決状態
  - upstream_status: enum(`available` | `not_configured`) - upstream設定状態
  - fetch_status: enum(`success` | `failed`) - fetch結果
  - behind_count: Integer | null - `rev-list HEAD..@{u}` の件数（fetch成功+upstream設定済み時のみ有効）
  - error_reason: String | null - エラー詳細（失敗時のみ有効）

### RemoteSyncNormalizer

- **責務**: RawCheckResult を `RemoteSyncResult` に正規化する（純粋な変換のみ）
- **操作**:
  - normalize(raw: RawCheckResult) → RemoteSyncResult

### RemoteSyncDecisionPolicy

- **責務**: `RemoteSyncResult` に基づく推奨アクションの決定（表示・UIインタラクションは手順層の責務）
- **操作**:
  - decide(result: RemoteSyncResult) → RecommendedAction

| RemoteSyncResult.status | RecommendedAction |
|------------------------|------------------|
| `up-to-date` | `continue` |
| `behind` | `prompt_user`（取り込む / スキップして続行） |
| `skipped` | `continue_with_warning` |

## 責務境界

| 層 | 責務 |
|----|------|
| git操作（inline） | `git fetch` + `git rev-list HEAD..@{u}` を実行し、raw結果を返す |
| ドメイン層（RemoteSyncNormalizer） | raw結果を RemoteSyncResult に正規化 |
| ドメイン層（RemoteSyncDecisionPolicy） | RemoteSyncResult から推奨アクションを決定 |
| 手順層（`01-setup.md`） | 推奨アクションに基づきメッセージ表示・AskUserQuestionを実行 |

## ユビキタス言語

- **リモート同期チェック**: リモート追跡ブランチにありローカルにないコミットの有無を確認するプロセス
- **behind**: リモートに存在するがローカルに取得されていないコミットがある状態（Inception Phase の `main_status:behind` と同義）
- **skipped**: チェック自体が実行不可能だった場合の安全な続行状態
