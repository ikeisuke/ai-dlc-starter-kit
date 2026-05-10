# レビューサマリ: Unit 002 migrate-backlog.sh UTF-8 多バイト境界分断バグ修正

## 基本情報

- **サイクル**: v2.6.0
- **フェーズ**: Construction
- **対象**: Unit 002 migrate-backlog.sh UTF-8 多バイト境界分断バグ修正

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-05-09 19:50:00

- **レビュー種別**: 計画承認前
- **使用ツール**: codex
- **反復回数**: 6
- **結論**: 指摘対応判断完了（Round 1: 中3件 → 全件修正 / Round 2: 中1件 + 低1件 → 全件修正 / Round 3: clean / Round 4 方針再策定: 中1件 + 低1件 → 全件修正 / Round 5: 中1件 + 低1件 → 全件修正 / Round 6: 0 件で `last_round_clean` 完了）

### 主要な経緯

Round 3 clean 後の実装着手・ローカル動作確認で **macOS BSD awk が `LC_ALL=C.UTF-8` でも `length()` をバイト数を返す** ことが判明。GNU awk との挙動分裂で NFR 正確性・可搬性が満たせず、Round 4 で `perl -CSD -Mutf8` 実装に方針再策定。Round 6 で全指摘解消。

### 指摘一覧（Round 4 以降の主要分）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R4-1 | 中 | `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md` - `_detect_utf8_locale` 参照が削除方針なのに残存（perl 実装で不要） | 修正済み（plans/unit-002-plan.md: 方針再策定ログ以外から `_detect_utf8_locale` 言及を全削除） | - |
| R4-2 | 低 | `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md` - bats ケース説明に旧実装由来 (`awk` 言及) が残存 | 修正済み（plans/unit-002-plan.md: ケース (f)(g) パイプ表記を `tr → perl → tr → sed → sed → perl` に更新） | - |
| R5-1 | 中 | `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md` - `_detect_utf8_locale` 参照がスコープ境界表 / 変更対象ファイル / Phase 2 手順に残存 | 修正済み（plans/unit-002-plan.md: 該当箇所から `_detect_utf8_locale` 言及を全削除、残存は方針再策定ログ節のみ） | - |
| R5-2 | 低 | `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md` - bats (a) サンプル入力が「51 文字超」説明と矛盾（フィルタ後 44 文字） | 修正済み（plans/unit-002-plan.md: bats テスト構造例の (a) を `<実装時に確定: フィルタ通過後 51 文字以上の日本語入力>` プレースホルダに変更） | - |

---

## Set 2: 2026-05-09 19:55:00

- **レビュー種別**: コード生成後
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（Round 1: 低1件 → 修正 / Round 2: 低1件 → 修正 / Round 3: 0 件で `last_round_clean` 完了）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R1-1 | 低 | `tests/aidlc-setup/migrate-backlog-slug.bats` - ヘッダコメントが「7 ケース構成」のまま、実テスト数 9 と不一致 | 修正済み（migrate-backlog-slug.bats L4-13: 「9 ケース構成（計画 7 ケース + 境界補強 (h)(i)）」に更新） | - |
| R2-1 | 低 | `skills/aidlc-setup/scripts/migrate-backlog.sh` L190 - `((error_count++))` が他箇所と不一致、`set -e` 安全性問題 | 修正済み（migrate-backlog.sh L190: `(( ++error_count ))` に統一） | - |

### Cross-platform-review 結果

- 使用スキル: `tools:cross-platform-review`
- 観点: BSD/GNU awk / perl `-CSD -Mutf8` 互換性 / `BASH_SOURCE[0]` ガード / ブレース展開 / `iconv` / シェバン
- **結論**: 互換性問題は検出されませんでした

### セキュリティ観点

- ローカル CLI スクリプト・ネットワーク非使用のため OWASP/認証/通信リスクは N/A 判定（codex 確認済み）

---

## Set 3: 2026-05-09 20:00:00

- **レビュー種別**: 統合とレビュー
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（Round 1: 中1件 + 低1件 → 全件修正 / Round 2: 0 件で `last_round_clean` 完了）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R1-1 | 中 | `.aidlc/cycles/v2.6.0/story-artifacts/units/002-fix-migrate-backlog-utf8-cut.md` - Unit 定義が方針再策定後の perl 実装と不整合・実装状態「未着手」のまま | 修正済み（002-fix-migrate-backlog-utf8-cut.md: 概要・責務・実装状態を perl 実装と完了状態に更新） | - |
| R1-2 | 低 | `.aidlc/cycles/v2.6.0/plans/unit-002-plan.md` 完了条件チェックボックス未反映、履歴/レビューサマリ未作成 | 修正済み（plans/unit-002-plan.md: 完了条件チェック更新、本レビューサマリ + history/construction_unit02.md 作成） | - |
