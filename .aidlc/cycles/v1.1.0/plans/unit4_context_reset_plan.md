# Unit 4: コンテキストリセット提案機能 - 実装計画

## 概要

フェーズ移行時およびUnit完了時にコンテキストリセットを推奨し、次のアクションを開始するためのプロンプトを提示する機能を実装する。

## 対象ファイル

以下のプロンプトファイルに「コンテキストリセット推奨」セクションを追加：

1. `docs/aidlc/prompts/inception.md` - Inception Phase完了時
2. `docs/aidlc/prompts/construction.md` - Unit完了時、全Unit完了時
3. `docs/aidlc/prompts/operations.md` - Operations Phase完了時（既存を強化）

## Phase 1: 設計

### ステップ1: ドメインモデル設計

- コンテキストリセット提案の概念モデルを定義
- 提案タイミング、メッセージ構造、次アクションプロンプトの構造を整理
- 成果物: `docs/cycles/v1.1.0/design-artifacts/domain-models/unit4_context_reset_domain_model.md`

### ステップ2: 論理設計

- 各プロンプトファイルへの追加内容を設計
- 提示フォーマットの統一仕様を定義
- 成果物: `docs/cycles/v1.1.0/design-artifacts/logical-designs/unit4_context_reset_logical_design.md`

### ステップ3: 設計レビュー

- ユーザーに設計内容を提示し承認を得る

## Phase 2: 実装

### ステップ4: コード生成

- `inception.md` への追加
- `construction.md` への追加
- `operations.md` の強化

### ステップ5: テスト生成

- 各プロンプトファイルの動作確認チェックリスト作成

### ステップ6: 統合とレビュー

- 実装内容の確認
- 実装記録の作成: `docs/cycles/v1.1.0/construction/units/unit4_context_reset_implementation.md`

## 完了基準

- [x] 計画作成
- [ ] ドメインモデル設計完了
- [ ] 論理設計完了
- [ ] 設計レビュー承認
- [ ] inception.md への追加
- [ ] construction.md への追加
- [ ] operations.md の強化
- [ ] 動作確認完了
- [ ] 実装記録作成
- [ ] progress.md 更新
- [ ] 履歴記録
- [ ] Gitコミット

## 見積もり

1.5時間
