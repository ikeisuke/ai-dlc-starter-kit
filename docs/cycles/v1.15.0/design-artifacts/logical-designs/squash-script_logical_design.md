# 論理設計: squashスクリプト作成

## 概要

Unit完了時にコミット履歴を1つにまとめるシェルスクリプトの論理設計。git/jj両環境対応。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

シングルスクリプト + 関数分離パターン。1つのシェルスクリプト内で機能ごとに関数を分離し、メイン処理フローで組み合わせる。既存の `pr-ops.sh`、`issue-ops.sh` と同じ構成パターンを採用。

## コンポーネント構成

### モジュール構成

```text
prompts/package/bin/squash-unit.sh
├── ヘルプ・引数解析
│   ├── show_help()
│   └── parse_args()  ※ --vcs オプションでVCS種類を受け取る
├── 起点特定
│   ├── find_base_commit_git()
│   └── find_base_commit_jj()
├── Co-Authored-By抽出
│   └── extract_co_authors()
├── squash実行
│   ├── squash_git()
│   └── squash_jj()
└── メイン処理
    └── main()
```

### コンポーネント詳細

#### show_help()

- **責務**: 使用方法とオプションのヘルプテキストを表示
- **依存**: なし
- **公開インターフェース**: stdout出力

#### parse_args()

- **責務**: コマンドライン引数を解析し、グローバル変数に設定
- **依存**: なし
- **公開インターフェース**: CYCLE, UNIT, MESSAGE, DRY_RUN, VCS_TYPE 変数の設定

#### find_base_commit_git()

- **責務**: git環境で起点コミットのハッシュを特定
- **依存**: git CLI
- **公開インターフェース**: BASE_COMMIT 変数の設定

#### find_base_commit_jj()

- **責務**: jj環境で起点リビジョンのchange_idを特定（change_idはリビジョン書き換え後も安定するため、以降のrevset操作に使用）
- **依存**: jj CLI
- **公開インターフェース**: BASE_COMMIT 変数の設定（change_id値）

#### extract_co_authors()

- **責務**: 対象コミットからCo-Authored-By行を抽出し重複排除
- **依存**: git/jj CLI
- **公開インターフェース**: CO_AUTHORS 変数の設定（改行区切り）

#### squash_git()

- **責務**: git reset --soft + git commit でsquash実行
- **依存**: git CLI
- **公開インターフェース**: stdout出力（squash:success等）

#### squash_jj()

- **責務**: jj squash -r の順次実行でsquash実行
- **依存**: jj CLI
- **公開インターフェース**: stdout出力（squash:success等）

#### main()

- **責務**: 全体の処理フローを制御
- **依存**: 全コンポーネント
- **公開インターフェース**: スクリプトのエントリーポイント

## スクリプトインターフェース設計

### squash-unit.sh

#### 概要

Unit完了時に中間コミットを1つにまとめるsquashスクリプト。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <CYCLE>` | 必須 | サイクル名（例: v1.15.0） |
| `--unit <UNIT_NUMBER>` | 必須 | Unit番号（例: 001） |
| `--message <MESSAGE>` | 必須 | squash後のコミットメッセージ |
| `--vcs <git\|jj>` | 必須 | 使用するVCS種類 |
| `--dry-run` | 任意 | 実際のsquashを実行せず対象コミットの表示のみ |
| `-h, --help` | 任意 | ヘルプ表示 |

#### 成功時出力

```text
vcs_type:git
base_commit:abc1234
target_count:5
squash:success:def5678
```

- 終了コード: `0`
- 出力先: stdout

#### スキップ時出力（対象0件）

```text
vcs_type:git
base_commit:abc1234
target_count:0
squash:skipped:no-commits
```

- 終了コード: `0`
- 出力先: stdout

#### メッセージ整形時出力（対象1件）

```text
vcs_type:git
base_commit:abc1234
target_count:1
squash:success:ghi9012
```

- 終了コード: `0`
- 出力先: stdout（amend/describeでメッセージ整形後の結果）

#### ドライラン時出力

```text
vcs_type:git
base_commit:abc1234
target_count:5
squash:dry-run:5
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
squash:error:base-not-found
```

```text
squash:error:dirty-working-tree
```

```text
vcs_type:git
base_commit:abc1234
target_count:5
squash:error:commit-failed
recovery:git reset --soft xyz7890
```

- 終了コード: `1`（一般エラー）、`2`（引数エラー）
- 出力チャネル規約:
  - **stdout**: 構造化出力のみ（`squash:error:...`、`recovery:...` 等のkey:value形式）。パースを前提とするため、人間向けメッセージを混入させない
  - **stderr**: 人間向けの詳細エラーメッセージ（例: `Error: base commit not found for cycle v1.15.0`）

#### 使用コマンド

```bash
# 基本的な使用方法
prompts/package/bin/squash-unit.sh --cycle v1.15.0 --unit 001 --vcs git --message "feat: [v1.15.0] Unit 001完了 - squashスクリプト作成"

# ドライラン
prompts/package/bin/squash-unit.sh --cycle v1.15.0 --unit 001 --vcs git --message "feat: ..." --dry-run

# ヘルプ
prompts/package/bin/squash-unit.sh --help
```

## 処理フロー概要

### 正常系（git環境、2件以上）の処理フロー

**ステップ**:

1. 引数解析: --cycle, --unit, --vcs, --message を取得
2. 事前チェック: `git status --porcelain` で working tree clean を確認
4. HEAD保存: `SAVED_HEAD=$(git rev-parse HEAD)` でリカバリ用保存
5. 起点特定: `git log --format="%H %s"` で `feat: [CYCLE]` or `Phase完了` パターンを検索
6. 対象コミット列挙: `git log --oneline BASE..HEAD` で対象一覧を取得
7. Co-Authored-By抽出: `git log --format="%b" BASE..HEAD` から `Co-Authored-By:` 行を抽出・重複排除
8. squash実行: `git reset --soft BASE` → `git commit -m "MESSAGE\n\nCo-Authored-By: ..."`
9. 結果出力: `squash:success:<new_hash>`

**関与するコンポーネント**: parse_args, find_base_commit_git, extract_co_authors, squash_git, main

### 正常系（jj環境、2件以上）の処理フロー

**ステップ**:

1. 引数解析: --cycle, --unit, --vcs, --message を取得
2. 事前チェック: `jj status` で working copy に変更がないことを確認
4. 起点特定: `jj log --no-graph -T 'change_id ++ " " ++ description' -r "ancestors(@-, 50)..@-"` で起点を検索
5. 対象リビジョン列挙: 起点の次から@-までのリビジョンを取得
6. bookmark確認: 対象範囲内のbookmarkを `jj bookmark list` で確認、存在すれば警告
7. Co-Authored-By抽出: 対象リビジョンの説明文から `Co-Authored-By:` 行を抽出・重複排除（squash前に実行。squash後は元メッセージが失われるため）
8. squash実行: 最新側から順に `jj squash -r <rev>` で親方向へ統合。各squash後にリビジョンIDが書き換わるため、revset `<base_change_id>..@-` で対象リストを再取得してから次のsquashを実行
9. メッセージ設定: `jj describe -r <統合後rev> -m "MESSAGE\n\nCo-Authored-By: ..."` でメッセージとCo-Authored-Byを設定
10. bookmark維持確認: squash後のbookmark状態を検証
11. 結果出力: `squash:success:<new_rev>`

**関与するコンポーネント**: parse_args, find_base_commit_jj, extract_co_authors, squash_jj, main

### メッセージ整形（1件）の処理フロー

**ステップ**:

1. 対象コミットが1件と判定
2. Co-Authored-By抽出: 対象コミットのメッセージから `Co-Authored-By:` 行を抽出
3. git: `git commit --amend -m "MESSAGE\n\nCo-Authored-By: ..."`
4. jj: `jj describe -r <rev> -m "MESSAGE\n\nCo-Authored-By: ..."`
5. 結果出力: `squash:success:<hash_or_rev>`

### エラー系（git commit失敗）の処理フロー

**ステップ**:

1. `git reset --soft BASE` は成功（HEADが移動済み）
2. `git commit -m "..."` が失敗（pre-commit hookエラー等）
3. SAVED_HEADとHEADの不一致を検出
4. リカバリコマンドを出力: `recovery:git reset --soft <SAVED_HEAD>`
5. エラー結果出力: `squash:error:commit-failed`

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 数十コミット程度のsquashが数秒以内に完了すること
- **対応策**: git reset --soft は高速（O(1)）。jj squash -r は対象数に線形だが、数十件なら数秒以内

### 可用性

- **要件**: スクリプト実行失敗時に復旧可能であること
- **対応策**:
  - git: SAVED_HEAD保存、git reflog利用可能
  - jj: jj undo で直前操作を取り消し可能
  - エラー時にrecoveryコマンドを出力

## 技術選定

- **言語**: Bash（`#!/usr/bin/env bash`）
- **依存コマンド**: git CLI, jj CLI
- **設定**: `set -euo pipefail`（既存スクリプトと統一）

## 実装上の注意事項

- `prompts/package/bin/` に配置（`docs/aidlc/bin/` は直接編集しない）
- 既存スクリプトの出力形式（`key:value`）に従う
- エラーメッセージは stderr、構造化出力は stdout（既存パターン踏襲）
- macOS / Linux 両対応（BSD sed / GNU sed の差異に注意不要。sed は使用しない方針）
- `git commit --amend` 時は `--no-verify` を使用しない（pre-commit hookを尊重）
