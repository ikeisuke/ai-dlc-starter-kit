# Unit 001 計画: lib/ディレクトリrsync同期追加

## 概要

aidlc-setup.shのSYNC_DIRS配列に"lib"を追加し、`prompts/package/lib/`ディレクトリ（validate.sh等）がセットアップ時に`docs/aidlc/lib/`へ自動同期されるようにする。

**注記**: `docs/aidlc/`は`prompts/package/`の一方向rsyncコピーであり、直接編集は禁止（`rules.md`参照）。lib/も同じルールに従う。

## 変更対象ファイル

- `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` - SYNC_DIRS配列に"lib"を追加

## 実装計画

1. `aidlc-setup.sh`のSYNC_DIRS配列定義ブロックに `"lib"` を追加
2. 既存の同期ループはソースディレクトリ不在時にスキップする仕組みを持っているため、ループ側の変更は不要

## 完了条件チェックリスト

- [ ] aidlc-setup.shのSYNC_DIRS配列にlibを追加
- [ ] 同期の動作確認
