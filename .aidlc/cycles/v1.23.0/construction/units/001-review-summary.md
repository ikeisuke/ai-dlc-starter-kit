# レビューサマリ: 共通プロンプトリファクタリング

## 基本情報

- **サイクル**: v1.23.0
- **フェーズ**: Construction
- **対象**: Unit 001 - 共通プロンプトリファクタリング

---

## Set 1: 2026-03-17 23:18:06

- **レビュー種別**: code, security
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘対応判断完了

### 指摘一覧

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| C1 | 高 | review-flow.md エラー処理セクション - `tools = []` の扱いが行27（cli_available=false）と行51（デフォルト使用）で矛盾 | 修正済み（review-flow.md L51: 空配列の記述を「cli_available=false扱い」に統一） |
| C2 | 中 | review-flow.md 共通履歴記録手順 - `{呼び出し元のステップ名}` 列挙にPhase 2 ステップ4と計画承認前が欠落 | 修正済み（review-flow.md L938-942: 2項目を追加） |
| C3 | 低 | review-flow.md 簡易インライン方式 - 「ステップ5のレビュー種別一覧等」の参照先表現が不正確 | 修正済み（review-flow.md L757: 「レビュー種別の決定」セクション参照に変更） |
| C4 | 中 | commit-flow.md --from/--toフォールバック手順 - 手順1がコードブロック内コメントで連番が不自然 | 修正済み（commit-flow.md L386: 手順1をコードブロック外の番号付きリストに移動） |
| C5 | 中 | review-flow.md write-history.sh呼び出しパターン - Writeツール→実行→削除が多数重複 | OUT_OF_SCOPE（理由: 本Unitのスコープは設計で定義した「履歴記録テンプレート」「ステップ末尾の共通処理」の2パターンのみ。write-history.sh呼び出しパターンの共通化は別途対応） |
| S1 | 高 | review-flow.md write-history.shテンプレート - `--cycle {{CYCLE}}`等のプレースホルダ変数が未クォートでシェルインジェクションリスク | 修正済み（review-flow.md 全テンプレート: `"{{CYCLE}}"` `"{{PHASE}}"` `"{N}"` にクォート追加） |
| S2 | 中 | review-flow.md/commit-flow.md 一時ファイル - 固定パス例がコマンド引数に使用されシンボリックリンク悪用リスク | OUT_OF_SCOPE（理由: テンポラリファイル規約（L105）で「コードブロック内の/tmp/aidlc-*パスはパターン例示」と明記済み。実運用ではmktempで生成） |
| S3 | 中 | commit-flow.md 共通手順 - `git add -A` が標準で機密ファイルを誤ステージングするリスク | OUT_OF_SCOPE（理由: git add方針の変更は本Unitの冗長記述削減スコープ外） |
| S4 | 低 | subagent-usage.md - 委任時のクレデンシャル最小化ルールが不足 | OUT_OF_SCOPE（理由: 本Unitはステップ参照番号の更新のみ。委任ルール拡充は別途対応） |
