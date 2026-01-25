# Construction Phase 履歴 - Unit 003

## Unit: その他のAIツール対応ドキュメント

### 基本情報

- **開始日**: 2026-01-20
- **完了日**: 2026-01-21
- **担当**: @ai

### 成果物

| ファイル | 種別 | 内容 |
|---------|------|------|
| `prompts/package/guides/skill-usage-guide.md` | 新規作成 | スキル利用ガイド |
| `prompts/package/prompts/AGENTS.md` | 更新 | AIツール対応セクション追加 |
| `docs/cycles/v1.8.2/design-artifacts/domain-models/003_kirocli_docs_domain_model.md` | 新規作成 | ドメインモデル |
| `docs/cycles/v1.8.2/design-artifacts/logical-designs/003_kirocli_docs_logical_design.md` | 新規作成 | 論理設計 |
| `docs/cycles/v1.8.2/plans/unit-003-plan.md` | 新規作成 | 計画ファイル |

### 実施内容

#### Phase 1: 設計

1. ドメインモデル設計
   - 各AIツールのスキル参照方式を概念モデルとして整理
   - スキルファイルの配置場所を明確化

2. 論理設計
   - ドキュメント構成とセクション設計
   - AGENTS.md と skill-usage-guide.md の役割分担を定義

3. 設計レビュー（Codex MCP）
   - スコープ不整合、パス解決、受け入れ基準等の指摘を反映

#### Phase 2: 実装

1. skill-usage-guide.md 作成
   - スキルの概念説明（特定のAIツールを呼び出すための手順書）
   - 各ツールでの使い方

2. AGENTS.md 更新
   - AIツール対応セクション追加
   - KiroCLI設定例

3. 実装レビュー（Codex MCP）
   - 「別のAIツール」→「特定のAIツール」に修正
   - スキルの概念をより正確に表現

### 発見されたバックログ

| Issue | タイトル | 優先度 |
|-------|---------|--------|
| #87 | AIDLCアップグレード指示にメタ開発用パス参照を追加 | 低 |
| #88 | init-cycle-dir.sh でプレリリースバージョンをサポート | 中 |

### 所感

- スキルの概念定義で議論があり、「他のAIツールを呼び出す」から「特定のAIツールを呼び出す」に修正
- 同一ツール呼び出し（例: /claude で Claude 自身を呼び出す）も考慮した表現に
