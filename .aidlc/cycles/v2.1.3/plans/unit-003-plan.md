# Unit 003 計画: AskUserQuestion使用ルールの追加

## 概要

`steps/common/rules.md` にAskUserQuestionツールの適切な使用ルールを追加し、ゲート承認・ユーザー選択・情報収集の3種類を区別するセクションを設ける。

## 変更対象ファイル

- `skills/aidlc/steps/common/rules.md` — AskUserQuestion使用ルールセクションの追加

## 実装計画

1. `steps/common/rules.md` の「ユーザーの承認プロセス」セクションの後に「AskUserQuestion使用ルール」セクションを追加
2. ゲート承認 / ユーザー選択 / 情報収集の3種類の区別を表形式で明記
3. 各種類の代表的な具体例を含める
4. 既存のセミオートゲート仕様との整合性を確認

### 追加内容の設計

- セクション名: `## AskUserQuestion使用ルール【重要】`
- 3種類の区別表: 種類・説明・対応方法・`automation_mode`での扱い・具体例
- セミオートゲート仕様との関係を既存語彙（`automation_mode`, `auto_approved`, `fallback`）で明示的にマッピング
- ゲート承認のみ `semi_auto` で自動化対象、ユーザー選択・情報収集は `automation_mode` に関わらずAskUserQuestion必須

## 完了条件チェックリスト

- [ ] `steps/common/rules.md` にAskUserQuestion使用ルールセクションを追加
- [ ] ゲート承認 / ユーザー選択 / 情報収集の3種類の区別を表形式で明記
- [ ] 各種類の代表的な具体例を含める
- [ ] 既存のセミオートゲート仕様との矛盾がないことを確認
