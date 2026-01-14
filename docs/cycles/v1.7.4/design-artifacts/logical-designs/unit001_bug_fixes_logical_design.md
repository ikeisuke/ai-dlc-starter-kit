# Unit 001: バグ修正 - 論理設計

## 概要

プロンプト内のbash条件式を修正するための具体的なパターンを定義する。

## 修正パターン

### パターン1: バックログモードのGitHub CLI依存チェック

**修正前**:

```bash
if [ "$BACKLOG_MODE" = "issue" ]; then
```

**修正後**:

```bash
if [ "$BACKLOG_MODE" = "issue" ] || [ "$BACKLOG_MODE" = "issue-only" ]; then
```

**適用理由**:

- 明示的な列挙により、意図しないモードがマッチするリスクを排除
- `issue*` のようなワイルドカードは将来の新モードを誤って拾う可能性がある

### パターン2: バックログモードの否定条件

**修正前**:

```bash
if [ "$BACKLOG_MODE" != "issue" ]; then
```

**修正後**:

```bash
if [ "$BACKLOG_MODE" != "issue" ] && [ "$BACKLOG_MODE" != "issue-only" ]; then
```

**適用理由**:

- 否定条件でも同様に明示列挙が必要

### パターン3: 変更検出コマンド

**修正前**:

```bash
git diff --quiet && git diff --cached --quiet || git add -A && git commit -m "..."
```

**修正後**:

```bash
[ -n "$(git status --porcelain)" ] && git add -A && git commit -m "..."
```

**適用理由**:

- `git status --porcelain` は追跡済み変更と未追跡ファイルの両方を検出
- 出力が空でない場合にコミットを実行

## 修正対象の範囲

### ファイル構成と反映の流れ

```text
prompts/package/prompts/*.md  →（rsync）→  docs/aidlc/prompts/*.md
        ↑                                         ↑
    修正対象（ソース）                      配布物（自動生成）
```

**重要**: `docs/aidlc/` は `prompts/package/` の rsync コピーである（`docs/cycles/rules.md` 参照）。

- `prompts/package/prompts/` を修正すれば、Operations Phase の rsync で `docs/aidlc/prompts/` に自動反映される
- したがって、本設計では `prompts/package/prompts/` のみを修正対象とする
- `docs/aidlc/prompts/` を直接編集すると、次回rsyncで上書きされて変更が消える

## 修正箇所一覧

### バグ1: issue-onlyモード対応

| ファイル | 行 | パターン |
|---------|-----|----------|
| `prompts/package/prompts/setup.md` | 170付近 | パターン1 |
| `prompts/package/prompts/inception.md` | 661付近 | パターン2 |

### バグ2: 未追跡ファイル検出

| ファイル | 箇所数 | パターン |
|---------|--------|----------|
| `prompts/package/prompts/construction.md` | 4箇所 | パターン3 |
| `prompts/package/prompts/inception.md` | 4箇所 | パターン3 |
| `prompts/package/prompts/operations.md` | 4箇所 | パターン3 |

## 周辺テキストの更新

### setup.md

- 見出し「mode=issueの場合、GitHub CLI確認」→「mode=issueまたはissue-onlyの場合、GitHub CLI確認」
- 見出し「backlogラベル確認・作成【mode=issueの場合のみ】」→「...【mode=issueまたはissue-onlyの場合のみ】」
- 前提条件の記述も更新

### inception.md

- 関連するコメントや説明文を確認し、必要に応じて更新
