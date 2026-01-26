# 論理設計: env-info.sh セットアップ情報追加

## コンポーネント構成

```
env-info.sh
├── 引数解析（main関数）
├── ツール状態確認
│   ├── check_gh()
│   └── check_tool()
└── セットアップ情報取得（新規）
    ├── get_project_name()
    ├── get_backlog_mode()
    ├── get_current_branch()
    └── get_latest_cycle()
```

## 新規関数設計

### get_project_name()

```bash
# docs/aidlc.toml から project.name を取得
# dasel未インストール時は空値を返す
get_project_name() {
    if ! command -v dasel >/dev/null 2>&1; then
        echo ""
        return
    fi
    dasel -f docs/aidlc.toml -r toml 'project.name' 2>/dev/null || echo ""
}
```

### get_backlog_mode()

```bash
# docs/aidlc.toml から backlog.mode を取得
# dasel未インストール時は空値を返す
get_backlog_mode() {
    if ! command -v dasel >/dev/null 2>&1; then
        echo ""
        return
    fi
    dasel -f docs/aidlc.toml -r toml 'backlog.mode' 2>/dev/null || echo ""
}
```

### get_current_branch()

```bash
# 現在のGitブランチを取得
# Gitリポジトリ外では空値を返す
get_current_branch() {
    git branch --show-current 2>/dev/null || echo ""
}
```

### get_latest_cycle()

```bash
# docs/cycles/ 配下の最新サイクルバージョンを取得
# ディレクトリがない場合は空値を返す
get_latest_cycle() {
    if [[ ! -d "docs/cycles" ]]; then
        echo ""
        return
    fi
    ls -1 docs/cycles/ 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 || echo ""
}
```

## 引数解析の拡張

```bash
main() {
    local setup_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --setup)
                setup_mode=true
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done

    # 既存出力（常に出力）
    echo "gh:$(check_gh)"
    echo "dasel:$(check_tool dasel)"
    echo "jj:$(check_tool jj)"
    echo "git:$(check_tool git)"

    # --setup オプション時のみ追加出力
    if [[ "$setup_mode" == true ]]; then
        echo "project.name:$(get_project_name)"
        echo "backlog.mode:$(get_backlog_mode)"
        echo "current_branch:$(get_current_branch)"
        echo "latest_cycle:$(get_latest_cycle)"
    fi
}
```

## ヘルプ更新

```
OPTIONS:
  -h, --help    このヘルプを表示
  --setup       セットアップ情報を追加出力
```

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| dasel未インストール | project.name, backlog.mode は空値 |
| docs/aidlc.toml不存在 | project.name, backlog.mode は空値 |
| Gitリポジトリ外 | current_branch は空値 |
| docs/cycles/不存在 | latest_cycle は空値 |
