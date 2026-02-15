# Unit 005 計画: プロンプトリファクタリング

## 概要

Unit 003の方針（論理設計）に基づき、プロンプト全体のリファクタリングを実施する。
段階1〜3（common/ 新規ファイル作成、フェーズプロンプトの重複削除、AGENTS.mdの責務分離）を実行する。

**正本パス**: `prompts/package/prompts/`（編集対象）
**展開先**: `docs/aidlc/prompts/`（rsync同期、直接編集禁止）

## 変更対象ファイル

### 新規作成（8ファイル）

すべて `prompts/package/prompts/common/` 配下に作成。

| # | ファイル | 抽出元 | 内容 |
|---|---------|--------|------|
| 1 | `agents-rules.md` | AGENTS.md L73-150 | 実行前検証、フェーズ固有ルール、質問と深掘り、バックログ管理、禁止事項、コンテキスト要約時の情報保持 |
| 2 | `feedback.md` | AGENTS.md L154-210 | フィードバック送信機能（設定確認、手順、注意事項） |
| 3 | `ai-tools.md` | AGENTS.md L213-273 | AIツール対応（レビュースキル、ワークフロースキル、KiroCLI対応） |
| 4 | `project-info.md` | 3フェーズプロンプト共通部 | プロジェクト概要、ディレクトリ構成（共通部）、制約事項、テンプレート参照 |
| 5 | `phase-responsibilities.md` | 3フェーズプロンプト共通部 | フェーズの責務分離 |
| 6 | `progress-management.md` | 3フェーズプロンプト共通部 | 進捗管理と冪等性 |
| 7 | `context-reset.md` | construction/operations | コンテキストリセット対応テンプレート（{{PHASE}}, {{CYCLE}}プレースホルダー） |
| 8 | `compaction.md` | 3フェーズプロンプト | コンパクション時の対応手順（{{PHASE}}, {{CYCLE}}プレースホルダー） |

### 変更（4ファイル）

| # | ファイル | 変更内容 |
|---|---------|---------|
| 1 | `AGENTS.md` | 共通ルール・フィードバック・AIツール対応を外部参照に変更、ナビゲーション部分のみ残す |
| 2 | `inception.md` | プロジェクト情報・責務分離・進捗管理・コンパクション対応をcommon/への読み込み指示に置換 |
| 3 | `construction.md` | 同上 + コンテキストリセット対応をcommon/への参照に置換 |
| 4 | `operations.md` | 同上 + コンテキストリセット対応をcommon/への参照に置換 |

### 変更なし

- `CLAUDE.md`, `common/intro.md`, `common/rules.md`, `common/review-flow.md`, `common/commit-flow.md`, `setup.md`, `lite/inception.md`, `lite/construction.md`, `lite/operations.md`

## 実装計画

### 段階1: common/ 新規ファイル作成

1. `common/agents-rules.md` 作成（AGENTS.mdから抽出）
2. `common/feedback.md` 作成（AGENTS.mdから抽出）
3. `common/ai-tools.md` 作成（AGENTS.mdから抽出）
4. `common/project-info.md` 作成（3フェーズから共通部抽出）
5. `common/phase-responsibilities.md` 作成（フェーズの責務分離）
6. `common/progress-management.md` 作成（進捗管理と冪等性）
7. `common/context-reset.md` 作成（construction/operationsから抽出）
8. `common/compaction.md` 作成（3フェーズから抽出）

### 段階2: フェーズプロンプトの重複削除

1. `inception.md` からプロジェクト情報共通部・責務分離・進捗管理・テンプレート参照・コンパクション対応を削除し、common/への読み込み指示に置換
2. `construction.md` から同上 + コンテキストリセット対応を削除し、common/への読み込み指示に置換
3. `operations.md` から同上 + コンテキストリセット対応を削除し、common/への読み込み指示に置換

### 段階3: AGENTS.md の責務分離

1. AGENTS.md の「AI-DLC共通ルール」セクションを `common/agents-rules.md` への参照に置換
2. 「フィードバック送信」セクションを `common/feedback.md` への参照に置換
3. 「AIツール対応」セクションを `common/ai-tools.md` への参照に置換

### 段階4: 動作確認

1. 各フェーズプロンプト内の読み込み指示パスが正しいことを確認
2. 新規common/ファイルが全て存在することを確認
3. Lite版が変更なく維持されていることを確認

## 完了条件チェックリスト

- [ ] Unit 003の方針ドキュメントに記載された変更のすべてを実施
- [ ] Lite版との整合性維持（Lite版ファイルに変更がないこと）
- [ ] リファクタリング後のワークフロー動作確認（読み込み指示パスの整合性）
- [ ] 依存方向が上位→下位の一方向のみであること（common間の相互参照がないこと、AGENTS/フェーズからcommonへの一方向参照であること）
