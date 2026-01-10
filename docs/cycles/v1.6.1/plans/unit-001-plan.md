# Unit 001: ルール責務分離とフェーズ簡略指示 - 実行計画

**作成日**: 2026-01-10
**対象Unit**: 001-rules-separation

---

## 概要

rules.md の汎用ルールを AGENTS.md テンプレートに移動し責務を分離する。
また、フェーズ簡略指示機能を追加し、シンプルな指示でフェーズを開始できるようにする。

---

## Phase 1: 設計フェーズ

### ステップ1: ドメインモデル設計

**対象ファイル**:
- `docs/cycles/v1.6.1/design-artifacts/domain-models/rules-separation_domain_model.md`

**内容**:
- ルール責務の分類（AI-DLC共通 vs プロジェクト固有）
- フェーズ簡略指示のマッピング定義

### ステップ2: 論理設計

**対象ファイル**:
- `docs/cycles/v1.6.1/design-artifacts/logical-designs/rules-separation_logical_design.md`

**内容**:
- ファイル変更一覧と変更内容
- フェーズ簡略指示の実装方針

### ステップ3: 設計レビュー

設計内容をレビューし、承認を得る

---

## Phase 2: 実装フェーズ

### ステップ4: コード生成

**変更対象ファイル**:
1. `prompts/package/prompts/AGENTS.md` - 共通ルールセクション追加 + フェーズ簡略指示機能追加
2. `prompts/setup/templates/rules_template.md` - AI-DLC共通ルール削除
3. `prompts/package/prompts/inception.md` - 完了時メッセージ更新
4. `prompts/package/prompts/construction.md` - 完了時メッセージ更新
5. `prompts/package/prompts/operations.md` - 完了時メッセージ更新
6. `prompts/package/prompts/setup.md` - 完了時メッセージ更新
7. `docs/cycles/rules.md` - プロジェクト固有ルールのみに更新

### ステップ5: テスト生成

- プロンプト・テンプレートの変更はテストコード不要
- 動作確認として、変更後のテンプレートの整合性チェック

### ステップ6: 統合とレビュー

- 変更内容の最終確認
- 実装記録作成

---

## バックログ連携

このUnitで対応するバックログ項目:
- `docs/cycles/backlog/chore-move-common-rules-to-agents-md.md` → Unit完了時にアーカイブ

---

## 完了基準

- [ ] AGENTS.md.template に共通ルールセクションが追加されている
- [ ] rules_template.md からAI-DLC共通ルールが削除されている
- [ ] フェーズ簡略指示機能がAGENTS.mdに追加されている
- [ ] 各フェーズプロンプトの完了時メッセージが簡略指示形式に更新されている
- [ ] docs/cycles/rules.md がプロジェクト固有ルールのみになっている
- [ ] 実装記録が作成されている
