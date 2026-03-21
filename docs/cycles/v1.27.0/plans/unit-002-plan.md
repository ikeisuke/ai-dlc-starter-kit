# Unit 002 計画: ワイルドカードルール検出による重複防止

## 概要

`setup-ai-tools.sh` の `_merge_permissions_jq()` と `_merge_permissions_python()` にワイルドカード包含判定ロジックを追加し、既存のワイルドカードルールに包含される個別ルールの追加をスキップする。

## 変更対象ファイル

- `prompts/package/bin/setup-ai-tools.sh` — `_merge_permissions_jq()` と `_merge_permissions_python()` の2関数
- `prompts/package/bin/tests/test_setup_ai_tools.sh` — テストケース新規作成

## 実装計画

### 1. ワイルドカード包含判定の仕様（関数契約）

**ルール文法**:
- 有効なルール形式: `Type(content)` — 文字列型のみ対象
- ワイルドカードルール: 末尾が `:*)` で終わるルール
- 不正形式（`Type(...)` パターンに合致しない要素）: 非包含として無視（既存の動作と整合）

**包含判定ロジック**:
- 既存allowリスト内のルールから `:*)` で終わるもの（ワイルドカードルール）を抽出
- 追加候補の各デフォルトルールについて:
  1. ルールから `Type(...)` 形式のType部分とパス部分を分離
  2. 既存ワイルドカードルールと同一Typeかチェック
  3. ワイルドカードのパスプレフィックス（`:*)` を除いた部分）が追加候補のパスの先頭と一致するかチェック
  4. 一致する場合 → 包含されているため追加をスキップ

**境界条件**:
- 候補自体がワイルドカードルール（`:*)`で終わる）の場合: 完全一致は既存の重複排除で処理済み。プレフィックスマッチは行わない
- Type不一致: 異なるType間ではワイルドカード判定を適用しない（`Bash(...)` のワイルドカードは `Skill(...)` に影響しない）

**例**:
- 既存: `Bash(docs/aidlc/bin/:*)` → ワイルドカード、Type=`Bash`, prefix=`docs/aidlc/bin/`
- 候補: `Bash(docs/aidlc/bin/env-info.sh)` → Type=`Bash`, path=`docs/aidlc/bin/env-info.sh`
- 判定: prefix `docs/aidlc/bin/` は path の先頭と一致 → スキップ

### 2. `_merge_permissions_jq()` の修正

jqの `($defaults - $existing)` の後に、ワイルドカード包含チェックを追加。既存ルール（`$existing`）からワイルドカードパターンを抽出し、新規パターン（`$new`）から包含されるものを除外する。

### 3. `_merge_permissions_python()` の修正

Pythonのリスト内包表記にワイルドカード包含チェックを追加。`is_covered_by_wildcard()` ヘルパー関数を定義する。仕様はセクション1の関数契約と同一。

### 4. スキップログの出力

**重要**: stderrの出力形式（単一整数のnew_count）は後方互換のため変更しない。呼び出し側（`setup_claude_permissions()`）がstderrを整数として読み取るため。

スキップ情報は関数内のstdout側ログとして出力する（呼び出し側のstdout表示に自然に含まれる）。ただし、既存の関数はstdoutでマージ済みJSONを返す契約のため、スキップログは呼び出し側（`setup_claude_permissions()`）で出力する。

### 5. テスト

`prompts/package/bin/tests/test_setup_ai_tools.sh` を新規作成し、jq経路とpython3経路の両方で同一ケースを検証する（バックエンド同値性テスト）:

- ワイルドカードルールが存在する場合に個別ルールがスキップされること
- ワイルドカードルールが存在しない場合に通常どおりマージされること
- 異なるType間ではワイルドカード判定が適用されないこと
- 不正形式のルールが非包含として扱われること

## 完了条件チェックリスト

- [ ] `_merge_permissions_jq()` にワイルドカード包含判定ロジックを追加
- [ ] `_merge_permissions_python()` にワイルドカード包含判定ロジックを追加
- [ ] スキップされたルール数のログ出力（stderr契約は変更しない）
