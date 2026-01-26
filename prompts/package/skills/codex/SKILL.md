---
name: codex
description: OpenAI Codex CLIを使用したコードレビュー、分析、コードベースへの質問を実行する。使用場面: (1) コードレビュー依頼時、(2) コードベース全体の分析、(3) 実装に関する質問、(4) バグの調査、(5) リファクタリング提案、(6) 解消が難しい問題の調査。トリガー: "codex", "コードレビュー", "レビューして", "分析して", "/codex"
---

# Codex

Codex CLIを使用してコードレビュー・分析を実行するスキル。

## 実行コマンド

```bash
codex exec -s read-only -C <project_directory> "<request>"
```

## セッション継続（resume）

前回のセッションを継続して会話する場合:

```bash
codex exec resume <session-id> "<request>"
```

- セッションIDは前回の実行結果の末尾に `session id: xxx` として表示されます
- 同じコンテキストで追加の質問や確認ができます

## パラメータ

| パラメータ | 説明 |
|-----------|------|
| `-s read-only` | 読み取り専用サンドボックス（安全な分析用） |
| `-s workspace-write` | ワークスペース書き込み可能 |
| `-C <dir>` | 対象プロジェクトのディレクトリ |
| `--full-auto` | 自動実行（`-s workspace-write`を含む、読み取り専用と併用不可） |
| `"<request>"` | 依頼内容（日本語可） |

## 使用例

### コードレビュー（読み取り専用）

```bash
codex exec -s read-only -C /path/to/project "このプロジェクトのコードをレビューして、改善点を指摘してください"
```

### バグ調査（読み取り専用）

```bash
codex exec -s read-only -C /path/to/project "認証処理でエラーが発生する原因を調査してください"
```

### 自動修正（書き込み可能）

```bash
codex exec --full-auto -C /path/to/project "このバグを修正してください"
```

### セッション引き継ぎ

上記「セッション継続（resume）」セクションを参照。

## 実行手順

1. ユーザーから依頼内容を受け取る
2. 対象プロジェクトのディレクトリを特定する
3. 上記コマンド形式でCodexを実行
4. 結果をユーザーに報告
