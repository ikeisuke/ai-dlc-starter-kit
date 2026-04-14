# 論理設計: Operations Phase リモート同期チェック追加

## 概要

`steps/operations/01-setup.md` にリモート同期チェックステップを追加し、Operations Phase開始時にリモートの未取得コミットがある状態で作業を進めるリスクを低減する。

## アーキテクチャパターン

既存の手順層パターンを踏襲: ステップファイル（markdown）がgit操作の手順を定義し、結果を正規化して分岐する構造。Inception Phase ステップ9-3 の `main_status` パターンとの一貫性を確保。

## コンポーネント構成

### 修正対象

```text
steps/operations/
└── 01-setup.md          ← リモート同期チェックステップを追加
```

### 参照のみ（変更なし）

```text
scripts/
├── validate-git.sh      ← 参照のみ（出力契約の一貫性確認用。本ステップでは使用しない）
└── setup-branch.sh      ← check_main_freshness() のアプローチを参考
```

### コンポーネント詳細

#### `steps/operations/01-setup.md` - 新ステップ 6a

- **責務**: Operations Phase開始時のリモート同期チェックの実行手順を定義
- **依存**: git CLI（`git fetch`, `git rev-list`）のみ。既存スクリプトへの直接依存なし
- **公開インターフェース**: ステップ6a として既存フローに挿入。他ステップからの参照なし

### チェック方式の選定理由

`validate-git.sh remote-sync` は `remote_ref..HEAD`（ローカル→リモート方向 = 未pushコミット検出）であり、本Unitの目的（リモートの未取得コミット検出）とはチェック方向が逆。`setup-branch.sh` の `check_main_freshness()` と同等のアプローチ（`git merge-base --is-ancestor` または `git rev-list HEAD..@{u}`）を採用し、追跡ブランチに対する逆方向チェックを実行する。

## 処理フロー概要

### リモート同期チェックの処理フロー

ステップ6（進捗管理ファイル確認）完了後、ステップ6b（タスクリスト作成）の前に実行。

**ステップ**:

1. upstream remote を解決: `git config branch.<current_branch>.remote`（未設定時はフォールバック `origin`）
2. `git fetch <resolved_remote>`（`GIT_TERMINAL_PROMPT=0` で非対話モード実行）
3. `git rev-list HEAD..@{u} --count`（リモート→ローカル方向で未取得コミット数を取得）
3. 結果を RemoteSyncResult に正規化し、分岐:

```text
resolve upstream remote → git fetch <remote> (GIT_TERMINAL_PROMPT=0)
    │
    ├─ fetch成功
    │   └─ git rev-list HEAD..@{u} --count
    │       │
    │       ├─ 0件
    │       │   → remote_sync_status = up-to-date
    │       │   → 「✓ リモートブランチと同期済みです」表示
    │       │   → ステップ6bへ続行
    │       │
    │       └─ N件 (N > 0)
    │           → remote_sync_status = behind (behind_count = N)
    │           → 「⚠ リモートブランチに未取得のコミットが {N} 件あります」表示
    │           → AskUserQuestion:「取り込む / スキップして続行」
    │               ├─ 取り込む → ユーザーに git merge/rebase を依頼、
    │               │              完了後にステップ6aを再実行して up-to-date を確認
    │               └─ スキップして続行 → ステップ6bへ続行
    │
    ├─ fetch失敗
    │   → remote_sync_status = skipped (error_reason = "fetch失敗")
    │   → 「⚠ リモート同期チェックをスキップしました（リモート接続失敗）」表示
    │   → ステップ6bへ続行
    │
    └─ upstream未設定 (@{u} 解決不可) / detached HEAD
        → remote_sync_status = skipped (error_reason = "upstream未設定"/"detached HEAD")
        → 「⚠ リモート同期チェックをスキップしました（{reason}）」表示
        → ステップ6bへ続行
```

**関与するコンポーネント**: `01-setup.md`（手順層）、git CLI（基盤）

### 修正箇所の詳細

#### `steps/operations/01-setup.md` への変更

**挿入位置**: ステップ6（進捗管理ファイル確認）とステップ6a（タスクリスト作成）の間に「### 6a. リモート同期チェック【推奨】」として追加。

**記述内容**:

1. チェック手順: upstream remote 解決 → `git fetch <remote>` → `git rev-list HEAD..@{u} --count`
2. 正規化状態テーブル（ドメインモデルの RemoteSyncResultMapping と同一）
3. 分岐テーブル（ドメインモデルの RemoteSyncDecisionPolicy と同一）
4. behind 時の「取り込む」選択後の手順: ユーザーに `git merge` または `git rebase` を依頼 → 完了後にステップ6aを再実行して `up-to-date` を確認
5. SKILL.md「推奨・提案応答確保ルール」への参照

**既存ステップへの影響**: ステップ番号の変更なし（6a として既存の6の後に挿入（既存の6aは6bに再採番））。他ステップの参照に影響なし。

## 原因調査結果

### 取り込み漏れの原因

Operations Phase のリモート同期チェックは `operations-release.md` ステップ7.9〜7.11（リリース準備段階）にのみ存在し、Phase開始時（`01-setup.md`）にはチェックポイントが欠落していた。

- **影響**: リモートの最新変更を取得しないまま Operations Phase を進行し、リリース直前（ステップ7）で初めて差分に気づくリスク
- **根本原因**: Operations Phase開始時のプリフライトチェック・セットアップステップにリモート同期確認が設計されていなかった
- **対策**: 本Unitで `01-setup.md` にリモート同期チェックステップを追加
- **注意**: ステップ7の `verify-git` は未pushコミット（ローカル→リモート方向）の検出であり、本ステップの未取得コミット（リモート→ローカル方向）とは補完関係にある

### Inception Phase との比較

| 項目 | Inception Phase (ステップ9-3) | Operations Phase (新ステップ6a) |
|------|-------------------------------|-------------------------------|
| チェック対象 | mainブランチの最新化 | リモート追跡ブランチとの同期 |
| 情報源 | `setup-branch.sh` → `main_status` | inline git操作 → RemoteSyncResult |
| チェック方向 | `merge-base --is-ancestor origin/main HEAD` | `rev-list HEAD..@{u} --count` |
| behind時の動作 | AskUserQuestion「取り込む / スキップして続行」 | 同左（一貫性確保） |
| 失敗時の動作 | `fetch-failed` → スキップ | `skipped` → 警告表示してスキップ |

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: チェックは軽量（`git fetch` + 差分確認程度）
- **対応策**: `git fetch` + `git rev-list --count` のみで完結。ネットワーク遅延は `git fetch` に依存

### 可用性

- **要件**: オフライン環境でスキップ可能
- **対応策**: fetch失敗・upstream未設定・detached HEAD を `skipped` に変換し、ブロッカーとしない

## 実装上の注意事項

- 新ステップは6aとして挿入、既存の6a（タスクリスト作成）は6bに再採番
- behind 時の「取り込む」操作はユーザーが手動で `git merge` または `git rebase` を実行する前提（AIエージェントが自動実行しない）
- `@{u}` が解決できない場合（upstream未設定）は `git rev-parse --abbrev-ref @{u}` のエラーを検出して `skipped` に変換
