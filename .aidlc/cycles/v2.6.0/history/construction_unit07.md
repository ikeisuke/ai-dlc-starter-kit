# Construction Phase 履歴: Unit 07

## 2026-05-10T13:15:12+09:00

- **フェーズ**: Construction Phase
- **Unit**: 07-squash-unit-fail-open（squash-unit.sh の CI 構造チェック fail-open 化）
- **ステップ**: 計画承認 + 中断
- **実行内容**: Unit 007 計画ファイル作成（Construction Phase 中の割り込み追加 / 分類2「別 Unit」）。Intent v2.6.0「含まれるもの」に「#(squash-unit.sh consumer fail-open)」セクションを追記、Unit 定義ファイル `.aidlc/cycles/v2.6.0/story-artifacts/units/007-squash-unit-fail-open.md` を新設、計画ファイル `.aidlc/cycles/v2.6.0/plans/unit-007-plan.md` を作成（GATE-1〜GATE-6 / 完了条件チェックリスト / 工程 A-C / リスク・トレードオフ / 検証コマンド）。Unit 007 状態を「進行中」に更新。承認: semi_auto + フォールバック条件非該当 → auto_approved。コンテキストリセット実施: 計画作成完了時点でユーザー指示により context をリセットして次セッションで Phase 1 から再開する。次のアクション: `/aidlc c` で Construction Phase 継続 → Unit 選定で 007 が自動選択 → Phase 1 設計（depth_level=standard / 小規模 Unit のため軽量化検討）→ Phase 2 実装 → 完了処理。
- **成果物**:
  - `.aidlc/cycles/v2.6.0/plans/unit-007-plan.md`
  - `.aidlc/cycles/v2.6.0/story-artifacts/units/007-squash-unit-fail-open.md`
  - `.aidlc/cycles/v2.6.0/requirements/intent.md`

---

## 2026-05-10T15:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 07-squash-unit-fail-open（→ opt-in 化に方針転換）
- **ステップ**: Phase 1 設計 + 設計レビュー完了（承認済み）
- **実行内容**:
  - Phase 1 設計成果物作成（ドメインモデル / 論理設計）
  - codex 設計レビュー Round 1〜4 で当初案（starter kit / consumer 判定方式）を反復改善（判定キー強化 / 関数化 / return-only / 出力チャネル統一 / bats `--separate-stderr` 統一）
  - **Round 4 後に方針転換**: ユーザー指示「ドッグフーディング特殊処理を本体に埋めない」を受けて opt-in シグナル方式（各 `bin/${check}.sh` の存在を opt-in シグナルとして個別判定）に再設計
  - **CLAUDE.md 新設**: プロジェクトルート直下に「ドッグフーディング特殊処理を本体に埋めない」設計原則を SoT として追記（採用すべき代替方針 / 適用対象 / 関連経緯を明記）
  - Plan 全面同期（GATE-7 廃止トークン互換方針 / GATE-8 starter kit 側 3 種揃い保証境界契約を新設）
  - 論理設計に「移行契約」「starter kit 側 3 種揃い保証境界契約」セクション + bats ケース 4 を追加
  - codex 設計レビュー Round 5〜8 で対応（Plan 全面同期 / 互換方針明文化 / 境界契約明記 / ケース数統一 / 契約文言とテスト実装例整合）
  - **承認**: Round 8 で「指摘 0 件」 → `last_round_clean` で完了 → semi_auto + フォールバック条件非該当 → auto_approved
  - 関連サイクル間バックログ追加: Issue #686「Cycle Phase Completion check を draft PR でスキップする」（v2.6.0 スコープ外 / 別サイクル対応）
- **成果物**:
  - `CLAUDE.md`（新設 / プロジェクトルート）
  - `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_007_squash_unit_fail_open_domain_model.md`（opt-in 方式 / Decision Table 中心）
  - `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_007_squash_unit_fail_open_logical_design.md`（opt-in 方式 / 関数化 / 移行契約 / 境界契約 / 4 ケース bats 戦略）
  - `.aidlc/cycles/v2.6.0/plans/unit-007-plan.md`（GATE-1〜8 全面更新）
- **次のアクション**: Phase 2 実装（squash-unit.sh の関数化 + opt-in 判定 + main ガード化 / `bin/tests/squash-unit/internal_ci_checks_optin.bats` 新設 4 ケース / CHANGELOG 追記 / 廃止トークン依存 grep）

---

## 2026-05-10T16:00:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 07-squash-unit-fail-open（opt-in 化）
- **ステップ**: Phase 2 実装 + コードレビュー + 完了処理
- **実行内容**:
  - `skills/aidlc/scripts/squash-unit.sh` を opt-in シグナル方式に変更:
    - `run_internal_ci_checks_or_skip()` 関数を main 直前に新規追加（return-only / 個別 skip = 無音 continue / 集約 skip 時のみ stdout `squash:info:internal-ci-checks-skipped` + stderr info ログ）
    - 既存の fail-closed 3 種チェックループ（983-996 行）を `if ! run_internal_ci_checks_or_skip "${repo_root_for_checks}"; then exit 1; fi` に置換
    - 末尾 `main "$@"` を `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` に変更（bats source 対応）
    - `set -e` 下での `[[ ]] && cmd` 短絡問題を `if/fi` 形式で回避
  - `bin/tests/squash-unit/internal_ci_checks_optin.bats` を新規作成（4 ケース）:
    - 全揃い: 3 種コピー + git init + commit → status=0 / 集約 skip トークン非出力
    - 全不在: bin/ なし → status=0 / stdout に `squash:info:internal-ci-checks-skipped` / stderr に info ログ
    - 部分存在: 1 種のみコピー → status=0 / 集約 skip 非出力 / 個別 skip 無音
    - starter kit 3 種揃い保証: REPO_ROOT に 3 ファイル `[ -f ]` 個別アサート（GATE-8 境界契約）
  - `CHANGELOG.md` に破壊的変更追記（廃止トークン `squash:error:${check}-script-missing` / 新設トークン `squash:info:internal-ci-checks-skipped` / 移行手順）
  - 廃止トークン依存箇所 `git grep` → 該当なし
  - 構文チェック `bash -n skills/aidlc/scripts/squash-unit.sh` → OK
  - bats 全件 regression: gh-project (40) + operations-712-squash (5) + aidlc-paths (15) + check-test-isolation (9) + 新設 internal_ci_checks_optin (4) = 計 73 件すべて pass
  - codex コードレビュー（reviewing-construction-code / focus: code,security）: Round 1 で「指摘 0 件」 → `1R clean` 完了条件成立 → semi_auto auto_approved
  - Unit 007 状態を「完了」に更新（完了日: 2026-05-10）
- **AIレビュー完了**:
  - 対象タイミング: 設計レビュー（Round 1〜8）+ 統合とレビュー（コードレビュー Round 1）
  - 設計レビュー: 計 14 件指摘 → Round 8 で 0 件 → `last_round_clean` 完了
  - コードレビュー: 0 件 → `1R clean` 完了
  - すべて auto_approved（semi_auto + フォールバック条件非該当）
- **意思決定記録**:
  - DR: 「ドッグフーディング特殊処理を本体に埋めない」原則の採用（CLAUDE.md「設計原則」に SoT 化）
  - 選択肢: A) starter kit 判定方式（当初案 / Round 1〜4 で精緻化済）/ B) opt-in シグナル方式（汎用論理）
  - 採用: B（ユーザー指示）
  - 理由: 本体スクリプトに「自リポジトリ種別判定」を持たせない / 派生条件を呼び込みやすい構造を回避 / consumer プロジェクト誤検知リスク解消
  - 副次効果: `squash:error:${check}-script-missing` トークンの破壊的廃止（CHANGELOG 移行手順記載）
  - 関連バックログ: #687（CI 構造チェックスクリプトの設定駆動化 / 残るハードコードを次サイクル以降で解消）
- **成果物**:
  - `skills/aidlc/scripts/squash-unit.sh`（関数追加 + 呼び出し置換 + main ガード化）
  - `bin/tests/squash-unit/internal_ci_checks_optin.bats`（新設 / 4 ケース）
  - `CHANGELOG.md`（v2.6.0 破壊的変更追記）
  - `.aidlc/cycles/v2.6.0/story-artifacts/units/007-squash-unit-fail-open.md`（実装状態 完了に更新）
- **次のアクション**: squash + Unit 007 完了コミット + 残 Unit 確認（Unit 008 以降があれば次サイクル / なければ Construction 完了 → Operations Phase）

---
