# ステップ4: Unit定義 計画

## 目的
ユーザーストーリーを独立した価値提供ブロック（Unit）に分解

## Unit構成（推奨実装順序に基づく）

既存コード分析の依存関係分析を反映：

| Unit | 名称 | 依存関係 | 優先度 |
|------|------|----------|--------|
| 1 | パス参照不整合修正 | なし | 低 |
| 2 | 変数具体例削除 | なし | 高 |
| 3 | タグ付け自動化 | なし | 中 |
| 4 | バージョン管理 | なし | 中 |
| 5 | セットアップ分離 | Unit 4 | 中 |
| 6 | プロンプト生成方式改善 | Unit 5 | 中 |
| 7 | プロンプト分割・短縮化 | Unit 4, 5, 6 | 高 |

## 作成するファイル
- `docs/cycles/v1.2.0/story-artifacts/units/unit1_path_fix.md`
- `docs/cycles/v1.2.0/story-artifacts/units/unit2_variable_cleanup.md`
- `docs/cycles/v1.2.0/story-artifacts/units/unit3_auto_tagging.md`
- `docs/cycles/v1.2.0/story-artifacts/units/unit4_version_management.md`
- `docs/cycles/v1.2.0/story-artifacts/units/unit5_setup_separation.md`
- `docs/cycles/v1.2.0/story-artifacts/units/unit6_prompt_generation.md`
- `docs/cycles/v1.2.0/story-artifacts/units/unit7_prompt_split.md`

## 備考
- Unit 1〜4 は独立して実装可能
- Unit 5, 6 は連携して設計する必要あり
- Unit 7 は最も大きな変更のため最後に実装
