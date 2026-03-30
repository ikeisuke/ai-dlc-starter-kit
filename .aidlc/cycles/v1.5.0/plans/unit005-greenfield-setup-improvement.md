# Unit 005: グリーンフィールドセットアップ改善 - 実行計画

## 概要

新規プロジェクト（グリーンフィールド）でのaidlc.tomlセットアップ時に、より詳細な質問でプロジェクト情報を収集する改善を行う。

## 背景

バックログ `improve-greenfield-aidlc-toml.md` より：
- **グリーンフィールド**: README.md などの情報源が少ないため、細かく質問してプロジェクト情報を収集する必要がある
- **ブラウンフィールド**: 推測できる情報は多いので、可変な設定部分のみ確認するシンプルなフローを維持

## 変更対象ファイル

- `prompts/setup-init.md`（セクション5「プロジェクト情報の収集」を改善）

## 実装方針

### 1. グリーンフィールド/ブラウンフィールドの判定追加

現在のセクション5の前に判定ロジックを追加：
- README.mdの有無・内容量
- package.json、go.mod等のプロジェクト設定ファイルの有無
- 既存コードの有無

### 2. グリーンフィールド向け追加質問項目

README.mdが存在しない、または情報が少ない場合に詳細質問：
- プロジェクトの目的・背景
- ターゲットユーザー（誰向けか）
- 主要機能（何ができるか）
- アーキテクチャ方針（モノリス/マイクロサービス等）
- テスト方針（TDD/後付け等）

### 3. ブラウンフィールド向けシンプルフロー維持

既存の推測ベースのフローを維持しつつ、以下のみ確認：
- 命名規則
- ドキュメント言語
- カスタムルール

## 予想される成果物

- **ドメインモデル**: `docs/cycles/v1.5.0/design-artifacts/domain-models/005-greenfield-setup_domain_model.md`
- **論理設計**: `docs/cycles/v1.5.0/design-artifacts/logical-designs/005-greenfield-setup_logical_design.md`
- **実装記録**: `docs/cycles/v1.5.0/construction/units/005-greenfield-setup_implementation.md`
- **コード変更**: `prompts/setup-init.md`

## 依存関係

- Unit 004（サイクルセットアップ分離）: 完了済み ✓

## リスクと対策

| リスク | 対策 |
|--------|------|
| 質問項目が多すぎてユーザー負担増 | 必須/任意を明確にし、デフォルト値を充実 |
| 既存フローとの整合性 | 判定ロジックを慎重に設計 |

---

計画ファイル: `docs/cycles/v1.5.0/plans/unit005-greenfield-setup-improvement.md`
