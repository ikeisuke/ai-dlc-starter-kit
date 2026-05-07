# レビューサマリ: Unit 004 predecessor-issue.sh の retrospective-issue.sh 横依存解消

## 基本情報

- **サイクル**: v2.5.3
- **フェーズ**: Construction
- **対象**: Unit 004 predecessor-issue.sh の retrospective-issue.sh 横依存解消（#643）

---

## Set 1: 2026-05-07 / 設計レビュー

- **レビュー種別**: 設計レビュー
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘0件（最後 2 round 連続 clean）

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 中 | verify 呼出保持の検証コマンドが弱い | awk + grep で具体化 |
| 2 | 中 | __retro_diag の扱い未確定 | 案 A（複製）で確定 |
| 3 | 中 | 関数レベル契約テスト不足 | aidlc-helpers-migration.bats で対応 |
| 4 | 中 | bats テスト件数固定（223件）が不整合 | 「全件 pass」に変更 |

合計 4 件 → 全件修正済み

---

## Set 2: 2026-05-07 / コードレビュー

- **レビュー種別**: コードレビュー
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件（Round 1 + Round 2 連続 clean）

合計 0 件

---

## Set 3: 2026-05-07 / 統合レビュー

- **レビュー種別**: 統合レビュー
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘0件（最後 2 round 連続 clean）

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 中 | __retro_validate_cycle 異常系戻り値が設計/計画では 1、実装は 2 で不整合 | 設計/計画を実装と整合（exit 2） |
| 2 | 中 | 完了条件チェックリスト未更新 | 全項目 [x] 化 |
| 3 | 中 | logical_design L17 の残存「0/1」記述 | 「0/2」に修正 |

合計 3 件 → 全件修正済み

## 全レビュー Set サマリ

| Set | 種別 | Round | 指摘 | 結論 |
|-----|------|-------|------|------|
| 1 | 設計レビュー | 5 | 4件 | clean / auto_approved |
| 2 | コードレビュー | 2 | 0件 | clean / auto_approved |
| 3 | 統合レビュー | 4 | 3件 | clean / auto_approved |

合計指摘 7 件、全件修正対応。defer 0 件。

## Unit 001 不変条件保持の検証結果

- **AC-U004-RETRO-GUARD-IMMUTABLE-1**: `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` 関数定義 + `retrospective_issue_create` 内 verify 呼出すべて保持確認
- **AC-U004-RETRO-GUARD-IMMUTABLE-2**: 新 helper 群（aidlc-validate.sh / aidlc-gh.sh / aidlc-spool.sh）に Unit 001 関数なし（grep で 0 件）

## ストーリー 4 受け入れ基準達成状況

| 受け入れ基準 | 結果 |
|------------|------|
| (a) `predecessor-issue.sh` から `retrospective-issue.sh` への直接 source 撤去 | 達成 |
| (b) 3 関数の独立 helper への移管 | 達成（aidlc-validate.sh / aidlc-gh.sh / aidlc-spool.sh） |
| (c) 相互 source 禁止 | 達成（grep 検証 0 件） |
| (d) CLI 引数互換 | 達成（既存 BATS pass） |
| (e) exit code 互換 | 達成 |
| (f) stderr 文言互換 | 達成 |
| (g) 関数レベル契約テスト | 達成（aidlc-helpers-migration.bats 14 件 pass） |
