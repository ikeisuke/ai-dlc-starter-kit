# 論理設計: cleanup trap unbound variable 修正

## 修正対象
- ファイル: `prompts/package/bin/migrate-config.sh`
- 関数: `_cleanup()` (34行目)

## 修正内容
```diff
- for f in "${_cleanup_files[@]}"; do
+ for f in ${_cleanup_files[@]+"${_cleanup_files[@]}"}; do
```

## 影響範囲分析
| 呼び出し経路 | 影響 | 確認方法 |
|-------------|------|---------|
| dry-run 経路（`_mktmp` 未呼び出し） | 修正により正常終了 | `--dry-run` で実行し exit code 確認 |
| 通常経路（`_mktmp` 呼び出しあり） | 変更なし（配列に要素あり） | 変換対象セクション（`[rules.mcp_review]`等）を含む fixture で実行し、一時ファイル生成・削除を確認 |
| trap EXIT（正常終了） | 上記2経路に含まれる | 上記で確認 |

**注**: エラー終了経路（trap EXIT でのエラーシグナル）は修正パターンの展開安全性により理論上安全だが、今回の Unit では正常終了時の cleanup を確認対象とする。

## 代替案と選定理由
| パターン | 互換性 | 採用 |
|---------|--------|------|
| `${arr[@]+"${arr[@]}"}` | Bash 3.2+ | ✓ |
| `(( ${#arr[@]} > 0 ))` + if 分岐 | Bash 3.2+ | 冗長 |
| `"${arr[@]}"` のまま（Bash 4.4+依存） | Bash 4.4+ のみ | macOS非互換 |
