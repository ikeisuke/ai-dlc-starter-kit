# ドメインモデル: squashスクリプト作成

## 概要

Unit完了時にコミット履歴を整理するsquashスクリプトのドメインモデル。VCS環境の判定、コミット範囲の特定、squash操作、リカバリの概念を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### SquashOperation

squash操作の実行単位。1回のスクリプト実行に対応する。

- **ID**: 実行時のタイムスタンプ + サイクル名 + Unit番号（一意性保証）
- **属性**:
  - cycle: string - サイクル名（例: v1.15.0）
  - unit_number: string - Unit番号（例: 001）
  - message: string - squash後のコミットメッセージ
  - dry_run: boolean - ドライランモードかどうか
  - vcs_type: VcsType - 判定されたVCS種類
  - base_commit: CommitRef - 起点コミット/リビジョン
  - target_commits: CommitRef[] - squash対象のコミット/リビジョン一覧
  - result: SquashResult - 操作結果
- **振る舞い**:
  - execute: VCS種類に応じたsquash処理を実行する
  - validate_preconditions: 事前条件（clean working tree等）を検証する

## 値オブジェクト（Value Object）

### VcsType

VCS環境の種類を表す列挙値。

- **値**: `git` または `jj`
- `--vcs` 引数で呼び出し元が指定（自動検出はしない）

### CommitRef

コミットまたはリビジョンへの参照。

- **属性**:
  - hash: string - コミットハッシュ（git）またはchange_id（jj）。jjではchange_idを使用する（リビジョン書き換え後も安定しているため、revsetでの再追跡に適する）
  - subject: string - コミットメッセージの1行目

### CommitRange

起点から対象までのコミット範囲。

- **属性**:
  - base: CommitRef - 起点コミット（この次のコミットからがsquash対象）
  - targets: CommitRef[] - squash対象コミットの順序付きリスト（古い順）
  - count: integer - 対象コミット数（= targets の長さ）

### SquashResult

squash操作の結果を表す。

- **属性**:
  - status: enum(success, skipped, dry_run, error)
  - detail: string - 結果の詳細（コミットハッシュ、スキップ理由、エラー理由等）
  - recovery_command: string? - リカバリコマンド（エラー時のみ）

### CoAuthoredBy

コミットのCo-Authored-By情報。

- **属性**:
  - raw: string - 元のCo-Authored-By行全体（`Co-Authored-By: Name <email>`）
- raw値の一致で重複排除

## 集約（Aggregate）

### SquashOperation（集約ルート）

- **集約ルート**: SquashOperation
- **含まれる要素**: VcsType, CommitRange, SquashResult, CoAuthoredBy[]
- **境界**: 1回のsquash実行に関する全情報
- **不変条件**:
  - squash実行前にworking tree/working copyがcleanであること
  - base_commitが必ず存在すること（フォールバックなし）
  - target_commits.count >= 2 の場合のみsquashを実行すること
  - 1件の場合はメッセージ整形のみ（amend/describe）
  - 0件の場合はスキップ（`squash:skipped:no-commits`）を返し、コミットは作成しない

## ドメインサービス

### BaseCommitFinder

起点コミットを特定するサービス。

- **責務**: コミット履歴から境界コミット（前Unit完了/Phase完了）を検索
- **操作**:
  - find_base(cycle, vcs_type): CommitRef - 起点コミットを返す。見つからない場合はエラー
- **検索パターン**: `feat: [{cycle}]` または `chore: [{cycle}] .* Phase完了`

### CoAuthorExtractor

squash対象コミットからCo-Authored-By情報を抽出するサービス。

- **責務**: コミットメッセージからCo-Authored-By行を検出し重複排除
- **操作**:
  - extract(targets): CoAuthoredBy[] - 対象コミットからCo-Authored-By一覧を返す

### GitSquasher

git環境でのsquash実行サービス。

- **責務**: `git reset --soft` + `git commit` によるsquash実行
- **操作**:
  - squash(base, message, co_authors): SquashResult - squashを実行し結果を返す
  - amend_message(message, co_authors): SquashResult - 1件時のメッセージ整形

### JjSquasher

jj環境でのsquash実行サービス。

- **責務**: `jj squash -r` の順次実行によるsquash
- **操作**:
  - squash(targets, message, co_authors): SquashResult - squashを実行し結果を返す。各squash後にリビジョンIDが書き換わるため、revset（`<base_change_id>..@-`）で対象リストを再取得してから次を実行
  - describe_message(rev, message, co_authors): SquashResult - 1件時のメッセージ整形（Co-Authored-By付き）
  - verify_bookmarks: boolean - squash後のbookmark整合性を検証

## ユビキタス言語

- **起点コミット（base commit）**: squash対象範囲の直前のコミット。前Unitの完了コミットまたはPhase完了コミット
- **中間コミット（intermediate commit）**: レビュー前/反映コミットなど、Unit作業中に作成される一時的なコミット
- **squash**: 複数のコミットを1つにまとめる操作
- **ドライラン（dry run）**: 実際のsquashを実行せず、対象コミットの確認のみ行うモード
- **リカバリ**: squash操作の失敗時に元の状態に復旧するための手段
- **bookmark**: jjにおけるGitブランチに相当するポインタ（手動移動が必要）
