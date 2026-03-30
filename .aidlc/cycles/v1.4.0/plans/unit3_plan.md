# Unit 3: Operations Phase構造改善 - 実装計画

## 概要
Operations Phaseの完了作業を構造化し、アプリバージョン確認を追加する

## 含まれるユーザーストーリー
- ストーリー7: 完了作業の構造改善
- ストーリー8: アプリバージョン確認

## 変更対象ファイル
- `prompts/package/prompts/operations.md`（メイン）
- `prompts/package/templates/operations_handover_template.md`（バージョン確認設定追加）

## 変更内容

### 1. ステップ1「デプロイ準備」にアプリバージョン確認を追加
- 対話形式でバージョン確認対象（package.json, pyproject.toml等）を設定
- 運用引き継ぎ（operations.md）に記録されている場合は再利用
- バージョン確認コマンド例を追加

### 2. ステップ5「リリース後の運用」→「バックログ整理と運用計画」に変更
- 現在の「完了時の必須作業」セクションからバックログ整理を統合
- 「AI-DLCサイクル完了」セクションのバックログ記録と連携
- リリース後の運用計画も含める

### 3. ステップ6「リリース準備」を新設
- 現在の「完了時の必須作業」セクションの内容を移行:
  - README更新
  - 履歴記録
  - Gitコミット
  - PR作成
- ステップ形式にすることでprogress.mdでの進捗管理が可能に

### 4. 「完了時の必須作業」セクションの調整
- ステップ6に移動した内容を削除
- 残すべき内容（最終チェック等）があれば残す

### 5. 運用引き継ぎテンプレートの更新
- バージョン確認対象のファイル設定セクションを追加

## 新しいステップ構成（変更後）

| ステップ | 名称 | 変更 |
|----------|------|------|
| 1 | デプロイ準備 | バージョン確認追加 |
| 2 | CI/CD構築 | 変更なし |
| 3 | 監視・ロギング戦略 | 変更なし |
| 4 | 配布 | 変更なし |
| 5 | バックログ整理と運用計画 | 名称変更・内容統合 |
| 6 | リリース準備 | **新設** |

## 実装フロー

### Phase 1: 設計（コードは書かない）
1. ドメインモデル設計: operations.mdの構造変更を設計
2. 論理設計: 各ステップの詳細内容を設計
3. 設計レビュー: ユーザー承認

### Phase 2: 実装
4. コード生成: operations.mdを編集
5. テンプレート更新: operations_handover_template.mdを編集
6. 統合とレビュー: 整合性確認、実装記録作成

## 注意事項
- `prompts/package/` を編集（`docs/aidlc/` は直接編集しない）
- 既存のステップ番号への依存がないことを確認
- progress.mdテンプレートへの影響を考慮

## 成果物
- `docs/cycles/v1.4.0/design-artifacts/domain-models/unit3_domain_model.md`
- `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit3_logical_design.md`
- `docs/cycles/v1.4.0/construction/units/unit3_implementation.md`
