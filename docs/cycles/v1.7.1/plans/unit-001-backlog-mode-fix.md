# Unit 001: バックログモード読み込み修正 - 計画

## 概要

aidlc.tomlの`[backlog].mode`設定がセットアップ時に正しく読み込まれない問題を修正する。

## 現状分析

### 問題

- `backlog.mode` の参照はガイド（`issue-driven-backlog.md`）にのみ存在
- 各フェーズプロンプト（setup.md, inception.md, construction.md, operations.md）には組み込まれていない
- セットアップ時にmode設定が読み込まれず、常にデフォルト動作（git）になる

### 関連ファイル

- `prompts/package/prompts/setup.md` - サイクルセットアップ
- `prompts/package/prompts/inception.md` - 要件定義
- `prompts/package/prompts/construction.md` - 実装
- `prompts/package/prompts/operations.md` - 運用
- `prompts/package/guides/issue-driven-backlog.md` - ガイド（参照パターンあり）

## 修正方針

### Phase 1: 設計

1. **ドメインモデル設計**
   - バックログモード判定ロジックの責務を定義
   - mode=git / mode=issue での分岐ポイントを特定

2. **論理設計**
   - 各プロンプトのどこでmode設定を参照すべきか決定
   - 設定読み込みパターンの統一

### Phase 2: 実装

1. **setup.md**
   - 既存の「最初に必ず実行すること」セクションにmode設定参照を追加
   - mode=issue時の追加処理（将来のUnit 002で使用する準備）

2. **construction.md**
   - 気づき記録フローでmode設定を参照
   - mode=issueの場合はIssue作成フローを案内

3. **inception.md / operations.md**（必要に応じて）
   - バックログ関連処理がある箇所を確認し、必要に応じてmode参照を追加

## 成果物

- `prompts/package/prompts/setup.md` の更新
- `prompts/package/prompts/construction.md` の更新
- 必要に応じて `inception.md`, `operations.md` の更新
- `docs/cycles/v1.7.1/design-artifacts/domain-models/001-backlog-mode-fix_domain_model.md`
- `docs/cycles/v1.7.1/design-artifacts/logical-designs/001-backlog-mode-fix_logical_design.md`

## 見積もり

- Phase 1（設計）: 30分
- Phase 2（実装）: 30分
- 合計: 1時間
