---
name: codex-review
description: Codex CLIでコードレビューを実行する。AI-DLCの設計・実装レビューに使用。
argument-hint: [対象ファイルまたはレビュー指示]
compatibility: Requires codex CLI and network access (OpenAI API). Runs in read-only sandbox mode.
allowed-tools: Bash(codex:*)
---

# Codex Review

Codex CLIを使用してコードレビューを実行するスキル。

## 実行コマンド

```bash
codex exec -s read-only -C <project_directory> "<レビュー指示>"
```

## セッション継続（resume）

前回のセッションを継続してレビューする場合:

```bash
codex exec resume <session-id> "<追加指示>"
```

- セッションIDは前回の実行結果の末尾に表示されます（例: `session id: xxx`）
- resumeを使用すると、前回のセッション設定（`-C`、`-s`等）が継承されます

## 反復レビュー時のルール【重要】

AI-DLCの反復レビューフロー（`docs/aidlc/prompts/common/review-flow.md`）でCodexを使用する際は、**必ずresumeを使用**してください。

### resumeを使うべき場面

| 場面 | resume使用 | 理由 |
|------|------------|------|
| 反復レビュー（2回目以降） | 必須 | 前回の指摘内容を踏まえた継続レビューが必要 |
| 指摘への追加質問 | 必須 | 指摘の文脈を保持したまま深掘りできる |
| 修正後の再レビュー | 必須 | 修正箇所と元の指摘の関連を理解できる |
| 別のUnitや独立したレビュー対象 | 不要 | 新しいコンテキストで開始すべき |

### 反復レビューの流れ

```text
[1回目] codex exec -s read-only -C . "設計ドキュメントをレビューしてください"
        → 指摘あり、session id: abc123

[修正を実施]

[2回目] codex exec resume abc123 "指摘を修正しました。再度レビューしてください"
        → 追加指摘あり

[修正を実施]

[3回目] codex exec resume abc123 "追加の修正を行いました。確認してください"
        → 指摘なし、レビュー完了
```

## パラメータ

| パラメータ | 説明 |
|-----------|------|
| `-s read-only` | 読み取り専用サンドボックス（レビュー用） |
| `-C <dir>` | 対象プロジェクトのディレクトリ |
| `"<request>"` | レビュー指示（日本語可） |

## 使用例

### 設計レビュー

```bash
codex exec -s read-only -C . "docs/cycles/v1.12.1/design-artifacts/の設計ドキュメントをレビューしてください"
```

### 実装レビュー

```bash
codex exec -s read-only -C . "prompts/package/prompts/construction.mdの変更をレビューしてください"
```

## 実行手順

1. レビュー対象を特定する
2. 上記コマンド形式でCodexを実行
3. 指摘があれば修正し、resumeで再レビュー
4. 指摘なしになるまで反復
