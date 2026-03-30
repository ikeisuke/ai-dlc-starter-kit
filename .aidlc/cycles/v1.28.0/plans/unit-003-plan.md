# Unit 003: reviewing-inception AIDLC固有観点の追加 - 実行計画

## 概要

reviewing-inception スキルに AIDLC 固有のレビュー観点（Intent-Unit 整合性チェック、意思決定記録の充足性チェック）を追加する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/skills/reviewing-inception/SKILL.md` | 2つの新規レビュー観点追加 + セルフレビューテンプレート更新 |

## 実装計画

### Phase 1: 設計
1. ドメインモデル設計: 新規観点の定義
2. 論理設計: SKILL.md への統合方法
3. 設計レビュー

### Phase 2: 実装
4. SKILL.md に観点追加
5. 統合とレビュー

## 完了条件チェックリスト

- [ ] SKILL.md に Intent-Unit 整合性チェック観点が追加されている
- [ ] SKILL.md に意思決定記録の充足性チェック観点が追加されている
- [ ] セルフレビューモードの指示テンプレートが更新されている
