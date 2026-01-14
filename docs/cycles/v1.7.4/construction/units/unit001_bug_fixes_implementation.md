# Unit 001: バグ修正 - 実装記録

## 概要

AI-DLCプロンプト内の2つのバグを修正した。

## 対象Issue

- #66: issue-onlyモードの正常動作
- #63: 未追跡ファイルのコミット対応

## 修正内容

### バグ#66: issue-onlyモード対応

**問題**: バックログモードが `issue-only` の場合、GitHub CLI確認やサイクルラベル作成がスキップされてしまう

**修正箇所**:

| ファイル | 修正内容 |
|---------|---------|
| `prompts/package/prompts/setup.md` | 条件式を `issue \|\| issue-only` に変更、見出し・テキストを更新 |
| `prompts/package/prompts/inception.md` | 条件式を `issue && issue-only` の否定から明示列挙に変更、見出しを更新 |

**修正パターン**:

```bash
# Before
if [ "$BACKLOG_MODE" = "issue" ]; then
if [ "$BACKLOG_MODE" != "issue" ]; then

# After
if [ "$BACKLOG_MODE" = "issue" ] || [ "$BACKLOG_MODE" = "issue-only" ]; then
if [ "$BACKLOG_MODE" != "issue" ] && [ "$BACKLOG_MODE" != "issue-only" ]; then
```

### バグ#63: 未追跡ファイル検出

**問題**: `git diff --quiet && git diff --cached --quiet` は未追跡ファイルを検出できない

**修正箇所**:

| ファイル | 箇所数 |
|---------|--------|
| `prompts/package/prompts/inception.md` | 4箇所 |
| `prompts/package/prompts/construction.md` | 4箇所 |
| `prompts/package/prompts/operations.md` | 4箇所 |

**修正パターン**:

```bash
# Before
git diff --quiet && git diff --cached --quiet || git add -A && git commit -m "..."

# After
[ -n "$(git status --porcelain)" ] && git add -A && git commit -m "..."
```

## 検証結果

- markdownlint: エラー0件
- 条件式の動作確認: パターンマッチは正しく機能

## 完了日

2026-01-14
