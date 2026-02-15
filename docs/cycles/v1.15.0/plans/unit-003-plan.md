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

## 実装計画

### Phase 1: 設計（分析・方針策定）

#### ステップ1: ドメインモデル設計（プロンプト構造分析）

各ファイルについて以下を分析し、ドメインモデルドキュメントに整理:
- ファイル一覧と行数
- 各ファイルの責務（何を定義しているか）
- ファイル間の依存関係（読み込み指示の追跡）
- 共通部分と固有部分の明確化

#### ステップ2: 論理設計（Skills化方針策定）

分析結果に基づき、以下を論理設計ドキュメントに整理:
- Skills化に必要な分離ポイントの特定
- 各フェーズプロンプトの独立動作に必要な変更
- Lite版との整合性確保方針
- 具体的な変更内容リスト（ファイル単位）
- 次サイクル以降のSkills化ロードマップ

#### ステップ3: 設計レビュー

AIレビュー実施後、ユーザーに方針提示・承認取得

### Phase 2: 実装（成果物作成）

#### ステップ4: 成果物の最終化

- 分析結果ドキュメントの最終調整
- 方針ドキュメントの整備

#### ステップ5: テスト（検証）

- 分析の網羅性確認（全ファイルがカバーされているか）
- 方針の整合性確認（矛盾がないか）

#### ステップ6: 統合とレビュー

- AIレビュー・ユーザー承認
- 実装記録作成

## 成果物

- `docs/cycles/v1.15.0/design-artifacts/domain-models/prompt-structure-analysis_domain_model.md`
- `docs/cycles/v1.15.0/design-artifacts/logical-designs/prompt-structure-analysis_logical_design.md`
- `docs/cycles/v1.15.0/construction/units/prompt-structure-analysis_implementation.md`

## 完了条件チェックリスト

- [ ] 現在のプロンプト構造の詳細分析（ファイル一覧、依存関係、行数、責務）
- [ ] Skills化に必要な分離ポイントの特定
- [ ] 整理方針ドキュメントの作成（具体的な変更内容を含む）
- [ ] ユーザーへの方針提示と承認取得
