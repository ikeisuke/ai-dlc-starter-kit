# Unit 001 計画: サイクル一覧の不要項目除外

## 概要

setup.md のサイクル一覧取得時に、バージョンディレクトリ以外の項目（backlog/, rules.md等）を除外する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `docs/aidlc/prompts/setup.md` | L235: サイクル一覧取得コマンドの修正 |

## 実装計画

### Phase 1: 設計（スキップ可能）

この変更は単純なコマンド修正のため、ドメインモデル設計・論理設計は不要。

### Phase 2: 実装

1. `docs/aidlc/prompts/setup.md` の L235 を修正
   - 変更前: `ls -d docs/cycles/* 2>/dev/null | sort -V`
   - 変更後: `ls -d docs/cycles/*/ 2>/dev/null | grep -vE '(backlog|backlog-completed)' | sort -V`

2. 動作確認
   - 修正後のコマンドでバージョンディレクトリのみが表示されることを確認

## 完了条件チェックリスト

- [x] setup.md のサイクル一覧取得コマンドを修正
- [x] backlog/backlog-completed を除外するgrepパターンを追加
- [x] 変更後のコマンドが正しく動作することを確認
