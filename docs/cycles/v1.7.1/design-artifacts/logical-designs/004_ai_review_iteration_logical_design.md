# 論理設計: AIレビュー反復プロセス

## 概要

AIレビューフローに反復プロセスを追加し、設定読み込みパターンを改善する。

**重要**: この論理設計では**コードは書かず**、変更箇所と変更内容の定義のみを行います。

## 変更対象の範囲

### 対象ファイル

`prompts/package/prompts/` 配下の以下のファイル:

- construction.md
- inception.md
- operations.md
- setup.md

### 対象外ファイル

- **`docs/aidlc/prompts/*.md`**: `prompts/package/prompts/` からrsyncでコピーされる生成物のため、直接編集しない。Operations PhaseでAI-DLC環境アップグレード時に自動更新される。
- **`prompts/setup-prompt.md`**: 設定セクションの追加と確認のみ行い、設定読み込み処理がないため対象外。

## 変更箇所と変更内容

### 1. AIレビューフロー反復プロセス（construction.md）

#### 変更箇所

`prompts/package/prompts/construction.md` の「AIレビューフロー」セクション（227-240行目付近）

#### 現状

```text
4. **AIレビューフロー**:
   - レビュー前コミット
   - AIレビューを実行
   - レビュー結果を確認
   - 指摘があれば修正を反映
   - レビュー後コミット
   - 修正後の成果物を人間に提示
   - 人間の承認を求める
```

#### 改善後

```text
4. **AIレビューフロー**:
   - レビュー前コミット
   - AIレビューを実行
   - レビュー結果を確認
   - 指摘があれば修正を反映
   - **指摘がなくなるまでAIレビューを繰り返す**（反復ループ）
   - レビュー後コミット
   - 修正後の成果物を人間に提示
   - 人間の承認を求める
```

#### 追加する反復ループ記述

ステップ4内に以下を追加:

```text
- **反復レビュー**:
  1. AIレビュー実行
  2. 指摘があれば修正
  3. 指摘がゼロになるまで1-2を繰り返す
  4. **反復完了後に**レビュー後コミットを実行
  5. 人間レビューへ進む
```

**注意**: 「レビュー後コミット」は反復完了後（指摘がゼロになった時点）のみ実行する。反復中の修正はコミットしない。

### 2. 設定読み込みパターン改善

#### 共通のAWKパターン（標準形）

**設計原則**:

1. awkでセクション内の設定を読み取る
2. コメント行（`^#` または `^[[:space:]]*#`）を除外
3. セクション終了（`^\[`）で`found`フラグをリセット
4. バリデーションとフォールバック処理を統一

#### 2.1 MCP_REVIEW_MODE読み込み改善

**対象ファイル**: construction.md, inception.md, operations.md（3箇所）

**現状**:

```bash
MCP_REVIEW_MODE=$(grep -A1 "^\[rules.mcp_review\]" docs/aidlc.toml 2>/dev/null | grep "mode" | sed 's/.*"\([^"]*\)".*/\1/' || echo "recommend")
```

**問題点**:

- `-A1`で1行しか見ないため、コメント行の後の設定を見逃す
- コメント行を誤って読み込む可能性

**改善後**:

```bash
MCP_REVIEW_MODE=$(awk '
  /^\[rules\.mcp_review\]/ { found=1; next }
  /^\[/ { found=0 }
  found && !/^[[:space:]]*#/ && /^[[:space:]]*mode[[:space:]]*=/ {
    gsub(/.*=[[:space:]]*"|".*/, "")
    print
    exit
  }
' docs/aidlc.toml 2>/dev/null)

# デフォルト値とバリデーション
case "$MCP_REVIEW_MODE" in
  required|recommend|disabled) ;;
  *)
    [ -n "$MCP_REVIEW_MODE" ] && echo "警告: 無効なrules.mcp_review.mode値 '${MCP_REVIEW_MODE}'。recommendにフォールバックします。"
    MCP_REVIEW_MODE="recommend"
    ;;
esac
echo "AIレビューモード: ${MCP_REVIEW_MODE}"
```

#### 2.2 WORKTREE_ENABLED読み込み改善

**対象ファイル**: setup.md（1箇所）

**現状**:

```bash
grep -A1 "^\[rules.worktree\]" docs/aidlc.toml 2>/dev/null | grep "enabled" | grep -q "true" && echo "WORKTREE_ENABLED" || echo "WORKTREE_DISABLED"
```

**改善後**:

```bash
# 生の値を抽出（true/false以外も取得可能）
WORKTREE_ENABLED=$(awk '
  /^\[rules\.worktree\]/ { found=1; next }
  /^\[/ { found=0 }
  found && !/^[[:space:]]*#/ && /^[[:space:]]*enabled[[:space:]]*=/ {
    gsub(/.*=[[:space:]]*/, "")
    gsub(/[[:space:]]*#.*/, "")  # インラインコメント除去
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")  # 前後空白トリム
    print
    exit
  }
' docs/aidlc.toml 2>/dev/null)

# バリデーション（true/false以外は警告してfalseにフォールバック）
case "$WORKTREE_ENABLED" in
  true|false) ;;
  "")
    WORKTREE_ENABLED="false"
    ;;
  *)
    echo "警告: 無効なrules.worktree.enabled値 '${WORKTREE_ENABLED}'。falseにフォールバックします。"
    WORKTREE_ENABLED="false"
    ;;
esac
[ "$WORKTREE_ENABLED" = "true" ] && echo "WORKTREE_ENABLED" || echo "WORKTREE_DISABLED"
```

#### 2.3 CHANGELOG_ENABLED読み込み改善

**対象ファイル**: operations.md（1箇所）

**現状**:

```bash
CHANGELOG_ENABLED=$(grep -A2 "^\[rules.release\]" docs/aidlc.toml 2>/dev/null | grep "changelog" | grep -o "true\|false" || echo "false")
```

**改善後**:

```bash
# 生の値を抽出
CHANGELOG_ENABLED=$(awk '
  /^\[rules\.release\]/ { found=1; next }
  /^\[/ { found=0 }
  found && !/^[[:space:]]*#/ && /^[[:space:]]*changelog[[:space:]]*=/ {
    gsub(/.*=[[:space:]]*/, "")
    gsub(/[[:space:]]*#.*/, "")  # インラインコメント除去
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")  # 前後空白トリム
    print
    exit
  }
' docs/aidlc.toml 2>/dev/null)

# バリデーション
case "$CHANGELOG_ENABLED" in
  true|false) ;;
  "")
    CHANGELOG_ENABLED="false"
    ;;
  *)
    echo "警告: 無効なrules.release.changelog値 '${CHANGELOG_ENABLED}'。falseにフォールバックします。"
    CHANGELOG_ENABLED="false"
    ;;
esac
```

#### 2.4 VERSION_TAG_ENABLED読み込み改善

**対象ファイル**: operations.md（1箇所）

**現状**:

```bash
VERSION_TAG_ENABLED=$(grep -A3 "^\[rules.release\]" docs/aidlc.toml 2>/dev/null | grep "version_tag" | grep -o "true\|false" || echo "false")
```

**改善後**:

```bash
# 生の値を抽出
VERSION_TAG_ENABLED=$(awk '
  /^\[rules\.release\]/ { found=1; next }
  /^\[/ { found=0 }
  found && !/^[[:space:]]*#/ && /^[[:space:]]*version_tag[[:space:]]*=/ {
    gsub(/.*=[[:space:]]*/, "")
    gsub(/[[:space:]]*#.*/, "")  # インラインコメント除去
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")  # 前後空白トリム
    print
    exit
  }
' docs/aidlc.toml 2>/dev/null)

# バリデーション
case "$VERSION_TAG_ENABLED" in
  true|false) ;;
  "")
    VERSION_TAG_ENABLED="false"
    ;;
  *)
    echo "警告: 無効なrules.release.version_tag値 '${VERSION_TAG_ENABLED}'。falseにフォールバックします。"
    VERSION_TAG_ENABLED="false"
    ;;
esac
```

## 変更サマリ

| ファイル | 変更箇所 | 変更内容 |
|----------|----------|----------|
| construction.md | 196行目 | MCP_REVIEW_MODE読み込み改善 |
| construction.md | 227-240行目 | AIレビューフロー反復追加 |
| inception.md | 123行目 | MCP_REVIEW_MODE読み込み改善 |
| operations.md | 125行目 | MCP_REVIEW_MODE読み込み改善 |
| operations.md | 555行目 | CHANGELOG_ENABLED読み込み改善 |
| operations.md | 831行目 | VERSION_TAG_ENABLED読み込み改善 |
| setup.md | 299行目 | WORKTREE_ENABLED読み込み改善 |

## 非機能要件への対応

- **パフォーマンス**: N/A（プロンプトファイルの変更のため）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 実装上の注意事項

1. **POSIXawk互換性**: `\s`を使わず`[[:space:]]`を使用
2. **コメント行除外**: `!/^[[:space:]]*#/`でコメント行を除外
3. **セクション終了検出**: `^\[`で新セクション開始を検出し`found=0`にリセット
4. **バリデーション統一**: case文で許可値をチェックし、不正値は警告+フォールバック
5. **空白トリム**: 前後の空白を除去してからバリデーション
6. **非対応事項**（現時点では対応しない）:
   - `;`コメント: TOML v1.0では`;`は正式なコメント記号ではないため非対応
   - 引用符付きbool値（`"true"`）: TOMLではboolに引用符を付けないため非対応

## 不明点と質問（設計中に記録）

（なし - 設計は明確）
