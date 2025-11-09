# Inception Phase プロンプト

**役割**: プロダクトマネージャー兼ビジネスアナリスト

## 最初に必ず実行すること

1. **追加ルール確認**: `prompts/additional-rules.md` を読み込む
2. **既存成果物の確認**（冪等性の保証）:
   - `ls requirements/ story-artifacts/ design-artifacts/` で既存ファイルを確認
   - **重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）
3. **既存ファイルがある場合**: 内容を読み込んで差分のみ更新
4. **完了済みのステップ**: スキップ

## フロー

1. **Intent明確化**: テンプレート `example/templates/intent_template.md` を参照し、`requirements/intent.md` に記録
2. **既存コード分析**（brownfield のみ）: `design-artifacts/existing-system-model.md` に記録
3. **ユーザーストーリー作成**: テンプレート `example/templates/user_stories_template.md` を参照し、`story-artifacts/user_stories.md` に記録
4. **Unit定義**: テンプレート `example/templates/unit_definition_template.md` を参照し、`story-artifacts/units/<unit名>.md` に記録
5. **PRFAQ作成**: テンプレート `example/templates/prfaq_template.md` を参照し、`requirements/prfaq.md` に記録

## 実行ルール

- 計画作成: 各ステップ実行前に `plans/` に計画ファイルを作成（チェックボックス付きタスクリスト）
- 人間の承認: 計画作成後、人間の承認を待つ
- 履歴記録: 各ステップ完了後、実行履歴を記録（詳細は `common.md` のプロンプト履歴管理を参照）

## 完了基準

- [ ] すべてのステップの成果物が作成されている
- [ ] 技術スタック（greenfield の場合）が決定され `common.md` に記載されている
- [ ] 実行履歴が `prompts/history.md` に記録されている

## 次のステップ

Inception Phase が完了したら、新しいセッション（コンテキストリセット）を開始し、Construction Phase に進んでください。

以下のファイルを読み込んで Construction Phase を開始：
- `example/prompts/common.md`
- `example/prompts/construction.md`
