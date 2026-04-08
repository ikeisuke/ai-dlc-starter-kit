# レビューサマリ: Unit 001 Inception フェーズインデックスのパイロット実装

## 基本情報

- **サイクル**: v2.3.0
- **フェーズ**: Construction
- **対象**: Unit 001

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-04-09 設計レビュー（反復4回）

- **レビュー種別**: construction_design（ドメインモデル + 論理設計）
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘0件（承認可）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | Unit 002 接続点（CurrentStepDetermination 論理インターフェース）が未定義で、実判定責務の差し込み箇所が実装者依存になる | 修正済み（ドメインモデル / 論理設計に `CurrentStepDetermination` 論理インターフェース仕様、入出力契約、Unit 001/002 責務境界表を追加） | - |
| 2 | 中 | ドメインモデル冒頭「Inception に限定して確立し Unit 003/004 で汎用化」が計画・Unit 定義とズレている。Unit 001 は基盤 Unit として共通構造を確立する前提 | 修正済み（ドメインモデル概要を「Unit 001 はフェーズ非依存の共通構造仕様を確立する基盤 Unit。Unit 003/004 はそのまま適用」に修正） | - |
| 3 | 中 | 詳細ステップファイルの変更範囲に「boilerplate 削減」が混入していて、計画・Unit 定義の範囲を超える可能性 | 修正済み（論理設計で変更範囲を「分岐・判定の重複記述のみ」に限定し、boilerplate 削減は DoD 対象外・結果的減少は許容と明文化） | - |
| 4 | 高 | 予算超過時の対処に「判定チェックポイント骨格スキーマの列削減」が含まれており、Unit 001/002 の契約を再び可変にしていた | 修正済み（「契約不変領域」として `StepLoadingContract`/`RecoveryCheckpoint` の列構造・行構造を固定と明記。削減対象は説明文・分岐ロジック表現・汎用構造仕様コメント等の非契約部分に限定） | - |
| 5 | 中 | `CurrentStepDetermination` の `user_confirmation_required=true` 固定化と、責務境界表の `TBD` 扱いが二重定義 | 修正済み（Unit 001 は「ユーザー確認フローへ接続しうる契約点のみ定義」「固定真偽値は定義しない」に修正。実値は Unit 002 が reason_code ごとに決定） | - |
| 6 | 高 | `step_id` 未指定時の既定動作が未定義で、Unit 002 未完成期間に `/aidlc inception` 開始経路が閉じない | 修正済み（Unit 001 時点の既定ルートとして「未指定時は `inception.01-setup` を既定開始点」を論理設計のフロー1に明記） | - |
| 7 | 中 | 「インデックスが現在位置判定の唯一の正本」宣言と `compaction.md` 旧判定テーブル温存が矛盾し、Unit 001 期間中の参照元が二重化 | 修正済み（Unit 001 期間中に `index.md` 冒頭で「旧 compaction.md 判定テーブルは非正本・参照禁止・Unit 002 で削除予定」と宣言する方針を責務境界表に明記） | - |
| 8 | 低 | DoD 検証が代表3件の `step_id` のみで、全5行固定契約と `RecoveryCheckpoint` 側の全5行・5列・全 `TBD` セル確認が漏れている | 修正済み（フロー2 を全5 `step_id` 解決確認 + `StepLoadingContract`/`RecoveryCheckpoint` 列構造・行構造・TBD セル固定確認 + 既定ルート確認に拡張） | - |

**最終レビュー結果**: 指摘0件 / 承認可（codex、反復4回目で指摘ゼロ）

**シグナル**: `review_detected=true, resolved_count=8, deferred_count=0, unresolved_count=0`
**ゲート判定**: `auto_approved`（`unresolved_count==0` / フォールバック非該当）

---

## Set 2: 2026-04-09 コードレビュー（反復2回）

- **レビュー種別**: construction_code（code + security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件（承認可）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `03-intent.md:49` / `04-stories-units.md:56,101` で見出し語を「セミオートゲート判定」から「ゲート判定」に変更。SKILL.md は「セミオートゲート判定」を semi_auto 対象識別の契約語として参照しており、変更すると Inception フローの自動承認判定に回帰リスク | 修正済み（見出し語「セミオートゲート判定」を維持し、内容のみ `index.md` の「2.4 automation_mode 分岐」への参照に置換） | - |

**最終レビュー結果**: 指摘0件 / 承認可（codex、反復2回目で指摘ゼロ）

**シグナル**: `review_detected=true, resolved_count=1, deferred_count=0, unresolved_count=0`
**ゲート判定**: `auto_approved`（`unresolved_count==0` / フォールバック非該当）

---

## Set 3: 2026-04-09 統合レビュー（反復4回）

- **レビュー種別**: construction_integration
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘0件（承認可）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | コンパクション復帰経路が `compaction.md:13` で `steps/inception/01-setup.md` から順読みする旧ルートのまま。index.md と compaction.md が整合せず、コンパクション復帰時だけ旧ルートに戻る回帰リスク | 修正済み（compaction.md の再読み込みパス表の Inception 行を `index.md` + 契約テーブル経由に更新。スキル再読み込み手順にも Inception 復帰時の流れを追記） | - |
| 2 | 中 | `compaction.md:32` の判定表が `story-artifacts/units/*.md` の存在だけで Construction と判定するため、Inception `04-stories-units` 完了後を誤判定する（#553 再現条件） | 修正済み（判定表に『非正本・暫定・Unit 002 で削除予定』注記を追加。Inception 優先ガード判定順2として `inception/progress.md` の未完了ステップ存在チェックを Construction 判定より優先） | - |
| 3 | 中 | コンパクション復帰時に `inception.01-setup` を既定開始点として使うと、`03-intent`/`04-stories-units` 作業中でも `01-setup` を再読み込みしてしまう | 修正済み（index.md の既定ルートを『新規開始時のみ』と明示。コンパクション復帰時は `inception/progress.md` から未完了ステップ特定、不在/パース不能時はユーザー確認フォールバック） | - |
| 4 | 中 | compaction.md:13 の要約表が依然として「step_id 未指定時は inception.01-setup 既定開始点」と読め、先頭の要約表だけが旧ルールを保持 | 修正済み（要約表の Inception 行を『inception/progress.md から未完了ステップ特定 → 契約テーブル経由』に更新、progress.md 不在／新規開始時のみ既定開始点と明示） | - |
| 5 | 中 | compaction.md:34 の注記が「index.md の判定チェックポイントセクションが正本」と案内しているが、そこは TBD 骨格で実運用ルールに辿り着けない | 修正済み（注記を『正本は index.md 全体。Unit 001 時点の実運用ルールは 4.1 既定ルート。3. 判定チェックポイント骨格は Unit 002 用の TBD 骨格』と明示） | - |

**最終レビュー結果**: 指摘0件 / 承認可（codex、反復4回目で指摘ゼロ）

**シグナル**: `review_detected=true, resolved_count=5, deferred_count=0, unresolved_count=0`
**ゲート判定**: `auto_approved`（`unresolved_count==0` / フォールバック非該当）

---

## 最終計測結果（Unit 001 DoD）

| 項目 | 計測値 | 目標 | 判定 |
|------|--------|------|------|
| Inception 初回ロード | 13,443 tok | ≤ 15,000 tok | ✅ 達成（余裕 1,557 tok） |
| v2.2.3 ベースライン比 | -9,529 tok（-41.5%） | - | - |
| SKILL.md 本文行数 | 239 行 | ≤ 500 行 | ✅ 達成 |
| StepLoadingContract 全5行解決 | 5/5 成功 | 5/5 | ✅ 達成 |
| RecoveryCheckpoint 骨格 | 5行 × 5列、全TBD | 固定 | ✅ 達成 |
| load_timing 全 on_demand | 5/5 | 5/5 | ✅ 達成 |
| 既定ルート (新規開始時) | inception.01-setup 明記 | 必須 | ✅ 達成 |
| テンプレート完全一致 | 6ファイル一致 | 不変 | ✅ 達成 |
| 成果物パス一覧一致 | 8パス一致 | 不変 | ✅ 達成 |
| write-history 呼び出し | v2.2.3 と一致 | 不変 | ✅ 達成 |
| progress.md 参照 | v2.2.3 と一致 | 不変 | ✅ 達成 |
