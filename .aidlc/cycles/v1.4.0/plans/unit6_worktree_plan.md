# Unit 6: git worktree提案 - 実装計画

## 概要
セットアップ時にgit worktreeの使用を提案し、複数サイクルの並行作業を支援する。
**デフォルトでは無効、aidlc.toml の設定で有効化可能。**

## 対象ファイル
- `prompts/setup-init.md`（編集）: aidlc.toml に `[rules.worktree]` セクション追加
- `prompts/setup-cycle.md`（編集）: worktree設定が有効な場合の提案ロジック追加

## 変更箇所

### 1. setup-init.md: aidlc.toml テンプレートに設定追加

`[rules.mcp_review]` の後に以下を追加:

```toml
[rules.worktree]
# git worktree設定
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false
```

### 2. setup-cycle.md: セクション 3.2 を条件分岐に変更

現在の構造:
```
1. 新しいブランチを作成して切り替える
2. 現在のブランチで続行する
```

変更後の構造（worktree設定が有効な場合のみ選択肢追加）:
```
# worktree が有効な場合
1. git worktreeを使用して新しい作業ディレクトリを作成する
2. 新しいブランチを作成して切り替える
3. 現在のブランチで続行する

# worktree が無効な場合（デフォルト）
1. 新しいブランチを作成して切り替える
2. 現在のブランチで続行する
```

### 追加するコンテンツ（worktree選択時の案内）
- worktreeのメリット説明（並行作業可能、ブランチ切り替え不要）
- 推奨ディレクトリ構成例
- worktree作成コマンドの案内

### 変更しないこと
- worktreeの自動作成は行わない（提案のみ）
- worktreeの詳細な使い方説明は追加しない
- デフォルト動作は変更なし（worktree無効時は既存動作と同じ）

## 実装ステップ

1. **Phase 1: 設計**（ドキュメント編集のみのため簡素化）
   - ドメインモデル: 対象外（ビジネスロジックなし）
   - 論理設計: aidlc.toml 設定構造と setup-cycle.md の条件分岐を定義

2. **Phase 2: 実装**
   - prompts/setup-init.md に `[rules.worktree]` セクション追加
   - prompts/setup-cycle.md のセクション3に worktree 条件分岐追加

## 見積もり
小規模（プロンプト編集のみ）

## 備考
- このUnitはプロンプト編集のみのため、コード生成・テストは不要
- 設計ドキュメント（ドメインモデル・論理設計）は簡素化版を作成
