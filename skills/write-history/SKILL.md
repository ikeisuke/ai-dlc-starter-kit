---
name: write-history
description: "AI-DLCの履歴ファイルに記録を追記する。ステップ完了時やレビュー完了時に使用。"
argument-hint: "--phase <phase> --step <step> --content <content>"
---

# write-history スキル

aidlcスキルの `scripts/write-history.sh` を実行して、AI-DLCの履歴ファイルに記録を追記する。

> **注**: このスキルはaidlcスキルに依存する委譲スキルです。スクリプト実体は `skills/aidlc/scripts/write-history.sh` にあり、以下の使用例はaidlcフロー（呼び出し元）のコンテキストでのパス表記です。

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
| `--content` | 片方必須 | 実行内容（テキスト）。`--content-file` と排他 |
| `--content-file` | 片方必須 | 実行内容をファイルから読み込み。`--content` と排他 |
| `--artifacts` | No | 成果物パス（複数回指定可能） |
| `--operations-stage` | No | Operations Phase ステージ（`pre-merge` / `post-merge`）。`post-merge` は即拒否（exit 3）。未定義値は exit 1。省略時は従来動作（7.8 以降の未指定呼び出しは第二条件フォールバックで判定される）。Unit 002 / DR-001 |
| `--mode` | No | 履歴エントリのモード（`base` / `unit-complete-short-note` / `operations-round`、デフォルト `base`）。Unit 002 / #637（v2.5.3） |
| `--short-note` | `--mode unit-complete-short-note` 時必須 | Unit 完了 short note（3-5 行の自由記述） |
| `--round` | `--mode operations-round` 時必須 | Operations round 番号（1-5 の整数 / user_stories.md ストーリー 2B 準拠） |
| `--findings` | `--mode operations-round` 時必須 | 指摘総数（非負整数） |
| `--critical` / `--high` / `--medium` / `--low` | `--mode operations-round` 時必須 | 重要度別件数（各非負整数） |
| `--resolved-count` / `--deferred-count` | `--mode operations-round` 時必須 | 修正対応件数 / defer 化件数（各非負整数） |
| `--dry-run` | No | 追記せず、状態のみ表示 |

`--content` と `--content-file` は排他。

**AI エージェント第一推奨経路（v2.6.2 Unit 006 / Issue #697）**: AI エージェントが Bash ツール経由で本スクリプトを呼び出す際は **`--content-file` を第一推奨とする**。`--content` は短文（1〜2 行 / コマンド置換構文を含まないことが明らかな短い文字列）にのみ使用する。長文・Markdown inline code・backtick / `$(...)` が混入する可能性のある文字列は、Write ツールで一時ファイルに書き出して `--content-file` 経由で渡すこと。理由・規約本文・安全パターン詳細は [`CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン](../../CLAUDE.md#ai-エージェント-bash-ツール経由の安全パターン) および [`skills/aidlc/steps/common/bash-tool-safety.md`](../aidlc/steps/common/bash-tool-safety.md) を参照。

`--operations-stage` は Unit 002 で追加された Operations Phase の post-merge ガード用引数。7.8〜7.13 以降の誤呼び出しは本引数または第二条件（`completion_gate_ready=true` AND `gh pr view` で `state=MERGED ∧ mergedAt!=null ∧ number 一致`）によって拒否される。

### `--mode` モード仕様（v2.5.3 / Unit 002 / #637）

| モード | 動作 | 必須追加引数 |
|--------|------|-------------|
| `base`（デフォルト） | 既存動作（完全互換）。base エントリのみ追記 | なし |
| `unit-complete-short-note` | base 追記後、`history/construction_unitNN.md` 末尾に「## 補足（short note）」セクションを追加 | `--short-note` |
| `operations-round` | base 追記後、`history/operations.md` 末尾に「## Round R: timestamp」見出し + 指摘集計テーブルを追加 | `--round` / `--findings` / `--critical` / `--high` / `--medium` / `--low` / `--resolved-count` / `--deferred-count`（すべて非負整数） |

エラーコード:
- `error:invalid-mode`: `--mode` 値が列挙値以外
- `error:invalid-mode-phase-combination`: mode と phase の組み合わせが不正（`unit-complete-short-note` は construction、`operations-round` は operations のみ）
- `error:missing-short-note`: `--mode unit-complete-short-note` で `--short-note` 欠落
- `error:missing-round-args`: `--mode operations-round` で必須引数のいずれか欠落
- `error:invalid-numeric-arg`: `--round` が 1-5 の整数以外 / count が非負整数以外

post-merge ガード（`--operations-stage post-merge`）は新モードでも有効（exit 3）。

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

### 終了コード

| コード | 意味 |
|--------|------|
| `0` | 成功 |
| `1` | 引数不正（未指定値・不正値・排他違反 等） |
| `2` | I/O 失敗（ファイル作成失敗 等） |
| `3` | Operations Phase post-merge ガード拒否（Unit 002 / DR-001）。`error:post-merge-history-write-forbidden:<reason_code>:<diagnostics>` 形式のメッセージが stdout と stderr の両方に重複出力される |

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
# pre-merge（通常）: --operations-stage pre-merge を明示して従来動作
scripts/write-history.sh \
    --cycle v2.1.0 \
    --phase operations \
    --operations-stage pre-merge \
    --step "リリース準備" \
    --content "バージョン確認、CHANGELOG更新、PR Ready化完了"

# 後方互換: --operations-stage を省略しても、PR 未マージかつ progress.md
# の completion_gate_ready が true でなければ従来動作（appended）となる
scripts/write-history.sh \
    --cycle v2.1.0 \
    --phase operations \
    --step "リリース準備" \
    --content "バージョン確認、CHANGELOG更新、PR Ready化完了"
```

**7.8〜7.13 以降（マージ後）の呼び出しは禁止**: `--operations-stage post-merge` を指定、または progress.md の `completion_gate_ready=true` かつ PR が `state=MERGED ∧ mergedAt!=null ∧ number 一致` の場合、exit 3 で拒否される。詳細は `skills/aidlc/steps/operations/04-completion.md` のマージ前完結ルールを参照。

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
