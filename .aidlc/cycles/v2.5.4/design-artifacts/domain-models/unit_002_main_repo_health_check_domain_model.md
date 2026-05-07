# Unit 002 ドメインモデル: メインリポジトリ Health Check

## 概要

`skills/aidlc/scripts/main-repo-health-check.sh` のドメイン語彙を定義する。worktree 環境で AI-DLC を運用する際に Operations Phase 開始時にメインリポジトリの状態異常を早期検出する helper のドメイン領域。

## ドメイン語彙

### MainRepositoryPath（値オブジェクト）

メインリポジトリの worktree top の絶対パス。`git rev-parse --show-toplevel` と `git rev-parse --git-common-dir` の組み合わせで動的に解決する。

- **状態**: `resolved`（絶対パス確定） / `unresolved`（解決失敗、exit 2）
- **不変条件**: 解決後は絶対パス。相対パス・ハードコードを禁止
- **解決手順**:
  1. 現ディレクトリの `git rev-parse --show-toplevel` で worktree top を取得
  2. `git rev-parse --git-common-dir` で `.git` ディレクトリ（メインリポジトリの場合は `<main-repo>/.git`、worktree の場合は `<main-repo>/.git/worktrees/<name>` の親 = `<main-repo>/.git`）を取得
  3. 戻り値が相対パスの場合、`show-toplevel` を基準に絶対化（`cd <toplevel> && cd <git-common-dir>` で正規化）
  4. `git-common-dir` の親ディレクトリを「メインリポジトリの worktree top」とする

### HealthCheckItem（列挙）

3 種類の検出項目。

| 値 | 意味 | 検出ロジック |
|----|------|-------------|
| `unmerged-paths` | unmerged paths 検出 | メインリポジトリの `git status --porcelain` で `^UU /^AA /^DD /^DU /^UD /^AU /^UA` 等のマージコンフリクト行を検出 |
| `merge-in-progress` | マージ進行中状態 | `git -C <main-repo> rev-parse --git-path MERGE_HEAD` / `CHERRY_PICK_HEAD` / `REBASE_HEAD` で **メインリポジトリの実 gitdir パス**を解決し、各ファイルの存在確認。`<main-repo>/.git/MERGE_HEAD` のみ検出（linked worktree 配下の進行中状態は本 Unit の scope 外、別 Unit / 別 helper で対応する次サイクル候補） |
| `conflict-marker` | コンフリクトマーカー残骸 | メインリポジトリの worktree top 配下の tracked ファイルに `<<<<<<< ` / `>>>>>>> ` / `^=======$` パターンが残存していないか scan |

### HealthCheckResult（集約ルート）

helper 全体の実行結果。

- **`overall_status`**: `ok` / `warning` / `error`
  - `ok`: 3 項目すべて問題なし
  - `warning`: 1 項目以上で問題検出（運用続行可、ユーザー判断で復旧）
  - `error`: メインリポパス解決失敗 / git コマンド失敗（exit 2）
- **`item_results[]`**: 各 `HealthCheckItem` の判定結果
- **`exit_code`**: `0` (`ok` または `warning`) / `1` (バリデーションエラー、本 helper では通常非発生) / `2` (`error` = システムエラー)
- **不変条件**:
  - `overall_status=warning` のとき、`item_results` に少なくとも 1 件 `warning` を含む
  - `exit_code=2` は `overall_status=error` のときのみ
  - 警告の通知は **stdout の `status:warning`** で行い、exit code は `0` を維持する（exit-code-convention.md 準拠）

### ItemResult（値オブジェクト）

各検出項目の個別判定結果。

- **`item`**: `HealthCheckItem`
- **`status`**: `ok` / `warning`
- **`detail`**: 警告時の詳細（例: 検出ファイル数 / マーカー行番号 / MERGE_HEAD のパス）

### ConflictMarkerPattern（値オブジェクト）

コンフリクトマーカー scan で検出するパターン集合。

- **パターン**（**Git 標準マーカーのみ scope**）:
  - `^<<<<<<< `（先頭 7 文字 `<` + 空白）
  - `^>>>>>>> `（先頭 7 文字 `>` + 空白）
  - `^=======$`（先頭・末尾の `=` 7 文字のみの行）
- **不変条件**: 本 Unit の検出対象は **Git 標準のコンフリクトマーカー**（`git merge` / `git cherry-pick` / `git rebase` / `git stash apply --3way` で生成）に限定する。手編集で末尾空白が削除された変種（例: `<<<<<<<` の直後に空白なし）や非標準パターン（IDE が独自フォーマットで出力した残骸等）は **scope 外**
- **理由**: `<<<<<<< <branch-name>` / `>>>>>>> <branch-name>` の形式が Git 標準であり、末尾空白は Git の出力フォーマット上必須。この前提で false positive を抑える
- **scan 主経路**: `git grep -I -n -E "<pattern>"` で tracked + バイナリ自動除外。`git ls-files` 経由は代替経路として記載するが、BSD/GNU 差異吸収のため `git grep` 中心に統一
- **境界**: `.gitignore` 配下のファイル（untracked）は scan 対象外

## 終了コード規約（exit-code-convention.md 準拠）

| exit code | 意味 | 用途 | stdout |
|-----------|------|------|--------|
| `0` | 正常完了 | 健全（`ok`）+ 警告検出（`warning`）を含む | `status:ok` または `status:warning` |
| `1` | バリデーションエラー | 引数不正等。本 helper は引数を取らないため通常非発生 | （該当ケース通常非発生） |
| `2` | システムエラー | メインリポジトリパス解決失敗 / git コマンド失敗等 | `error:<code>:<message>` |

## stdout フォーマット契約

`validate-git.sh` の `status:`/`error:` 出力規約に揃える:

```
status:{ok|warning}
health-check:<item>:<status>:<detail>  # 各項目（warning 時のみ詳細を含む）
health-check:<item>:<status>:<detail>
...
```

エラー時:

```
status:error
error:<code>:<message>
```

エラーコード: `git-path-resolve-failed` / `git-status-failed` / `git-grep-failed` / その他。

## 境界（再掲）

- **検出のみ**: 自動修復は行わない（ユーザーへの復旧手順案内のみ）
- **worktree 主対象**: 通常リポジトリ（worktree 環境ではない）での動作は best-effort
- **Operations Phase 限定**: Inception / Construction Phase での呼び出しはスコープ外
- **未コミット差分（コンフリクト含まない）の警告は対象外**: 誤検知を防ぐため
- **本 helper は引数を取らない**: 引数解析・バリデーションは不要

## 集約ルートとレイヤ責務

| レイヤ | 責務 | ファイル |
|--------|------|---------|
| 集約ルート | `HealthCheckResult` の組み立て・全体ステータス決定 | `main-repo-health-check.sh` メインエントリポイント |
| エンティティ | 各 `HealthCheckItem` の検出ロジック | `main-repo-health-check.sh` 内の関数（`check_unmerged_paths` / `check_merge_in_progress` / `check_conflict_marker`） |
| 値オブジェクト | `MainRepositoryPath` / `ConflictMarkerPattern` の解決 | `main-repo-health-check.sh` 内の関数（`resolve_main_repo_path` / patterns 配列） |
| 呼び出し点 | helper 呼び出しと stdout 解釈 | `skills/aidlc/steps/operations/01-setup.md` step:3a |
| 自動テスト | 4 ケース fixture（健全 / unmerged / MERGE_HEAD / コンフリクトマーカー） | `tests/main-repo-health-check.bats` |

## 関連ドメインとの境界

- **`validate-git.sh`**: 同一スクリプト群だが責務が別（uncommitted / remote-sync vs main-repo health check）。本 Unit では `validate-git.sh` への変更を行わず、出力フォーマット規約のみを参照
- **`post-merge-cleanup.sh`**: 後段の cleanup 時に同様の検出を行うが、本 Unit はあくまで Operations Phase **開始時**の早期検出。`post-merge-cleanup.sh` 自体の改修はスコープ外
- **AI-DLC レビュールール（review-flow.md）**: コンフリクトマーカーは過去サイクルの `git stash pop` 残骸が原因（v2.5.3）。本 helper による検出が成功すれば、レビュー以前のサイクル開始時点で運用者に異常を通知できる
