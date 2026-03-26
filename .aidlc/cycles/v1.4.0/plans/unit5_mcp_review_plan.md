# Unit 5: AI MCPレビュー提案 - 実装計画

## 概要

AI MCPが利用可能な場合に、成果物のレビューを積極的に推奨する機能を追加する。

## 目的

- MCPサーバー（Codex MCP等）が利用可能な環境で、成果物完了時にレビューを**推奨**
- **MCP未設定時は提案自体をスキップ**（煩わしさを避ける）

## 変更対象ファイル

以下のファイルを編集（`prompts/package/prompts/` 配下）:

1. **inception.md** - Intent、ユーザーストーリー、Unit定義の完了時に推奨
2. **construction.md** - 設計、コード、テストの完了時に推奨
3. **operations.md** - デプロイ計画、運用ドキュメントの完了時に推奨

> **注意**: `docs/aidlc/` は直接編集しない（rsyncで上書きされるため）

## 実装方針

### 提案タイミング

| フェーズ | 提案タイミング |
|---------|---------------|
| Inception | Intent完了時、ユーザーストーリー完了時、Unit定義完了時 |
| Construction | 設計レビュー完了時、コード生成完了時、テスト完了時 |
| Operations | デプロイ計画完了時、運用ドキュメント完了時 |

### 推奨文例（強いトーン）

```
【レビュー推奨】別のAIエージェント（Codex MCP等）が利用可能です。
品質向上のため、この成果物のレビューを実施することを推奨します。
レビューを実施しますか？
```

### MCP検出と動作

- **MCPが利用可能な場合**: 上記の推奨メッセージを表示し、レビュー実施を促す
- **MCPが利用不可の場合**: 提案自体をスキップ（何も表示しない）

## Phase 1: 設計（コードなし）

### ステップ1: ドメインモデル設計

- MCP推奨機能の概念モデルを定義
- 提案タイミングと条件の整理

### ステップ2: 論理設計

- 各プロンプトへの追加箇所を特定
- 推奨文のフォーマットを定義

### ステップ3: 設計レビュー

- ユーザーに設計内容を提示し承認を得る

## Phase 2: 実装

### ステップ4: コード生成

- `prompts/package/prompts/inception.md` を編集
- `prompts/package/prompts/construction.md` を編集
- `prompts/package/prompts/operations.md` を編集

### ステップ5: テスト生成

- プロンプト変更のため、自動テストは該当なし
- 手動確認: 推奨が適切なタイミングで表示されるか

### ステップ6: 統合とレビュー

- 変更内容の最終確認
- 実装記録の作成

## 成果物

- `docs/cycles/v1.4.0/design-artifacts/domain-models/unit5_domain_model.md`
- `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit5_logical_design.md`
- `docs/cycles/v1.4.0/construction/units/unit5_implementation.md`
- 更新: `prompts/package/prompts/inception.md`
- 更新: `prompts/package/prompts/construction.md`
- 更新: `prompts/package/prompts/operations.md`

## リスクと対策

| リスク | 対策 |
|--------|------|
| 推奨が多すぎて煩わしい | 主要な完了タイミングのみに絞る |
| MCP未設定時の動作 | 条件付き記述で完全スキップ |

---

作成日: 2024-12-14
