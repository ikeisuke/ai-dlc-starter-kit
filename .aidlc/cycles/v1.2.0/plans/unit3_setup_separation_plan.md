# Unit 3: セットアップ分離 - 実行計画

## 概要

初回セットアップとサイクル開始を分離し、Unit 2 で設計した設定アーキテクチャに基づいて `project.toml` を中心とした設定管理を実装する。

## 依存関係の確認

- **Unit 2: 設定アーキテクチャ設計** - ✅ 完了
  - 成果物: `docs/cycles/v1.2.0/design-artifacts/architecture/config_architecture.md`

## 現状分析

### 現在の setup-prompt.md の問題点

1. **変数置換方式**: `{{CYCLE}}` 等のテンプレート変数を使用
2. **単一ファイル**: 初回セットアップとサイクル開始が混在
3. **additional-rules.md**: 別ファイルで管理（project.toml に統合予定）

### 設計アーキテクチャ（Unit 2）の方針

1. **project.toml**: プロジェクト設定を集約
2. **変数置換の廃止**: AI読み取り方式に変更
3. **セットアップ分離**: 初回/サイクル開始を別プロンプトに

---

## Phase 1: 設計

### ステップ 1: ドメインモデル設計

**成果物**: `docs/cycles/v1.2.0/design-artifacts/domain-models/unit3_domain_model.md`

セットアップ処理のドメインモデルを定義:
- セットアップ判定ロジック（初回/継続）
- プロジェクト設定エンティティ
- サイクル管理

### ステップ 2: 論理設計

**成果物**: `docs/cycles/v1.2.0/design-artifacts/logical-designs/unit3_logical_design.md`

プロンプトファイル構成を定義:
- `setup-prompt.md` のエントリーポイント設計
- `setup-init.md` の処理フロー
- `setup-cycle.md` の処理フロー

### ステップ 3: 設計レビュー

ユーザーに設計内容を提示し、承認を得る。

---

## Phase 2: 実装

### ステップ 4: コード生成

**成果物**:

1. **prompts/setup-prompt.md**（エントリーポイント、分岐処理）
   - 初回/継続の判定ロジック
   - 適切なサブプロンプトへの誘導

2. **prompts/setup-init.md**（初回セットアップ用）
   - `docs/aidlc/project.toml` の生成
   - 共通プロンプト・テンプレートの配置
   - `version.txt` の配置

3. **prompts/setup-cycle.md**（サイクル開始用）
   - サイクルディレクトリの作成
   - `history.md` の初期化
   - progress.md のテンプレート生成

4. **設定ファイルテンプレート**
   - `project.toml` のテンプレート

### ステップ 5: テスト生成

手動テストシナリオを作成:
- 新規プロジェクトでのセットアップ
- 既存プロジェクトでのサイクル開始
- バージョンアップ時の動作

### ステップ 6: 統合とレビュー

- 既存ファイルとの整合性確認
- 実装記録の作成

---

## 成果物一覧

| ファイル | 種類 | 説明 |
|---------|------|------|
| `prompts/setup-prompt.md` | 修正 | エントリーポイント化 |
| `prompts/setup-init.md` | 新規 | 初回セットアップ用 |
| `prompts/setup-cycle.md` | 新規 | サイクル開始用 |
| ドメインモデル | 新規 | 設計ドキュメント |
| 論理設計 | 新規 | 設計ドキュメント |
| 実装記録 | 新規 | 完了記録 |

---

## 見積もり

2時間

## 注意事項

- Unit 4 でフェーズプロンプト改修を行うため、このUnitではフェーズプロンプト自体は変更しない
- `additional-rules.md` の廃止は Unit 4 以降で実施
- 既存の `prompts/setup/` ディレクトリは当面維持（後方互換性）
