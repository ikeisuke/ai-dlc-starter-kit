# 論理設計: メタ開発ドキュメント整理

## 概要

開発者向けファイルを `prompts/package/` から分離し、ユーザー配布対象から除外する。

## 対象ファイルと対応

### 削除（PoC検証用ファイル）

| 削除対象 |
|---------|
| `prompts/package/prompts/common/poc-test-level1.md` |
| `prompts/package/prompts/common/poc-test-level2.md` |
| `prompts/package/prompts/common/poc-test-level3.md` |
| `docs/aidlc/prompts/common/poc-test-level1.md` |
| `docs/aidlc/prompts/common/poc-test-level2.md` |
| `docs/aidlc/prompts/common/poc-test-level3.md` |

### 移動（開発者向けツール・ガイド）

| 移動元 | 移動先 |
|-------|-------|
| `prompts/package/bin/sync-prompts.sh` | `prompts/dev/bin/sync-prompts.sh` |
| `prompts/package/bin/check-references.sh` | `prompts/dev/bin/check-references.sh` |
| `prompts/package/guides/reference-guide.md` | `prompts/dev/guides/reference-guide.md` |
| `prompts/package/guides/deprecation.md` | `prompts/dev/guides/deprecation.md` |

対応する `docs/aidlc/` 側のファイルも削除。

## 分離理由

- **PoC検証用ファイル**: 検証完了済みで不要
- **sync-prompts.sh**: 開発リポジトリ専用の同期スクリプト
- **check-references.sh**: プロンプト作者向け品質チェック
- **reference-guide.md**: プロンプト作成者向けガイド
- **deprecation.md**: スターターキットの非推奨機能一覧（メンテ用）

## 参照の更新

`deprecation.md` への参照（construction.md, setup.md）を GitHub URL に変更：
- `https://github.com/ikeisuke/ai-dlc-starter-kit/blob/main/prompts/dev/guides/deprecation.md`

## rsync同期への影響

`prompts/package/` から削除/移動したファイルは rsync 同期対象外となる。
`prompts/dev/` は rsync 同期対象外のため、ユーザープロジェクトには配布されない。
