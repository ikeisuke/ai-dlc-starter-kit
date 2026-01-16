# Unit: markdownlint設定対応

## 概要
markdownlint実行をプロジェクト設定で制御可能にする。

## 含まれるユーザーストーリー
- ストーリー 3-1: markdownlint設定対応

## 関連Issue
- #67

## 責務
- `aidlc.toml` に `[rules.linting]` セクション追加
- プロンプト内のmarkdownlint実行に条件分岐を追加

## 境界
- 他のlintツール（eslint等）の対応は含まない

## 依存関係

### 依存する Unit
- Unit 003: 設定値取得スクリプト（依存理由: get-config.shを使用して設定値を取得）

### 外部依存
- markdownlint-cli2（オプション）

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: 将来の他lintツール対応を考慮した設計
- **可用性**: markdownlint未インストールでもエラーにならない

## 技術的考慮事項

### aidlc.toml 設定追加
```toml
[rules.linting]
# markdownlint設定（v1.8.0で追加）
# markdown_lint: true | false
# - true: markdownlint を実行する（デフォルト）
# - false: markdownlint をスキップする
markdown_lint = true
```

### プロンプト変更箇所
- `construction.md` (行637付近): markdownlint実行前に設定確認を追加
- `operations.md` (行802付近): markdownlint実行前に設定確認を追加

### 条件分岐ロジック
```bash
# 設定確認
MARKDOWN_LINT=$(docs/aidlc/bin/get-config.sh rules.linting.markdown_lint true)
if [ "$MARKDOWN_LINT" = "true" ]; then
    npx markdownlint-cli2 "docs/cycles/{{CYCLE}}/**/*.md" "prompts/**/*.md" "*.md"
else
    echo "markdownlintはスキップされました（設定: markdown_lint=false）"
fi
```

## 実装優先度
Medium

## 見積もり
1時間

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
