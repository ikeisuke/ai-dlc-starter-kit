# Unit 003 計画: プロンプト構造分析・方針策定

## 概要

現在のプロンプト構造（`prompts/package/prompts/`）を詳細に分析し、各フェーズをKiroCLI Skills形式で提供するための整理方針を策定する。実際のリファクタリングはUnit 005で実施するため、本Unitは分析・方針策定のみ。

## 関連Issue

- #116: 各AI-DLCフェーズをSkillsとして提供

## 分析対象ファイル

### メインプロンプト

- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`
- `prompts/package/prompts/setup.md`

### 共通モジュール

- `prompts/package/prompts/common/intro.md`
- `prompts/package/prompts/common/rules.md`
- `prompts/package/prompts/common/review-flow.md`

### エントリポイント

- `prompts/package/prompts/AGENTS.md`
- `prompts/package/prompts/CLAUDE.md`

### Lite版

- `prompts/package/prompts/lite/inception.md`
- `prompts/package/prompts/lite/construction.md`
- `prompts/package/prompts/lite/operations.md`

## 実行計画

### Phase 1: 設計（分析・方針策定）

#### ステップ1: ドメインモデル設計（プロンプト構造分析）

各ファイルについて以下を分析し、ドメインモデルドキュメントに整理:

- ファイル一覧と行数
- 各ファイルの責務（何を定義しているか）
- ファイル間の依存関係（読み込み指示の追跡）
- 依存マトリクス（許可/禁止方向の明示）
- 循環依存チェック結果
- 共通部分と固有部分の明確化

**依存方向ルール**: `main → common` は許可、`common → main` は禁止。Lite版はメイン版に依存しない独立構造とする。

#### ステップ2: 論理設計（Skills化方針策定）

分析結果に基づき、以下を論理設計ドキュメントに整理:

- Skills化に必要な分離ポイントの特定
- 各フェーズプロンプトの独立動作に必要な変更
- Lite版との整合性確保方針
- 具体的な変更内容リスト（ファイル単位）
- 次サイクル以降のSkills化ロードマップ

#### ステップ3: 方針レビュー（論点確定）

- AIレビュー実施後、ユーザーに方針提示・承認取得
- **判定条件**: 分析の網羅性と方針の整合性が確認できること

### Phase 2: 成果物整備・検証

#### ステップ4: 成果物の最終化

- 分析結果ドキュメントの最終調整
- 方針ドキュメントの整備

#### ステップ5: 検証

- 分析の網羅性確認（全ファイルがカバーされているか）
- 方針の整合性確認（矛盾がないか）

#### ステップ6: 成果物レビュー（品質確認）

- AIレビュー・ユーザー承認
- **判定条件**: 成果物が完了条件を満たし、Unit 005で利用可能な品質であること
- 完了記録作成

## 成果物

### ドメインモデル（プロンプト構造分析）

`docs/cycles/v1.15.0/design-artifacts/domain-models/prompt-structure-analysis_domain_model.md`

必須セクション:

- **ファイルカタログ**: 全ファイルの一覧、行数、責務
- **依存グラフ**: ファイル間の読み込み関係（Mermaid図）
- **依存マトリクス**: 許可/禁止方向の一覧
- **共通/固有分離マップ**: 共通部分と固有部分の境界

### 論理設計（Skills化方針）

`docs/cycles/v1.15.0/design-artifacts/logical-designs/prompt-structure-analysis_logical_design.md`

必須セクション:

- **分離ポイント一覧**: Skills化に必要な分離箇所と理由
- **ファイル単位変更リスト**: 各ファイルに対する具体的な変更内容
- **マイグレーションルール**: 現行構造からSkills構造への移行ルール
- **Lite版整合性方針**: Lite版との整合性確保方法

### 完了記録

`docs/cycles/v1.15.0/construction/units/prompt-structure-analysis_implementation.md`

## 完了条件チェックリスト

- [ ] 現在のプロンプト構造の詳細分析（ファイル一覧、依存関係、行数、責務）
- [ ] Skills化に必要な分離ポイントの特定
- [ ] 整理方針ドキュメントの作成（具体的な変更内容を含む）
- [ ] ユーザーへの方針提示と承認取得
