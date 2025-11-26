# Inception Phase への復帰プロンプト

## 状況

Construction Phase を開始しましたが、Inception Phase の成果物が不完全であることが判明しました。
以下のファイルを読み込んで、Inception Phase を再開してください：

- docs/versions/v1.0.0/prompts/common.md
- docs/versions/v1.0.0/prompts/inception.md

## 現在の状態

**存在するファイル**:
- `docs/versions/v1.0.0/story-artifacts/units/` に5つのUnit定義
- `docs/versions/v1.0.0/construction/progress.md`

**不足しているファイル**:
- `docs/versions/v1.0.0/requirements/intent.md`
- `docs/versions/v1.0.0/story-artifacts/user_stories.md`（またはその他のユーザーストーリー関連ファイル）
- `docs/versions/v1.0.0/requirements/prfaq.md`（推測）

## 実行してほしいこと

1. **既存成果物の確認**: `ls` コマンドで requirements/ と story-artifacts/ の内容を確認
2. **不足ファイルの特定**: 何が作成されていて、何が不足しているかを明確化
3. **冪等性の保証**: 既存のUnit定義ファイルを読み込み、内容を把握
4. **不足部分の補完**: Intent、ユーザーストーリー、PRFAQ等の不足している成果物を作成
5. **Unit間の関係性の明確化**: 各Unitの依存関係が適切に定義されているか確認し、必要に応じて更新
6. **進捗管理ファイルの検証**: progress.md の内容が正しいか確認

## 重要な注意事項

- 既存のUnit定義ファイルは削除せず、内容を活用すること
- 対話形式で不明点を確認しながら進めること（一問一答形式）
- すべての成果物が揃ったら、Inception Phase 完了のGitコミットを作成すること

---

**プロンプト実行コマンド**:

```
以下のファイルを読み込んで、Inception Phase を再開してください：
- docs/versions/v1.0.0/prompts/common.md
- docs/versions/v1.0.0/prompts/inception.md

AI-DLC Starter Kit v1.0.0 の Inception Phase を再開します。
既存の成果物を確認し、不足している部分を補完してください。
```
