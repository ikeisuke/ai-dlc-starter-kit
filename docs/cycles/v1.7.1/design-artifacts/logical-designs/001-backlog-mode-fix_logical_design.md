# 論理設計: バックログモード読み込み修正

## 概要

各フェーズプロンプトにbacklog.mode設定の読み込みロジックを追加し、モードに応じた処理分岐を実現する。

## 設定読み込みパターン（共通）

### 読み込みコード（各プロンプトで使用）

**注意**: 以下のパターンには既知の問題があり、Unit 004で改善予定:
- コメント行を誤って読み込む可能性
- 次のセクション `[...]` で止まらない
- 空白やクォートなしの値に未対応

```bash
# バックログモード設定を読み込み（暫定版、Unit 004で改善予定）
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
echo "バックログモード: ${BACKLOG_MODE}"
```

### Issue駆動時のフォールバック確認

```bash
# mode=issue かつ GitHub CLI未インストールまたは未認証の場合はフォールバック
if [ "$BACKLOG_MODE" = "issue" ]; then
    if ! command -v gh &>/dev/null; then
        echo "警告: GitHub CLI未インストール。Git駆動にフォールバックします。"
        BACKLOG_MODE="git"
    elif ! gh auth status &>/dev/null; then
        echo "警告: GitHub CLI未認証。Git駆動にフォールバックします。"
        BACKLOG_MODE="git"
    fi
fi
```

**重要**: フォールバック時は必ず `BACKLOG_MODE="git"` に変更する（警告のみで放置しない）

## 各プロンプトの修正箇所

### 1. setup.md

**追加箇所**: 「最初に必ず実行すること」セクション（ステップ0.5後、ステップ1前）

**追加内容**:

```markdown
### 0.7. バックログモード確認

バックログモード設定を確認:

\`\`\`bash
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
echo "バックログモード: ${BACKLOG_MODE}"
\`\`\`

**判定結果表示**:
- `git`: ローカルファイル駆動（`docs/cycles/backlog/`）
- `issue`: GitHub Issue駆動（Issue作成、ラベル管理）

**mode=issue の場合、GitHub CLI認証確認**:
\`\`\`bash
if [ "$BACKLOG_MODE" = "issue" ]; then
    if gh auth status &>/dev/null; then
        echo "GitHub CLI: 認証済み"
    else
        echo "警告: GitHub CLI未認証。Issue駆動機能は制限されます。"
    fi
fi
\`\`\`
```

**目的**: Unit 002（ラベル作成）の前提となるmode判定を確立

### 2. construction.md

**追加箇所**: 「気づき記録フロー」セクション（127行目付近）

**修正内容**: 既存のファイル作成手順をmode分岐に変更

```markdown
**現在の記述**:
2. **共通バックログに新規ファイル作成**: `docs/cycles/backlog/{種類}-{スラッグ}.md` を作成

**修正後**:
2. **バックログ項目を作成**:

   **設定確認**:
   \`\`\`bash
   BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
   [ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
   \`\`\`

   **mode=git の場合**:
   `docs/cycles/backlog/{種類}-{スラッグ}.md` にファイルを作成

   **mode=issue の場合**:
   GitHub Issueを作成（ガイド参照: `docs/aidlc/guides/issue-driven-backlog.md`）
```

### 3. inception.md

**追加箇所**: 「バックログ確認」セクション（452行目付近）

**修正内容**: mode分岐を追加

```markdown
### 3. バックログ確認

**設定確認**:
\`\`\`bash
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
\`\`\`

#### 3-1. バックログ項目確認

**mode=git の場合**:
\`\`\`bash
ls docs/cycles/backlog/ 2>/dev/null
\`\`\`

**mode=issue の場合**:
\`\`\`bash
gh issue list --label backlog --state open
\`\`\`

**両モード共通**: ローカルファイルとIssue両方を確認し、漏れを防ぐ
```

### 4. operations.md

**追加箇所1**: 「バックログ整理と運用計画」セクション（493行目付近）

**修正内容**: mode分岐を追加

```markdown
#### 5.1 バックログ整理

**設定確認**:
\`\`\`bash
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
\`\`\`

**mode=git の場合**:
\`\`\`bash
ls docs/cycles/backlog/
\`\`\`
対応済み項目は `docs/cycles/backlog-completed/{{CYCLE}}/` に移動

**mode=issue の場合**:
\`\`\`bash
gh issue list --label backlog --state open
\`\`\`
対応済み項目は Issue をクローズ

**両モード共通**: ローカルファイルとIssue両方を確認
```

**追加箇所2**: 「バックログ記録」セクション（758行目付近）

**修正内容**: construction.mdと同様のmode分岐を追加

## 非機能要件

### パフォーマンス

- 設定読み込みは awk による単純なテキスト処理（即座に完了）
- GitHub CLI呼び出しはネットワーク遅延あり（mode=issue時のみ）

### 互換性

- デフォルト値 `git` により、既存プロジェクトへの影響なし
- aidlc.toml に `[backlog]` セクションがなくても動作

### セキュリティ

- 該当なし（ローカル設定の読み込みのみ）

## 設計レビュー確認事項

1. 設定読み込みパターンは既存（mcp_review等）と統一されているか → Yes
2. フォールバック機構は適切か → Yes
3. 各プロンプトでの追加箇所は適切か → 確認必要

## 不明点と質問

設計上の不明点はなし。
