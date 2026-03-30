# 完了時の必須作業 計画

## 概要

Operations Phase の全ステップ完了後、リリースに向けた最終作業を実施する。

## 作業内容

### 1. README更新
README.md に v1.3.0 の変更内容を追記

### 2. 履歴記録
`docs/cycles/v1.3.0/history.md` に Operations Phase 完了を追記（heredoc使用）

### 3. バックログ整理
`docs/cycles/v1.3.0/backlog.md` を確認し、共通バックログに反映が必要な項目がないか確認

### 4. メタ開発特有の作業
- `version.txt` を `1.3.0` に更新
- setup-init実行（アップグレードモード）で `docs/aidlc/` を最新化

### 5. Gitコミット
Operations Phase で作成したすべてのファイルをコミット

### 6. PR作成
mainブランチへのPRを作成

## 成果物

- 更新された README.md
- 更新された history.md
- PRのURL
