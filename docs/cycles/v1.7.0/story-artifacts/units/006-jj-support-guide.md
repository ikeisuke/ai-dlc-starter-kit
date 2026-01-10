# Unit: jj基本ワークフロー

## 概要
jj（Jujutsu）を使用したAI-DLC開発ワークフローを文書化し、実験的機能として提供する。

## 含まれるユーザーストーリー
- ストーリー 3-1: jj基本ワークフローの文書化

## 責務
- `prompts/package/guides/jj-support.md` の作成
- jjの特徴と利点の説明（5項目以上）
- Git/jjコマンド対照表の作成（10件以上）
- AI-DLCワークフローとの互換性説明（サイクル開始、コミット、ブランチ切り替え等）

## 境界
- jj固有の高度な機能の説明は対象外
- プロンプトへのjj対応コマンド追加は対象外（将来検討）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- jj（Jujutsu）- ユーザー環境に依存

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 実験的機能として位置づけ、オプトインで利用可能
- Gitとの共存（colocate）を前提

## 参考ファイル
- `prompts/setup-prompt.md`（スターターキットセットアップ - git操作の参考）
- `prompts/package/prompts/setup.md`（サイクルセットアップ - git操作の参考）
- `prompts/package/prompts/inception.md`（Inception Phase - ブランチ操作の参考）
- `prompts/package/prompts/construction.md`（Construction Phase - コミット操作の参考）
- `prompts/package/prompts/operations.md`（Operations Phase - タグ・プッシュ操作の参考）
- `docs/cycles/backlog/feature-jj-experimental-support.md`（バックログ）

## 実装優先度
Low

## 見積もり
中（ガイドドキュメント作成）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
