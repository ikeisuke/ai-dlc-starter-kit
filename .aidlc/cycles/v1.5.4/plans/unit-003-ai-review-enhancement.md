# Unit 003: AIレビュー機能強化 - 計画

## 概要

AIレビュー必須設定（`mode = "required"`）が確実に機能するよう、設定確認の具体的なコマンドを追加し、レビュー前後のコミット処理を実装する。

## 現状の問題

1. **設定確認コマンドが不明確**: 「`docs/aidlc.toml` の `[rules.mcp_review]` セクションを確認」とあるが、具体的なコマンドがない
2. **MCP利用可否チェックの具体的な手順がない**: 「AI MCP（Codex MCP等）が利用可能か確認」とあるが、どうやって確認するかの指示がない
3. **レビュー前後のコミット処理がない**: 現在のルールにはコミット処理が含まれていない

## 修正対象ファイル

- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

## 修正内容

### 1. 設定確認コマンドの明示化

**追加するコマンド**:
```bash
# AIレビュー設定の確認
MCP_REVIEW_MODE=$(grep -A1 "^\[rules.mcp_review\]" docs/aidlc.toml 2>/dev/null | grep "mode" | sed 's/.*"\([^"]*\)".*/\1/' || echo "recommend")
echo "AIレビューモード: ${MCP_REVIEW_MODE}"
```

### 2. MCP利用可否チェックの具体化

**追加する確認手順**:
- Codex MCPが利用可能かどうかは、AIエージェント自身が `mcp__codex__codex` ツールにアクセスできるかどうかで判断
- 明示的なチェック方法をプロンプトに記載

```markdown
**MCP利用可否の確認方法**:
- このAIエージェントが Codex MCP（`mcp__codex__codex` ツール）にアクセス可能か確認
- 利用可能な場合: AIレビューを実行
- 利用不可の場合: mode設定に応じて警告またはスキップ
```

### 3. レビュー前後のコミット処理追加

**レビュー前コミット**:
```bash
git add -A
git commit -m "chore: [{{CYCLE}}] レビュー前 - {成果物名}"
```

**レビュー後コミット**（修正があった場合）:
```bash
git add -A
git commit -m "chore: [{{CYCLE}}] レビュー反映 - {成果物名}"
```

## 具体的な修正箇所

### 各プロンプトの「AIレビュー優先ルール」セクション

**Before**:
```markdown
**設定確認**: `docs/aidlc.toml` の `[rules.mcp_review]` セクションを確認

**処理フロー**:
1. **mode確認**: 設定ファイルからmodeを読み取る
2. **MCP利用可否チェック**: AI MCP（Codex MCP等）が利用可能か確認
```

**After**:
```markdown
**設定確認**: 以下のコマンドでAIレビューモードを確認
\`\`\`bash
MCP_REVIEW_MODE=$(grep -A1 "^\[rules.mcp_review\]" docs/aidlc.toml 2>/dev/null | grep "mode" | sed 's/.*"\([^"]*\)".*/\1/' || echo "recommend")
echo "AIレビューモード: ${MCP_REVIEW_MODE}"
\`\`\`

**MCP利用可否の確認**:
- このAIエージェントが Codex MCP（`mcp__codex__codex` ツール）にアクセス可能か確認
- ツールが存在しない場合は「MCP利用不可」として処理

**処理フロー**:
1. **mode確認**: 上記コマンドでmodeを取得
   - 空または取得失敗時は「recommend」として扱う
2. **MCP利用可否チェック**: Codex MCPツールの存在確認
```

### レビュー前後コミット処理の追加

**追加箇所**: 処理フロー「3. MCP利用可能時」の直前と直後

```markdown
**レビュー前コミット**:
AIレビュー実行前に、現在の成果物をコミットする。
\`\`\`bash
git add -A
git commit -m "chore: [{{CYCLE}}] レビュー前 - {成果物名}"
\`\`\`

3. **MCP利用可能時**:
   - AIレビューを実行
   - レビュー結果を確認
   - 指摘があれば修正を反映
   - **レビュー後コミット**（修正があった場合）:
     \`\`\`bash
     git add -A
     git commit -m "chore: [{{CYCLE}}] レビュー反映 - {成果物名}"
     \`\`\`
   - 修正後の成果物を人間に提示
```

## Phase 1: 設計

このUnitはプロンプトファイルの修正のみで、新しいドメインモデルや論理設計は不要。
直接実装フェーズに進む。

## Phase 2: 実装ステップ

1. `prompts/package/prompts/inception.md` の修正
2. `prompts/package/prompts/construction.md` の修正
3. `prompts/package/prompts/operations.md` の修正
4. 動作確認（修正後のプロンプトが正しい形式か確認）
5. 履歴記録とコミット

## 成果物

- 修正されたプロンプトファイル（3ファイル）
- 履歴記録（`docs/cycles/v1.5.4/history/construction_unit3.md`）
