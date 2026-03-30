# レビューサマリ: スクリプトバグ修正

## 基本情報

- **サイクル**: v1.18.0
- **フェーズ**: Construction
- **対象**: Unit 004 - スクリプトバグ修正

---

## Set 1: 2026-03-01 09:14:53

- **レビュー種別**: architecture
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 高 | ルートコミット時の範囲式定義が誤り。Gitの`A..B`はAを含まないため`first..last`ではfirstが欠落 | 修正済み: `safe_log_range()`で`git log last`（ルートから全コミット含む）に変更 |
| 2 | 中 | resolve-starter-kit-path.shの依存定義矛盾。「依存なし」だが`ghq root`に依存 | 修正済み: `ghq root`依存を削除、環境変数`AIDLC_STARTER_KIT_PATH`（必須）に変更 |
| 3 | 中 | `label-not-found`の後方互換方針不足。ヘルプ・呼び出し側契約更新が未記載 | 修正済み: `show_help()`のエラー一覧更新を実装注意事項に追記 |
| 4 | 低 | 出力方針の一貫性。stderr依存が発生する可能性 | 修正済み: アーキテクチャパターン節で「機械可読契約はstdoutのみ、stderrは非契約」を明記 |
| 5 | 中 | AIDLC_STARTER_KIT_PATHが「オプション」記載だが実質必須 | 修正済み: user-projectモードで「必須」と明記、未設定時エラーメッセージ追記 |
| 6 | 低 | stderr vs stdout不整合。冒頭と実装注意で解釈が分かれる | 修正済み: アーキテクチャパターン節を統一 |
| 7 | 低 | safe_range_exprのインターフェースとrebase起点の責務混在 | 修正済み: safe_log_range（git log専用）とrebase_base_args（rebase専用）に分離 |
