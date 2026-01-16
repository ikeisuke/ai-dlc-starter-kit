# Unit 002 計画: 共通ラベル一括初期化スクリプト

## 概要

バックログ管理用の共通ラベル（backlog, type:\*, priority:\*）を一括で作成するスクリプトを作成する。

## 関連Issue

- #34

## Phase 1: 設計

### ステップ1: ドメインモデル設計

- **目的**: ラベル管理の構造と責務を定義
- **成果物**: `docs/cycles/v1.8.0/design-artifacts/domain-models/002-init-labels_domain_model.md`
- **内容**:
  - ラベルエンティティの定義（名前、色、説明）
  - ラベルリポジトリの責務
  - 既存ラベルチェックのロジック

### ステップ2: 論理設計

- **目的**: スクリプトの構成とインターフェースを定義
- **成果物**: `docs/cycles/v1.8.0/design-artifacts/logical-designs/002-init-labels_logical_design.md`
- **内容**:
  - スクリプト構成
  - 入出力仕様
  - エラー処理

### ステップ3: 設計レビュー

- AIレビュー（Codex Skill）を実施
- ユーザー承認を取得

## Phase 2: 実装

### ステップ4: コード生成

- **成果物**: `prompts/package/bin/init-labels.sh`
- **内容**:
  - 11個の共通ラベルを一括作成
  - 既存ラベルのスキップ処理
  - 出力フォーマット統一

### ステップ5: テスト生成

- **内容**:
  - 手動テスト手順の作成（シェルスクリプトのため）
  - 動作確認項目の定義

### ステップ6: 統合とレビュー

- **変更対象ファイル**:
  - `prompts/package/prompts/setup.md`（呼び出し追加）
  - `prompts/package/guides/backlog-management.md`（呼び出し追加）
- AIレビュー実施
- ユーザー承認

## 作成するラベル一覧

| ラベル名 | 色 | 説明 |
|---------|------|------|
| backlog | 0052CC | バックログアイテム |
| type:feature | A2EEEF | 新機能 |
| type:bugfix | D73A4A | バグ修正 |
| type:chore | FEF2C0 | 雑務 |
| type:refactor | C5DEF5 | リファクタリング |
| type:docs | 0075CA | ドキュメント |
| type:perf | F9D0C4 | パフォーマンス |
| type:security | D93F0B | セキュリティ |
| priority:high | B60205 | 優先度: 高 |
| priority:medium | FBCA04 | 優先度: 中 |
| priority:low | 0E8A16 | 優先度: 低 |

## 完了条件

- [ ] `init-labels.sh` スクリプトが作成されている
- [ ] 11個のラベルを一括作成できる
- [ ] 既存ラベルはスキップされる
- [ ] setup.mdから呼び出し可能
- [ ] backlog-management.mdに記載されている
