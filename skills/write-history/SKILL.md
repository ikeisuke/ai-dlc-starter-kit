---
name: write-history
description: "AI-DLCの履歴ファイルに記録を追記する。ステップ完了時やレビュー完了時に使用。"
argument-hint: "--phase <phase> --step <step> --content <content>"
---

# write-history スキル

`scripts/write-history.sh` を実行して、AI-DLCの履歴ファイルに記録を追記する。

## 基本情報

- 日時は `write-history.sh` が内部で自動取得する
- 履歴ファイルのパスはフェーズ・Unit情報から自動決定される

## 引数

| 引数 | 必須 | 説明 |
|------|------|------|
| `--cycle` | Yes | サイクルバージョン（例: `v1.8.0`） |
| `--phase` | Yes | `inception` / `construction` / `operations` |
| `--unit` | construction のみ | Unit番号（例: `3`） |
| `--unit-name` | construction のみ | Unit名 |
| `--unit-slug` | construction のみ | Unitスラッグ |
| `--step` | Yes | ステップ名（例: `AIレビュー完了`） |
| `--content` | Yes（排他） | 実行内容（テキスト） |
| `--content-file` | Yes（排他） | 実行内容をファイルから読み込み |
| `--artifacts` | No | 成果物パス（複数回指定可能） |
| `--dry-run` | No | 追記せず、状態のみ表示 |

`--content` と `--content-file` は排他。長文の場合は一時ファイルに書き出して `--content-file` を使用する。

## 出力

```text
history:<ファイルパス>:<状態>
```

| 状態 | 説明 |
|------|------|
| `created` | 新規ファイル作成＋追記成功 |
| `appended` | 既存ファイルへの追記成功 |
| `would-create` | 新規作成予定（dry-run） |
| `would-append` | 追記予定（dry-run） |
| `error` | 処理失敗 |

## 使用例

### Inception Phase

```bash
scripts/write-history.sh \
    --cycle v2.1.0 \
    --phase inception \
    --step "Intent作成" \
    --content "Intent文書を作成し、ユーザーの承認を取得" \
    --artifacts ".aidlc/cycles/v2.1.0/requirements/intent.md"
```

### Construction Phase

```bash
scripts/write-history.sh \
    --cycle v2.1.0 \
    --phase construction \
    --unit 3 \
    --unit-name "400行超えMarkdownファイルの分割" \
    --unit-slug "split-large-markdown" \
    --step "設計レビュー" \
    --content "ドメインモデルと論理設計のレビュー完了" \
    --artifacts ".aidlc/cycles/v2.1.0/design-artifacts/domain-models/unit-003.md"
```

### Operations Phase

```bash
scripts/write-history.sh \
    --cycle v2.1.0 \
    --phase operations \
    --step "リリース準備" \
    --content "バージョン確認、CHANGELOG更新、PR Ready化完了"
```

### レビューフロー内での使用

review-flow.md の各イベントで以下のステップ名を使用する:

| イベント | ステップ名 |
|---------|-----------|
| AIレビュー完了 | `AIレビュー完了` |
| フォールバック発生 | `フォールバック` |
| 千日手判断 | `千日手判断` |
| 指摘対応判断 | `AIレビュー指摘対応判断` |
| バックログ登録 | `バックログ自動登録` |
| スキップ | `AIレビュースキップ` |

### content-file を使用する場合（長文）

```bash
# 1. 一時ファイルにコンテンツを書き出す（Writeツール使用）
# 2. write-history.sh を実行
scripts/write-history.sh \
    --cycle v2.1.0 \
    --phase construction \
    --unit 3 \
    --unit-name "..." \
    --unit-slug "..." \
    --step "AIレビュー完了" \
    --content-file /tmp/aidlc-history-content.txt
# 3. 一時ファイルを削除
```

## 履歴レベル

`.aidlc/config.toml` の `[rules.history].level` で記録頻度を制御:

| level | Inception | Construction |
|-------|-----------|-------------|
| `detailed` | ステップ完了時 + 修正差分 | ステップ完了時 + 修正差分 |
| `standard`（デフォルト） | ステップ完了時 | ステップ完了時 |
| `minimal` | フェーズ完了時 | Unit完了時 |
