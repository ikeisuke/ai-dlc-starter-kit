# 論理設計: main最新化チェック判定ロジック

## 変更箇所

### prompts/package/bin/setup-branch.sh

#### 新規関数: check_main_freshness()

handle_branch_mode()の前（L63付近）に追加:

```bash
# mainブランチの最新化チェック
check_main_freshness() {
    local target_ref="${1:-HEAD}"

    # fetch（GIT_TERMINAL_PROMPT=0で非対話、失敗時はfetch-failedで即return）
    if ! GIT_TERMINAL_PROMPT=0 git fetch -- origin >/dev/null 2>&1; then
        echo "main_status:fetch-failed"
        return 0
    fi

    # リモートのデフォルトブランチ検出（get-default-branch.shと同じロジック）
    local remote_main=""
    local default_branch
    default_branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
    if [[ -n "$default_branch" ]]; then
        remote_main="origin/${default_branch}"
    elif git rev-parse --verify origin/main >/dev/null 2>&1; then
        remote_main="origin/main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
        remote_main="origin/master"
    else
        echo "main_status:fetch-failed"
        return 0
    fi

    # 最新化判定: remote_mainがtarget_refの祖先かを確認
    if git merge-base --is-ancestor "$remote_main" "$target_ref" 2>/dev/null; then
        echo "main_status:up-to-date"
    else
        echo "main_status:behind"
    fi

    return 0
}
```

#### main()関数の変更（L148-159付近）

case文の後、ブランチ/worktree作成成功時に`check_main_freshness`を呼び出す:

```bash
    case "$mode" in
        branch)
            handle_branch_mode "$version"
            ;;
        worktree)
            handle_worktree_mode "$version"
            ;;
        *)
            output "error" "" "" "無効なモード: ${mode}（branch または worktree を指定してください）"
            return 1
            ;;
    esac

    # ブランチ/worktree作成成功後にmain最新化チェック
    # サイクルブランチのHEADを判定対象にする
    check_main_freshness "cycle/${version}"
```

**注意**: `set -e`環境で`handle_*`が失敗した場合、case文後のcheck_main_freshnessは実行されない（期待動作）。

#### 出力仕様コメントの更新（L10-15付近）

```text
# 出力形式:
#   status:success|already_exists|error
#   branch:cycle/v1.12.1
#   worktree_path:.worktree/cycle-v1.12.1  (worktreeモードのみ)
#   message:詳細メッセージ
#   main_status:up-to-date|behind|fetch-failed  (オプション、成功時のみ)
```

## テストケース

| シナリオ | 期待出力 |
|---------|---------|
| origin/mainがサイクルブランチHEADの祖先 | `main_status:up-to-date` |
| origin/mainにサイクルブランチ未取込のコミットがある | `main_status:behind` |
| git fetch失敗（ネットワーク障害等） | `main_status:fetch-failed` |
| origin/mainもorigin/masterも存在しない | `main_status:fetch-failed` |
| origin/masterのみ存在するリポジトリ | 正常にmasterで判定 |
| trunkブランチのリポジトリ | git remote show originから検出して正常判定 |
| worktreeモードで作成後 | サイクルブランチ（cycle/version）を判定対象にする |
