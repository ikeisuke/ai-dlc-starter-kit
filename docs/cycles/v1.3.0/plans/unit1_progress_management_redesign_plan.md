# Unit 1: 進捗管理再設計 - 実行計画

## 概要

progress.mdの維持・廃止・改善を検討し、複数人開発でもコンフリクトが起きにくい進捗管理の仕組みを実現する。

## Phase 1: 設計（対話形式、コードは書かない）

### ステップ1: ドメインモデル設計

現状の課題を分析し、以下の選択肢を検討:

1. **progress.md廃止**: ファイル存在チェックやGit状態から進捗を自動検出
2. **progress.md維持（構造改善）**: Unit単位でファイル分割、JSON形式への変更など
3. **ハイブリッド**: 最小限の情報のみ記録し、詳細は自動検出

成果物: `docs/cycles/v1.3.0/design-artifacts/domain-models/unit1_progress_management_redesign_domain_model.md`

### ステップ2: 論理設計

選択した方針に基づき、具体的な実装設計を行う:
- ファイル構造
- 更新タイミング
- 各フェーズでの一貫性

成果物: `docs/cycles/v1.3.0/design-artifacts/logical-designs/unit1_progress_management_redesign_logical_design.md`

### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る。

## Phase 2: 実装（設計承認後）

### ステップ4: コード生成

設計に基づき、以下を修正:
- プロンプトファイル（construction.md, inception.md, operations.md）
- テンプレートファイル（必要に応じて）

### ステップ5: テスト生成

該当なし（ドキュメント・プロンプト修正のため）

### ステップ6: 統合とレビュー

- 変更内容のレビュー
- 実装記録の作成

成果物: `docs/cycles/v1.3.0/construction/units/unit1_progress_management_redesign_implementation.md`

## 完了基準

- 進捗管理の方針が決定されている
- 各フェーズのプロンプトが一貫した進捗管理を行う
- 複数人開発でコンフリクトが起きにくい構造になっている
- progress.md（または代替手段）が更新されている
