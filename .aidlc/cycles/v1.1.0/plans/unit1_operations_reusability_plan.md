# Unit 1: Operations Phase再利用性 - 実装計画

## 概要

Operations Phaseの成果物（運用情報）をサイクル横断で引き継げる仕組みを構築する。

## 目標

1. 運用引き継ぎ情報の格納場所（`docs/aidlc/operations/`）の定義
2. Operations Phase開始時に既存の実設定ファイル（`.github/workflows/`等）を認識するフローの追加
3. 引き継ぎ情報と実設定を参照して、再利用/更新/新規作成を選択できる仕組み

## 格納する引き継ぎ情報の例

- 監視対象のメトリクス一覧
- アラート閾値
- デプロイ手順のメモ
- CI/CDの設定方針
- 運用時の注意事項

## 実装ステップ

### Phase 1: 設計（コードは書かない）

#### ステップ1: ドメインモデル設計
- 運用引き継ぎ情報の種類と構造を定義
- 既存実設定ファイルとの関係を整理
- 成果物: `docs/cycles/v1.1.0/design-artifacts/domain-models/unit1_operations_reusability_domain_model.md`

#### ステップ2: 論理設計
- `docs/aidlc/operations/` のディレクトリ構造設計
- operations.mdプロンプトへの追加内容設計
- setup-prompt.mdへの追加内容設計
- 成果物: `docs/cycles/v1.1.0/design-artifacts/logical-designs/unit1_operations_reusability_logical_design.md`

#### ステップ3: 設計レビュー
- ユーザーに設計内容を提示し承認を得る

### Phase 2: 実装

#### ステップ4: コード生成
- `docs/aidlc/operations/` ディレクトリと初期ファイルの作成
- `docs/aidlc/prompts/operations.md` への引き継ぎフロー追加
- `prompts/setup-prompt.md` への共通Operationsディレクトリ作成の追加

#### ステップ5: テスト生成
- ドキュメント変更のため、手動検証チェックリストを作成

#### ステップ6: 統合とレビュー
- 変更内容の最終確認
- 実装記録の作成

## 成果物一覧

| 成果物 | パス |
|--------|------|
| ドメインモデル | `docs/cycles/v1.1.0/design-artifacts/domain-models/unit1_operations_reusability_domain_model.md` |
| 論理設計 | `docs/cycles/v1.1.0/design-artifacts/logical-designs/unit1_operations_reusability_logical_design.md` |
| 実装記録 | `docs/cycles/v1.1.0/construction/units/unit1_operations_reusability_implementation.md` |

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `docs/aidlc/operations/` | 新規ディレクトリ作成（運用引き継ぎ情報の格納場所） |
| `docs/aidlc/prompts/operations.md` | 既存設定認識フロー・引き継ぎ情報参照フローの追加 |
| `prompts/setup-prompt.md` | 共通Operationsディレクトリ作成の追加 |

## 境界（スコープ外）

- 実際のCI/CD設定ファイルの作成（それはOperations Phaseで実施）
- プロジェクト横断での共有（同一プロジェクト内のサイクル横断のみ）

## 見積もり

2時間
