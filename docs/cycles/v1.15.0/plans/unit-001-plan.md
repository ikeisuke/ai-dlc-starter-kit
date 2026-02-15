# Unit 001 計画: squashスクリプト作成

## 概要

Unit完了時に中間コミット（レビュー前/反映コミット等）を1つのコミットにまとめるsquashスクリプトを作成する。git環境（`git reset --soft` 方式）とjj環境（`jj squash` 方式）の両方に対応する。

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `prompts/package/bin/squash-unit.sh` | 新規作成 | squashスクリプト本体 |

## 実装計画

### 1. スクリプトインターフェース

```bash
prompts/package/bin/squash-unit.sh [OPTIONS]
```

**必須オプション**:

- `--cycle <CYCLE>`: サイクル名（例: v1.15.0）
- `--unit <UNIT_NUMBER>`: Unit番号（例: 001）
- `--message <MESSAGE>`: squash後のコミットメッセージ
- `--vcs <git|jj>`: 使用するVCS種類（呼び出し元が判定済みのため引数で受け取る）

**任意オプション**:

- `--dry-run`: 実際のsquashを実行せず、対象コミットの表示のみ
- `-h, --help`: ヘルプ表示

### 2. 処理フロー

#### 2.1 VCS種類

`--vcs` オプションで `git` または `jj` を指定する。呼び出し元（AI-DLCプロンプト）がコミット操作でどちらのVCSを使用しているかを把握しているため、スクリプト側での自動検出は行わない。

**出力**: `vcs_type:git` または `vcs_type:jj`

#### 2.2 実行タイミングと責務

squashスクリプトは **Unit完了コミット（`feat:` コミット）を作成する前** に実行される。

**スクリプトの責務**:

- 中間コミットの `git reset --soft`（git）または `jj squash`（jj）による統合
- `--message` で指定されたメッセージでの **最終コミットの作成まで** 本スクリプトが行う
- 呼び出し元はsquash完了後に追加のコミットを作成しない
- **例外（0件）**: 対象コミットが0件の場合は `squash:skipped:no-commits` を返し、スクリプトはコミットを作成しない。呼び出し元が必要に応じてコミットを作成する

**実行時の状態**:

- HEADは最後の中間コミット（`chore: [CYCLE] レビュー前/反映 - ...`）を指している
- **squash対象**: 起点コミット（前Unit完了 or Phase完了）の次のコミットからHEADまで
- squash実行後、これらの中間コミットが `--message` で指定された1つのコミットに置き換わる

#### 2.3 git環境の処理フロー

1. **事前チェック**: working treeがcleanであることを確認（`git status --porcelain`）
2. **HEAD保存**: squash前のHEADコミットハッシュを変数に保存（リカバリ用）
3. **起点コミット特定**: `git log --oneline --format="%H %s"` から、現在のUnit作業開始直前のコミットを特定
   - 検索パターン: 直近の `feat: [CYCLE]` または `chore: [CYCLE] .* Phase完了` パターンのコミット（前Unitの完了 or Phase完了）
   - **フォールバックなし**: 起点コミットが見つからない場合はエラー終了（exit 1）。サイクル全体を誤ってsquashするリスクを排除
4. **対象コミット確認**: 起点の次のコミット〜HEAD間のコミット一覧を表示
5. **squash実行**:
   - `git reset --soft <起点コミット>` で中間コミットを巻き戻し（変更はステージングに残る）
   - `git commit -m "<message>"`（Co-Authored-By付き）
   - **`git commit` 失敗時のリカバリ**: `git reset --soft` でHEADが移動済みの中途半端状態を検出し、保存済みHEADハッシュを使って復旧コマンドを出力
     ```text
     squash:error:commit-failed
     recovery:git reset --soft <saved_head_hash>
     ```
6. **復旧情報**: squash前のHEADコミットハッシュを表示（`git reflog` での復旧用）

#### 2.4 jj環境の処理フロー

1. **事前チェック**: working copyに未コミット変更がないことを確認（`jj status` で変更ファイルがないこと）
2. **起点リビジョン特定**: `jj log --no-graph -r "ancestors(@-, N)..@-"` で十分な範囲（N=50程度）を探索し、`feat: [CYCLE]` または `Phase完了` パターンの説明を持つ直近のリビジョンを特定
   - **フォールバックなし**: 起点リビジョンが見つからない場合はエラー終了
3. **対象リビジョン確認**: 起点の次〜現在のリビジョン（@-）間の一覧を表示
4. **bookmark確認**: 対象リビジョン範囲内のbookmarkを検出し、存在する場合は警告を出力
5. **Co-Authored-By抽出**: 対象リビジョンの説明文から `Co-Authored-By:` 行を抽出・重複排除（squash前に実行。squash後は元メッセージが失われるため）
6. **squash実行**:
   - 対象リビジョンが A → B → C → D（Aが起点の次）の場合:
   - 最新側から順に親へsquash: `jj squash -r D`（DをCに統合）→ `jj squash -r C'`（C'をBに統合）→ ... と繰り返し
   - **リビジョンID再取得**: 各squash後にリビジョンIDが書き換わるため、revset `<base_change_id>..@-` で対象リストを再取得してから次のsquashを実行
7. **メッセージ設定**: 最終的に1つのリビジョンにまとめた後、`jj describe -r <統合後rev> -m "<message>\n\nCo-Authored-By: ..."` でメッセージとCo-Authored-Byを設定
8. **bookmark維持確認**: squash後にbookmarkが正しく維持されているか検証
9. **復旧情報**: `jj undo` での復旧方法を表示

### 3. エラーハンドリング

| 状況 | 対応 | 終了コード |
|------|------|-----------|
| 起点コミットが見つからない | エラーメッセージを表示し終了 | 1 |
| 対象コミットが0件 | `squash:skipped:no-commits` を返す。呼び出し元が必要に応じてコミットを作成 | 0 |
| 対象コミットが1件 | squash不要だがメッセージ整形を実施（git: `git commit --amend -m`、jj: `jj describe -m`） | 0 |
| git: working treeが汚れている | エラーメッセージを表示し終了 | 1 |
| jj: working copyに未コミット変更がある | エラーメッセージを表示し終了 | 1 |
| git reset --soft失敗 | エラーメッセージを表示し終了 | 1 |
| git commit失敗（reset後） | 保存済みHEADハッシュで復旧コマンドを出力し終了 | 1 |
| jj squash失敗 | エラーメッセージを表示し終了（`jj undo`で復旧可能） | 1 |
| --vcs に無効な値 | エラーメッセージを表示し終了 | 2 |

### 4. 出力形式

既存スクリプト（`pr-ops.sh`, `issue-ops.sh`等）との一貫性を保つキー:値形式：

```text
# メタ情報（常に出力）
vcs_type:<git|jj>
base_commit:<hash|rev>
target_count:<number>

# 正常系
squash:success:<squashed_commit_hash_or_rev>

# ドライラン
squash:dry-run:<commit_count>

# squash不要
squash:skipped:<reason>

# エラー
squash:error:<reason>

# リカバリ情報（git commit失敗時のみ）
recovery:<recovery_command>
```

### 5. Co-Authored-Byの引き継ぎ

squash対象コミットの中からCo-Authored-Byヘッダーを検出し、squash後のコミットメッセージに引き継ぐ。複数の異なるCo-Authored-Byが存在する場合は重複排除して全て含める。

### 6. 依存する既存スクリプト

なし（VCS種類は `--vcs` オプションで受け取るため、外部スクリプトへの依存はない）。

**注意**: 配置先は `prompts/package/bin/`（`docs/aidlc/bin/` は rsync コピーのため直接編集しない）。

## 完了条件チェックリスト

- [x] git環境用のsquashスクリプト（`git reset --soft` + `git commit` 方式）の実装
- [x] jj環境用のsquashスクリプト（`jj squash` 方式）の実装
- [x] 起点コミットの自動特定ロジック（フォールバックなし、エラー終了方式）
- [x] 正常系/異常系のエラーハンドリング（git commit失敗時のリカバリ含む）
- [x] Co-Authored-Byの引き継ぎ
- [x] `--dry-run` オプションの実装
- [x] スクリプトのテスト（git環境での動作確認）
