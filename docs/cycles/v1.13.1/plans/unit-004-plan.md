# Unit 004 計画: ドキュメント・テンプレート強化

## 概要

CLAUDE.mdのAskUserQuestion機能ガイドを強化し、論理設計テンプレートにスクリプトインターフェース設計セクションを追加する。

## 変更対象ファイル

1. `prompts/package/prompts/CLAUDE.md`
   - AskUserQuestion機能の「必ず使用すべき場面」リストを追加

2. `prompts/package/templates/logical_design_template.md`
   - 「スクリプトインターフェース設計」セクションを追加

## 実装計画

### Phase 1: 設計（省略）

このUnitはドキュメント・テンプレートの修正のみであり、ドメインモデル・論理設計は不要。

### Phase 2: 実装

#### ステップ4: コード生成（ドキュメント修正）

1. **CLAUDE.md の修正**
   - 「AskUserQuestion機能の活用」セクションに「必ず使用すべき場面」サブセクションを追加
   - 具体的な利用シーン（Unit選択、設計承認、PRレビュー等）を列挙

2. **logical_design_template.md の修正**
   - 新規セクション「## スクリプトインターフェース設計（該当する場合）」を追加
   - 必須サブセクション: 引数、成功時出力、エラー時出力、使用コマンド
   - シェルスクリプトの入出力設計ガイドを記載

#### ステップ5: テスト生成（該当なし）

ドキュメント修正のため、自動テストは不要。

#### ステップ6: 統合とレビュー

1. 修正内容をレビュー
2. AIレビュー実施
3. 実装記録を作成

## 完了条件チェックリスト

- [ ] CLAUDE.mdに「必ず使用すべき場面」サブセクションを追加（最低3項目以上）
  - 例: Unit選択、設計承認、PRレビュー判断、レビュー継続判断
- [ ] logical_design_template.mdに「## スクリプトインターフェース設計（該当する場合）」セクションを追加
  - 必須サブセクション: 成功時出力、エラー時出力、使用コマンド

## ソースオブトゥルースと同期

- **修正対象**: `prompts/package/`配下がソースオブトゥルース
- **同期先**: `docs/aidlc/`配下はOperations Phaseでrsync同期される
- **検証**: 本Unit完了時点では`prompts/package/`配下の変更を確認。`docs/aidlc/`への反映はOperations Phase完了後に確認

## 技術的考慮事項

- CLAUDE.mdはClaude Code固有の設定ファイル
- logical_design_template.mdはConstruction Phase Phase 1で使用されるテンプレート
- rsync同期のため`prompts/package/`配下を修正対象とする
- `docs/aidlc/`配下は直接編集しない（Operations Phaseでrsync同期される）
