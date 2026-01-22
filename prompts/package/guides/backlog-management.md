# バックログ管理ガイド

## 概要

AI-DLCにおけるバックログ管理の方式とフローを定義します。

### モード一覧

| mode | 保存先 | 説明 |
|------|--------|------|
| git | `docs/cycles/backlog/*.md` | ローカルファイルがデフォルト（他の保存先も許容） |
| issue | GitHub Issues | GitHub Issueがデフォルト（他の保存先も許容） |
| git-only | `docs/cycles/backlog/*.md` | ローカルファイルのみ（Issue作成禁止） |
| issue-only | GitHub Issues | GitHub Issueのみ（ローカルファイル作成禁止） |

### 排他モード（`*-only`）について

`git-only` または `issue-only` を選択した場合：
- 指定された保存先のみを使用
- 他の保存先への記録は禁止
- バックログ確認時も指定された保存先のみを確認

### Git駆動 vs Issue駆動

| 項目 | Git駆動 | Issue駆動 |
|------|---------|-----------|
| 保存先 | `docs/cycles/backlog/*.md` | GitHub Issues |
| 可視性 | リポジトリ内 | GitHub UI |
| 検索性 | grep/ファイル検索 | Issueフィルタ・ラベル |
| コラボレーション | PR経由 | Issueコメント |
| 外部連携 | 限定的 | GitHub Projects等 |

---

## 設定方法

### `docs/aidlc.toml` への設定

```toml
[backlog]
# バックログ管理モード設定
# mode: "git" | "issue" | "git-only" | "issue-only"
# - git: ローカルファイルがデフォルト、状況に応じてIssueも許容（デフォルト）
# - issue: GitHub Issueがデフォルト、状況に応じてローカルも許容
# - git-only: ローカルファイルのみ（Issueへの記録を禁止）
# - issue-only: GitHub Issueのみ（ローカルファイルへの記録を禁止）
mode = "git"
```

### モードの選択基準

| 条件 | 推奨モード |
|------|------------|
| 個人開発・ローカル完結 | `git` または `git-only` |
| チーム開発・外部可視化 | `issue` または `issue-only` |
| GitHub CLI未導入 | `git` または `git-only` |
| GitHub Projects連携予定 | `issue` または `issue-only` |
| 柔軟な運用が必要 | `git` または `issue`（非排他） |
| 厳密な一元管理が必要 | `git-only` または `issue-only`（排他） |

### ラベル構成

Issue駆動を選択した場合、以下のラベルを使用します。

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

#### Issue駆動の場合

**モード確認**: AIが `docs/aidlc.toml` をReadツールで読み取り、`[backlog]` セクションの `mode` 値を確認。

**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `git` として扱う。

```bash
# Issue駆動の場合（issue または issue-only）
if [ "$BACKLOG_MODE" = "issue" ] || [ "$BACKLOG_MODE" = "issue-only" ]; then
    # GitHub CLI認証確認
    if ! gh auth status &>/dev/null; then
        if [ "$BACKLOG_MODE" = "issue-only" ]; then
            echo "エラー: GitHub CLI未認証。issue-only モードでは認証が必須です。"
            echo "gh auth login を実行してください。"
            exit 1
        else
            echo "警告: GitHub CLI未認証。Git駆動にフォールバックします。"
            # Git駆動にフォールバック
        fi
    else
        gh issue create \
            --title "[Backlog] タイトル" \
            --label "backlog,type:feature,priority:medium" \
            --body "$(cat <<'EOF'
## スラッグ
feature-example-slug

## 概要
簡潔な説明

## 詳細
詳細な説明

## 対応案
推奨される対応方法
EOF
)"
    fi
fi
```

#### Git駆動の場合

`docs/cycles/backlog/{type}-{slug}.md` にファイルを作成します。

テンプレート: `docs/aidlc/templates/backlog_item_template.md`

### バックログ完了時

#### Issue駆動の場合

```bash
# Issueをクローズ
gh issue close {ISSUE_NUMBER}
```

#### Git駆動の場合

```bash
# 完了ディレクトリに移動（履歴保持）
mkdir -p docs/cycles/backlog-completed/{{CYCLE}}
mv docs/cycles/backlog/{type}-{slug}.md docs/cycles/backlog-completed/{{CYCLE}}/
```

### バックログ無効化時（対応しない）

#### Issue駆動の場合

```bash
# 「対応しない」としてクローズ
gh issue close {ISSUE_NUMBER} --reason "not planned"
```

#### Git駆動の場合

```bash
# ファイルを削除（履歴はgitに残る）
rm docs/cycles/backlog/{type}-{slug}.md
```

### バックログ参照時

**非排他モード（git / issue）の場合**: IssueとGitファイル両方を確認します。

```bash
# GitHub Issueを確認
gh issue list --label backlog --state open

# ローカルファイルを確認
ls docs/cycles/backlog/
```

**排他モード（git-only / issue-only）の場合**: 指定された保存先のみを確認します。

---

## フェーズ固有のアクション

各フェーズでバックログに対して行うアクションを定義します。

### Inception Phase

1. **バックログ確認**: 既存のバックログ項目を確認し、今回のサイクルで対応する項目を選定
2. **サイクルラベル付与**（Issue駆動の場合）: 対応する項目に `cycle:vX.X.X` ラベルを付与
   ```bash
   gh issue edit {ISSUE_NUMBER} --add-label "cycle:vX.X.X"
   ```
3. **移行提案**（非排他モードのみ）: 現在のmodeと異なる保存先に項目がある場合、移行を提案

### Construction Phase

1. **バックログ記録**: 作業中に発見した課題・気づきをバックログに記録
2. **workaround記録**: 暫定対応を行った場合、本質的な解決策をバックログに記録

### Operations Phase

1. **バックログクローズ**: サイクルで対応した項目をクローズ
   - Issue駆動: `gh issue close {ISSUE_NUMBER}`
   - Git駆動: `docs/cycles/backlog-completed/{{CYCLE}}/` に移動
2. **残存確認**: 未対応の項目を次サイクルに引き継ぐか確認

---

## トラブルシューティング

### GitHub CLI未認証時の対応

Issue駆動モードでGitHub CLI未認証の場合:
1. 警告メッセージが表示されます
2. 自動的にGit駆動にフォールバックします
3. 設定ファイル（`aidlc.toml`）は変更されません

認証するには:
```bash
gh auth login
```

### Issueラベルの設定

共通ラベルが存在しない場合、初期化スクリプトで一括作成できます:

```bash
# 共通ラベルの一括作成（11個）
docs/aidlc/bin/init-labels.sh

# 確認のみ（実際に作成しない）
docs/aidlc/bin/init-labels.sh --dry-run
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
