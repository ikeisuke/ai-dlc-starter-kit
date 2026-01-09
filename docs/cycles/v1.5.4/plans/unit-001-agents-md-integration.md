# Unit 001 実行計画: AGENTS.md/CLAUDE.md統合

## 概要

AIエージェント（Claude Code等）がAI-DLCの存在を自動認識できるようにするため、AGENTS.mdとCLAUDE.mdを新規作成する。

## 関連バックログ

- `docs/cycles/backlog/feature-agents-md-integration.md`
- `docs/cycles/backlog/feature-ask-user-question-for-qa.md`

## 実行ステップ

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
- AGENTS.md の構造・内容を定義
- CLAUDE.md の構造・内容を定義
- 他のAIエージェントも参照可能な汎用形式を検討

#### ステップ2: 論理設計
- ファイル配置場所（プロジェクトルート）
- 参照関係の設計
- テンプレート化の検討（`prompts/package/templates/` への追加）

#### ステップ3: 設計レビュー
- 設計内容をユーザーに提示し承認を得る

### Phase 2: 実装

#### ステップ4: コード生成
- AGENTS.md を新規作成
- CLAUDE.md を新規作成
- `prompts/package/templates/` へのテンプレート追加（必要に応じて）

#### ステップ5: テスト生成
- 内容の検証（AI-DLC情報が正しく記載されているか）
- 参照関係の検証

#### ステップ6: 統合とレビュー
- 実装記録の作成
- Git コミット

## 成果物

| 成果物 | パス |
|--------|------|
| ドメインモデル設計 | `docs/cycles/v1.5.4/design-artifacts/domain-models/001_agents_md_domain_model.md` |
| 論理設計 | `docs/cycles/v1.5.4/design-artifacts/logical-designs/001_agents_md_logical_design.md` |
| AGENTS.md | `AGENTS.md`（プロジェクトルート） |
| CLAUDE.md | `CLAUDE.md`（プロジェクトルート） |
| 実装記録 | `docs/cycles/v1.5.4/construction/units/001_agents_md_implementation.md` |

## 注意事項

- このUnitはドキュメントのみで、コード実装はない
- `prompts/package/` への変更が必要な場合は、`docs/aidlc/` を直接編集しないこと
- バックログの対応案を参考にしつつ、必要に応じて調整

## Unitブランチ

- ブランチ名: `cycle/v1.5.4/unit-001`（作成推奨）
