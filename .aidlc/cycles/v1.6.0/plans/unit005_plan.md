# Unit 005: バージョンタグ運用 - 実行計画

**作成日**: 2026-01-10 00:42:17 JST

## 対象Unit

Unit 005: バージョンタグ運用

## 目的

1. v1.0.0以降のタグがないバージョンにgitタグを付与
2. operations.mdにタグ付け手順を追加
3. operations.mdにCHANGELOG.md更新手順を追加

## 依存関係

- Unit 004 (CHANGELOG作成): ✅ 完了済み

## 実行計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
- バージョンタグの命名規則とタグ付け対象コミットの特定方法を設計
- 成果物: `docs/cycles/v1.6.0/design-artifacts/domain-models/version-tagging_domain_model.md`

#### ステップ2: 論理設計
- operations.mdへの追加内容を設計
- タグ付けワークフローの整理
- 成果物: `docs/cycles/v1.6.0/design-artifacts/logical-designs/version-tagging_logical_design.md`

#### ステップ3: 設計レビュー
- 設計内容のユーザー承認

### Phase 2: 実装

#### ステップ4: 過去バージョンのタグ付け
- 既存タグの確認
- タグがないバージョンの特定
- gitタグの付与

#### ステップ5: operations.md更新
- タグ付け手順の追加
- CHANGELOG.md更新手順の追加
- 対象ファイル: `prompts/package/prompts/operations.md`

#### ステップ6: 統合とレビュー
- 変更のレビュー
- 実装記録の作成

## 成果物一覧

| 成果物 | パス |
|--------|------|
| ドメインモデル設計 | `docs/cycles/v1.6.0/design-artifacts/domain-models/version-tagging_domain_model.md` |
| 論理設計 | `docs/cycles/v1.6.0/design-artifacts/logical-designs/version-tagging_logical_design.md` |
| operations.md | `prompts/package/prompts/operations.md` |
| 実装記録 | `docs/cycles/v1.6.0/construction/units/version-tagging_implementation.md` |

## 注意事項

- `docs/aidlc/`は直接編集禁止（`prompts/package/`を編集）
- タグは`v1.x.x`形式（セマンティックバージョニング）
- 過去タグは各バージョンのマージコミットまたは最終コミットに付与
