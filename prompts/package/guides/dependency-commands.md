# 依存コマンド追加手順

新しい依存コマンドをAI-DLCに追加する手順。

## 1. env-info.shへの追加

### 1.1 汎用ツールの場合

認証確認が不要なツール（例: dasel, jj）を追加する場合。

**追加手順**:

1. `prompts/package/bin/env-info.sh` のヘルプメッセージにツール名を追加
2. `main` 関数に `check_tool` を使った出力を追加

**コード例**:

```bash
# ヘルプメッセージ（show_help関数の cat << 'EOF' ... EOF 内）に追加
依存ツール（gh, dasel, jj, git, newtool）の状態を一覧で出力します。

# main関数内に追加（出力順を考慮して適切な位置に）
echo "newtool:$(check_tool newtool)"
```

### 1.2 認証が必要なツールの場合

認証確認が必要なツール（例: gh）を追加する場合。

**追加手順**:

1. 専用のチェック関数を作成（`check_gh` を参考に）
2. ヘルプメッセージとコメントを更新:
   - ファイル先頭コメントの `not-authenticated` 説明から「（ghのみ）」を更新
   - `show_help` 関数内のツール名を追加（`依存ツール（gh, dasel, jj, git, newtool）`）
   - `show_help` 関数内の `not-authenticated` 説明から「（ghのみ）」を更新
   - 例示出力行にツールを追加
3. `main` 関数で専用関数を呼び出し

**コード例**:

```bash
# 新しいチェック関数を追加（check_gh関数の後に配置）
check_newtool() {
    if ! command -v newtool >/dev/null 2>&1; then
        echo "not-installed"
        return
    fi
    # 認証コマンドはツールごとに異なる（例: newtool auth status）
    if newtool auth status >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-authenticated"
    fi
}

# main関数内で呼び出し
echo "newtool:$(check_newtool)"
```

## 2. setup.mdへの追加

### 2.1 運用ルールへの影響説明追加

**追加場所**: `prompts/package/prompts/setup.md` の「**gh/daselが `available` 以外の場合の影響**」セクション

**コード例**:

```markdown
**gh/dasel/newtoolが `available` 以外の場合の影響**:

- gh: ドラフトPR作成、Issue操作、ラベル作成をスキップ
- dasel: AIが設定ファイルを直接読み取る（機能上の影響なし）
- newtool: [影響の説明]
```

### 2.2 状態値の意味の更新（認証ツール追加時のみ）

認証が必要なツールを追加した場合、「状態値の意味」セクションも更新が必要。

**追加場所**: `prompts/package/prompts/setup.md` の「状態値の意味」セクション

**変更内容**:

```markdown
# 変更前
- `not-authenticated`: 未認証（ghのみ）

# 変更後（例: newtoolを追加した場合）
- `not-authenticated`: 未認証（gh, newtool）
```

## 3. 各プロンプトでの利用方法追加（必要に応じて）

新しいツールが特定のフェーズで使用される場合、該当プロンプトに利用方法を追加。

**対象ファイル例**:

- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

**追加内容**:

- ツールの利用可否確認方法（env-info.sh結果の参照）
- ツールが利用不可の場合の代替フロー

## 4. チェックリスト

依存コマンド追加時の確認項目:

- [ ] env-info.shのヘルプメッセージにツール名追加
- [ ] env-info.shにチェック関数またはcheck_tool呼び出し追加
- [ ] env-info.shの出力順コメント更新（`# 出力順序は固定（gh → dasel → jj → git）` の行、必要に応じて）
- [ ] env-info.shのヘルプ例示出力行にツール追加
- [ ] setup.mdの影響説明に追加
- [ ] 動作確認（env-info.sh実行）
- [ ] 関連プロンプトへの利用方法追加（必要に応じて）

**認証が必要なツールの場合、追加で確認**:

- [ ] env-info.shのファイル先頭コメントで「(ghのみ)」→「(gh, newtool)」に更新
- [ ] env-info.shのshow_help関数内で「(ghのみ)」→「(gh, newtool)」に更新
- [ ] setup.mdの「状態値の意味」で「(ghのみ)」→「(gh, newtool)」に更新
