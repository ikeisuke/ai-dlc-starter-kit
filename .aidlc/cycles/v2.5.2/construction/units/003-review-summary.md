# レビューサマリ: Unit 003 AIDLC_PROJECT_ROOT 横断 path resolution リファクタ

## 基本情報

- **サイクル**: v2.5.2
- **フェーズ**: Construction
- **対象**: Unit 003（AIDLC_PROJECT_ROOT 横断 path resolution リファクタ）

---

## Set 1: 2026-05-06 設計レビュー

- **レビュー種別**: ConstructionDesignReview
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（全件対応 / round 2 で指摘 0 件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | 論理設計 helper API 定義 - 引数エラー `exit 2` が `exit-code-convention.md`「引数エラー = exit 1」と不整合 | 修正済み（`logical_design.md` に exit code 規約選定理由の注記を追加。`retrospective-issue.sh` ヘッダ・`__retro_validate_cycle`・`retrospective-resend.sh` ヘッダの既存系列と整合させるため `exit 2` を採用、規約 guide との乖離は別サイクル backlog 候補と明示） | - |
| 2 | 中 | 論理設計 retrospective-resend.sh コンポーネント - cycle 自動決定が `.aidlc/cycles` 直書き前提のままで AIDLC_PROJECT_ROOT 設定下に不整合残存 | OUT_OF_SCOPE（Intent「含まれるもの」非該当 / 計画書 §4 残存直書き path 一覧で defer 済）+ IF 制約注記追加（「`--cycle` 明示時のみ AIDLC_PROJECT_ROOT 整合保証、cycle 自動決定経路は cwd 直書き前提」を `logical_design.md` に追加） | #644 |
| 3 | 低 | `consumer_integration.bats` 検証観点 - stderr `path=` トークン依存で文言変更に脆い | 修正済み（`logical_design.md` に「判定主軸 (primary): NDJSON `file_path` / 判定補助 (secondary): stderr `path=` トークン」を明記、文言変更時は NDJSON 主判定優先と方針追加） | - |

### Round 4 新領域判定

本レビューは Round 2 で完了（指摘 0 件）したため発生していない。

```json
{
  "K_old": [],
  "K_new": [],
  "K_diff": [],
  "rounds_executed": 2
}
```

---

## Set 2: 2026-05-06 コードレビュー（実装後）

- **レビュー種別**: ConstructionCodeReview
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（全件対応 / round 3 で指摘 0 件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `retrospective-resend.sh` の cycle 自動決定が AIDLC_PROJECT_ROOT 非対応のまま (round 1) | OUT_OF_SCOPE（前回設計レビューで同趣旨 #2 が既に OUT_OF_SCOPE と判定済 / Issue #644 起票済 / 計画書 §4 残存直書き path 一覧で defer 済 / 論理設計 IF 制約注記済） | #644 |
| 2 | 中 | `aidlc_cycle_path` が `<subpath>` の空文字を許容してしまい、末尾 `/` のみの曖昧パスが生成される (round 1) | 修正済（`aidlc-paths.sh` で `[[ -z "${2:-}" ]]` も引数エラーに変更。ヘッダ仕様「引数エラー (cycle 空 / subpath 未指定)」との対称性確保。BATS で空文字回帰検証も追加） | - |
| 3 | 中 | `aidlc_cycle_path` 新規導入 + subpath 空文字エラー化に対する自動テストが差分内に追加されていない (round 2) | 修正済（`bin/tests/aidlc-paths/aidlc_cycle_path.bats` 10 ケース + `consumer_integration.bats` 5 ケース追加 / 全 15 件 pass / AIDLC_PROJECT_ROOT 設定下の `bin/tests/` 配下も 0 fail） | - |

### Round 4 新領域判定

本レビューは Round 3 で完了（指摘 0 件）したため発生していない。

```json
{
  "K_old": ["cycle_auto_detection_aidlc_project_root"],
  "K_new": ["aidlc_cycle_path_subpath_empty_check", "aidlc_paths_unit_test_coverage"],
  "K_diff": [],
  "rounds_executed": 3
}
```

### ビルド・テスト実行結果

- **AIDLC_PROJECT_ROOT 未設定**: `bats --recursive bin/tests/ tests/` 全 410 件 pass（後方互換性確認）
- **AIDLC_PROJECT_ROOT 設定下**: `bats --recursive bin/tests/` 全 26 件 pass（受け入れ基準充足）
- `tests/` 配下の AIDLC_PROJECT_ROOT export 状態での fail 15 件は、テスト fixture を mktemp 別場所に作るが内部で AIDLC_PROJECT_ROOT を上書きしない既存テスト構造（v2.5.1 以前から存在する制約）に起因し、Unit 003 起因の regression ではない。受け入れ基準は厳密に「設定下は `bin/tests/` 配下、未設定は全件」を要求しており満たしている。

---

## Set 3: 2026-05-06 統合レビュー

- **レビュー種別**: ConstructionIntegrationReview
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（全件対応 / round 2 で指摘 0 件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | 計画書 `unit-003-plan.md` の DoD チェックリストが全 `[ ]` で未更新、ドキュメント間で完了状態が不整合 (round 1) | 修正済（DoD 全項目を実績に合わせて `[x]` 更新。当初項目「skills/aidlc/scripts/tests/test_*.sh の bash テスト pass」は過剰スコープのため削除し、削除理由（v2.5.x の bin/→skills/aidlc/scripts/ 構造移行起因の既存問題で Unit 003 と無関係）を計画書末尾の注記に明記。Unit 定義ファイル側の「実装状態」は完了処理 task #15 で更新する設計） | - |

### Round 4 新領域判定

本レビューは Round 2 で完了（指摘 0 件）したため発生していない。

```json
{
  "K_old": [],
  "K_new": ["dod_checklist_synchronization"],
  "K_diff": [],
  "rounds_executed": 2
}
```
