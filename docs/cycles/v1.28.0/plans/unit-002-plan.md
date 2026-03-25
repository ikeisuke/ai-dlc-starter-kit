# Unit 002: 意思決定プロセスの記録 - 実行計画

## 概要

Inception Phase で複数の選択肢から意思決定した際に、選択理由・却下理由を構造的に記録する仕組みを追加する。意思決定記録テンプレートの作成と、Inception Phase プロンプトへの記録フロー追加を行う。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/templates/decision_record_template.md` | 新規作成: 意思決定記録テンプレート |
| `prompts/package/prompts/inception.md` | 記録フローの追加 |
| `docs/aidlc/templates/index.md` | テンプレート索引へ追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 意思決定記録の構造定義
   - 記録対象: AIが複数選択肢を提示してユーザーが選択した場面
   - 必須記録項目: 決定事項、選択肢、選択理由、却下理由
   - 保存先: `docs/cycles/{{CYCLE}}/inception/decisions.md`

2. **論理設計**: Inception Phase プロンプトへの統合方法
   - 記録タイミング: 各ステップで意思決定が発生した時点
   - 記録フロー: 対話中の意思決定を自動検出し、テンプレートに沿って記録

3. **設計レビュー**

### Phase 2: 実装

4. **コード生成**: テンプレート作成、プロンプト修正
5. **テスト生成**: テンプレート構造の妥当性確認
6. **統合とレビュー**

## 完了条件チェックリスト

- [ ] 意思決定記録テンプレート（`decision_record_template.md`）が作成されている
- [ ] Inception Phase プロンプトに記録フローが追加されている
- [ ] `docs/cycles/{{CYCLE}}/inception/decisions.md` への記録仕様が定義されている
