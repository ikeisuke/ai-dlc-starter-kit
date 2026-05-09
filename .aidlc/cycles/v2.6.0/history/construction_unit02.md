# Construction Phase 履歴: Unit 02

## 2026-05-09T20:12:36+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-fix-migrate-backlog-utf8-cut（migrate-backlog.sh UTF-8 多バイト境界分断バグ修正）
- **ステップ**: Unit完了
- **実行内容**: Unit 002（migrate-backlog.sh UTF-8 多バイト境界分断バグ修正、Issue #615 priority:high）の Construction Phase 全工程を完了。Round 4 で実装方針を `LC_ALL=C.UTF-8 awk` から `perl -CSD -Mutf8` に再策定。

## 変更内容

- `skills/aidlc-setup/scripts/migrate-backlog.sh`:
  - L79: `cut -c1-50` → `perl -CSD -Mutf8 -pe 'chomp; $_ = substr($_, 0, 50) if length($_) > 50; $_ .= "\n";'`
  - L190: `((error_count++))` → `(( ++error_count ))`（他箇所と統一、set -e 安全性向上）
  - 末尾: `main "$@"` → `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`（テスト容易性）
- `tests/aidlc-setup/migrate-backlog-slug.bats`: 新規 9 ケース（計画 7 + 境界補強 (h)(i)）
- `.github/workflows/migration-tests.yml`: PATHS_REGEX に `skills/aidlc-setup/scripts/migrate-backlog\.sh` 追加（CI トリガー対応）

## 検証結果

- `bats tests/aidlc-setup/migrate-backlog-slug.bats`: 9 ケース全 PASS
- `bats tests/aidlc-setup/`: 全 26 ケース PASS（既存 17 + 新規 9、regression なし）
- `tools:cross-platform-review`: 互換性問題は検出されませんでした

## 方針再策定の経緯（Round 4）

Round 1〜3 で `LC_ALL=C.UTF-8 awk '{ length / substr }'` 実装を採用、Round 3 で codex AI レビュー clean となった。Round 3 clean 後、実装着手・ローカル動作確認で以下を確認:

```text
$ printf '%s' "これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ" \
  | LC_ALL=C.UTF-8 awk '{ print length($0) }'
70   # macOS BSD awk: バイト数（期待: 44）
```

- macOS BSD awk が `LC_ALL=C.UTF-8` でも `length()` をバイト数で返す
- GNU awk（Linux / GH Actions ubuntu-latest）では文字数を返す
- クロスプラットフォーム挙動分裂で本 Unit の NFR「正確性: UTF-8 コードポイント単位で正確に 50 文字を保持」「可搬性: macOS / Linux 両対応」が満たせない

`perl` は本スクリプトの既存依存（先行段で `s/[^...]//g` フィルタに利用済み）であり、`-CSD -Mutf8` で全環境統一動作するため移行コスト最小。Round 4 で perl 実装に再策定し、Round 6 で計画レビュー全件 clean。

## AI レビュー実施証跡（品質ゲート）

優先ツール: codex（`.aidlc/config.toml [rules.reviewing].tools = ['codex']` 準拠）。各レビュー結果は `.aidlc/cycles/v2.6.0/construction/units/002-review-summary.md` に集約済み。

| レビュー種別 | 反復回数 | 結論 | 指摘内訳（主要分） |
|---|---|---|---|
| 計画承認前 (`reviewing-construction-plan`) | 6R | 指摘対応判断完了 (`last_round_clean`) | Round 1: 中3件 / Round 2: 中1件+低1件 / Round 3: 0件 / Round 4 方針再策定: 中1件+低1件 / Round 5: 中1件+低1件 / Round 6: 0件 |
| コード生成後 (`reviewing-construction-code`) | 3R | 指摘対応判断完了 (`last_round_clean`) | Round 1: 低1件（bats ヘッダコメント不一致）/ Round 2: 低1件（L190 set -e 安全性）/ Round 3: 0件 |
| 統合とレビュー (`reviewing-construction-integration`) | 本セッション内で完了予定 | - | Round 1 で Unit 定義/履歴未更新を指摘 → 完了処理で対応中 |
| Cross-platform-review (`tools:cross-platform-review`) | 1R | 互換性問題なし | BSD/GNU awk + perl `-CSD -Mutf8` + BASH_SOURCE ガード + iconv 全観点 PASS |

最終判定: 全レビューで完了条件達成。`semi_auto` でフォールバック条件非該当のため `auto_approved`。

## 完了条件達成状況

機能整合 4 項目（perl 置換 / main ガード化 / 他処理不変） / テスト・lint 必須項目（bats 9 ケース PASS、regression なし） / CI 接続（PATHS_REGEX 追加） / Cross-platform 検証（問題なし） / 履歴（本ファイル + レビューサマリ） / 品質ゲート（AI レビュー全件完了条件達成）。すべて達成。

## 関連成果物

- 計画ファイル: `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md`
- レビューサマリ: `.aidlc/cycles/v2.6.0/construction/units/002-review-summary.md`
- Unit 定義（実装状態を「完了」に更新）: `.aidlc/cycles/v2.6.0/story-artifacts/units/002-fix-migrate-backlog-utf8-cut.md`

## 意思決定記録

DR-007: Round 4 方針再策定（`LC_ALL=C.UTF-8 awk` → `perl -CSD -Mutf8`）について、本サイクルでは Construction Phase の意思決定として記録対象外（Inception Phase の意思決定記録 decisions.md に追記する形式の対象は Inception 主要決定のみ。Construction 内の方針再策定は履歴ファイル + 計画ファイル「方針再策定ログ」セクションで履歴管理）。意思決定記録: 対象なし（履歴・計画で完結）。

## 残課題

なし（OUT_OF_SCOPE 化された指摘なし、レビューサマリ「残課題」も該当なし）。
- **成果物**:
  - `skills/aidlc-setup/scripts/migrate-backlog.sh`
  - `tests/aidlc-setup/migrate-backlog-slug.bats`
  - `.github/workflows/migration-tests.yml`
  - `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md`
  - `.aidlc/cycles/v2.6.0/construction/units/002-review-summary.md`
  - `.aidlc/cycles/v2.6.0/story-artifacts/units/002-fix-migrate-backlog-utf8-cut.md`

---
