# Construction Phase 履歴: Unit 03

## 2026-04-28T11:00:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: 計画作成
- **実行内容**: Unit 003 (migrate-backlog-utf8-fix / Issue #610) の実装計画ファイルを作成。プリフライト全項目クリア（depth_level=standard / automation_mode=semi_auto / review_mode=required / review_tools=['codex'] / squash_enabled=true / unit_branch_enabled=false / merge_method=merge）。Issue 本文の修正案（`perl -CSD -Mutf8 -pe ...`）を採用し、3 ケース動作確認（fullwidth カッコ / SQLite vnode / AgencyConfig DDD）+ `--dry-run` 同等動作確認をスコープに含めた。検証-A/B 判定トリガーを設定（bats インフラ有無で確定）。Issue ステータスを in-progress に更新済み。
- **成果物**:
  - `.aidlc/cycles/v2.4.3/plans/unit-003-plan.md`

---
## 2026-04-28T11:08:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: 計画AIレビュー完了
- **実行内容**: 計画承認前 AIレビューを実施。Codex usage limit（4/29 7:56 AM 復旧予定）のため review-routing.md §6 `cli_runtime_error → retry_1_then_user_choice` に従いユーザー選択でセルフレビュー（サブエージェント方式）を採用（Unit 001/002 と同じフォールバック方針）。反復1: 5件指摘（中2/低3）→ 全件修正（Issue 4ケース目の参考併記＋除外理由明示 / 検証-A/B 採用条件の客観化（CI連動 grep条件含む3項目）/ 一-龯 範囲の Phase 1 実測委譲 / ロケール非依存化検証ケース追加 / 4タイミング AIレビュー整合）。反復2: 0件指摘で承認可能。シグナル: review_detected=true, resolved=5, unresolved=0, deferred=0 / フォールバック条件（review_not_executed / error / review_issues / incomplete_conditions / decision_required）いずれも非該当 → ゲート判定: `auto_approved` (reason_code: none)
- **成果物**:
  - `.aidlc/cycles/v2.4.3/plans/unit-003-plan.md`（指摘反映済み版）

---
## 2026-04-28T11:18:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: Phase 1（設計）成果物作成
- **実行内容**: ドメインモデル / 論理設計を作成。エンコーディング契約 `(ioLayerEncoding, regexLayerEncoding)` を値オブジェクトとして整理し、修正前 `(utf8, latin1_default)` → 修正後 `(utf8, utf8)` への遷移を不変条件として記述。設計判断 A/B 確定: 検証-A（実行表）採用（DEPRECATED スクリプト対象のため bats 追加は過剰、bats インフラと CI 連動はあるが小規模追加コストよりメンテナンスコスト恒常化リスクを優先）/ defaults.toml 影響なし / `--dry-run` は 1 ケース / `LANG=C` ロケール検証 1 ケース。検証-A 実行表を 6 行（必須3 + 参考1 + dry-run 1 + LANG=C 1）に拡張し Phase 2 実測値を history に追記する方針を確立。
- **成果物**:
  - `.aidlc/cycles/v2.4.3/design-artifacts/domain-models/unit_003_migrate_backlog_utf8_fix_domain_model.md`
  - `.aidlc/cycles/v2.4.3/design-artifacts/logical-designs/unit_003_migrate_backlog_utf8_fix_logical_design.md`

---
## 2026-04-28T11:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: AIレビュー完了（Phase 1 設計レビュー）
- **実行内容**: Phase 1（設計）成果物 AIレビュー完了。Codex usage limit 継続のためサブエージェント方式セルフレビュー継続。反復1: 6件指摘（中2/低4 / 集約不変条件のOR網羅 / 検証-A採用根拠の差異明示 / EncodingContract 4状態網羅表 / dry-run検証スコープ明記 / SlugGenerationService 責務再定義 / ロケール非依存化検証 1ケース解釈強化）→ 全件修正。反復2: 0件指摘で承認可能。設計判断（検証-A 採用 / `--dry-run` 1ケース / `LANG=C` 1ケース / defaults.toml 影響なし / Phase 2 で `一-龯` 範囲実測）すべて確定。シグナル: review_detected=true, resolved=6, unresolved=0, deferred=0 / フォールバック条件非該当 → ゲート判定: `auto_approved` (reason_code: none)
- **成果物**:
  - `.aidlc/cycles/v2.4.3/design-artifacts/domain-models/unit_003_migrate_backlog_utf8_fix_domain_model.md`（指摘反映済み版）
  - `.aidlc/cycles/v2.4.3/design-artifacts/logical-designs/unit_003_migrate_backlog_utf8_fix_logical_design.md`（指摘反映済み版）
  - `.aidlc/cycles/v2.4.3/construction/units/003-review-summary.md`

---
## 2026-04-28T11:42:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: Phase 2（実装）コード生成 + ビルド・テスト実行（検証-A）
- **実行内容**: `skills/aidlc-setup/scripts/migrate-backlog.sh` L75 の Perl invocation を `perl -pe` → `perl -CSD -Mutf8 -pe` に修正（実質 1 行）。検証-A 実行表 6 ケースを実行し以下の結果を記録。

### 検証-A 実行表（実測値）

| # | 入力タイトル | 実測 slug | rc | stderr | 環境 | 評価 |
|---|------------|----------|-----|--------|------|------|
| 1 | `テスト分離の改善（並列テスト対応）` | `テスト分離の改善並列テスト対応` | 0 | (empty) | `LANG=ja_JP.UTF-8` | PASS（fullwidth カッコ除去・後半保持） |
| 2 | `SQLite vnode エラー（DB差し替え時の競合アクセス）` | `sqlite-vnode-エラーdb差し替え時の競合アクセス` | 0 | (empty) | `LANG=ja_JP.UTF-8` | PASS（全角＋半角混在で末尾保持） |
| 3 | `AgencyConfig DDD責務整理` | `agencyconfig-ddd責務整理` | 0 | (empty) | `LANG=ja_JP.UTF-8` | PASS（半角主体＋日本語末尾保持） |
| 4 | `Cloudflare Worker GTFS ダウンロード最適化` | `cloudflare-worker-gtfs-ダウンロード最適化` | 0 | (empty) | `LANG=ja_JP.UTF-8` | PASS（参考、完了条件外） |
| 5 | `テスト分離の改善（並列テスト対応）` | `テスト分離の改善並列テスト対応` | 0 | (empty) | `LANG=ja_JP.UTF-8` + `migrate-backlog.sh` source（`--dry-run` 分岐前のコードパス） | PASS（slug 値ケース1と完全一致） |
| 6 | `テスト分離の改善（並列テスト対応）` | `テスト分離の改善並列テスト対応` | 0 | (empty) | `LANG=C` | PASS（Perl 段階の効果確認のみ、50 バイト以内範囲は同等） |

### Phase 2 で発見された副次問題（OUT_OF_SCOPE）

- **副次発見**: `LANG=C` × Case 2 入力（`SQLite vnode エラー（DB差し替え時の競合アクセス）`、50 バイト超）で `cut -c1-50` 段階の BSD/POSIX 挙動によりバイト単位切り詰めとなり、UTF-8 多バイト境界を分断して末尾文字化け（`sqlite-vnode-エラーdb差し替え時の競合�`）が発生
- **判定**: Issue #610 主旨（Perl invocation の UTF-8 化）は Case 1〜4 で達成済み。`cut` 段階のロケール依存は Intent §「成功基準」#610 / §「含まれるもの」3 に明示されておらず、本 Unit のスコープ外
- **ユーザー確認**: AskUserQuestion で「別 Issue 化＋検証ケース 6 再定義（推奨）」を選択（OUT_OF_SCOPE 化）
- **バックログ登録**: GitHub Issue #615 を作成（labels: `backlog,type:bugfix,priority:medium`、タイトル: `[Backlog] migrate-backlog.sh: cut -c1-50 が LANG=C 等で UTF-8 多バイト境界を分断（slug 末尾文字化け）`）
- **計画/設計の再定義**: 計画ファイル L146（受け入れ基準ロケール非依存化検証）と論理設計 §設計判断記録「ロケール非依存化検証」/ 検証手段表ケース 6 の評価基準を「Perl 段階の効果確認のみ（regex で日本語分断なし・stderr エラーなし・50 バイト以内範囲の slug 本体が期待通り）」に再定義

### スコープ保護確認結果

- Intent §「含まれるもの」#610 は「Perl invocation の UTF-8 化」のみ明示。`cut` 段階のロケール依存は直接記載なし
- 計画ファイル側で追加した検証ケース 6 の評価基準を絞る判断は Intent §「含まれるもの」に抵触しない
- スコープ保護ルール対象（Intent 内要件のスコープ縮小）には該当しないが、ユーザー確認は安全側の判断として実施

- **成果物**:
  - `skills/aidlc-setup/scripts/migrate-backlog.sh`（L75 修正済み）
  - `.aidlc/cycles/v2.4.3/plans/unit-003-plan.md`（Case 6 再定義）
  - `.aidlc/cycles/v2.4.3/design-artifacts/logical-designs/unit_003_migrate_backlog_utf8_fix_logical_design.md`（Case 6 再定義）
  - GitHub Issue #615（バックログ登録）

---
## 2026-04-28T11:50:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: AIレビュー完了（Phase 2 コードレビュー / Set 2）
- **実行内容**: Phase 2（実装）コードレビュー完了。Codex usage limit 継続のためサブエージェント方式セルフレビュー継続。反復1: 0件指摘で承認可能判定（設計→実装の追跡可能性が完全一致、副次発見 Issue #615 は OUT_OF_SCOPE で別 Issue 化済み）。シグナル: review_detected=false, resolved=0, unresolved=0, deferred=0 / フォールバック条件非該当 → ゲート判定: `auto_approved` (reason_code: none)
- **成果物**:
  - `.aidlc/cycles/v2.4.3/construction/units/003-review-summary.md`（Set 2 追記）

---
## 2026-04-28T11:55:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: AIレビュー完了（Phase 2 統合レビュー / Set 3）+ 実装承認
- **実行内容**: Phase 2 完了時の統合レビュー実施。Codex usage limit 継続のためサブエージェント方式セルフレビュー継続。反復1: 0件指摘で承認可能判定（設計→実装→検証の追跡可能性が完全一致、Issue #610 解消、副次発見は Issue #615 で OUT_OF_SCOPE 化、後方互換性問題なし、千日手検出なし）。シグナル: review_detected=false, resolved=0, unresolved=0, deferred=0 / フォールバック条件非該当 → ゲート判定: `auto_approved` (reason_code: none)。Phase 2 実装承認完了、Phase 3（完了処理）へ移行。
- **成果物**:
  - `.aidlc/cycles/v2.4.3/construction/units/003-review-summary.md`（Set 3 追記）

---
## 2026-04-28T12:05:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-backlog-utf8-fix（migrate-backlog-utf8-fix）
- **ステップ**: Unit 完了処理
- **実行内容**: Unit 003 完了処理を実施。完了条件チェック（Unit 定義「責務」4項目 / Issue #610 受け入れ基準5項目 / Construction Phase 共通6項目）すべて達成。残課題集約: Issue #615 を OUT_OF_SCOPE 1件として可視化（review-summary.md Set 2 副次発見記録経由、計画 §リスク・design.md §設計判断記録 / §検証手段表で再定義済み）。設計・実装整合性: ドメインモデル `EncodingContract (utf8, utf8)` 契約 → 論理設計 §実装範囲 → 実装 L75 で完全一致、検証-A 実行表期待値 ←→ history 実測値も完全一致、乖離なし。AIレビュー実施確認: 4 タイミング（計画 / 設計 / コード / 統合）すべて履歴記録済み。意思決定記録: DR-008 として「Unit 003 副次発見の OUT_OF_SCOPE 化（cut -c1-50 ロケール依存）」を `inception/decisions.md` に追記（連番継続、合計 8 件）。Unit 定義ファイル `003-migrate-backlog-utf8-fix.md` の実装状態を「未着手」→「完了」に更新（開始日/完了日: 2026-04-28）。
- **成果物**:
  - `.aidlc/cycles/v2.4.3/inception/decisions.md`（DR-008 追記）
  - `.aidlc/cycles/v2.4.3/story-artifacts/units/003-migrate-backlog-utf8-fix.md`（実装状態更新）

---
