# Unit: migrate-backlog.sh UTF-8 多バイト境界分断バグ修正

## 概要

`skills/aidlc-setup/scripts/migrate-backlog.sh` line 79 の `cut -c1-50` を `perl -CSD -Mutf8 -pe 'chomp; $_ = substr($_, 0, 50) if length($_) > 50; $_ .= "\n";'` 実装に置換し、日本語タイトルを含む Issue 移行時の slug 末尾文字化けを解消する。

> **方針再策定（Construction Phase Round 4）**: 当初は `LC_ALL=C.UTF-8 awk substr` 実装を採用予定だったが、ローカル動作確認で macOS BSD awk が `LC_ALL=C.UTF-8` でも `length()` をバイト数で返すことが判明（GNU awk と挙動分裂）。`perl` は本スクリプトの既存依存であり追加コストなしで全環境統一動作するため、`perl -CSD -Mutf8` に方針を再策定した。詳細は計画ファイル `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md` の「方針再策定ログ（Round 4）」を参照。

## 含まれるユーザーストーリー

- ストーリー 5: migrate-backlog.sh の UTF-8 多バイト境界分断バグ修正

## 責務

- `migrate-backlog.sh` line 79 の文字数切り詰め処理を UTF-8 安全な実装（`perl -CSD -Mutf8`）に置換
- 呼び出し側ロケール非依存化（`perl -CSD -Mutf8` がロケール非依存に UTF-8 として動作）
- 新規 bats テスト `tests/aidlc-setup/migrate-backlog-slug.bats` の追加（9 ケース: 計画 7 ケース + 境界補強 (h)(i)）
- 既存テストの回帰確認
- `.github/workflows/migration-tests.yml` の `PATHS_REGEX` に migrate-backlog.sh を追加し CI トリガー対応
- `migrate-backlog.sh` 末尾 `main "$@"` のガード化（テスト容易性のための最小拡張）

## 境界

- `migrate-backlog.sh` の他の処理（タイトル抽出 / Issue 番号取得 / 出力フォーマット）は対象外
- 他のスクリプトでの同様の `cut -c` 利用調査・修正は対象外（Issue 内容に従い line 79 のみ）
- `perl` 不在環境でのフォールバックは設けない（既存の `command -v perl` チェックで明示エラー exit）

## 依存関係

### 依存する Unit

- なし（独立して実装可能）

### 外部依存

- `perl` 5.18+（既存依存。先行段で `s/[^...]//g` フィルタに利用済み）
- `perl` モジュール `utf8`（標準）と `-CSD` フラグ（標準入出力の UTF-8 化、perl 5.8+ で標準）

## 非機能要件（NFR）

- **正確性**: UTF-8 コードポイント単位で正確に 50 文字を保持（perl `-CSD -Mutf8` の `length` / `substr` がコードポイント単位で動作）
- **互換性**: 純 ASCII タイトル時は従来動作と完全一致
- **可搬性**: macOS（system perl）/ Linux（perl 5.x）双方で動作（perl `-CSD -Mutf8` はロケール非依存に UTF-8 として動作）

## 技術的考慮事項

- 採用実装（Round 4 で再策定）:

  ```bash
  perl -CSD -Mutf8 -pe 'chomp; $_ = substr($_, 0, 50) if length($_) > 50; $_ .= "\n";'
  ```

- 当初は `LC_ALL=C.UTF-8 awk substr` を採用予定だったが、ローカル動作確認で macOS BSD awk が `LC_ALL=C.UTF-8` でも `length()` をバイト数を返すことが判明（GNU awk と挙動分裂）。`perl -CSD -Mutf8` に方針再策定（詳細は計画ファイルの「方針再策定ログ（Round 4）」参照）
- bats テスト入力例（フィルタ通過後 51 文字以上）: `printf 'あ%.0s' {1..51}`
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

- **状態**: 完了
- **開始日**: 2026-05-09
- **完了日**: 2026-05-09
- **担当**: AI-DLC (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
