# Unit: update-version.sh の挙動変更（starter_kit_version 上書き廃止）

## 概要

`bin/update-version.sh` がリリース時に `.aidlc/config.toml.starter_kit_version` を上書きする v1 流儀の挙動を廃止する。更新対象を `version.txt` と `skills/*/version.txt` のみに限定し、出力フォーマットから `aidlc_toml_*` 行を削除する。これによりメタ開発時のバージョン三角検証（local / skill / remote）が正しく機能するようになる。本 Unit はスクリプト本体の挙動変更のみを担当し、ドキュメント・周知側は Unit 003 で扱う。

## 含まれるユーザーストーリー

- ストーリー 6a: update-version.sh のスクリプト挙動変更（#596 実装側）

## 責務

- `bin/update-version.sh` の更新対象から `.aidlc/config.toml` 書き込みを削除（`version.txt` と `skills/*/version.txt` のみ更新）
- dry-run 出力から `aidlc_toml_current` / `aidlc_toml_new` 行を削除
- 成功出力から `aidlc_toml:${VERSION}` 行を削除
- `.aidlc/config.toml` 関連のテンポラリファイル / バックアップ / ロールバック処理を削除
- `.aidlc/config.toml` の存在チェック（`config-toml-not-found` エラー）は残置（リポジトリ整合性検証目的、入力読み取りのみ）
- メタ開発リポジトリで `bin/update-version.sh --version v9.9.9 --dry-run` 実行時に `aidlc_toml_*` 行が含まれないことを目視確認
- 既存テスト（`scripts/tests/` または `bin/tests/` 配下にあれば）の期待出力フォーマット追従、なければ最小限の新規テスト追加判断

## 境界

- ドキュメント側（CHANGELOG / README / rules.md / docs/configuration.md）への変更は Unit 003 で扱う
- `aidlc-setup` / `aidlc-migrate` 側の `starter_kit_version` 書き込み経路の変更は本サイクル対象外（既存挙動維持）
- バージョン番号フォーマット（semver）の変更は本 Unit 対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `dasel`（v3+、TOML パーサ。既存利用継続）
- bash 3.2+（既存スクリプト前提）
- mktemp / mv（同一 FS 上のアトミック更新前提、既存処理踏襲）

## 非機能要件（NFR）

- **パフォーマンス**: スクリプト実行時間は変更前と同等以下（`.aidlc/config.toml` 書き込み処理が削除される分、わずかに高速化される可能性）
- **セキュリティ**: ファイルパーミッション・所有権の変更なし、バックアップ削除タイミングは既存通り
- **スケーラビリティ**: 単一マシンでの単発実行が前提、変更なし
- **可用性**: メタ開発リポジトリの dry-run 試験で 100% 成功すること

## 技術的考慮事項

- ロールバック処理（`_rollback`）から `.aidlc/config.toml` のバックアップ・復元行を削除する際、他のロールバック対象（`version.txt` / `skills/*/version.txt`）への影響がないことを確認する
- `_bak_toml` / `_tmp_toml` 等の変数名と trap での参照箇所を一括で削除する（残骸が残ると新たなバグの温床になる）
- 既存テスト不在の場合、bash assertion テスト（`bin/tests/test_update_version_dry_run.sh` 相当）を最小限追加し、`grep -E '^aidlc_toml_' <output>` が 0 行を返すことを assert する
- `set -euo pipefail` は維持

## 関連Issue

- #596（部分対応：本 Unit はスクリプト挙動変更のみ。ドキュメント・周知は Unit 003）

## 実装優先度

High（メタ開発時のバージョン三角検証が機能するための前提）

## 見積もり

1〜2 時間（スクリプト修正 + dry-run 確認 + 最小テスト追加）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-23
- **完了日**: 2026-04-23
- **担当**: AI（Claude / codex 協調）
- **エクスプレス適格性**: eligible
- **適格性理由**: bash スクリプト局所修正 + 6 ケース 31 アサーション自動テスト、bash 3.2 / 5.x 両対応確認済み、Unit 003 との境界遵守、メタ開発シナリオ手動検証済み
