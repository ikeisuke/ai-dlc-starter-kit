# Unit 004: KiroCLI対応 - 実行計画

- **作成日時**: 2026-01-14 17:23:11 JST
- **対象Unit**: 004-kirocli-support
- **関連Issue**: #57

## 概要

KiroCLIでAI-DLCを使用するための設定案内をAGENTS.mdに追加する。

## 実行ステップ

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

- KiroCLI対応に必要な情報構造を定義
- 案内すべき設定内容の整理

#### ステップ2: 論理設計

- AGENTS.mdへの追加位置・形式を決定
- 記載内容の構成を設計

#### ステップ3: 設計レビュー

- 設計内容をユーザーに提示し承認を得る

### Phase 2: 実装

#### ステップ4: コード生成

- `prompts/package/prompts/AGENTS.md` にKiroCLI向け設定案内セクションを追加
- 編集先: `prompts/package/prompts/AGENTS.md`（`docs/aidlc/` は直接編集しない）

#### ステップ5: テスト生成

- ドキュメント追加のため、テストコードは不要
- Markdownlintによる構文チェックを実施

#### ステップ6: 統合とレビュー

- 変更内容のレビュー
- 実装記録の作成

## 成果物

- `docs/cycles/v1.7.4/design-artifacts/domain-models/kirocli-support_domain_model.md`
- `docs/cycles/v1.7.4/design-artifacts/logical-designs/kirocli-support_logical_design.md`
- `prompts/package/prompts/AGENTS.md`（更新）
- `docs/cycles/v1.7.4/construction/units/kirocli-support_implementation.md`

## 技術的考慮事項

- `@` 参照記法がKiroCLIでは機能しない旨を説明
- Kiroエージェントへの `resources` 設定確認手順を記載
- 参照: <https://kiro.dev/docs/cli/custom-agents/configuration-reference/#resources-field>

## リスクと対策

- **リスク**: 記載内容がKiroCLIの仕様変更で陳腐化する可能性
- **対策**: 公式ドキュメントへのリンクを記載し、最新情報を参照できるようにする
