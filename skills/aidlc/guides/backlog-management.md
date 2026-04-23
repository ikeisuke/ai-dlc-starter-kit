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

**対応開始時の Milestone 紐付け（v2.4.0 以降）**:
- **前提**: 本機能は `[rules.github].milestone_enabled=true` のときのみ動作する（既定 off / Unit 008 / #597 Unit G）。明示有効化していないプロジェクトでは Milestone 関連ステップが全てスキップされる
- Milestone は Inception Phase の `05-completion.md` ステップ 1 で正式作成する（`vX.X.X` 形式、例: `v1.8.0`）。`02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作
- Issue 紐付けも `05-completion.md` ステップ 1 で正式実施（主経路: `gh issue edit --milestone "vX.X.X"`、権限/環境差分による失敗時フォールバック: `gh api --method PATCH`）
- 旧運用の `cycle:vX.X.X` ラベルは v2.4.0 で deprecated（物理残置、新サイクルでは付与しない）

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
2. **Milestone 紐付け**: 対応する項目を v2.4.0 以降の Milestone に紐付け（Inception Phase が自動実施）

   ```bash
   # 手動復旧パターン A-1: gh 利用可能 + duplicate/closed 混在の復旧時
   # 完了条件: title == "vX.X.X" の Milestone が open=1, closed=0 となること（同名 closed が残ると後続ステップが closed_count >= 1 で再停止する）
   # まず同名 Milestone 一覧を確認:
   gh api "repos/$OWNER/$REPO/milestones?state=all" --jq "[.[] | select(.title == \"vX.X.X\") | {number, state}]"
   # 不要 duplicate は close ではなく title 変更（例: vX.X.X-archived-YYYY-MM-DD）または delete で同名衝突を除去:
   gh api --method PATCH "repos/$OWNER/$REPO/milestones/<dup_number>" -f title="vX.X.X-archived-2026-04-23"
   # または:
   gh api --method DELETE "repos/$OWNER/$REPO/milestones/<dup_number>"
   # 整理後は A-2 で Issue 再紐付けに進む
   ```

   ```bash
   # 手動復旧パターン A-2 (Issue): gh 利用可能 + Issue 側 LINK_FAILED の復旧時。主経路:
   gh issue edit {ISSUE_NUMBER} --milestone "vX.X.X"
   # 権限/環境差分により失敗する場合のフォールバック:
   gh api --method PATCH "repos/OWNER/REPO/issues/{ISSUE_NUMBER}" -F milestone={MILESTONE_NUMBER}

   # 手動復旧パターン A-2 (PR): gh 利用可能 + PR 側 LINK_FAILED の復旧時。
   # GitHub 仕様により PR は Issue API 経由で Milestone を操作する:
   gh api --method PATCH "repos/OWNER/REPO/issues/{PR_NUMBER}" -F milestone={MILESTONE_NUMBER}
   # または GitHub UI 上で PR を開き、右サイドバーの Milestone を手動選択
   ```

   ```bash
   # 手動復旧パターン B: gh 利用不可時。REST API 直叩き（PAT が必要）または GitHub UI で手動操作。
   # 1. リポジトリ URL から OWNER/REPO を確認（例: github.com/OWNER/REPO）
   # 2. GitHub UI の Milestones 一覧（https://github.com/OWNER/REPO/milestones）または以下の REST API で MILESTONE_NUMBER を取得:
   curl -H "Authorization: token <PAT>" \
     -H "Accept: application/vnd.github+json" \
     "https://api.github.com/repos/OWNER/REPO/milestones?state=all" \
     | jq '.[] | select(.title == "vX.X.X" and .state == "open") | .number'
   # 上記が 1 件でない場合は紐付けせず、先に duplicate/closed 衝突を解消する（パターン A-1 相当を REST/UI で実施）
   # 3a. Issue に Milestone を紐付け:
   curl -X PATCH -H "Authorization: token <PAT>" \
     -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/OWNER/REPO/issues/{ISSUE_NUMBER} \
     -d '{"milestone": <MILESTONE_NUMBER>}'
   # または: GitHub UI 上で Issue を開き、右サイドバーの Milestone を手動選択

   # 3b. PR に Milestone を紐付け（GitHub 仕様により PR は Issue API 経由）:
   curl -X PATCH -H "Authorization: token <PAT>" \
     -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/OWNER/REPO/issues/{PR_NUMBER} \
     -d '{"milestone": <MILESTONE_NUMBER>}'
   # または: GitHub UI 上で PR を開き、右サイドバーの Milestone を手動選択
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

**注**: サイクル管理は v2.4.0 以降 GitHub Milestone に移行しました。Milestone は Inception Phase の `05-completion.md` ステップ 1 で正式作成・関連 Issue 紐付けを行います。`02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作です。旧運用の `cycle:vX.X.X` ラベルは deprecated（物理残置、Operations 担当者の判断で個別対応）:

```text
旧運用（v2.3.6 以前、deprecated）: `gh label create "cycle:v1.8.0" ...` を手動実行していた
新運用（v2.4.0 以降）: Milestone 作成の主経路は Inception Phase の `05-completion.md` ステップ 1。Milestone 不在時は Operations Phase の `01-setup.md` ステップ 11 が fallback 作成する。**Issue/PR の Milestone 紐付け復旧に限れば**、手動対応が必要なのは `gh` 利用不可時、または duplicate/closed 混在・`LINK_FAILED` で自動処理が停止した後の復旧時のみ。なお Milestone close（`04-completion.md` ステップ 5.5）は `gh_status != available` 時 / close API 失敗時にも手動復旧が必要（REST API 直叩き curl + PAT または GitHub UI、詳細は `skills/aidlc/steps/operations/04-completion.md` ステップ 5.5 を参照）
```

---

## 関連機能の現状（v2.4.0 時点）

GitHub Milestone との連携は v2.4.0 で本採用済み:

- **Inception Phase の `05-completion.md` ステップ 1 での Milestone 作成**: Inception Phase 完了処理として自動実施（Unit 005 / #597）
- **Operations Phase の `04-completion.md` ステップ 5.5 での Milestone close**: サイクル完了時に自動実施（Unit 006 / #597）
- **Operations Phase の `01-setup.md` ステップ 11 での Milestone 紐付け確認・fallback 作成**: Operations 開始時に自動実施（5 ケース判定 + 冪等補完原則）

将来的な追加検討:

- Unit 完了時の Issue 自動クローズ（現状: サイクル PR マージで Closes キーワード経由の auto-close）
- GitHub Projects との連携（ステータス管理）
- Milestone 進捗バッジの README 追加（v2.5.0 以降）
