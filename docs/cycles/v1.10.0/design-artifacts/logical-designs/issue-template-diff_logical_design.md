# 論理設計: Issueテンプレート差分確認

## 概要

`prompts/setup-prompt.md` のセクション8.2.5を修正し、Issueテンプレートの差分確認機能を追加する。

## 現在の実装（変更前）

セクション8.2.5では以下の処理を行っている:

1. `.github/ISSUE_TEMPLATE/` の存在確認
2. 存在しない場合: 新規コピー
3. 同名ファイルが存在する場合: ユーザーに上書き/スキップ/個別確認を選択させる
4. 同名ファイルが存在しない場合: 新規ファイルのみコピー

## 変更後の実装

差分がない場合はスキップし、差分がある場合のみユーザー確認を行う。

### 処理フロー

```bash
# 1. ディレクトリ存在確認
if [ ! -d ".github/ISSUE_TEMPLATE" ]; then
    # 新規コピー（従来通り）
fi

# 2. 差分確認（diff -q を使用）
DIFF_FILES=""
for file in backlog.yml bug.yml feature.yml feedback.yml; do
    SOURCE="[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file"
    TARGET=".github/ISSUE_TEMPLATE/$file"
    if [ -f "$TARGET" ]; then
        if ! diff -q "$SOURCE" "$TARGET" >/dev/null 2>&1; then
            DIFF_FILES="${DIFF_FILES}${file} "
        fi
    else
        # 新規ファイル（差分扱い）
        DIFF_FILES="${DIFF_FILES}${file}(new) "
    fi
done

# 3. 差分判定
if [ -z "$DIFF_FILES" ]; then
    echo "Issueテンプレートに差分はありません。スキップします。"
    # 終了
fi

# 4. 差分がある場合のユーザー確認
echo "以下のIssueテンプレートに差分があります："
echo "$DIFF_FILES"
# ユーザー選択...
```

### ユーザー確認フロー

```text
以下のIssueテンプレートに差分があります：
[差分ファイル一覧]

選択してください:
1. 上書きする（推奨）
2. スキップする
3. 差分を確認してから決める

どれを選択しますか？
```

- **選択1（上書き）**: 差分のあるファイルのみコピー
- **選択2（スキップ）**: 何もせず終了
- **選択3（差分確認）**: 各ファイルの `diff` 出力を表示後、再度選択

## 変更箇所

### prompts/setup-prompt.md セクション8.2.5

**変更前**: 同名ファイル存在チェック → ユーザー確認

**変更後**:
1. ディレクトリ存在確認
2. 差分確認（`diff -q`）
3. 差分なし → スキップメッセージ表示
4. 差分あり → ユーザー確認フロー

## テスト観点

1. ターゲットディレクトリが存在しない場合: 新規コピー実行
2. 全ファイル差分なし: スキップメッセージ表示
3. 一部ファイルに差分あり: 差分ファイル一覧表示 + ユーザー確認
4. 新規ファイルがある場合: 差分扱いで表示
