# 実装記録: バックログ管理改善

## 概要

バックログ管理機能を改善し、排他モード（git-only/issue-only）とガイドの集約を行った。

## 実装内容

### 1. backlog-management.md ガイド作成

`prompts/package/guides/backlog-management.md` を新規作成し、以下を集約:
- mode一覧（git/issue/git-only/issue-only）
- 排他モードの説明
- Git駆動 vs Issue駆動の比較
- 新規バックログ作成フロー
- フェーズ固有のアクション

### 2. AGENTS.md にバックログ管理セクション追加

`prompts/package/prompts/AGENTS.md` にバックログ管理方針を追加:
- mode一覧表
- 排他モードの説明

### 3. setup-prompt.md のmodeオプション拡張

`prompts/setup-prompt.md` のaidlc.tomlテンプレートを更新:
- git-only/issue-only オプションを追加
- 各modeの説明を更新

### 4. 各フェーズプロンプトの排他モード対応

以下のプロンプトに排他モード対応を追加:
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

変更内容:
- mode=git → mode=git または mode=git-only
- mode=issue → mode=issue または mode=issue-only
- 「両方確認」→ 非排他モードのみ
- ガイドへの参照を追加

### 5. issue-driven-backlog.md の削除

`prompts/package/guides/issue-driven-backlog.md` を削除し、`backlog-management.md` に統合。

## 設計変更

当初の設計（single_sourceオプション追加）から、modeに排他値を追加する設計に変更:
- 理由: `git-only` / `issue-only` の方が意図が明確
- 効果: 設定が1つで済み、理解しやすい

## テスト結果

- Markdownlint: パス（0 errors）
- AIレビュー: パス（指摘なし）

## 完了日

2026-01-13
