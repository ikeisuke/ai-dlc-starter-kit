# Unit 001: セットアップスクリプトのシェル互換性修正 - 計画

## 概要

macOS/zsh で動作しない `grep -oP` を、POSIX互換の `grep -E + sed` に置き換える。

## 対象ファイル

| ファイル | 行番号 | 現在のコード |
|----------|--------|--------------|
| `prompts/setup-prompt.md` | 56 | `grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml` |
| `prompts/package/prompts/setup.md` | 73 | `grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml` |

## 修正内容

### 修正前
```bash
grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml
```

### 修正後
```bash
grep -E 'starter_kit_version\s*=\s*"[^"]+"' docs/aidlc.toml | sed 's/.*"\([^"]*\)".*/\1/'
```

### 技術的説明
- `grep -oP` は Perl互換正規表現（PCRE）を使用し、macOS の BSD grep ではサポートされていない
- `grep -E` は拡張正規表現で、macOS/Linux 両方でサポート
- `sed 's/.*"\([^"]*\)".*/\1/'` でダブルクォート内の値を抽出

## 作業ステップ

### Phase 1: 設計（本Unitはシンプルなため設計ドキュメント作成をスキップ）

このUnitは小規模な文字列置換のみのため、詳細な設計ドキュメントは不要と判断。

### Phase 2: 実装

1. `prompts/setup-prompt.md` の修正（行56）
2. `prompts/package/prompts/setup.md` の修正（行73）
3. 動作確認（bash/zsh 両環境でテスト）
4. 履歴記録
5. Gitコミット

## 完了基準

- [x] 修正後のコマンドが macOS (zsh) で動作する
- [x] 修正後のコマンドが Linux (bash) で動作する
- [x] 元の機能（バージョン抽出）が維持される

## 見積もり

小規模（2ファイル、各1行の修正）
