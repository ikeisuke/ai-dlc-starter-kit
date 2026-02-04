# Unit 001 計画: env-info.shバグ修正

## 概要

`env-info.sh --setup` 実行時に `starter_kit_version` と `current_branch` が空になる問題を修正する。

## 問題分析

### current_branch が空になる原因

- jj co-location モードでは、git は **detached HEAD** 状態になる
- `git branch --show-current` は detached HEAD 状態で空を返す
- jj 側では `cycle/v1.12.1` 等の bookmark が正しく設定されている

### starter_kit_version が空になる原因

- 現行コードは `version.txt` から取得しているが、受け入れ条件では「docs/aidlc.toml から取得」が求められている
- `docs/aidlc.toml` にはトップレベルに `starter_kit_version = "1.12.0"` が定義されている
- dasel 未インストール環境ではフォールバックが必要

## 変更対象ファイル

- `prompts/package/bin/env-info.sh`

## 実装計画

### 1. starter_kit_version の取得ロジック変更

`version.txt` ではなく `docs/aidlc.toml` から取得するように変更:

1. **dasel が利用可能な場合**: `dasel -f docs/aidlc.toml 'starter_kit_version'` で取得
2. **dasel 未インストールの場合**: grep + sed でフォールバック取得
   - 書式: `starter_kit_version = "X.Y.Z"` の先頭一致行から抽出
   - 最初の定義のみ採用（複数定義は無視）
   - 引用符（ダブルクォート/シングルクォート）を除去
   - コメント行（`#` で始まる）は無視
3. **ファイル不存在の場合**: 空値を返す

### 2. current_branch の取得ロジック修正

jj/git 環境を考慮した優先順位で取得:

1. **jj が利用可能な場合**: `jj log -r @ --no-graph -T 'bookmarks'` でカレントリビジョンの bookmark を取得
   - **複数bookmark時の選定ルール**: `cycle/` で始まるものを優先、なければ最初のものを採用
   - **出力の正規化**: 空白で分割してリスト化 → 選定ルールで1つを選択（空白除去で結合しない）
   - 空文字または空リストの場合は次のフォールバックへ
2. **git branch --show-current** で取得（jj未使用環境向け）
3. **detached HEAD の場合のフォールバック**: `git rev-parse --abbrev-ref HEAD` で再試行し、結果が `HEAD` の場合は空値として扱う
4. **すべて失敗した場合**: 空値を返す（`unknown` やエラー終了はしない）

### 用語の定義

- **current_branch**: 現在のブランチ名またはbookmark名を返す。タグ名は返さない。
- **失敗時の振る舞い**: 空値を返す（エラー終了しない）

## AIレビュー指摘対応

| 指摘 | 重要度 | 対応 |
|------|--------|------|
| 複数bookmark時の選定ルール未定義 | High | `cycle/` prefix 優先ルールを追加 |
| jj出力の正規化ルール未設計 | High | 空白で分割→選定→1つを返す（結合しない） |
| grep+sedで書式の揺れ未対応 | Medium | 先頭一致、最初の定義、引用符除去を明記 |
| git describeはタグ名を返す | Medium | タグ系削除、rev-parse --abbrev-ref + HEAD判定へ変更 |
| 失敗時の振る舞い未定義 | Low | 空値を返すことを明記 |

## 完了条件チェックリスト

- [ ] starter_kit_version が docs/aidlc.toml から正しく取得される
- [ ] current_branch が jj/git 環境で正しく取得される
- [ ] dasel 未インストール環境でもフォールバックが動作する
