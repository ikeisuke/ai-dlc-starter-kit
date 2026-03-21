# Unit 002 計画: ワイルドカードルール検出による重複防止

## 概要

`setup-ai-tools.sh` の `_merge_permissions_jq()` と `_merge_permissions_python()` にワイルドカード包含判定ロジックを追加し、既存のワイルドカードルールに包含される個別ルールの追加をスキップする。

## 変更対象ファイル

- `prompts/package/bin/setup-ai-tools.sh` — `_merge_permissions_jq()` と `_merge_permissions_python()` の2関数
- `prompts/package/bin/tests/test_setup_ai_tools.sh` — テストケース追加（存在する場合）

## 実装計画

### 1. ワイルドカード包含判定ロジックの設計

**ルール形式**: `Type(path_or_pattern)` — ワイルドカードは末尾 `:*` で示される

**判定ロジック**:
- 既存allowリスト内のルールから `:*` で終わるもの（ワイルドカードルール）を抽出
- 追加候補の各デフォルトルールについて:
  1. ルールから `Type(...)` 形式のType部分とパス部分を分離
  2. 既存ワイルドカードルールと同一Typeかチェック
  3. ワイルドカードのパスプレフィックス（`:*` を除いた部分）が追加候補のパスの先頭と一致するかチェック
  4. 一致する場合 → 包含されているため追加をスキップ

**例**:
- 既存: `Bash(docs/aidlc/bin/:*)` → ワイルドカード、Type=`Bash`, prefix=`docs/aidlc/bin/`
- 候補: `Bash(docs/aidlc/bin/env-info.sh)` → Type=`Bash`, path=`docs/aidlc/bin/env-info.sh`
- 判定: prefix `docs/aidlc/bin/` は path の先頭と一致 → スキップ

### 2. `_merge_permissions_jq()` の修正

jqの `($defaults - $existing)` の後に、ワイルドカード包含チェックを追加。既存ルールからワイルドカードパターンを抽出し、新規パターンから包含されるものを除外する。

### 3. `_merge_permissions_python()` の修正

Pythonのリスト内包表記にワイルドカード包含チェックを追加。`is_covered_by_wildcard()` ヘルパー関数を定義する。

### 4. スキップログの出力

スキップされたルール数をログに出力する。stderrの出力形式に `skipped_count` を追加。

### 5. テスト

- ワイルドカードルールが存在する場合に個別ルールがスキップされること
- ワイルドカードルールが存在しない場合に通常どおりマージされること
- 異なるType間ではワイルドカード判定が適用されないこと

## 完了条件チェックリスト

- [ ] `_merge_permissions_jq()` にワイルドカード包含判定ロジックを追加
- [ ] `_merge_permissions_python()` にワイルドカード包含判定ロジックを追加
- [ ] スキップされたルール数のログ出力
