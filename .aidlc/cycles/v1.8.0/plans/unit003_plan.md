# Unit 003 計画: サイクルディレクトリ初期化スクリプト

## 概要

サイクル用ディレクトリ構造を一括で作成するスクリプト `init-cycle-dir.sh` を作成する。

## 対象Issue

- #34

## スコープ

### 実装内容

1. **スクリプト作成**: `prompts/package/bin/init-cycle-dir.sh`
   - サイクルバージョンを引数で受け取る
   - 9個のディレクトリを一括作成
   - history/inception.md の初期化

2. **プロンプト修正**: `prompts/package/prompts/setup.md`
   - mkdir コマンドをスクリプト呼び出しに置換

### 作成するディレクトリ構造

```text
docs/cycles/{{CYCLE}}/
├── plans/
├── requirements/
├── story-artifacts/units/
├── design-artifacts/domain-models/
├── design-artifacts/logical-designs/
├── design-artifacts/architecture/
├── inception/
├── construction/units/
├── operations/
└── history/
```

### スコープ外

- backlog/ ディレクトリは別処理（サイクル固有ではない）

## Phase 1: 設計

### ステップ1: ドメインモデル設計

- スクリプトの責務と入出力を定義
- エラーハンドリング方針

### ステップ2: 論理設計

- スクリプトの処理フロー
- setup.md への統合方法

### ステップ3: 設計レビュー

- 設計内容をユーザーに提示し承認を得る

## Phase 2: 実装

### ステップ4: コード生成

- `prompts/package/bin/init-cycle-dir.sh` を作成
- `prompts/package/prompts/setup.md` を修正

### ステップ5: テスト生成

- スクリプトの動作確認（dry-run またはテスト実行）

### ステップ6: 統合とレビュー

- 実装記録を作成
- コードレビュー

## 成果物

- `prompts/package/bin/init-cycle-dir.sh`（新規）
- `prompts/package/prompts/setup.md`（修正）
- `docs/cycles/v1.8.0/design-artifacts/domain-models/init-cycle-dir_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/init-cycle-dir_logical_design.md`
- `docs/cycles/v1.8.0/construction/units/init-cycle-dir_implementation.md`

## 見積もり

30分
