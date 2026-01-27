# Unit 004 計画: Issue用基本ラベル移動

## 概要

`init-labels.sh` の呼び出しを `setup.md`（サイクル開始時）から `setup-prompt.md`（初期セットアップ時）に移動する。基本ラベルは初期セットアップ時に1回作成すれば十分で、毎回のサイクル開始時に確認する必要がないため。

## 現状

- `prompts/package/prompts/setup.md` 159行目 - `init-labels.sh` の呼び出しがある
- `prompts/setup-prompt.md` - 呼び出しがない

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/setup.md` | ラベル作成セクション（セクション5）を削除 |
| `prompts/setup-prompt.md` | `init-labels.sh` の呼び出しセクションを追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 移動フローの定義
2. **論理設計**: 削除箇所と追加箇所の特定

### Phase 2: 実装

1. `prompts/package/prompts/setup.md` からセクション5「Issue用基本ラベルの確認」を削除
2. `prompts/setup-prompt.md` にセクション「8.2.6 Issue用基本ラベルの作成」を追加

## 完了条件チェックリスト

- [ ] セットアッププロンプト（setup-prompt.md）へのラベル作成処理追加
- [ ] サイクルセットアップ（setup.md）からのラベル作成処理削除
- [ ] 冪等性の確保 → スクリプト側で対応済み
- [ ] GitHub CLI利用可否の確認 → スクリプト側で対応済み
