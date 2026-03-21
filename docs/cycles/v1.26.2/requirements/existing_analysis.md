# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
bin/
  post-merge-cleanup.sh    # マージ後クリーンアップスクリプト（主要対象）
  post-merge-sync.sh       # post-merge-cleanup.shのラッパー（rules.mdで参照）
  ...
prompts/package/guides/    # ガイドドキュメント配置先（メタ開発用、14ファイル）
docs/aidlc/guides/         # ガイドドキュメント（rsync同期コピー、直接編集禁止）
```

## アーキテクチャ・パターン

### post-merge-cleanup.sh
- **構造**: ヘルパー関数 + 6処理ステップ（0a〜5）+ 引数解析 + オーケストレーション
- **根拠**: スクリプト内のステップ分割パターン（`step_0a`, `step_0b`, `step_1`〜`step_5`）
- **worktree判定**: `step_0a()` (L145-147) で `git_dir` が `<toplevel>/.git` と一致するか（ディレクトリ=通常リポジトリ、ファイル=worktree）で判定

### 処理ステップの移植性分析

| ステップ | 処理内容 | worktree固有 | 通常ブランチ適用可否 |
|---------|---------|:---:|:---:|
| 0a | 環境検証（worktreeチェック） | ○ | 分岐が必要 |
| 0b | 状態検証（未コミット変更等） | △ | 流用可能 |
| 1 | main pull (`git -C` で親リポジトリ更新) | × | 流用可能（自リポジトリのpullに変更） |
| 2 | fetch | × | 流用可能 |
| 3 | detached HEAD化 | ○ | スキップ（通常ブランチではmain checkoutに変更） |
| 4 | マージ済みブランチ削除 | × | 流用可能 |
| 5 | リモートブランチ削除 | × | 流用可能 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash | bin/post-merge-cleanup.sh |
| 依存コマンド | git, grep, printf, echo, cat | bin/post-merge-cleanup.sh 内のコマンド使用 |
| CLI引数 | --cycle (必須), --dry-run (任意), -h/--help | bin/post-merge-cleanup.sh 引数解析部 |

## 依存関係

- `post-merge-sync.sh` → `post-merge-cleanup.sh` を呼び出すラッパー（rules.mdで案内）
- `post-merge-cleanup.sh` は外部ライブラリ依存なし（bash + git + 標準Unixユーティリティ）
- ガイドドキュメントは `prompts/package/guides/` → `docs/aidlc/guides/` のrsync同期関係

## 特記事項

- メタ開発のため、ガイドの新規作成は `prompts/package/guides/troubleshooting.md` に行い、Operations Phaseのaidlc-setup同期で `docs/aidlc/guides/` にコピーされる
- `post-merge-cleanup.sh` は `bin/` 直下のため、直接編集可能（メタ開発のrsync対象外）
