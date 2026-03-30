# バックログ管理ガイド

## 概要

AI-DLCにおけるバックログ管理の方式とフローを定義します。

バックログは常にGitHub Issueに記録します。

**関連ガイド**: ユーザー起点のバックログ登録時の確認フローは [backlog-registration.md](backlog-registration.md) を参照

> **DEPRECATED**: `[rules.backlog]` 設定は廃止されました。バックログは常にGitHub Issueに記録されます。設定ファイルに `[rules.backlog]` セクションが残っていても無視されます。

### ラベル構成

以下のラベルを使用します。

**作成時に付けるラベル（必須）**:
- `backlog` - バックログIssueの識別
- `type:feature` / `type:bugfix` / `type:chore` / `type:refactor` / `type:docs` / `type:perf` / `type:security` - 種類
- `priority:high` / `priority:medium` / `priority:low` - 優先度

**対応開始時に追加するラベル**:
- `cycle:vX.X.X` - 対応中のサイクル（例: `cycle:v1.8.0`）

---

## 前提条件

### GitHub CLIのインストールと認証

```bash
# インストール確認
gh --version

# 認証状態確認
gh auth status
```

未認証の場合:
```bash
gh auth login
```

### リポジトリへの書き込み権限

Issue作成にはリポジトリへの書き込み権限が必要です。

---

## フロー定義

### 新規バックログ作成

GitHub Issueを作成します。

```bash
gh issue create \
    --title "[Backlog] タイトル" \
    --label "backlog,type:feature,priority:medium" \
    --body-file /tmp/aidlc-backlog-body.txt
```

Issue本文はWriteツールで一時ファイルに書き出し、`--body-file` で指定します。

### バックログ完了時

```bash
# Issueをクローズ
gh issue close {ISSUE_NUMBER}
```

### バックログ無効化時（対応しない）

```bash
# 「対応しない」としてクローズ
gh issue close {ISSUE_NUMBER} --reason "not planned"
```

### バックログ参照時

```bash
# GitHub Issueを確認
gh issue list --label backlog --state open
```

---

## フェーズ固有のアクション

各フェーズでバックログに対して行うアクションを定義します。

### Inception Phase

1. **バックログ確認**: 既存のバックログ項目を確認し、今回のサイクルで対応する項目を選定
2. **サイクルラベル付与**: 対応する項目に `cycle:vX.X.X` ラベルを付与
   ```bash
   gh issue edit {ISSUE_NUMBER} --add-label "cycle:vX.X.X"
   ```

### Construction Phase

1. **バックログ記録**: 作業中に発見した課題・気づきをバックログに記録
2. **workaround記録**: 暫定対応を行った場合、本質的な解決策をバックログに記録

### Operations Phase

1. **バックログクローズ**: サイクルで対応した項目をクローズ（`gh issue close {ISSUE_NUMBER}`）
2. **残存確認**: 未対応の項目を次サイクルに引き継ぐか確認

---

## トラブルシューティング

### GitHub CLI未認証時の対応

GitHub CLI未認証の場合:
1. 警告メッセージが表示されます
2. ユーザーに手動登録を依頼します

認証するには:
```bash
gh auth login
```

### Issueラベルの設定

共通ラベルが存在しない場合、初期化スクリプトで一括作成できます:

```bash
# 共通ラベルの一括作成（11個）
# セットアップ時: prompts/setup/bin/init-labels.sh
# 単独実行時: [スターターキットパス]/prompts/setup/bin/init-labels.sh

# 確認のみ（実際に作成しない）
[スターターキットパス]/prompts/setup/bin/init-labels.sh --dry-run
```

**注**: サイクルラベル（`cycle:vX.X.X`）は上記スクリプトに含まれません。サイクル開始時に別途作成してください:

```bash
gh label create "cycle:v1.8.0" --color "5319E7" --description "サイクル v1.8.0"
```

---

## 将来検討事項

### サイクル・フェーズ管理へのIssue連携

将来的には以下の連携も検討可能です:

- サイクル開始時のマイルストーン作成
- Unit完了時のIssue自動クローズ
- GitHub Projectsとの連携（ステータス管理）
