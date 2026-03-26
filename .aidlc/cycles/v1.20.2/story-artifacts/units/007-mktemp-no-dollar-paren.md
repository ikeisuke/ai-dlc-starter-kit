# Unit: mktempでの$()使用禁止の徹底

## 概要

テンポラリファイル規約とsetup-prompt.mdにおけるmktemp使用箇所から`$()`を排除し、一貫した手順に統一する。

## 含まれるユーザーストーリー

- ストーリー 7: mktempでの$()使用禁止の徹底

## 責務

- `prompts/setup-prompt.md` の `TEMP_FILE=$(mktemp)` パターン（3件）を`$()`を使わない方式に修正
- `prompts/package/prompts/common/rules.md` のテンポラリファイル規約にmktemp実行時の`$()`禁止を明記
- 手順説明の統一（Bashツールで単独実行→パス取得→Writeツール→使用→削除）

## 境界

- `.sh` スクリプト内の `$(mktemp)` は既存例外ルールにより対象外
- ガイドドキュメントの修正（Unit 001〜005）は対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- 該当なし（ドキュメント修正のみ）

## 技術的考慮事項

- 編集対象: `prompts/setup-prompt.md`（3件）、`prompts/package/prompts/common/rules.md`
- setup-prompt.mdの該当箇所はbashコードブロック内のため、AIが実行時に解釈するコンテキスト

## 実装優先度

Medium

## 見積もり

小規模（2ファイルの修正のみ）

## 完了条件

- `prompts/setup-prompt.md` 内に `$(mktemp)` パターンが0件
- `prompts/package/prompts/common/rules.md` のテンポラリファイル規約にmktemp時の`$()`禁止が明記されている
- 手順説明が「Bashツールでmktempを単独実行→パス取得」の流れで統一されている

## 関連Issue

なし

---

## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-12
- **完了日**: 2026-03-12
- **担当**: -
