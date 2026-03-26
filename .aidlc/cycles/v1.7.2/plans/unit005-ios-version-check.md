# Unit 005: iOSバージョン確認強化 - 実行計画

## 概要

Operations PhaseでiOSプロジェクトのビルド番号（CURRENT_PROJECT_VERSION）の確認手順を追加する。

## 対象ストーリー

1. **ストーリー 4-1**: Operations Phaseでのビルド番号確認 (新規)

## Phase 1: 設計

### ステップ1: ドメインモデル設計

iOSバージョン管理の概念モデルを定義：

- **MARKETING_VERSION**: App Storeに表示されるバージョン（例: 1.0.0）
- **CURRENT_PROJECT_VERSION**: ビルド番号（例: 1, 2, 3...）
- **確認対象**: project.type = "ios" のプロジェクトのみ

### ステップ2: 論理設計

Operations Phase ステップ1での変更内容を設計：

1. **project.type判定**
   - aidlc.tomlからproject.typeを読み取り
   - "ios"の場合のみビルド番号確認を実行

2. **ビルド番号確認フロー**
   - デフォルトブランチを取得
   - project.pbxprojファイルを検索（複数の場合はユーザー確認）
   - CURRENT_PROJECT_VERSIONを現在のブランチとデフォルトブランチで比較
   - 同一の場合はインクリメントを提案

3. **注意事項の追加**
   - App Storeは同一ビルド番号での再提出を許可しない点を明記

## Phase 2: 実装

### ステップ4: コード生成

1. prompts/package/prompts/operations.md のステップ1を修正

### ステップ5: テスト生成

- Markdownlintによる構文チェック
- 手動レビュー（プロンプトのテストは手動確認）

### ステップ6: 統合とレビュー

- 変更を統合
- AIレビュー実施（mcp_review.mode = required）
- 実装記録の作成

## 編集対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/operations.md` | ステップ1にiOSビルド番号確認フローを追加 |

## 注意事項

- `docs/aidlc/` は直接編集禁止。必ず `prompts/package/` を編集する
- 変更はOperations PhaseのrsyncでAI-DLC環境に反映される

## 完了条件

- prompts/package/prompts/operations.md の更新完了
- Markdownlintパス
- AIレビュー完了
- 実装記録作成
