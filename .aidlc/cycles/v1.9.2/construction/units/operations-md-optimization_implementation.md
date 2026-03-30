# 実装記録: operations.mdサイズ最適化

## 概要

operations.mdの冗長な説明を簡略化し、1029行から807行に削減した。

## 実装内容

### 1. 付録の外部ファイル化

- 「付録: 依存コマンド追加手順」セクション（128行）を削除
- 新規ガイドファイル `prompts/package/guides/dependency-commands.md` に内容を移動
- operations.mdには参照リンクのみ残す（3行）

### 2. iOSビルド番号確認のスクリプト化

- 新規スクリプト `prompts/package/bin/ios-build-check.sh` を作成
- 複雑なbashコマンド（約80行）をスクリプトに移動
- operations.mdではスクリプト呼び出しと出力解釈のみ記載（約30行）

### 3. デフォルトブランチ取得のスクリプト化

- 新規スクリプト `prompts/package/bin/get-default-branch.sh` を作成
- 重複するブランチ取得ロジックを統一

## 変更ファイル

| ファイル | 操作 | 変更概要 |
|----------|------|----------|
| `prompts/package/prompts/operations.md` | 編集 | 付録削除、スクリプト呼び出しに置換 |
| `prompts/package/guides/dependency-commands.md` | 新規 | 付録内容を移動 |
| `prompts/package/bin/ios-build-check.sh` | 新規 | iOSビルド番号確認スクリプト |
| `prompts/package/bin/get-default-branch.sh` | 新規 | デフォルトブランチ取得スクリプト |

## 検証結果

| 項目 | 結果 |
|------|------|
| 行数 | 807行（目標1000行以下 達成） |
| 削減量 | 222行（21.6%削減） |
| 必須キーワード | すべて存在（CI/CD, 監視, CHANGELOG, git tag） |
| 必須セクション | すべて存在 |
| スクリプト動作 | 正常 |

## 完了条件チェックリスト

- [x] 冗長な説明文の簡略化
- [x] 重複する注意書きの削減
- [x] 過度に詳細な例示の簡略化
- [x] 最終行数が1000行以下であること（807行）
- [x] 必須セクションがすべて存在すること
- [x] 重要キーワードがすべて存在すること

## 状態

完了
