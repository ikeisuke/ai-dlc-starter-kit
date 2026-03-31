# 論理設計: レビュースキルのタイミングベース化

## 概要

9つの新スキルSKILL.md作成と全参照箇所の更新。各スキルのSKILL.mdは既存スキルの共通構造を維持し、レビュー観点セクションのみタイミング固有に変更する。

## SKILL.md 共通構造

全スキルで以下の構造を維持:

1. frontmatter（name, description, argument-hint, compatibility, allowed-tools）
2. レビュー観点（タイミング固有）
3. 実行コマンド（Codex/Claude/Gemini）
4. セッション継続
5. 外部ツールとの関係
6. セルフレビューモード

## 新スキル別レビュー観点

### reviewing-inception-intent (focus: inception)

- Intent品質: 目的・スコープの明確さ、妥当性
- 旧reviewing-inceptionの「Intent品質」セクションを抽出

### reviewing-inception-stories (focus: inception)

- ストーリー品質: INVEST準拠、受け入れ基準の具体性
- 旧reviewing-inceptionの「ユーザーストーリー品質」セクションを抽出

### reviewing-inception-units (focus: inception)

- Unit定義品質: 分割適切さ、依存関係、見積もり妥当性
- Intent-Unit整合性、意思決定記録の充足性
- 旧reviewing-inceptionの「Unit定義品質」「Intent-Unit整合性」「意思決定記録」を抽出

### reviewing-construction-plan (focus: architecture)

- 計画・アーキテクチャ整合性、実装計画の妥当性
- 旧reviewing-architectureの観点を計画レビュー向けに調整

### reviewing-construction-design (focus: architecture)

- 設計品質、パターン適用、API設計
- 旧reviewing-architectureの全観点を維持

### reviewing-construction-code (focus: code, security)

- コード品質（旧reviewing-code全観点）
- セキュリティ（旧reviewing-securityの主要観点を統合）
- 指摘にfocus=security タグを付与する指示を含む

### reviewing-construction-integration (focus: code)

- 設計との乖離確認
- レビュー/テスト実施状況の確認
- 完了条件の達成度チェック

### reviewing-operations-deploy (focus: architecture)

- デプロイ計画の妥当性、ロールバック手順
- 環境設定・監視の確認

### reviewing-operations-premerge (focus: code, security)

- PR全体の品質確認
- セキュリティの最終チェック

## review-flow.md CallerContextマッピング（新）

| 呼び出し元ステップ | スキル名 |
|---|---|
| 計画承認前 | `reviewing-construction-plan` |
| Phase 1 ステップ3（設計レビュー） | `reviewing-construction-design` |
| Phase 2 ステップ4（コード生成後） | `reviewing-construction-code` |
| Phase 2 ステップ6（統合とレビュー） | `reviewing-construction-integration` |
| Intent承認前 | `reviewing-inception-intent` |
| ユーザーストーリー承認前 | `reviewing-inception-stories` |
| Unit定義承認前 | `reviewing-inception-units` |
| デプロイ計画承認前 | `reviewing-operations-deploy` |
| PRマージ前レビュー | `reviewing-operations-premerge` |

## review-flow.md focus参照変更

security指摘の非公開扱い判定を変更:
- 旧: `レビュー種別 == security` → 非公開扱い
- 新: `finding.focus == security` → 非公開扱い

これによりスキル名に依存せず、指摘の性質（focus）で分岐する。
