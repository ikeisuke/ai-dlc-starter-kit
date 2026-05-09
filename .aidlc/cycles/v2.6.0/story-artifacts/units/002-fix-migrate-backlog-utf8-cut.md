# Unit: migrate-backlog.sh UTF-8 多バイト境界分断バグ修正

## 概要

`skills/aidlc-setup/scripts/migrate-backlog.sh` line 79 の `cut -c1-50` を `LC_ALL=C.UTF-8 awk substr` 実装に置換し、日本語タイトルを含む Issue 移行時の slug 末尾文字化けを解消する。

## 含まれるユーザーストーリー

- ストーリー 5: migrate-backlog.sh の UTF-8 多バイト境界分断バグ修正

## 責務

- `migrate-backlog.sh` line 79 の文字数切り詰め処理を UTF-8 安全な実装に置換
- `LC_ALL=C.UTF-8` の明示固定により呼び出し側ロケール非依存化
- 新規テスト `test_migrate_backlog_slug.sh` の追加（日本語混在 / `LC_ALL=C` / ASCII 純の 3 ケース）
- 既存テストの回帰確認

## 境界

- `migrate-backlog.sh` の他の処理（タイトル抽出 / Issue 番号取得 / 出力フォーマット）は対象外
- 他のスクリプトでの同様の `cut -c` 利用調査・修正は対象外（Issue 内容に従い line 79 のみ）
- `awk` 不在環境でのフォールバックは設けない（明示エラーで exit）

## 依存関係

### 依存する Unit

- なし（独立して実装可能）

### 外部依存

- `awk`（POSIX 標準、macOS / Linux で利用可能）
- `LC_ALL=C.UTF-8` ロケール（macOS / Linux で利用可能）

## 非機能要件（NFR）

- **正確性**: UTF-8 コードポイント単位で正確に 50 文字を保持
- **互換性**: 純 ASCII タイトル時は従来動作と完全一致
- **可搬性**: macOS（BSD awk）/ Linux（GNU awk）双方で動作

## 技術的考慮事項

- 採用実装:

  ```bash
  LC_ALL=C.UTF-8 awk '{ s=$0; if (length(s) > 50) s=substr(s, 1, 50); print s }'
  ```

- BSD awk と GNU awk での `length()` / `substr()` の動作差を Construction Phase で検証
- テスト用日本語入力例: `これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ`（51 文字超）
- `cross-platform-review` スキルでの portability 確認を推奨

## 関連Issue

- #615

## 実装優先度

High（バグ修正・priority:high）

## 見積もり

30〜45 分（修正 15 分 + テスト追加 15 分 + cross-platform-review 10 分）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
