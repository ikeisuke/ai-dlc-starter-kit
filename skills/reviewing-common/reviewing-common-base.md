# Reviewingスキル共通基盤

全Reviewingスキルで共有される外部ツール実行基盤。

## 実行コマンド

### Codex

```bash
codex exec -s read-only -C . "<レビュー指示>" </dev/null
```

`</dev/null` は非対話 subprocess 環境での stdin 待ちハング回避のため必須（後述「stdin 待ちガードルール」参照）。

### Claude Code

```bash
claude -p --output-format stream-json "<レビュー指示>"
```

### Gemini

```bash
gemini -p "<レビュー指示>" --sandbox
```

## セッション継続

反復レビュー時は前回のセッションを継続する。

- **Codex**: `codex exec resume <session-id> "<指示>" </dev/null`（`</dev/null` は必須 / 後述「stdin 待ちガードルール」参照）
- **Claude**: `claude --session-id <uuid> -p --output-format stream-json "<指示>"`
- **Gemini**: `gemini --resume <session_index> -p "<指示>"`

詳細は [references/session-management.md](references/session-management.md) を参照。

## 外部ツールとの関係

このスキルは2つのモードで動作する:

1. **通常モード（外部CLI使用）**: 外部CLIツール（codex / claude / gemini）を使用してレビューを実行する。呼び出し元が `優先ツール: [tool]` を引数に含める
2. **セルフレビューモード（フォールバック）**: 外部CLIが利用不可の場合に使用する。呼び出し元が `self-review` を引数の先頭トークンに含める

**責務の分離**:

- **呼び出し元（review-flow.md）**: 実行モードを決定し、適切な引数でスキルを呼び出す。ステップ3で外部CLI可用性を事前チェックする
- **スキル側**: 受け取った引数を解釈し、指定されたモードでレビューを実行する
- 外部CLIが利用可能な場合は、呼び出し元が常に通常モード（外部CLI使用）を選択する
- セルフレビューモードは、外部CLIが利用不可の場合のフォールバックとしてのみ使用される

## セルフレビューモード

引数の先頭トークンが `self-review` の場合、このモードで実行する。
引数の残り部分はレビュー対象ファイルパス（半角スペース区切り）。空白を含むファイルパスは非対応。

セルフレビューモードでは外部CLI（codex / claude / gemini）は使用しない。

### 手順

1. 引数の先頭トークン `self-review` を除去し、残りをレビュー対象ファイルパスとして取得する
2. 上記「レビュー観点」セクションの基準に基づいてレビューを実行する
3. レビュー結果は呼び出し元のフロー（review-flow.md）で定義されたセルフレビュー出力フォーマットに準拠して返す

### 実行方式

- **サブエージェント方式（推奨）**: Taskツールで `subagent_type: "general-purpose"` を起動し、以下の指示テンプレートを渡す。サブエージェントは読み取り専用の指示に従うこと（技術的な強制はプラットフォーム依存。指示テンプレート内の制約が実質的な手段）
- **インライン方式（フォールバック）**: サブエージェント起動失敗時（Taskツール利用不可含む）、メインエージェント自身がレビューを実施する。フォールバック発生時はその旨を結果に含める

### サブエージェントへの指示テンプレート

````text
以下のファイルをレビューしてください。
あなたの役割は読み取り専用のレビュアーです。ファイルの読み取りと評価のみを行い、ファイルの編集・コマンド実行・外部通信は行わないでください。

**レビュー種別**: {review_type}

**対象ファイル**:
{target_files を改行区切りで列挙}

**レビュー観点**:
{本SKILL.mdの「レビュー観点」セクション内容}

**出力フォーマット**:
レビュー結果を以下のフォーマットで出力してください。

指摘がある場合:

指摘 #1
- 重要度: {高 | 中 | 低}
- focus: {code | security | architecture | inception}
- 内容: {指摘内容の要約}
- 推奨修正: {修正方法の提案}

指摘 #2
...

合計: {N}件（高: {n}件 / 中: {n}件 / 低: {n}件）

指摘がない場合:
指摘0件
````

### 制約

- ファイルの編集・コマンド実行・外部通信は行わない（読み取り専用）
- 機密情報（秘密鍵・トークン・個人情報等）はレビュー出力に含めない
- セルフレビューは外部ツールに比べて品質が劣る可能性がある

## markdown lint 標準実行コマンド

starter kit 内 AI レビュー導線で markdown lint を実行する標準コマンドは `npm run lint:md`（SoT: repo ルート `package.json` の `scripts.lint:md`）。AI レビュー / CI / ローカル開発が同一エントリポイントから markdownlint-cli2 を起動できる（v2.6.4 Unit 003 / Issue #709）。

**適用境界**: 本ルールは starter kit 内 AI レビュー導線（reviewing-common 系スキル経由）に限定する。consumer プロジェクト一般向け導線・上位スキル横断 docs（README.md など）には適用しない（consumer が `package.json` 不在でも誤って `npm run lint:md` を要求されないため）。既存 `npx markdownlint-cli2` 直接呼び出し経路は後方互換のため残存する。

## stdin 待ちガードルール

非対話 subprocess 環境（Claude Code の Bash ツール / hooks / CI 等）で `codex exec` / `codex exec resume` を実行する場合、**`</dev/null` で stdin を閉じることを必須要件とする**（本セクションが codex 非対話実行運用の規約 SoT）。

### 症状

prompt を positional 引数として渡しているにもかかわらず、`Reading additional input from stdin...` の表示後に stdin EOF を待ち続けてハングする。

```bash
# ハング（非対話 subprocess 環境）
codex exec -s read-only -C . "<レビュー指示>"

# 正常動作（stdin を閉じる）
codex exec -s read-only -C . "<レビュー指示>" </dev/null
```

### 原因

codex-cli は positional 引数の prompt があっても stdin から追加入力を確認する設計のため、stdin が EOF にならない限り待ち続ける。短い prompt では偶然動作することがあり再現性に prompt 長依存があるように見えるが、根本原因は同一。jailrun shim 経由でも生 codex でも、`-s` フラグの値（`read-only` / `danger-full-access`）に関わらず、pipe の有無に関わらず再現する。

### 必須要件

- `codex exec` / `codex exec resume` の呼び出しには **常に `</dev/null` を付与する**（または `codex exec - < <file>` のように prompt 自体をファイル stdin から渡す。この場合もファイルが EOF になるため安全）
- `</dev/null` 欠落時は AI エージェントが応答を得られず、結果として「セルフレビューへの無自覚な降格」を起こす
- 横断ルールは `CLAUDE.md` / `AGENTS.md` の「Bash ツール経由の安全パターン」からも本セクションを参照する

### 関連

- v2.6.2 Unit 005 計画レビュー実行時に発見 / codex-cli 0.130.0 / Issue #703
