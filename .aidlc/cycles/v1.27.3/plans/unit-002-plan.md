# Unit 002: 終了コード規約統一 - 計画

## 概要
シェルスクリプトの終了コード規約を統一し、ガイド文書を作成する。

## 変更対象ファイル
1. `prompts/package/bin/squash-unit.sh` — exit 2 → exit 1（引数バリデーション23箇所）
2. `prompts/package/bin/post-merge-cleanup.sh` — 警告時 exit 2 追加
3. `prompts/package/guides/exit-code-convention.md` — 新規作成

## 実装計画
1. squash-unit.sh の引数バリデーション exit 2 を一括 exit 1 に変更
2. post-merge-cleanup.sh の末尾に OVERALL="warning" 時の exit 2 を追加
3. 終了コード規約ガイド文書を作成

## 完了条件チェックリスト
- [x] squash-unit.sh の引数バリデーション部 exit 2 → exit 1 修正（22箇所）
- [x] post-merge-cleanup.sh の警告時 exit 2 追加
- [x] 終了コード規約ガイド文書の作成
- [x] 呼び出し元プロンプトとの整合性確認（operations.md の判定基準を更新）
