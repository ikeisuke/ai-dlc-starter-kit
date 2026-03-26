# Operations Phase 完了作業 計画

## 概要
Operations Phase完了時の必須作業を実施

## 作業内容

### 1. バージョン更新（メタ開発特有）
```bash
echo "1.2.3" > version.txt
```

### 2. setup-init実行（アップグレードモード）
prompts/package/ → docs/aidlc/ に同期

### 3. README更新
変更履歴セクションにv1.2.3の内容を追記

### 4. 履歴記録
docs/cycles/v1.2.3/history.md に Operations Phase 完了を追記

### 5. バックログ整理
docs/cycles/v1.2.3/backlog.md を確認し、共通バックログに反映

### 6. Gitコミット
Operations Phase完了コミット

### 7. PR作成
mainブランチへのPRを作成

## 実行順序
1 → 2 → 3 → 4 → 5 → 6 → 7
