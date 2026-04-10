# レビューサマリ: Unit 006 - 削減目標達成の計測レポートと #519 クローズ判断

## 基本情報

- **サイクル**: v2.3.0
- **フェーズ**: Construction
- **対象**: Unit 006 削減目標達成の計測レポートと #519 クローズ判断

---

## Set 0: 2026-04-10 (計画承認前レビュー)

- **レビュー種別**: 計画承認前レビュー（focus: architecture）
- **使用ツール**: codex (session: 019d749c-55e2-76e3-b45e-e460d34cfb2d)
- **反復回数**: 4
- **結論**: 指摘0件（全件修正済み）

> 計画承認前レビューは review-flow.md の規定によりレビューサマリ生成は不要だが、本 Unit では verification record のレビュー履歴と整合させるため、追跡用に Set 0 として記録する。

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | クローズ判断が「3 フェーズの TOTAL 値が閾値以内か」のみで、Intent §成功基準の動作保証・#553 回帰防止・インデックス一意復帰を含まない弱い基準 | 修正済み（クローズ条件を 2 段階化: 段階 1 = 計測達成 + 段階 2 = Intent §成功基準項目達成。未達バックログも 5 カテゴリに構造化） | - |
| 2 | 高 | ベースライン参照が `git show v2.2.3:<path>` のタグ参照のみで、タグ差し替え・lightweight tag 揺れを防げない | 修正済み（`BASELINE_REF=56c64637...` を定数化し、`git rev-parse v2.2.3^{commit}` との一致確認を追加） | - |
| 3 | 中 | 計測対象ファイルリストの正本が計画書 / スクリプト / レポートで分散しており再現性の中核がズレ得る | 修正済み（スクリプト内 bash 配列を唯一の正本に統一、計画書とレポートは参考表示に降格） | - |
| 4 | 中 | v2.3.0 実測値の検証が「事前計測値と完全一致または ±10 tok 以内」で、決定論的なはずの計測に誤差許容を入れている | 修正済み（誤差許容を撤廃、検証 2 を「同一 ref 上の 2 回連続実行で完全一致」+ 検証 3「閾値判定」に分離） | - |
| 5 | 中 | boilerplate 削減確認が「定性的に確認」と曖昧で完了条件として弱い | 修正済み（4 パターン × 3 フェーズの applicability 表 + tok 比較で機械化、後に 2 軸化 + 補助項目化） | - |
| 6 | 高 | 旧方針の記述が新契約と矛盾する形で残存（measurement-report 正本扱い・git show v2.2.3 タグ参照・「計画書を真とする」等） | 修正済み（主な作業セクションと設計方針 1-3 を新契約「決定論性・正本=スクリプト・2 段階クローズ」に全面更新） | - |
| 7 | 中 | Intent 対照表の引用先 `unit_001_*_verification.md` が実在せず、Unit 001 のみ `_implementation.md` 命名 | 修正済み（Intent 対照表に実在パスを列挙、Unit 001 例外を明記） | - |
| 8 | 中 | boilerplate 完了条件「全パターン 1 件以上」が `operations/index.md` に `express` 分岐がなく成立しない | 修正済み（4 パターン × 3 フェーズ表に phase applicability 列を追加、Operations × `express` を `-` で適用外に） | - |
| 9 | 中 | `measurement-report.md` を正本扱いする記述が複数残存 | 修正済み（行 32 と行 215 の表記をスクリプト正本に統一） | - |
| 10 | 中 | 検証 5 の記述が「4 パターンすべて」となっており phase applicability 方針と矛盾 | 修正済み（applicability `○` のみ必須、Operations は `express` 除外を明記） | - |
| 11 | 低 | リスク節で Unit 001 の `_implementation.md` 例外が反映されていない | 修正済み（リスク節に Unit 001 のみ `_implementation.md` 例外を追記） | - |

---

## Set 1: 2026-04-10 (設計レビュー)

- **レビュー種別**: 設計レビュー（focus: architecture）
- **使用ツール**: codex (session: 019d749c-55e2-76e3-b45e-e460d34cfb2d)
- **反復回数**: 2
- **結論**: 指摘0件（全件修正済み）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | 段階 2 達成判定が「引用文の存在」のみで決まる契約となっており、失敗を示す引用でも段階 2 を通せる弱い判定 | 修正済み（IntentCriterionEvaluation に `expected_assertion` / `evidence_status` を追加し、`evidence_status=satisfied` のみ達成と見なす契約に変更。論理設計のユースケース 3 と NFR 「ガバナンス」も同期更新） | - |
| 2 | 中 | `MeasurementSession.phase_measurements` が「3 フェーズ分」と書かれていたが、`MeasurementReport` 集約と `MeasurementService.measure_all()` は 6 件前提で噛み合っていなかった | 修正済み（`baseline_measurements[3]` と `current_measurements[3]` の 2 つに分離し、合計 6 件の不変条件を明示。`pair_for(phase)` 振る舞いを追加） | - |
| 3 | 中 | boilerplate 検証ユースケース 4 が「12 セル全セルで `v2.3.0 ≤ v2.2.3`」となっており、計画書の applicability `-` セル N/A 契約と矛盾 | 修正済み（ユースケース 4 を「12 セル表示・applicability `○` の比較セルのみ判定対象・`-` セルは N/A 表示として判定対象外」に書き換え） | - |
| 4 | 低 | 集約名 `MeasurementReport` と集約ルート `MeasurementSession` が不一致 | 修正済み（集約名を `MeasurementSessionAggregate` にリネーム。`MeasurementReport` は派生成果物に降格し、`MeasurementReportSection` も派生成果物の値オブジェクトとして再分類） | - |

---

## Set 2: 2026-04-10 (コード生成後レビュー)

- **レビュー種別**: コード生成後レビュー（focus: code, security）
- **使用ツール**: codex (session: 019d749c-55e2-76e3-b45e-e460d34cfb2d)
- **反復回数**: 2
- **結論**: 指摘0件（全件修正済み）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `measurement-report.md` §8 動作保証基準の引用文が「同等記述」「各 verification.md」等の省略表現で監査不能。`expected_assertion` 充足の根拠が追えないまま全件 ✅ 判定している | 修正済み（§8 動作保証基準を 8 行に拡張し、各行に Unit 検証/実装記録の実在ファイル名 + 行番号 + 具体的引用を併記。`同等記述` のような省略表現を排除） | - |
| 2 | 中 | 計画書と measurement-report.md で boilerplate 補助項目方針が不整合。レポートは「クローズ非阻害」だが計画書の完了条件は「軸 1 全フェーズで `v2.3.0 ≤ v2.2.3`」を要求 | 修正済み（計画書 §boilerplate 削減状況の確認に「判定方針（非阻害）」セクションを追加し、軸 1 / 軸 2 ともに #519 クローズに影響しない補助項目であることを明文化） | - |
| 3 | 中 | 論理設計のレイヤー図と判定処理コンポーネント説明に旧 boilerplate 方針（grep -c × 4 patterns × 3 phases）が残存 | 修正済み（論理設計のレイヤー図を 2 軸モデルに更新、判定処理コンポーネントの責務記述も `expected_assertion` ベース + 2 軸 boilerplate 検証に同期） | - |
| 4 | 低 | `bin/measure-initial-load.sh` の終了コード契約が不完全。ヘルプは exit 1-4 のみ定義しているが measure_files() の Python 実行失敗・mkdir -p 失敗で raw exit 1 が漏れ得る | 修正済み（measure_files() 失敗を exit 5 に正規化、expand_baseline_files() の mkdir -p 失敗を exit 4 でカバー、ヘルプに exit 5 を追加） | - |

---

## Set 3: 2026-04-10 (統合レビュー)

- **レビュー種別**: 統合レビュー（focus: code）
- **使用ツール**: codex (session: 019d749c-55e2-76e3-b45e-e460d34cfb2d)
- **反復回数**: 2
- **結論**: 指摘0件（全件修正済み）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `measurement-report.md` §9 で「動作保証基準 3 項目」と要約しているが、§8 表は 8 行あり verification record も「8 項目」と記録しており件数不一致 | 修正済み（§9 を「動作保証基準 8 項目すべて達成（§8 動作保証基準テーブル参照）」に修正） | - |
| 2 | 中 | verification record の状態が「完了」だが、計画書の完了条件には #519 操作と CHANGELOG.md 更新が未実施 | 修正済み（状態を「実装・検証完了 / Unit 完了処理待ち」に変更し、Unit 完了処理ステップで「完了」に更新する旨を明記） | - |
| 3 | 低 | verification record のレビュー履歴に「計画レビュー」記録があるが、`006-review-summary.md` には設計レビューとコードレビューしか載っておらず追跡性が不足 | 修正済み（`006-review-summary.md` に Set 0「計画承認前レビュー」を追加し、計画レビュー全 4 反復・11 件の指摘対応を verification record と一致させた） | - |
