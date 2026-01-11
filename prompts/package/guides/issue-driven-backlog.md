# Issue駆動バックログ管理ガイド

## 概要

### Issue駆動バックログ管理とは

GitHub Issueを使用してバックログを管理する方式です。従来のローカルファイル管理（Git駆動）と選択制で利用できます。

### 従来方式（Git駆動）との違い

| 項目 | Git駆動 | Issue駆動 |
|------|---------|-----------|
| 保存先 | `docs/cycles/backlog/*.md` | GitHub Issues |
| 可視性 | リポジトリ内 | GitHub UI |
| 検索性 | grep/ファイル検索 | Issueフィルタ・ラベル |
| コラボレーション | PR経由 | Issueコメント |
| 外部連携 | 限定的 | GitHub Projects等 |

---

## 設定方法

### `docs/aidlc.toml` への設定追加

```toml
[backlog]
# バックログ管理モード設定
# mode: "git" | "issue"
# - git: ローカルファイルに保存（従来方式、デフォルト）
# - issue: GitHub Issueに保存
mode = "git"
```

### モードの選択基準

| 条件 | 推奨モード |
|------|------------|
| 個人開発・ローカル完結 | `git` |
| チーム開発・外部可視化 | `issue` |
| GitHub CLI未導入 | `git` |
| GitHub Projects連携予定 | `issue` |

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

```bash
# モード確認
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"

# Issue駆動の場合
if [ "$BACKLOG_MODE" = "issue" ]; then
    # GitHub CLI認証確認
    if ! gh auth status &>/dev/null; then
        echo "警告: GitHub CLI未認証。Git駆動にフォールバックします。"
        # Git駆動にフォールバック
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

**重要**: どのモードでも、参照時はIssueとファイル両方を確認します。

```bash
# GitHub Issueを確認
gh issue list --label backlog --state open

# ローカルファイルを確認
ls docs/cycles/backlog/
```

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

ラベルが存在しない場合、事前に作成が必要です:

```bash
# ラベル作成例
gh label create "backlog" --color "0052CC" --description "バックログアイテム"
gh label create "type:feature" --color "A2EEEF" --description "新機能"
gh label create "type:bugfix" --color "D73A4A" --description "バグ修正"
gh label create "type:chore" --color "FEF2C0" --description "雑務"
gh label create "type:refactor" --color "C5DEF5" --description "リファクタリング"
gh label create "type:docs" --color "0075CA" --description "ドキュメント"
gh label create "type:perf" --color "F9D0C4" --description "パフォーマンス"
gh label create "type:security" --color "D93F0B" --description "セキュリティ"
gh label create "priority:high" --color "B60205" --description "優先度: 高"
gh label create "priority:medium" --color "FBCA04" --description "優先度: 中"
gh label create "priority:low" --color "0E8A16" --description "優先度: 低"
gh label create "cycle:v1.7.0" --color "5319E7" --description "サイクル v1.7.0"
```

---

## 将来検討事項

### サイクル・フェーズ管理へのIssue連携

現在のUnit 005ではバックログ管理のみを対象としています。将来的には以下の連携も検討可能です:

- サイクル開始時のマイルストーン作成
- Unit完了時のIssue自動クローズ
- GitHub Projectsとの連携（ステータス管理）

詳細は `docs/cycles/backlog/feature-github-projects-integration.md` を参照してください。
