# 論理設計: 設定保存機能

## 概要

`write-config.sh` の新規作成と、3箇所のステップファイルへの設定保存フロー追加。

## アーキテクチャパターン

既存の `read-config.sh` / `toml-reader.sh` / `bootstrap.sh` のレイヤー構成に合わせる。

```text
ステップファイル（対話フロー）
    │ 呼び出し
    ▼
write-config.sh（書き込みインターフェース、sedベース）
    │ 利用
    ▼
lib/bootstrap.sh（環境変数・パス解決）
```

## スクリプトインターフェース設計

### write-config.sh

#### 概要

指定キー・値を指定スコープの設定ファイルに書き込む。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<key>` | 必須 | ドット区切りの設定キー（例: `rules.git.merge_method`） |
| `<value>` | 必須 | 設定値（文字列） |
| `--scope` | 任意 | `project` / `local`（デフォルト: `local`） |
| `--dry-run` | 任意 | 書き込みせず、対象ファイル・キー・値を表示 |

#### 成功時出力

```text
config:written:<filepath>:<key>=<value>
```

- 終了コード: `0`

#### エラー時出力

```text
config:error:<error_type>:<message>
```

- 終了コード: `1`（書き込み失敗）、`2`（引数エラー/dasel未インストール）

#### 処理フロー

1. `bootstrap.sh` を source してパス解決
2. 引数パース・バリデーション（キー形式: `^[A-Za-z_][A-Za-z0-9_.-]*$`）
3. dasel存在確認
4. スコープからファイルパス決定:
   - `project` → `$AIDLC_CONFIG`
   - `local` → `$AIDLC_LOCAL_CONFIG`
5. ファイル未存在時: 空ファイル作成（`local` の場合はパーミッション `600`）
6. dasel v2/v3 互換のキー変換（`toml-reader.sh` の `aidlc_detect_dasel_version` を流用）
7. dasel put で値を書き込み
8. 結果出力

#### 書き込み方式（sedベース）

dasel v3 では `put` サブコマンドが廃止されたため、sed ベースで TOML を更新する。

**既存キーの値更新**:
```bash
# key の最終セグメント（例: merge_method）をファイル内で検索し、値を置換
sed -i'' -e "s/^${leaf_key} *= *\".*\"/${leaf_key} = \"${value}\"/" "$file"
```

**新規キー追加**（ファイルにキーが存在しない場合）:
```bash
# 1. 親セクション（例: [rules.git]）が存在するか確認
# 2. 存在すれば、セクション末尾に `key = "value"` を追加
# 3. 存在しなければ、セクションヘッダーとキーを追加
```

**注意**: 対象キー3件（merge_method, branch_mode, draft_pr）はいずれも `config.toml` で既に定義されているパターンのため、`config.local.toml` への新規追加がメインケース。

## ステップファイル修正

### 共通パターン（3箇所共通）

各対象質問で `ask` 設定時にユーザーが値を選択した直後に、以下のフローを挿入:

```text
**設定保存フロー**（`ask` 設定時のみ）:

選択後、「この選択を設定に保存しますか？」と確認:
- **はい**: 保存先を選択（デフォルト: `config.local.toml`（個人設定）、代替: `config.toml`（プロジェクト共有））
  ```bash
  scripts/write-config.sh <key> "<選択した値>" --scope <local|project>
  ```
  成功時: 「設定を保存しました: <filepath>」と表示
  失敗時: 「設定の保存に失敗しました。手動で設定ファイルを編集してください。」と警告表示して続行
- **いいえ**: 今回の選択のみ使用して続行
```

### 修正箇所1: `operations/operations-release.md` 7.13

`merge_method=ask` → AskUserQuestion でマージ方法を選択した直後に設定保存フローを挿入。
キー: `rules.git.merge_method`、値: 選択したマージ方法（`merge`/`squash`/`rebase`）

### 修正箇所2: `inception/01-setup.md` ステップ9

`branch_mode=ask` → ユーザーにブランチ作成方式を選択させた直後に設定保存フローを挿入。
キー: `rules.git.branch_mode`、値: 選択した方式（`branch`/`worktree`）

**注意**: 「現在のブランチで続行」選択時は、デフォルト動作の変更ではなく今回限りの一時判断のため、設定保存フローは提示しない（保存対象外）。

### 修正箇所3: `inception/05-completion.md` ステップ5

`draft_pr` 設定確認時に設定保存フローを挿入。
キー: `rules.git.draft_pr`

**UI選択値 → 設定値マッピング**:
- 「はい（ドラフトPRを作成する）」→ 保存値: `always`
- 「いいえ（作成しない）」→ 保存値: `never`

**注意**: `ask` を保存値にすることは意味がないため選択肢に含めない。

## 実装上の注意事項

- sed はmacOSとLinuxで `sed -i` の挙動が異なる（macOS: `sed -i''`、Linux: `sed -i`）。bootstrap.shのOS検出を利用して分岐
- `config.local.toml` 新規作成時は `touch` + `chmod 600` を sed 実行の前に実行
- 書き込み失敗はワークフローをブロックしない（警告表示のみ）

## 不明点と質問

なし
