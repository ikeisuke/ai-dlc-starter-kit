# Unit 006 計画: PRによるIssue自動Close機能

## 概要

Operations PhaseのPR作成時に `Closes #xx` を自動記載し、PRマージ時に対応Issueが自動でCloseされるようにする。

## 変更対象ファイル

- `prompts/package/prompts/operations.md` - PR作成セクションの更新

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: Issue番号取得ロジックの構造定義
2. **論理設計**: PR本文テンプレートへの組み込み方法

### Phase 2: 実装

1. **operations.md更新**:
   - リリース準備（ステップ6）のPR作成部分に「Closes」セクションを追加
   - Issue番号の取得元を明示（intent.md または setup-context.md）
   - 複数Issue対応のフォーマット指定

### 変更内容の詳細

**追加するセクション**（PR本文テンプレート内）:

```markdown
## Closes

- Closes #[Issue番号1]
- Closes #[Issue番号2]
...
```

**Issue番号の取得ルール**:

1. `docs/cycles/{{CYCLE}}/requirements/intent.md` の「対象Issue」セクションから取得
2. または `docs/cycles/{{CYCLE}}/requirements/setup-context.md` から取得
3. Issue番号がない場合は「Closes」セクションを省略

## 完了条件チェックリスト

- [ ] Operations PhaseのPR作成セクション更新
- [ ] 対応Issue番号の取得ロジック追加
- [ ] PR本文テンプレートへの `Closes #xx` 組み込み
