# Unit 002 実装記録 - 名前付きサイクルスクリプト対応

## 概要

5つのシェルスクリプトを名前付きサイクル（`[name]/vX.Y.Z`）に対応させた。

## 変更ファイル一覧

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/bin/setup-branch.sh` | バージョン正規表現拡張、worktreeパス正規化、`..`チェック追加 |
| `prompts/package/bin/aidlc-cycle-info.sh` | `extract_version()`正規表現拡張、`cycle_name`/`cycle_version`出力追加 |
| `prompts/package/bin/post-merge-cleanup.sh` | バリデーション正規表現拡張、`..`チェック追加 |
| `prompts/package/bin/init-cycle-dir.sh` | スラッシュ検証を3段階ガードに変更（`..`/2レベル以上/先頭末尾） |
| `prompts/package/bin/suggest-version.sh` | ブランチパース拡張、TAB区切り戻り値、ディレクトリスキャン拡張 |

## 主要な技術判断

### TABセパレータ採用

`suggest-version.sh`の`get_branch_version()`は、バージョンとサイクル名の2値を返す必要がある。Bash関数は戻り値が1つのため、セパレータ付き文字列で返す方式を採用。

- `|`（パイプ）: git refで許容されるため不適切
- `\t`（TAB）: git refで禁止（`git check-ref-format`）のため安全

### バリデーション責務の分離

- **スクリプト側**: 構造的検証のみ（`[^/]+/vX.Y.Z`、パストラバーサル防止）
- **プロンプト側**: 文字種制限（`[a-z0-9][a-z0-9-]*`）はUnit 003で実装

### prerelease互換性

`setup-branch.sh`/`post-merge-cleanup.sh`はprerelease（`-xxx`）を許容するが、`aidlc-cycle-info.sh`/`suggest-version.sh`は非対応。既存の挙動を維持（スコープ外）。

## テスト結果

### 手動テスト

- `suggest-version.sh`: 名前付きブランチ（`cycle/waf/v1.0.0`相当）でのバージョン推測確認
- `aidlc-cycle-info.sh`: 名前付きサイクルの`cycle_name`/`cycle_version`出力確認
- `setup-branch.sh`: `waf/v1.0.0` worktreeモードでのパス正規化確認
- `init-cycle-dir.sh`: `waf/v1.0.0`形式でのディレクトリ作成確認
- `post-merge-cleanup.sh`: パストラバーサル拒否確認

## レビュー結果

- コードレビュー: 高1・中1・低1 → 全修正
- セキュリティレビュー: 低2 → 全修正
- 再レビュー4回 → 最終指摘0件

詳細は `002-review-summary.md` を参照。
