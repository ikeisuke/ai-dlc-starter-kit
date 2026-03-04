---
name: session-title
description: Sets terminal tab title and iTerm2 badge for AI-DLC session identification. Use at step 1.5 (Inception) or step 2.6 (Construction/Operations) of each AI-DLC phase. Also use when the user says "セッションタイトル", "set session title", or "session-title".
argument-hint: <project_name> <phase> <cycle>
---

# Session Title

ターミナルのタブタイトルとiTerm2バッジを設定し、複数セッションの判別を容易にする。

## 実行方法

1. 引数を決定する:
   - `project_name`: `docs/aidlc.toml` の `[project].name`、取得失敗時はディレクトリ名
   - `phase`: 現在のフェーズ名（`Inception` / `Construction` / `Operations`）
   - `cycle`: サイクルバージョン（`current_branch` から抽出、不明時は `unknown`）

2. スクリプトを探索して実行する:

```bash
if [ -x "prompts/package/skills/session-title/bin/aidlc-session-title.sh" ]; then
  bash prompts/package/skills/session-title/bin/aidlc-session-title.sh "$PROJECT_NAME" "$PHASE" "$CYCLE"
elif [ -x "docs/aidlc/skills/session-title/bin/aidlc-session-title.sh" ]; then
  bash docs/aidlc/skills/session-title/bin/aidlc-session-title.sh "$PROJECT_NAME" "$PHASE" "$CYCLE"
fi
```

- 各引数は必ず二重引用符で囲む
- コマンド内に `$()` を使用しない（AIが値を事前に解決してから組み立てる）
- エラー時はスキップして続行（フロー停止しない）

## 対応ターミナル

| ターミナル | タブタイトル | 背景バッジ |
|-----------|------------|-----------|
| iTerm2 | osascript | iTerm2エスケープシーケンス |
| Terminal.app | osascript | 非対応 |
| その他 | TTY直接書き込み | 非対応 |
