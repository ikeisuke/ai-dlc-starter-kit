# 論理設計: PRによるIssue自動Close機能

## 概要

Operations Phase（operations.md）のステップ6「リリース準備」でPRを作成する際、対応Issue番号を自動的にPR本文に含める。

## コンポーネント構成

### 変更対象

- `prompts/package/prompts/operations.md`
  - ステップ6のPR作成セクション

### 変更箇所

1. **新規PRを作成する場合**（600行目付近）
   - `gh pr create` コマンドの `--body` 部分にClosesセクションを追加

2. **ドラフトPRをReady化する場合**
   - PR本文更新時にClosesセクションを追加（必要に応じて）

## 処理フロー

```text
1. Issue番号の取得
   ├─ intent.md の「対象Issue」セクションを確認
   │   └─ 存在する場合: Issue番号を抽出
   └─ 存在しない場合: setup-context.md を確認
       └─ それでもない場合: Closesセクションをスキップ

2. PR本文の生成
   ├─ Summary セクション（既存）
   ├─ Test plan セクション（既存）
   ├─ Closes セクション（新規追加）
   │   └─ 各Issue番号を `Closes #xx` 形式で記載
   └─ Generated with... フッター（既存）
```

## PR本文テンプレート

```markdown
## Summary
- [サイクルの主要な変更点]

## Test plan
- [ ] 主要機能が動作する

## Closes

- Closes #[Issue番号1]
- Closes #[Issue番号2]
...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Issue番号取得の指示文

operations.mdに追加する指示:

```text
**Issue番号の取得**:
1. `docs/cycles/{{CYCLE}}/requirements/intent.md` の「対象Issue」セクションからIssue番号を取得
2. intent.mdにない場合は `docs/cycles/{{CYCLE}}/requirements/setup-context.md` を確認
3. Issue番号が見つからない場合は「Closes」セクションを省略

**複数Issueがある場合**:
各Issue番号を別行で `Closes #xx` 形式で記載
```

## 注意事項

- GitHub標準機能のキーワード（`Closes`, `Fixes`, `Resolves`）の中から `Closes` を採用
- PR本文内であればどこに記載してもGitHubが認識する
- 見やすさのため専用セクションとして配置
