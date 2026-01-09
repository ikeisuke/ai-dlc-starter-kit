# Unit 005 実装計画: スターターキットアップグレードフロー改善

## 概要

AI-DLCスターターキット自体の開発リポジトリでは、アップグレード案内を表示せずスキップするように修正する。

## 背景・動機

- setup.md のアップグレード案内は、通常のプロジェクトでは有用
- しかし、スターターキット自体の開発リポジトリでは混乱を招く
- 関連バックログ: `docs/cycles/backlog/chore-starter-kit-self-upgrade-flow.md`

## 実装方針

- プロジェクト名（`ai-dlc-starter-kit`）で開発リポジトリを判定
- 判定にはaidlc.tomlへのフラグ追加は行わない（Unit定義の境界に従う）
- 開発リポジトリと判定された場合、アップグレード案内をスキップ

## Phase 1: 設計

### ステップ1: ドメインモデル設計

- 成果物: `docs/cycles/v1.5.4/design-artifacts/domain-models/005_starter_kit_upgrade_domain_model.md`
- 内容:
  - プロジェクト判定ロジックの構造化
  - スターターキット開発リポジトリの定義

### ステップ2: 論理設計

- 成果物: `docs/cycles/v1.5.4/design-artifacts/logical-designs/005_starter_kit_upgrade_logical_design.md`
- 内容:
  - setup.md 内のアップグレード案内フローの修正設計
  - 判定処理の具体的な実装方針

### ステップ3: 設計レビュー

- 設計内容をユーザーに提示し承認を得る

## Phase 2: 実装

### ステップ4: コード生成

- 修正対象: `prompts/package/prompts/setup.md`
- 修正内容: プロジェクト名判定とスキップ処理の追加

### ステップ5: テスト生成

- 手動テスト: スターターキットリポジトリでの動作確認
- ドキュメントのみのため自動テストは不要

### ステップ6: 統合とレビュー

- 修正後のsetup.mdの動作確認
- 実装記録の作成

## 成果物一覧

| 種別 | パス |
|------|------|
| ドメインモデル | `docs/cycles/v1.5.4/design-artifacts/domain-models/005_starter_kit_upgrade_domain_model.md` |
| 論理設計 | `docs/cycles/v1.5.4/design-artifacts/logical-designs/005_starter_kit_upgrade_logical_design.md` |
| 実装 | `prompts/package/prompts/setup.md`（修正） |
| 実装記録 | `docs/cycles/v1.5.4/construction/units/005_starter_kit_upgrade_implementation.md` |

## 完了基準

- スターターキット開発リポジトリでアップグレード案内がスキップされること
- 通常のプロジェクトでは従来通りアップグレード案内が表示されること
- 実装記録に「完了」が明記されること
