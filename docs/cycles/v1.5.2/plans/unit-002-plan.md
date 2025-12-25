# Unit 002: setup-prompt.md改善 - 実装計画

## 対象Unit
- **Unit名**: setup-prompt.md改善
- **Unit定義ファイル**: docs/cycles/v1.5.2/story-artifacts/units/002-setup-prompt-improvement.md
- **見積もり**: 1時間
- **優先度**: High

## 概要
アップグレードしない場合でもサイクル開始できるよう、コピー元（`prompts/package/prompts/setup.md`）を直接参照する案内を表示する機能を実装します。

## 重要な注意事項【メタ開発の意識】
- **編集対象**: `prompts/package/prompts/setup.md`（`docs/aidlc/prompts/setup.md`ではない）
- **理由**: `docs/aidlc/` は `prompts/package/` からrsyncでコピーされるため、直接編集すると変更が消える
- **反映タイミング**: 次回のsetup時（Operations Phaseのrsync実行時）

## Phase 1: 設計【対話形式、コードは書かない】

### ステップ1: ドメインモデル設計
**成果物**: `docs/cycles/v1.5.2/design-artifacts/domain-models/setup_prompt_domain_model.md`

**設計内容**:
- エンティティ: SetupPrompt（setup.mdを表現）
- 値オブジェクト: FilePath、ExistenceStatus、GuidanceMessage
- 責務:
  - `docs/aidlc/prompts/setup.md`の存在確認
  - 存在しない場合のガイダンス表示
  - ケースC（バージョン同じ）の完了メッセージ修正

### ステップ2: 論理設計
**成果物**: `docs/cycles/v1.5.2/design-artifacts/logical-designs/setup_prompt_logical_design.md`

**設計内容**:
- レイヤー構造:
  - プレゼンテーション層: ガイダンスメッセージの表示
  - ビジネスロジック層: ファイル存在確認、条件分岐
- ファイル構成:
  - `prompts/package/prompts/setup.md`（編集対象）
- 処理フロー:
  1. サイクル存在確認
  2. `docs/aidlc/prompts/setup.md`の存在確認
  3. 存在しない場合、`prompts/package/prompts/setup.md`を参照する案内を表示
  4. ケースC（バージョン同じ）の完了メッセージ修正

### ステップ3: 設計レビュー
設計内容をユーザーに提示し、承認を得る

## Phase 2: 実装【設計を参照してコード生成】

### ステップ4: コード生成（Markdown編集）
**対象ファイル**: `prompts/package/prompts/setup.md`

**変更内容**:
1. サイクル存在確認後に`docs/aidlc/prompts/setup.md`の存在確認を追加
2. 存在しない場合の案内メッセージ追加:
   ```markdown
   エラー: docs/aidlc/prompts/setup.md が見つかりません。

   アップグレードせずにサイクルを開始する場合は、以下のファイルを参照してください：
   prompts/package/prompts/setup.md
   ```
3. ケースC（バージョン同じ）の完了メッセージに「次のサイクルを開始するには、上記のsetup.mdを参照してください」を追加

### ステップ5: テスト生成
**テスト方針**:
- 手動テスト（シェルスクリプトのため自動テスト困難）
- テストシナリオ:
  1. `docs/aidlc/prompts/setup.md`が存在しない状態で実行
  2. 案内メッセージが正しく表示されることを確認
  3. 案内されたパスが正しいことを確認

**成果物**: テストシナリオをドキュメント化

### ステップ6: 統合とレビュー
1. 変更内容の確認
2. テストシナリオの実行
3. 実装記録の作成: `docs/cycles/v1.5.2/construction/units/setup_prompt_implementation.md`

## 完了基準
- [ ] `prompts/package/prompts/setup.md`の編集完了
- [ ] 案内メッセージが適切に追加されている
- [ ] ケースCの完了メッセージが修正されている
- [ ] テストシナリオを実行し、正しく動作することを確認
- [ ] 実装記録に「完了」明記
- [ ] Unit定義ファイルの「実装状態」を「完了」に更新
- [ ] 履歴記録とGitコミット

## 依存関係
- **依存するUnit**: なし
- **外部依存**: Bashのファイル存在確認（`[ -f path ]`）

## リスクと対策
- **リスク**: `docs/aidlc/`を誤って編集してしまう
- **対策**: 編集前に必ずパスを確認、`prompts/package/`を編集していることを明示

## 質問事項
なし（要件が明確）
