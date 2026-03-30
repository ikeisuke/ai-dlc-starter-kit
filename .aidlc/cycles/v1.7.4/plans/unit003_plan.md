# Unit 003: サブエージェント活用ガイド - 実行計画

## 概要

バックログ追加処理やConstruction Phaseでのサブエージェント活用方法をガイド化する。

## 関連Issue

- #64: バックログ追加時のサブエージェント活用ガイド
- #62: Construction Phaseのサブエージェント委任ガイド

## Phase 1: 設計

### ステップ1: ドメインモデル設計

本Unitはドキュメント追加のみのため、ドメインモデルは軽量版で作成。

**成果物**: `docs/cycles/v1.7.4/design-artifacts/domain-models/003-subagent-guide_domain_model.md`

### ステップ2: 論理設計

ガイドの構成とコンテンツ配置を設計。

**成果物**: `docs/cycles/v1.7.4/design-artifacts/logical-designs/003-subagent-guide_logical_design.md`

### ステップ3: 設計レビュー

設計内容をユーザーに提示し承認を取得。

## Phase 2: 実装

### ステップ4: コード（ドキュメント）生成

設計に基づき、以下のファイルを編集・作成:

1. `prompts/package/guides/subagent-usage.md` - 新規ガイドファイル
2. `prompts/package/prompts/construction.md` - ガイド参照の追加

### ステップ5: テスト生成

ドキュメントのため該当なし（Markdownlintのみ）

### ステップ6: 統合とレビュー

- Markdownlint実行
- AIレビュー（設定: mode=required）
- 人間の最終承認

## 完了基準

- [ ] サブエージェント活用ガイドが作成されている
- [ ] Construction Phaseプロンプトからガイドが参照されている
- [ ] 委任可能/不可能な作業が明確化されている
- [ ] Markdownlintがパスする

## 備考

- 編集対象は `prompts/package/` 配下（Operations Phaseでrsync反映）
- Claude Code固有のTask Tool前提で記述
