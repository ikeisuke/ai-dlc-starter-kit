# Unit 4: 割り込み対応ルール - 実装計画

## 概要
作業中の割り込み要望を適切に分類し、計画を崩さずに追加要望を管理するルールをConstruction Phaseプロンプトに追加する。

## 関連バックログ項目
- `[2024-12-14] 気づき: コンテキスト増加時の自動リセット提案` - Unit 4 に関連する可能性あり（AI側からの能動的提案機能）

## 実装ステップ

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
割り込み要望の分類フローを定義：

1. **関係ない案件** → バックログに記録
2. **関係あるが別Unit** → バックログ or 別Unit定義に追加
3. **今のUnitに関係** → Unit定義に追記 → 設計から実装

#### ステップ2: 論理設計
- `prompts/package/prompts/construction.md` に「割り込み対応フロー」セクションを追加
- 配置場所: 「開発ルール」セクション内（気づき記録フローの近く）

#### ステップ3: 設計レビュー
設計内容をユーザーに提示し、承認を得る

### Phase 2: 実装

#### ステップ4: コード生成
`prompts/package/prompts/construction.md` を編集し、割り込み対応フローを追加

#### ステップ5: テスト生成
- プロンプト編集のみのため、自動テストは不要
- 手動確認: フローの読みやすさ・明確さを確認

#### ステップ6: 統合とレビュー
- 実装記録を作成
- Unit定義ファイルを更新
- 履歴記録
- Gitコミット

## 成果物
- `docs/cycles/v1.4.0/design-artifacts/domain-models/unit4_interruption_handling_domain_model.md`
- `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit4_interruption_handling_logical_design.md`
- `prompts/package/prompts/construction.md`（編集）
- `docs/cycles/v1.4.0/construction/units/unit4_interruption_handling_implementation.md`

## 見積もり
小規模（プロンプト編集のみ）
