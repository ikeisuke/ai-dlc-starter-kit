# Unit 002: コード記述制限ルール追加 - 実装計画

## 概要

Construction Phase以外でのコード記述を制限するルールを各フェーズプロンプトに追加する。

## 変更対象ファイル

1. `prompts/package/prompts/inception.md`
2. `prompts/package/prompts/construction.md`
3. `prompts/package/prompts/operations.md`

## 追加するルール内容

### コード記述制限ルール

**原則**: Construction Phase の Phase 2（実装フェーズ）以外では、実装コードを記述しない

**許容されるケース**:
1. **Construction Phase - Phase 2**: 設計承認後のコード生成（通常フロー）
2. **調査・分析時**: 既存コードの読み取り・引用は可（新規コード記述は要承認）
3. **Operations Phase**: CI/CD設定、デプロイスクリプト、監視設定等の運用コード
4. **緊急バグ修正**: ユーザー承認を得た上での修正

**禁止されるケース**:
1. Inception Phase での実装コード記述
2. Construction Phase - Phase 1（設計フェーズ）での実装コード記述
3. 承認なしでのコード変更

## 実装ステップ

### Phase 1: 設計

1. **ドメインモデル設計**: ルールの構造と適用範囲を定義
2. **論理設計**: 各プロンプトへの追記位置と形式を設計
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

4. **コード生成**: 各プロンプトファイルにルールを追記
5. **テスト生成**: N/A（プロンプト変更のため自動テストなし）
6. **統合とレビュー**: 変更内容の最終確認

## 成果物

- `docs/cycles/v1.5.0/design-artifacts/domain-models/unit002_domain_model.md`
- `docs/cycles/v1.5.0/design-artifacts/logical-designs/unit002_logical_design.md`
- `docs/cycles/v1.5.0/construction/units/unit002_implementation.md`

## リスク・注意事項

- 既存の開発ルールセクションとの整合性を確認
- メタ開発の意識: 変更は `prompts/package/` に対して行う
