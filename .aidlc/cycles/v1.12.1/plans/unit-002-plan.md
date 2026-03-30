# Unit 002 計画: setup-prompt.md参照先変更

## 概要

setup-prompt.mdからsetup.md経由ではなく、直接inception.mdを参照するように変更する。

## 背景

- v1.12.0でSetup/Inception統合が実施され、setup.mdはinception.mdへのリダイレクトファイルになっている
- 現状: setup-prompt.md → setup.md → inception.md（2段階リダイレクト）
- 目標: setup-prompt.md → inception.md（直接参照）

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-prompt.md` | setup.md参照をinception.md参照に変更 |
| `prompts/package/prompts/setup.md` | 削除（または後方互換用に残す - 要判断） |

## 実装計画

### Phase 1: 設計

1. setup-prompt.md内のsetup.md参照箇所を特定
2. setup.mdファイルの役割と削除可否を検討
3. 後方互換性の影響を評価

### Phase 2: 実装

1. setup-prompt.mdの該当箇所を修正
   - ケースB（cycle_start）: `setup.md` → `inception.md`
   - ケースC選択2: `setup.md` → `inception.md`
   - ケースD: `setup.md` → `inception.md`
2. setup.mdファイルの扱いを決定・実施
3. 動作確認

## 完了条件チェックリスト

- [ ] setup-prompt.mdがinception.mdを直接参照する
- [ ] setup.mdファイルの扱い（削除または後方互換用に残す）が決定される
- [ ] 既存プロジェクトへの影響がない
