# AIレビューサマリー: Unit 005 その他ガイドの事実誤記確認

## レビュー方法

- ツール: セルフレビュー（サブエージェント方式）
- 対象: `prompts/package/guides/config-merge.md`, `prompts/package/guides/error-handling.md`

## 指摘一覧

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 低 | config-merge.md: AI実行時のWriteツール使用推奨注記がない | スコープ外（既存構造） |
| 2 | 低 | config-merge.md: $HOME未設定時の終了コード挙動が不明 | スコープ外（既存構造） |
| 3 | 低 | error-handling.md: squash失敗のrecoveryコマンド具体例がない | スコープ外（既存構造） |

## 結論

指摘3件すべて低重要度・スコープ外。修正不要。
