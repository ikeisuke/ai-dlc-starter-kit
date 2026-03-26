# 実装記録: AGENTS.md/CLAUDE.md統合

## 概要

Unit 001 - AIエージェント（Claude Code等）がAI-DLCの存在を自動認識できるようにするためのAGENTS.mdとCLAUDE.mdを作成。

## 作成ファイル

| ファイル | パス | 説明 |
|----------|------|------|
| AGENTS.md | `AGENTS.md` | 汎用AIエージェント向け設定ファイル |
| CLAUDE.md | `CLAUDE.md` | Claude Code固有設定ファイル |
| AGENTS.md.template | `prompts/package/templates/AGENTS.md.template` | AGENTS.mdのテンプレート |
| CLAUDE.md.template | `prompts/package/templates/CLAUDE.md.template` | CLAUDE.mdのテンプレート |

## 設計ドキュメント

- ドメインモデル設計: `docs/cycles/v1.5.4/design-artifacts/domain-models/001_agents_md_domain_model.md`
- 論理設計: `docs/cycles/v1.5.4/design-artifacts/logical-designs/001_agents_md_logical_design.md`

## 実装詳細

### AGENTS.md

汎用的なAIエージェント向けの設定ファイル。以下のセクションを含む：
- 開発サイクルの開始（初期セットアップ、新規サイクル、継続）
- 推奨ワークフロー
- ドキュメントへの参照

### CLAUDE.md

Claude Code固有の設定ファイル。以下を含む：
- @AGENTS.md への参照
- AskUserQuestion機能の活用ルール
- 質問の深掘りルール
- TodoWriteツールの活用指示

### テンプレート

`prompts/package/templates/` に配置。セットアップ時にプロジェクトルートにコピーまたは追記される。

## テスト結果

- ドキュメント形式の検証: OK
- 参照パスの存在確認: OK
- @AGENTS.md 参照構文: OK

## AIレビュー

Codex MCPによるレビューを実施。以下の指摘を反映：
1. ソース・オブ・トゥルースの明確化
2. セットアップエントリポイントの明確化
3. ドメインモデルとの整合性確保

## 完了

- **状態**: 完了
- **完了日**: 2026-01-08
