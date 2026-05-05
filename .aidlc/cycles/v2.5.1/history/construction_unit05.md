# Construction Phase 履歴: Unit 05

## 2026-05-05T16:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-write-history-uncommitted-guard（#616 マージ前 write-history 追加コミット漏れガード）
- **ステップ**: Unit 完了
- **実行内容**: # Construction Unit 005 履歴: #616 マージ前 write-history 追加コミット漏れガード

## 概要

Operations §7.13 PR マージ実行時に `validate-git.sh uncommitted` を script-level pre-flight check として呼び出し、`status:warning`（未コミット差分検出）時は exit 1 + stderr `pre-merge-uncommitted-detected` で停止する構造的ガードを実装。`#616` で報告された v2.4.3 顕在シナリオ（write-history 追記後にコミット未実施 → push → マージ → 未コミット差分が post-merge で破棄しか選択肢なし）を AI 規律不要の構造的防御線で防止する。Option A/B/C/D の trade-off 評価で **A 補助 + C 強化版（script-level 構造ガード）** を採用 / B（write-history --commit）と D（write-history 1 回限定）は責務肥大化 / 履歴粒度変更影響大で不採用。

## Phase 1: 設計

- ドメインモデル: PreFlightCheckResult / WorkingTreeStatus（**OK | WARNING | ERROR** / `validate-git.sh` canonical 値域に完全一致 / 設計レビュー round 1 で `clean/dirty` 誤解を `ok/warning/error` に修正）/ MergePrInvocation エンティティ
- 論理設計: `__operations_release_pre_flight_check` 内部関数 / `validate-git.sh uncommitted` の `status:` 行 parse のみで判定（exit code は `|| true` で握り潰し / `local var=$(cmd) || rc=$?` masking バグ回避）
- 制御フロー reorder: `cmd_merge_pr` 内部で「引数 parse → pre-flight check → dry-run early return → 実マージ」順序確定 / `--dry-run` 時も pre-flight 必ず実行（I2 / 構造的検証信頼性）
- escape hatch: `--skip-checks` で pre-flight 完全 skip（既存規約踏襲 / 緊急時用）
- 二重ガード設計: §7.13 内に新規 broad pre-flight + 既存 `.aidlc/config.toml` 特化 (#601 案 B) の併存 / 対象が異なり競合しない
- 計画レビュー: codex 4 round / 7 件指摘（高 3 / 中 3 / 低 1）→ 全件解消 / `PLAN APPROVED ROUND 4`
- 設計レビュー: codex 2 round / 5 件指摘（高 1 / 中 2 / 低 2）→ 全件解消 / `DESIGN APPROVED ROUND 2`

## Phase 2: 実装

- 改修: `skills/aidlc/scripts/operations-release.sh`
  - 新規関数 `__operations_release_pre_flight_check`（cmd_merge_pr 直前に追加 / `validate-git.sh` 既存契約再利用）
  - `cmd_merge_pr` に pre-flight 呼出追加 + `--dry-run` early return を pre-flight 後に reorder
  - shellcheck severity=warning で 0 件
- 改修: `skills/aidlc/steps/operations/operations-release.md`
  - §7.12 完了条件として verify-git 再実行案内追加（補助 / Option A）
  - §7.13 に `merge-pr` pre-flight check 記述 + 既存 `.aidlc/config.toml` 特化ガードとの併存ルール明記
- 改修: `skills/aidlc/steps/common/review-flow.md` L50
  - 「(2) レビュー後コミット」を「(2a) 修正コミット → (2b) 履歴記録 (`/write-history`) → (2c) 履歴コミット」三段階分割明示
  - 適用範囲は既存「パス 1/2 完了時」を維持（パス 3 ユーザー主導は既存仕様踏襲）
- 改修: `.github/workflows/migration-tests.yml`
  - PATHS_REGEX に `tests/operations-uncommitted-detection.bats` + `operations-release.sh` + `operations-release.md` + `review-flow.md` を追加
  - bats 実行リストに新規 BATS を追加
- 新規: `tests/operations-uncommitted-detection.bats` 8 件（U1-U8）
  - U1（実行系）: dirty + --dry-run → exit 1 + stderr `pre-merge-uncommitted-detected`
  - U2（実行系）: clean + --dry-run → exit 0 + `pre-flight-pass` 表示
  - U3（実行系）: dirty + --skip-checks → exit 0（escape hatch / pre-flight skip）
  - U4（文書）: review-flow.md L50 三段階フロー grep 検証
  - U5（文書）: operations-release.md §7.12 verify-git + §7.13 merge-pr pre-flight 記述 grep 検証
  - U6（回帰）: write-history.sh post-merge ガード（exit 3）実動作 verify
  - U7（境界値）: validate-git.sh `status:error` 時 → warn + 続行（誤停止しない）
  - U8（境界値）: validate-git.sh `status:` 行欠落時 → unknown 扱い + warn + 続行

## Unit 004 incidental fix（境界跨ぎ更新 / Set 3 P1 対応）

Unit 005 コードレビュー round 1 で Unit 004 `__pred_read_spool_issue_url` の重大バグ発見:
- 旧実装: `.issue_url` のみ参照
- 問題: Unit 002 spool 実 schema は `partial_state.local_created` / `partial_state.mirror_created` に URL を格納 / `.issue_url` は v2.5.0 以前の互換 schema
- 影響: spool fallback 経路で URL 取得失敗 → 経路 3/4 へ誤遷移 → predecessor handoff 機能不全
- Fix: 優先順位 `.partial_state.local_created // .partial_state.mirror_created // .issue_url`（旧版 fallback 含む）
- Unit 004 domain model L112 も同期更新（Set 4 P2-1 対応）
- BATS テスト追加: P19（partial_state.local_created）+ P20（旧 issue_url fallback）→ 全 17 件 pass

## テスト

- tests/operations-uncommitted-detection.bats: 新規 8 件 pass
- tests/predecessor-issue-handoff.bats: 17 件 pass（Unit 004 fix 統合確認）
- 既存 BATS 退行ゼロ: 全 316 件 pass（Unit 004 完了時 305 + Unit 005 新規 8 + Unit 004 追加 P19/P20 + 境界値 1）
- shellcheck severity=warning warning 0
- `bin/check-bash-substitution.sh skills/aidlc/steps/` 違反 0

## レビュー（4 セット / 全 auto_approved）

- Set 1（計画 / codex 4 round）: 7 件指摘（高 3 / 中 3 / 低 1）→ 全件解消 / `PLAN APPROVED ROUND 4`
- Set 2（設計 / codex 2 round）: 5 件指摘（高 1 / 中 2 / 低 2）→ 全件解消 / `DESIGN APPROVED ROUND 2`
- Set 3（コード / codex 2 round）: 4 件指摘（Unit 005 高 1 = 解消 + Unit 004 P1 = 解消 / Unit 002 領域 3 件 = backlog defer）→ Unit 005 unresolved=0
- Set 4（統合 / codex 3 round）: 4 件指摘（中 4）→ 全件解消 / `INTEGRATION CLEAN ROUND 3`

## 主要決定

- DR-027: Option C 強化版（script-level 構造ガード）+ A 補助（review-flow 三段階明示）採用 / B+D 不採用
- DR-028: WorkingTreeStatus canonical = `OK | WARNING | ERROR`（validate-git.sh と完全一致）
- DR-029: 発火条件 = `status:warning` のみ exit 1 / `error` / `unknown` は warn + 続行（システムエラーで誤停止しない）
- DR-030: exit code 非依存判定（`validate-git.sh` の exit を `|| true` で握り潰し / `status:` 行 parse のみで決定）
- DR-031: escape hatch `--skip-checks` で pre-flight 完全 skip（既存規約踏襲）
- DR-032: 制御フロー reorder = 「引数 parse → pre-flight check → dry-run early return → 実マージ」/ `--dry-run` 時も pre-flight 必ず実行
- DR-033: 二重ガード = §7.13 内に新規 broad（順序 1）+ 既存 `.aidlc/config.toml` 特化 (#601 案 B / 順序 2) 併存 / 対象差異により競合なし
- DR-034: review-flow.md L50 三段階フロー = (2a) 修正 / (2b) 履歴記録 / (2c) 履歴コミット / 適用範囲は既存「パス 1/2 完了時」維持
- DR-035: Unit 002 spool 実 schema 整合（Unit 004 incidental fix）= partial_state.local_created // mirror_created // issue_url（旧 fallback）優先順位

## バックログ移送（Unit 002 領域 / Unit 004 既存 backlog と同期 / 重複登録回避）

1. `retrospective-resend.sh` `--cycle` 引数の `__retro_validate_cycle` 検証 + missing value 拒否（path traversal + auto-detect fallback 暴発防止）
2. `retrospective_issue_create` `target=both` 時の mirror duplicate check（local のみ検査 → mirror 重複時に重複起票発生）

## DoD 達成状況

- [x] AC1: `merge-pr` pre-flight check `validate-git.sh uncommitted` 呼出 + `status:warning` 時 exit 1 + stderr `pre-merge-uncommitted-detected`
- [x] AC2: `--skip-checks` escape hatch
- [x] AC3: `operations-release.md §7.12` verify-git 再実行案内 / §7.13 `merge-pr` pre-flight 記述
- [x] AC4: `review-flow.md` L50 三段階明示（パス 1/2 完了時 / 既存境界維持）
- [x] AC5: 二重ガード優先順位 §2 定義
- [x] AC6: 実行系 BATS U1-U3 pass
- [x] AC7: 文書 BATS U4-U5 pass
- [x] AC8: 回帰 BATS U6 pass（#579 post-merge exit 3 ガード破壊なし）
- [x] AC9: 全 BATS 316 件 pass
- [x] AC10: shellcheck warning 0
- [x] AC11: `$()` 規約準拠
- [x] AC12: #579 post-merge ガード整合
- [x] AC13: review-summary に Option 選定根拠 + 二重ガード設計記録

## サイクル完了

Unit 005 完了 = Construction Phase 完了 = v2.5.1 サイクルの全実装単位完了（001-005 / 5/5）。次は Operations Phase に移行可能。
