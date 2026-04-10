# Measurement Report: v2.3.0 / #519 コンテキスト圧縮プロジェクト

## §1 概要

### 目的

サイクル v2.3.0（案D: フェーズインデックス集約 + Tier 2 施策統合）の実装後における各フェーズ初回ロード tok 数を実測し、Intent §成功基準の達成状況を定量的に判定する。本レポートは #519 コンテキスト圧縮プロジェクトのクローズ判断の一次資料である。

### 計測条件

- **トークナイザー**: `tiktoken` (`cl100k_base`)
- **Python**: `/tmp/anthropic-venv/bin/python3` (tiktoken 0.12.0)
- **ベースライン commit**: `BASELINE_REF=56c6463747b41ab74108055a933cdfe29781fb43`（v2.2.3 タグ commit、`git rev-parse v2.2.3^{commit}` の結果と一致）
- **計測対象**: 各フェーズの初回ロードに含まれるファイル群（共通ファイル + フェーズ固有ファイル）
- **正本**: `bin/measure-initial-load.sh` の出力。本レポートは出力をそのまま転載し、人間向け解説を加える

> Unit 定義の `d88b0074` は v2.2.3 マージ元ブランチの最終コミット、`56c6463747b4...` は PR #550 のマージコミット（実際の v2.2.3 タグが指す commit）。`skills/aidlc/` 配下のツリー内容は両 commit で完全一致するが、本レポートでは `git rev-parse v2.2.3^{commit}` が返す実際のタグ commit を正本とする。

### 計測コマンド

```bash
bash bin/measure-initial-load.sh
```

### 決定論性

スクリプトを 2 回連続実行し、出力がバイト単位で完全一致することを `diff` で確認済み。

## §2 計測対象ファイル一覧（参考表示）

### v2.2.3 ベースライン（インデックス化前）

| フェーズ | ファイル群 |
|---------|---------|
| 共通 | `SKILL.md` / `steps/common/{rules-core, preflight, session-continuity}.md` |
| Inception | + `steps/inception/{01-setup, 02-preparation, 03-intent, 04-stories-units, 05-completion}.md` |
| Construction | + `steps/construction/{01-setup, 02-design, 03-implementation, 04-completion}.md` |
| Operations | + `steps/operations/{01-setup, 02-deploy, 03-release, 04-completion}.md` |

### v2.3.0 現状（インデックス化後）

| フェーズ | ファイル群 |
|---------|---------|
| 共通 | `SKILL.md` / `steps/common/{rules-core, preflight, session-continuity}.md` |
| Inception | + `steps/inception/index.md` |
| Construction | + `steps/construction/index.md` |
| Operations | + `steps/operations/index.md` |

正本は `bin/measure-initial-load.sh` 内の bash 配列。本表は参考表示。

## §3 v2.2.3 ベースライン計測結果

```text
=== v2.2.3 BASELINE: Inception ===
  4685 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   181 tok  skills/aidlc/steps/common/session-continuity.md
  3353 tok  skills/aidlc/steps/inception/01-setup.md
  2053 tok  skills/aidlc/steps/inception/02-preparation.md
  2536 tok  skills/aidlc/steps/inception/03-intent.md
  3076 tok  skills/aidlc/steps/inception/04-stories-units.md
  3238 tok  skills/aidlc/steps/inception/05-completion.md
 22972 tok  TOTAL

=== v2.2.3 BASELINE: Construction ===
  4685 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   181 tok  skills/aidlc/steps/common/session-continuity.md
  1960 tok  skills/aidlc/steps/construction/01-setup.md
  1319 tok  skills/aidlc/steps/construction/02-design.md
  3280 tok  skills/aidlc/steps/construction/03-implementation.md
  2705 tok  skills/aidlc/steps/construction/04-completion.md
 17980 tok  TOTAL

=== v2.2.3 BASELINE: Operations ===
  4685 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   181 tok  skills/aidlc/steps/common/session-continuity.md
  1315 tok  skills/aidlc/steps/operations/01-setup.md
  3158 tok  skills/aidlc/steps/operations/02-deploy.md
   768 tok  skills/aidlc/steps/operations/03-release.md
  3252 tok  skills/aidlc/steps/operations/04-completion.md
 17209 tok  TOTAL
```

## §4 v2.3.0 計測結果

```text
=== v2.3.0 CURRENT: Inception ===
  4960 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   585 tok  skills/aidlc/steps/common/session-continuity.md
  5260 tok  skills/aidlc/steps/inception/index.md
 14655 tok  TOTAL

=== v2.3.0 CURRENT: Construction ===
  4960 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   585 tok  skills/aidlc/steps/common/session-continuity.md
  6172 tok  skills/aidlc/steps/construction/index.md
 15567 tok  TOTAL

=== v2.3.0 CURRENT: Operations ===
  4960 tok  skills/aidlc/SKILL.md
  1885 tok  skills/aidlc/steps/common/rules-core.md
  1965 tok  skills/aidlc/steps/common/preflight.md
   585 tok  skills/aidlc/steps/common/session-continuity.md
  6107 tok  skills/aidlc/steps/operations/index.md
 15502 tok  TOTAL
```

## §5 差分サマリ（段階 1: 計測達成基準）

| フェーズ | v2.2.3 ベースライン | v2.3.0 実測 | 差分 | 削減率 | 必達閾値 | 判定 |
|---------|------------------:|----------:|------:|------:|--------:|:----:|
| Inception | 22,972 tok | **14,655 tok** | -8,317 tok | **-36.2%** | ≤ 15,000 tok | ✅ 達成 |
| Construction | 17,980 tok | **15,567 tok** | -2,413 tok | **-13.4%** | ≤ 17,980 tok | ✅ 達成 |
| Operations | 17,209 tok | **15,502 tok** | -1,707 tok | **-9.9%** | ≤ 17,209 tok | ✅ 達成 |

**段階 1 結果**: 3 フェーズすべてで必達基準を達成。Intent の主目標（Inception -35% 以上）を **-36.2%** で達成。

## §6 boilerplate 削減状況（補助項目）

> Intent §成功基準の必達項目には含まれない「自動解消扱い」の補助項目。本節の判定結果は #519 クローズ判断には影響しない。

### 軸 1: ステップファイル群合計 tok 比較

各フェーズの `steps/{phase}/0[1-5]-*.md` ステップファイル群（インデックス化対象外の従来ステップファイル）の合計 tok 数を比較する。

| フェーズ | v2.2.3 ステップファイル群合計 | v2.3.0 ステップファイル群合計 | 差分 | 削減率 | 判定 |
|---------|----------------------------:|----------------------------:|------:|------:|:----:|
| Inception | 14,256 tok | 13,999 tok | -257 tok | -1.8% | ✅ |
| Construction | 9,264 tok | 8,921 tok | -343 tok | -3.7% | ✅ |
| Operations | 8,493 tok | 8,676 tok | +183 tok | +2.2% | ⚠️ |

**Operations の微増理由**: Unit 005（Tier 2 施策統合）で `operations-release.sh` への呼び出し参照と `review-routing.md` への参照記述が `02-deploy.md` 等に追加されたことによる。これは「重複ロジックの削減」とは異なる「索引参照の追加」であり、案D の方針（詳細は index.md / 外部スクリプトに集約、ステップファイルからは参照のみ）の副作用。Intent §成功基準の必達項目には影響しない。

### 軸 2: index.md 集約証跡

各フェーズの index.md に、そのフェーズで意味を持つ boilerplate パターンが集約されているかを確認する。

| パターン名 | grep 正規表現 | Inception | Construction | Operations |
|---------|-------------|:---------:|:------------:|:----------:|
| automation_mode 分岐 | `automation_mode` | ✅ あり (○) | ✅ あり (○) | ✅ あり (○) |
| depth_level 分岐 | `depth_level` | ✅ あり (○) | ✅ あり (○) | ✅ あり (○) |
| AI レビュー分岐参照 | `review-flow.md\|review-routing.md` | ✅ あり (○) | ✅ あり (○) | ✅ あり (○) |
| エクスプレス分岐 | `express` | ✅ あり (○) | ✅ あり (○) | N/A (-) |

> Operations × `express` は phase applicability `-`（Operations にエクスプレス分岐は存在しない）のため判定対象外。

**軸 2 結果**: 全 applicability `○` セルで `index.md` への集約を確認（11/11 達成）。

### §6 総合

- 軸 1: Inception / Construction で削減達成、Operations のみ微増（+183 tok / +2.2%）
- 軸 2: 全 applicable パターンが index.md に集約済み

Operations の微増は Tier 2 施策（`operations-release.sh` 化、`review-routing.md` 抽出）の副作用であり、案D 方針（重複ロジックを index/外部スクリプトに集約）と整合する変化。Intent §成功基準の必達項目には含まれないため、#519 クローズ判断には影響しない補助項目として記録する。

## §7 中間値突合（Unit 001 / 003 / 004 vs 最終値）

| Unit | フェーズ | 中間検証時 tok | 最終 tok（本 Unit） | 差分 | 備考 |
|------|---------|--------------:|-------------------:|------:|------|
| Unit 001 | Inception | 13,443 tok | 14,655 tok | +1,212 | Unit 002 で `session-continuity.md` を 181 → 585 tok に拡張、Unit 005 で SKILL.md を 4,928 → 4,960 tok に微増、`inception/index.md` を 4,484 → 5,260 tok に拡張（Universal Recovery 取り込み） |
| Unit 003 | Construction | 15,426 tok | 15,567 tok | +141 | Unit 005 で SKILL.md / session-continuity.md / construction/index.md の微更新 |
| Unit 004 | Operations | 15,394 tok | 15,502 tok | +108 | Unit 005 で SKILL.md / session-continuity.md / operations/index.md の微更新（Tier 2 統合） |

すべての差分は Unit 002-005 で計画的に追加された機能（汎用復帰判定基盤、Tier 2 統合等）の正常な反映であり、回帰ではない。最終値（本 Unit 計測値）はすべて必達閾値内。

## §8 Intent 成功基準項目への対照（段階 2）

Intent §成功基準の必須・動作保証項目を Unit 001-005 の検証/実装記録から引用して達成状況を確認する。

### 必須基準

| Intent 基準 | 検証元 Unit | 引用元 | 引用文（達成根拠） | `expected_assertion` 充足 | 判定 |
|------------|-----------|-------|-------------------|------------------------|:----:|
| Inception 初回ロード ≤ 15,000 tok | 本 Unit | §5 差分サマリ | 本レポート §5 で 14,655 tok（≤15,000）と実測 | はい | ✅ |
| Construction / Operations 初回ロード現状維持 | 本 Unit | §5 差分サマリ | Construction 15,567 tok（≤17,980）、Operations 15,502 tok（≤17,209）と実測 | はい | ✅ |
| フェーズインデックスファイルが全フェーズで作成、3 点（目次・分岐・判定）集約 | Unit 001 / 003 / 004 | `unit_001_inception_phase_index_implementation.md` / `unit_003_construction_phase_index_verification.md` / `unit_004_operations_phase_index_verification.md` | Unit 001: 「最終 Inception 初回ロード: 13443 tok ... v2.2.3 比 -41.5%」「`<!-- phase-index-schema: v1 -->` でスキーマ世代を識別。Unit 003/004 が本構造をそのまま流用」 / Unit 003: 「2 段レゾルバ構造（`PhaseResolver` + `ConstructionStepResolver`）と Materialized Binding パターンが Construction Phase にも適用」 / Unit 004: 「`phase-recovery-spec.md §5` 配下のすべての phase（Inception §5.1 / Construction §5.2 / Operations §5.3）が実値化された」 | はい | ✅ |
| コンパクション復帰インデックスのみで一意判定 | Unit 002 | `unit_002_universal_recovery_base_verification.md` | 「全13ケース（正常系6 + 異常系4 + #553再現3）が仕様通りの期待値を**単値で導出**できることを静的検証で確認」 | はい | ✅ |
| #553 再現ケースで Inception として復帰成功 | Unit 002 | `unit_002_universal_recovery_base_verification.md` | 「【#553 根本解決】再現シナリオ1a/1b/2 の期待値を単値固定、spec §4 判定順3での吸収を明記」「【#553 対比記録】`phase-recovery-spec.md §10.3` に v2.2.3 判定ロジックとの対比を記載」 | はい | ✅ |

### 動作保証基準

| Intent 基準 | 検証元 Unit | 引用元 | 引用文（達成根拠） | 充足 | 判定 |
|------------|-----------|-------|-------------------|:----:|:----:|
| 全フェーズステップ実行が現行と同じ結果（Inception 静的構造回帰） | Unit 001 | `unit_001_inception_phase_index_implementation.md:67-68` | 「✅ テンプレート完全一致（6ファイル）: intent / user_stories / unit_definition / prfaq / decision_record / inception_progress」「✅ 成果物パス一覧一致（8パス）: history/inception.md / decisions.md / progress.md / existing_analysis.md / intent.md / prfaq.md / units/*.md / user_stories.md」 | はい | ✅ |
| 全フェーズステップ実行が現行と同じ結果（Construction 構造的一貫性） | Unit 003 | `unit_003_construction_phase_index_verification.md:200` | 「2 段レゾルバ構造（`PhaseResolver` + `ConstructionStepResolver`）と Materialized Binding パターンが Construction Phase にも適用され、Unit 001 Inception 実装との構造的一貫性が保たれている」 | はい | ✅ |
| 全フェーズステップ実行が現行と同じ結果（Operations 構造的一貫性） | Unit 004 | `unit_004_operations_phase_index_verification.md:195` | 「初回ロードは **15,394 tok**（-2,433 tok、-13.7%）で v2.2.3 ベースライン以下を達成。2 段レゾルバ構造（`PhaseResolver` + `OperationsStepResolver`）と Materialized Binding パターンが Operations Phase にも適用され、Unit 001/002/003 との構造的一貫性が保たれている」 | はい | ✅ |
| AI レビュー・セミオートゲートの機能 | Unit 001 / 005 | `unit_001_inception_phase_index_implementation.md:89` / `unit_005_tier2_integration_verification.md:139` | Unit 001: 「**レビュー履歴**: 計画（codex ×5）→ 設計（codex ×4）→ コード（codex ×2）→ 統合（codex ×4）、計15反復。全指摘計19件を解消。」 / Unit 005: 「AI レビュー: 計画承認前・設計レビュー・コード生成後・統合とレビュー の全 4 タイミングで完了（Phase 1 / Phase 2 合わせて 4 回、すべて `auto_approved`）」 | はい | ✅ |
| コンパクション復帰仕様の機能（fixture 単値性） | Unit 002 | `unit_002_universal_recovery_base_verification.md:23` | 「全13ケースが成功（終了コード 0）、期待値を含む fixture が正しく生成される」 | はい | ✅ |
| Operations 復帰の bootstrap ルート機能 | Unit 004 | `unit_004_operations_phase_index_verification.md:166` | 「Unit 003 で確立した『Construction → Operations 遷移』が Unit 004 の `OperationsStepResolver` を経由する新ルートでも動作することを fixture o5（bootstrap-from-construction）で確認」 | はい | ✅ |
| Tier 2 施策（operations-release）採用 | Unit 005 | `unit_005_tier2_integration_verification.md:17` | 「`skills/aidlc/steps/operations/operations-release.md` - `operations-release.sh` 呼び出しベースに簡略化（2,877 tok → 1,433 tok、50.2% 削減、目標 1,438 tok 以下達成）」 | はい | ✅ |
| Tier 2 施策（review-flow / review-routing）採用 | Unit 005 | `unit_005_tier2_integration_verification.md:18` / `:82` | 「`skills/aidlc/steps/common/review-flow.md` - ルーティング判定を `review-routing.md` に委譲し、実行手順（反復・指摘対応・完了処理・外部入力検証）のみに縮約（2,434 tok）」 / 「`review-flow.md + review-routing.md` `**3,979 tok**` ≤ 3,989 tok（整理前の `review-flow.md` 単体以下） OK」 | はい | ✅ |

### Tier 2 施策 boilerplate 削減（自動解消扱い）

§6 で確認済み。Intent §成功基準の必達項目に含まれず、判定結果は #519 クローズ判断に影響しない補助項目（Operations のみ +183 tok 微増、それ以外は削減）。

**段階 2 結果**: Intent §成功基準の必須項目・動作保証項目すべての達成を確認。

## §9 結論

### 段階 1（計測達成基準）

**達成 ✅**

- Inception: 14,655 tok ≤ 15,000 tok（-36.2%）
- Construction: 15,567 tok ≤ 17,980 tok（-13.4%）
- Operations: 15,502 tok ≤ 17,209 tok（-9.9%）

### 段階 2（Intent §成功基準項目）

**達成 ✅**

- 必須基準 5 項目すべて達成
- 動作保証基準 8 項目すべて達成（§8 動作保証基準テーブル参照）

### #519 クローズ判断

**段階 1 + 段階 2 ともに達成**。Issue #519 は **クローズ可能**。

### 補助項目（クローズに影響しない）

- boilerplate 削減: Inception / Construction で削減確認、Operations のみ +183 tok（+2.2%）の微増。Tier 2 施策の副作用であり、Intent §成功基準の必達項目に含まれないため #519 クローズには影響しない。今後の改善余地として記録のみ
