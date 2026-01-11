# Unit: AIレビュー反復プロセス

## 概要
AIレビュー後の修正→再レビューのループを明文化し、レビュー品質を向上させる。

## 含まれるユーザーストーリー
- ストーリー 4: AIレビュー反復プロセス

## 責務
- construction.mdのAIレビューフローに反復プロセスを追記
- 「指摘がなくなるまで繰り返す」ことを明記
- AIレビューのチェックタイミング改善（設計作成後に自動的にレビューフローに入るよう明確化）
- 設定読み込みパターンの改善（コメント行を誤って読み込む問題の修正）

## 境界
- AIレビュー機能自体の実装（Codex MCP側）
- レビュー回数の上限設定

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- prompts/package/prompts/construction.md を編集
- inception.md, operations.md にも同様のルールがあれば統一

### 設定読み込みパターン改善の詳細（Unit 001のAIレビューで発見）

**現状の問題点**:

1. **High**: `\s`がPOSIX awkで動かない
   - 修正: `[[:space:]]*` に置換

2. **Medium**: 次のセクション `[...]` で `found` がリセットされない
   - 修正: `/^\[/` で `found=0` に戻す

3. **Medium**: 許容値チェックがない（git/issue以外の値で不定動作）
   - 修正: `git|issue` のみ許可、それ以外は警告して `git` にフォールバック

4. **Low**: フォールバック前の値をログ出力している
   - 修正: フォールバック後に最終値を出力するよう統一

5. **発見**: コメント行（`# mode = "recommend"`）を誤って読み込む
   - 修正: コメント行（`^#` または `^\s*#`）を除外

**修正後のパターン案**:

```bash
# バックログモード設定を読み込み（改善版）
BACKLOG_MODE=$(awk '
  /^\[backlog\]/ { found=1; next }
  /^\[/ { found=0 }
  found && /^[[:space:]]*mode[[:space:]]*=/ {
    gsub(/.*=[[:space:]]*"?|"?[[:space:]]*$/, "")
    print
    exit
  }
' docs/aidlc.toml 2>/dev/null)

# デフォルト値とバリデーション
case "$BACKLOG_MODE" in
  git|issue) ;;
  *)
    [ -n "$BACKLOG_MODE" ] && echo "警告: 無効なbacklog.mode値 '${BACKLOG_MODE}'。gitにフォールバックします。"
    BACKLOG_MODE="git"
    ;;
esac

echo "バックログモード: ${BACKLOG_MODE}"
```

**適用対象プロンプト**:
- setup.md
- inception.md
- construction.md
- operations.md

**注意**: この改善は全プロンプトの設定読み込みパターン（mcp_review等）にも適用すべき

## 実装優先度
Medium

## 見積もり
1.5時間（当初30分 → スコープ拡大により増加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
