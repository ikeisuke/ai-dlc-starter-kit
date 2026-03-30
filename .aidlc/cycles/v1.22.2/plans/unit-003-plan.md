# Unit 003 計画: セットアップ時のデフォルト許可パターン追加

## 概要

AI-DLCセットアップ完了時に、頻繁に使用するスクリプトの実行許可パターンを `.claude/settings.json` に自動設定する。

## 問題分析

- AI-DLC利用時、`docs/aidlc/bin/*.sh` 等のスクリプト実行で毎回許可プロンプトが表示される
- `.claude/settings.local.json` に手動で追加する必要がある
- デフォルトの許可パターンをプロジェクト共有の `.claude/settings.json` に設定することで初回体験を改善

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/bin/setup-ai-tools.sh` | デフォルト許可パターンの `.claude/settings.json` 自動設定ステップ追加 |

## 実装計画

### 1. setup-ai-tools.sh への許可パターン設定ステップ追加

- 新規ステップ [4/4] としてClaude Code許可パターン設定を追加
- `.claude/settings.json` が存在しない場合は新規作成（テンプレートJSON）
- 既存の場合:
  - jqが利用可能 → `permissions.allow` 配列にパターンを追加（重複排除）
  - jqが利用不可 → 警告を出力しスキップ（手動設定を案内）
- テンポラリファイル経由で原子的更新（書き込み失敗時に元ファイルを破損しない）
- 既存エントリの削除は行わない

### 2. JSON操作ツール依存

| ツール | 必須/任意 | 使用場面 |
|--------|---------|---------|
| jq | 任意 | 既存JSONへのパターン追加・重複排除 |

- jq不在時: `.claude/settings.json`が不在なら新規作成（テンプレート出力）。既存なら警告スキップ。
- daselは使用しない（JSONのネスト配列操作にはjqが適切）

### 3. デフォルト許可パターン

AI-DLCの基本操作に必要な最小限のパターン。引数不要なスクリプトは`:*`を付けない:

```
Bash(docs/aidlc/bin/write-history.sh:*)
Bash(docs/aidlc/bin/read-config.sh:*)
Bash(docs/aidlc/bin/check-gh-status.sh)
Bash(docs/aidlc/bin/check-backlog-mode.sh)
Bash(docs/aidlc/bin/run-markdownlint.sh:*)
Bash(docs/aidlc/bin/issue-ops.sh:*)
Bash(docs/aidlc/bin/squash-unit.sh:*)
Bash(docs/aidlc/bin/setup-ai-tools.sh)
Bash(docs/aidlc/bin/setup-branch.sh:*)
Bash(docs/aidlc/bin/env-info.sh:*)
Bash(docs/aidlc/bin/suggest-version.sh:*)
Bash(docs/aidlc/bin/init-cycle-dir.sh:*)
Bash(docs/aidlc/bin/pr-ops.sh:*)
Bash(docs/aidlc/bin/check-open-issues.sh:*)
Bash(docs/aidlc/bin/validate-uncommitted.sh:*)
Bash(docs/aidlc/bin/validate-remote-sync.sh:*)
Bash(docs/aidlc/bin/cycle-label.sh:*)
Bash(docs/aidlc/bin/label-cycle-issues.sh:*)
Bash(docs/aidlc/bin/post-merge-cleanup.sh:*)
Bash(docs/aidlc/bin/sync-package.sh:*)
Bash(docs/aidlc/bin/validate-git.sh:*)
Bash(mktemp /tmp/aidlc-commit-msg.XXXXXX)
Bash(mktemp /tmp/aidlc-squash-msg.XXXXXX)
Bash(mktemp /tmp/aidlc-history-content.XXXXXX)
Bash(mktemp /tmp/aidlc-pr-body.XXXXXX)
Bash(mktemp /tmp/aidlc-review-input.XXXXXX)
Skill(reviewing-architecture)
Skill(reviewing-code)
Skill(reviewing-security)
Skill(reviewing-inception)
Skill(squash-unit)
Skill(aidlc-setup)
```

**`:*`の使用基準**: AI-DLCの各フェーズで自動実行されるスクリプトで、引数にcycle名・unit番号・パス等の可変値が必要なもの。引数不要なスクリプト（check-gh-status.sh等）は引数なしパターン。

### 4. 異常系対応

| 状況 | 対応 |
|------|------|
| `.claude/settings.json` 不在 | テンプレートJSONを新規作成 |
| `.claude/settings.json` がJSONとして不正 | バックアップ（`.claude/settings.json.bak`）後に新規作成 |
| 書き込み失敗 | テンポラリファイルを削除、警告を表示 |
| jq不在かつ既存JSON | 警告表示しスキップ（手動設定案内） |

### 5. 検証

- `.claude/settings.json` が存在しない状態から実行 → 新規作成されること
- 既存の `.claude/settings.json` がある状態から実行 → パターンが追加されること
- 既にパターンが含まれる場合 → 重複追加されないこと
- 壊れたJSONの場合 → バックアップ＋新規作成されること

## 完了条件チェックリスト

- [ ] setup-ai-tools.sh にデフォルト許可パターン設定ステップが追加されていること
- [ ] `.claude/settings.json` が新規作成されること（不在時）
- [ ] 既存の `.claude/settings.json` にパターンが追加されること（jqあり、既存時）
- [ ] 既存の `permissions.allow` エントリが削除されないこと
- [ ] 重複パターンが追加されないこと
- [ ] 壊れたJSONの場合にバックアップ＋新規作成されること
- [ ] jq不在時に既存JSONを破損しないこと（スキップ＋警告）
