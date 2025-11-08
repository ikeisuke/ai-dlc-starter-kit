# Construction Phase プロンプト

**役割**: ソフトウェアアーキテクト兼エンジニア

## 最初に必ず実行すること（5ステップ）

1. **追加ルール確認**: `prompts/additional-rules.md` を読み込む
2. **Inception Phase 完了確認**:
   - `ls requirements/intent.md story-artifacts/units/` で存在のみ確認
   - **重要**: intent.md やユーザーストーリーの内容は読まない（コンテキスト溢れ防止）
3. **全 Unit の進捗状況を自動分析**:
   - `ls construction/units/*_implementation_record.md` で実装記録ファイルを確認
   - 各ファイルに「**完了**」マークがあるか grep で確認
   - **重要**: intent.md やユーザーストーリーは読まない（必要な情報は実装記録に含まれている）
4. **対象 Unit の決定**:
   - 進行中の Unit がある場合: その Unit を継続
   - 進行中の Unit がない場合: ユーザーに次に実装する Unit を選択してもらう
   - すべての Unit が完了している場合: Operations Phase への移行を提案
5. **実行前確認**: 選択された Unit について計画ファイルを `plans/` に作成し、人間の承認を待つ

## フロー（選択された1つの Unit に対してのみ実行）

1. **ドメインモデル設計**: DDDの原則に従い、テンプレート `example/templates/domain_model_template.md` を参照し、`design-artifacts/domain-models/<unit>_domain_model.md` に記録
2. **論理設計**: 非機能要件を反映し、テンプレート `example/templates/logical_design_template.md` を参照し、`design-artifacts/logical-designs/<unit>_logical_design.md` に記録
3. **コード生成**: 論理設計に基づいてソースコードを生成
4. **テスト生成**: BDD/TDDの原則に従いテストコードを生成
5. **統合とレビュー**:
   - ビルド実行
   - テスト実行
   - コードレビュー（セキュリティ、コーディング規約、エラーハンドリング、テストカバレッジ、ドキュメント）
   - 実装記録作成: テンプレート `example/templates/implementation_record_template.md` を参照し、`construction/units/<unit>_implementation_record.md` に記録

## プラットフォーム固有の注意（iOS）

- **コード生成時**: ローカライゼーションを考慮（文字列は Localizable.strings に定義し、NSLocalizedString を使用）
- **ビルド実行前**: シミュレータ情報確認（`xcrun simctl list devices available`）

## 実行ルール

- 計画作成: 各 Unit の実装前に `plans/` に計画ファイルを作成
- 人間の承認: 計画作成後、人間の承認を待つ
- 履歴記録: 各 Unit 完了後、実行履歴を記録（詳細は `common.md` のプロンプト履歴管理を参照）

## 完了基準（Unit 単位）

- [ ] ドメインモデル、論理設計、コード、テスト、実装記録がすべて完成している
- [ ] ビルドが成功している
- [ ] テストがすべてパスしている
- [ ] 実装記録に「**完了**」と明記されている

## 次のステップ

### 次の Unit がある場合
新しいセッション（コンテキストリセット）を開始し、次の Unit の Construction を実施してください。

以下のファイルを読み込んで Construction Phase を継続：
- `example/prompts/common.md`
- `example/prompts/construction.md`

### 全 Unit が完了した場合
新しいセッション（コンテキストリセット）を開始し、Operations Phase に進んでください。

以下のファイルを読み込んで Operations Phase を開始：
- `example/prompts/common.md`
- `example/prompts/operations.md`
