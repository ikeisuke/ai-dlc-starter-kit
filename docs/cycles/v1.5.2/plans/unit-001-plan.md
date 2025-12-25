# Unit 001: backlog.md移行処理 - 実行計画

## 概要

旧形式の `docs/cycles/backlog.md` を新形式（`docs/cycles/backlog/` ディレクトリに個別ファイル）に自動移行する処理を実装する。

## Phase 1: 設計（コードは書かない）

### ステップ1: ドメインモデル設計
- **目的**: 移行処理のビジネスロジックを構造化
- **成果物**: `docs/cycles/v1.5.2/design-artifacts/domain-models/backlog-migration_domain_model.md`
- **内容**:
  - バックログ項目エンティティの定義
  - 移行処理ドメインサービスの責務
  - 完了済み判定ロジック

### ステップ2: 論理設計
- **目的**: 実装アーキテクチャを定義
- **成果物**: `docs/cycles/v1.5.2/design-artifacts/logical-designs/backlog-migration_logical_design.md`
- **内容**:
  - Markdown解析方式
  - ファイル分割・命名ロジック
  - エラーハンドリング・ロールバック

### ステップ3: 設計レビュー
- ユーザー承認を得る

## Phase 2: 実装（設計承認後）

### ステップ4: コード生成
- `prompts/package/prompts/setup.md` に移行処理スクリプトを追加
- 注意: `docs/aidlc/` は直接編集禁止（rules.md参照）

### ステップ5: テスト生成
- 手動テストシナリオの作成（BDD形式）

### ステップ6: 統合とレビュー
- 実際のbacklog.mdファイルでテスト
- 実装記録作成

## 技術的アプローチ

1. **Markdown解析**: `###` 見出し単位でセクション分割
2. **ファイル命名**: prefix（feature-, chore-, etc.）+ kebab-case化したタイトル
3. **メタデータ保持**: 発見日、発見サイクル、優先度を保持
4. **安全策**: 上書き防止、ロールバック機能

## 前提条件

- 旧形式 `docs/cycles/backlog.md` が存在する場合のみ実行
- 新形式ディレクトリ `docs/cycles/backlog/` は既に存在可能

## 成功基準

- backlog.mdの全セクションが個別ファイルに分割される
- 既存のbacklog/ファイルと重複しない
- 完了済み項目は除外される
- 元ファイルは削除される（または.bakにリネーム）
