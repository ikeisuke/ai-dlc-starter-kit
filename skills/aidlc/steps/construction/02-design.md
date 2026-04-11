# Construction Phase 設計（`construction.02-design`）

> Phase 1/Phase 2 境界・`depth_level` 分岐・AI レビュー分岐・`automation_mode` ゲート判定は `steps/construction/index.md` §2 に集約されている。本ファイルは Phase 1（設計）の詳細手順のみを含む。

**重要**: このフェーズでは設計ドキュメントのみ作成する。実装コードは Phase 2 で設計承認後に書く。設計レビューで承認を得るまで、コードファイルを作成・編集してはいけない（`depth_level=minimal` での省略を除く）。

## ステップ1: ドメインモデル設計

**タスクステータスを更新してください（着手時: `in_progress`、完了時: `completed`）。**

`depth_level` 別の動作差分は `steps/construction/index.md` §2.3 を参照（`minimal` スキップ可、`comprehensive` でドメインイベント追加）。スキップ時は「設計省略（depth_level=minimal）」を履歴記録。

- **対話形式**: 不明点は `[Question]` / `[Answer]` タグで記録し、**一問一答形式**でユーザーと対話しながら構造と責務を定義
- **成果物**: `.aidlc/cycles/{{CYCLE}}/design-artifacts/domain-models/[unit_name]_domain_model.md`（テンプレート: `templates/domain_model_template.md`）
- **重要**: **コードは書かず**、エンティティ・値オブジェクト・集約・ドメインサービスの構造と責務のみを定義

## ステップ2: 論理設計

**タスクステータスを更新してください（着手時: `in_progress`、完了時: `completed`）。**

`depth_level` 別の動作差分は `steps/construction/index.md` §2.3 を参照（`minimal` スキップ可、`comprehensive` でシーケンス図・状態遷移図追加）。

- **対話形式**: 同様に**一問一答形式**で対話しながらコンポーネント構成とインターフェースを定義
- **成果物**: `.aidlc/cycles/{{CYCLE}}/design-artifacts/logical-designs/[unit_name]_logical_design.md`（テンプレート: `templates/logical_design_template.md`）
- **重要**: **コードは書かず**、アーキテクチャパターン、コンポーネント構成、API設計の概要のみを定義

## ステップ3: 設計レビュー

**タスクステータスを更新してください（着手時: `in_progress`、完了時: `completed`）。**

> **順序制約**: `steps/common/review-flow.md` の手順を確認してからレビューを実行すること。設計承認なしに Phase 2（実装）に進むことは禁止。

1. **AI レビュー実施**（`steps/common/review-flow.md` に従う。`review_mode` / `automation_mode` 分岐は `steps/construction/index.md` §2.4/§2.8 参照）
2. レビュー結果を反映
3. **セミオートゲート判定**: `steps/construction/index.md` の「§2.4 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。

**承認なしで実装フェーズに進んではいけない**（`automation_mode=semi_auto` での自動承認を除く）

