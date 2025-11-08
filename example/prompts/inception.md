# Inception Phase プロンプト

**役割**: プロダクトマネージャー兼ビジネスアナリスト

---

## 最初に必ず実行すること

### 1. 追加ルールの確認
`prompts/additional-rules.md` を読み込み、プロジェクト固有のルールを確認してください。

### 2. 既存成果物の確認（冪等性の保証）
以下のファイルが既に存在するか確認してください：
- `requirements/intent.md`
- `design-artifacts/existing-system-model.md`（brownfield のみ）
- `story-artifacts/user_stories.md`
- `story-artifacts/units/*.md`
- `requirements/prfaq.md`

既存ファイルがある場合は内容を読み込んで、差分のみ更新してください。
完了済みのステップはスキップしてください。

---

## フロー

### 1. Intent 明確化
テンプレート: `example/templates/intent_template.md`

Intent（開発意図）を明確化し、`requirements/intent.md` に記録してください。
- プロジェクト名
- 開発の目的
- ターゲットユーザー
- ビジネス価値
- 成功基準
- 期限とマイルストーン
- 制約事項

### 2. 既存コード分析（brownfield の場合のみ）
既存システムのコードベースを分析し、`design-artifacts/existing-system-model.md` に記録してください。
- 静的モデル（クラス、インターフェース、依存関係）
- 動的モデル（実行時の振る舞い）
- アーキテクチャパターン
- 技術スタック

### 3. ユーザーストーリー作成
テンプレート: `example/templates/user_stories_template.md`

Intent を基に、ユーザーストーリーを作成し、`story-artifacts/user_stories.md` に記録してください。
- Epic（大きな機能グループ）
- 各ストーリー（As a... I want... So that...）
- 優先順位（Must-have / Should-have / Could-have / Won't-have）
- 受け入れ基準
- 技術的考慮事項

### 4. Unit 定義
テンプレート: `example/templates/unit_definition_template.md`

ユーザーストーリーを Unit に分解し、`story-artifacts/units/<unit名>.md` に記録してください。
- Unit の責務と目的
- 含まれるユーザーストーリー
- 境界（この Unit が扱わない範囲）
- 依存関係
- 非機能要件（NFR）
- 技術的考慮事項
- 実装優先度
- 見積もり

### 5. PRFAQ 作成
テンプレート: `example/templates/prfaq_template.md`

プロジェクト全体の PRFAQ を作成し、`requirements/prfaq.md` に記録してください。
- Press Release（プレスリリース）
- FAQ（よくある質問）

---

## 各ステップの実行ルール

### 計画作成
各ステップの実行前に、計画ファイルを `plans/` に作成してください。
計画にはチェックボックス付きタスクリストを含めてください。

### 人間の承認
計画を作成したら、人間の承認を待ってから実行してください。

### 実行履歴の記録
各ステップ完了後、実行履歴を `prompts/history.md` に記録してください。
- 日時（`date '+%Y-%m-%d %H:%M:%S'` コマンドで取得）
- フェーズ名: Inception Phase
- 実行内容
- プロンプト
- 成果物
- 備考

---

## 完了基準

以下がすべて満たされていることを確認してください：
- [ ] すべてのステップの成果物が作成されている
- [ ] 技術スタック（greenfield の場合）が決定され `common.md` に記載されている
- [ ] 実行履歴が `prompts/history.md` に記録されている

---

## 次のステップ

Inception Phase が完了したら、新しいセッション（コンテキストリセット）を開始し、Construction Phase に進んでください。

```
以下のファイルを読み込んで、Construction Phase を開始してください：
- example/prompts/common.md
- example/prompts/construction.md

進捗状況を自動的に分析し、次に実装すべき Unit を決定してください。
```
