---
name: claude-review
description: Claude Code CLIでコードレビューを実行する。AI-DLCの設計・実装レビューに使用。
argument-hint: [対象ファイルまたはレビュー指示]
allowed-tools: Bash(claude:*)
---

# Claude Review

Claude Code CLIを使用してコードレビューを実行するスキル。

## 実行コマンド

```bash
claude -p --output-format stream-json "<レビュー指示>"
```

`stream-json` を使用することで、長いレビューでも途中イベントが出力され、無応答に見える状態を避けられます。

## セッション継続

前回のセッションを継続してレビューする場合:

```bash
claude --session-id <uuid> -p --output-format stream-json "<追加指示>"
```

意図しないセッションの混同を防ぐため、`-c` (continue) ではなく `--session-id` を使用します。

## 反復レビュー時のルール【重要】

AI-DLCの反復レビューフローでClaude Codeを使用する際は、**必ずセッションIDを指定**してください。

### セッション継続を使うべき場面

| 場面 | セッション継続 | 理由 |
|------|----------------|------|
| 反復レビュー（2回目以降） | 必須 | 前回の指摘内容を踏まえた継続レビューが必要 |
| 指摘への追加質問 | 必須 | 指摘の文脈を保持したまま深掘りできる |
| 修正後の再レビュー | 必須 | 修正箇所と元の指摘の関連を理解できる |
| 別のUnitや独立したレビュー対象 | 不要 | 新しいコンテキストで開始すべき |

### 反復レビューの流れ

```text
[1回目] claude -p --output-format stream-json "設計ドキュメントをレビューしてください"
        → 指摘あり、session id確認

[修正を実施]

[2回目] claude --session-id <uuid> -p --output-format stream-json "指摘を修正しました。再度レビューしてください"
        → 追加指摘あり

[修正を実施]

[3回目] claude --session-id <uuid> -p --output-format stream-json "追加の修正を行いました。確認してください"
        → 指摘なし、レビュー完了
```

## パラメータ

| パラメータ | 説明 |
|-----------|------|
| `-p` / `--print` | 非対話モードで実行し結果を表示 |
| `--output-format stream-json` | JSON Lines形式でストリーミング出力（推奨） |
| `--session-id <uuid>` | 特定のセッションIDを指定して再開 |
| `"<request>"` | レビュー指示（日本語可） |

## 使用例

### 設計レビュー

```bash
claude -p --output-format stream-json "docs/cycles/v1.12.1/design-artifacts/の設計ドキュメントをレビューしてください"
```

### 実装レビュー

```bash
claude -p --output-format stream-json "prompts/package/prompts/construction.mdの変更をレビューしてください"
```

## 実行手順

1. レビュー対象を特定する
2. 上記コマンド形式でClaude Codeを実行
3. 指摘があれば修正し、セッションIDを指定して再レビュー
4. 指摘なしになるまで反復

## 既知の制限事項と対処法

### レスポンス未返却（長文ファイル）

`--output-format stream-json` なしで大きなファイルをレビューすると、処理完了まで一切の出力がなく無反応に見えることがあります。必ず `--output-format stream-json` を使用してください。

### 指摘の非決定性（反復レビュー時）

LLMは同一入力に対して毎回異なる出力を生成する性質があります。反復レビュー時に修正箇所と無関係な「言い回しの改善」指摘が毎回変わることがあります。

**推奨対処法**:

- 構造的な問題や論理的な誤りなど**重要度の高い指摘**を優先的に対応する
- 言い回しレベルの指摘は、一貫して指摘されない場合は対応不要と判断してよい
- セッション継続（`--session-id`）を使用し、前回の指摘コンテキストを維持する

### stream-json出力形式

- 出力はJSON Lines形式（1行1JSONオブジェクト）
- `type: "result"` のイベントにレビュー結果が含まれる
- 出力形式はClaude Code CLIのバージョンに依存する可能性がある（本スキルはCLI 2.1.39で動作確認済み）
