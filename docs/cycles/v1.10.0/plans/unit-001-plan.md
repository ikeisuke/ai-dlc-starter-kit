# Unit 001: version.txt参照問題修正 - 計画

## 概要

`prompts/version.txt` が存在しないのに参照されているというエラーを解消する。

## 調査結果

### 問題の原因

`prompts/setup-prompt.md` の128行目に以下の記述がある:

> このファイル（setup-prompt.md）のディレクトリから `../version.txt` を読み込み

この「`../version.txt`」という相対パス表記がAIに誤解され、`prompts/version.txt` を読もうとしてエラーになっている。

### 実態

- `version.txt` はプロジェクトルートに存在し、正常に動作している（内容: `1.9.3`）
- `prompts/setup/bin/check-version.sh` はパスを正しく計算しており問題なし
- 問題はプロンプトのテキスト説明の曖昧さのみ

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-prompt.md` | 128行目の相対パス表記を明確化 |

## 実装計画

### Phase 1: 設計

1. 修正内容の確定
   - 「`../version.txt`」→「プロジェクトルートの `version.txt`（リポジトリルート直下）」に変更

### Phase 2: 実装

1. `prompts/setup-prompt.md` の128行目を修正
2. 動作確認（`check-version.sh` の実行）

## 完了条件チェックリスト

- [ ] `prompts/version.txt` を参照している箇所の特定（完了: setup-prompt.md 128行目）
- [ ] 参照箇所の修正（相対パス表記を明確化）
- [ ] 修正後の動作確認（check-version.sh が正常動作すること）
