# 完了時の必須作業 計画

## 概要
Operations Phase 完了に伴う必須作業を実施する

## 作業項目

### 1. README更新
- v1.3.1 の改善点を追加
- バージョンバッジを 1.3.1 に更新

### 2. 履歴記録
- history.md に Operations Phase 完了を追記

### 3. バックログ整理
サイクル固有バックログ（v1.3.1/backlog.md）の項目を処理：
- **対応済み項目**（共通から転記）: backlog-completed.md に移動、共通から削除
  - バックログ項目の対応済みチェック（Unit 1）
  - セットアップスキップ（Unit 2）
  - Dependabot PR確認（Unit 3）
- **未対応項目**（このサイクルで発見）: 共通バックログに移動
  - コミットハッシュ記録の注意事項
  - PRマージ後のブランチ削除
  - 作業中の割り込み対応ルール

### 4. メタ開発特有の作業
- version.txt を 1.3.1 に更新
- setup-init 実行（rsync で docs/aidlc/ を最新化）

### 5. Gitコミット
- Operations Phase の全成果物をコミット

### 6. PR作成
- main ブランチへの PR を作成
