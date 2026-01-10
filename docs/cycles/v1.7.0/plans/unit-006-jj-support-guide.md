# Unit 006 計画: jj基本ワークフロー

## 概要

jj（Jujutsu）を使用したAI-DLC開発ワークフローのガイドドキュメントを作成する。

## 成果物

- `prompts/package/guides/jj-support.md`

## Phase 1: 設計

### ステップ1: ドメインモデル設計

**目的**: jjサポートガイドの構成要素を整理

**内容**:
- jjの特徴と利点（5項目以上）
- Git/jjコマンド対照表の項目洗い出し（10件以上）
- AI-DLCワークフローとの互換性ポイント

**成果物**: `docs/cycles/v1.7.0/design-artifacts/domain-models/jj-support_domain_model.md`

### ステップ2: 論理設計

**目的**: ガイドドキュメントの構成設計

**内容**:
- ドキュメント構成の決定
- 各セクションの詳細内容設計
- 注意事項・制限事項の整理

**成果物**: `docs/cycles/v1.7.0/design-artifacts/logical-designs/jj-support_logical_design.md`

### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る

## Phase 2: 実装

### ステップ4: ガイドドキュメント作成

**対象**: `prompts/package/guides/jj-support.md`

**含む内容**:
1. 概要（実験的機能としての位置づけ）
2. jjの特徴と利点
3. Git/jjコマンド対照表
4. AI-DLCワークフローでの使用方法
5. 注意事項と制限

### ステップ5: レビュー・統合

- ドキュメント内容の確認
- Gitコミット

## 見積もり

- Phase 1（設計）: ドキュメント構成の設計
- Phase 2（実装）: ガイドドキュメント作成

## 依存関係

- なし（独立して実行可能）

## リスク・注意事項

- 実験的機能として位置づけ、将来的な変更の可能性を明記
- Gitとの共存（colocate）を前提とした説明

---

作成日: 2026-01-11
