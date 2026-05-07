# Unit 001 計画: Operations §7 ステップ7「完了」更新タイミングをマージ前に統一

## 概要

`skills/aidlc/steps/operations/02-deploy.md` §7 の「ステップ完了時: progress.md でステップ7を「完了」に更新」（line 199）を、**§7.7 Git コミット時に main 反映**で確定するタイミング表現へ書き換える。あわせて `operations-release.md` §7.2〜§7.6 統合節 line 28 と §7.7 セクション line 51、`03-release.md` 完了時の確認 line 28-31、`04-completion.md` §4 マージ前完結ルール（line 476-491）、`templates/operations_progress_template.md` line 13 に同タイミングを通底させる。

これにより、AI エージェントが PR マージ後（§7.13 後）に `progress.md` を編集して「完了」化する経路をドキュメントレベルで構造的に消す（v2.5.3 で実害発生済の再発防止）。

> **解決候補**: Issue #656 では候補 1〜3（§7.7 / §7.8 / §7.12）が示されたが、Unit 001 責務記述（`story-artifacts/units/001-operations-step7-completion-timing.md` line 13-14）で **候補 1（§7.7 Git コミット時）** が確定済み。本計画は候補 1 の前提で進める。

### 「完了」と「PR準備完了」ラベルの関係【Round 1 指摘 #1 対応】

現行 docs では §7.6 における progress.md 更新を 2 種の表現で記述している:

- `02-deploy.md` line 17（状態ラベル定義）/ line 183（サブステップ列挙）: `PR準備完了`
- `operations-release.md` line 28（手順 SoT）: 「ステップ7を「完了」に更新し 7.7 のコミットに含める」
- `03-release.md` line 30（完了時の確認）: 「progress.md でステップ7が「完了」（= PR準備完了）」

`03-release.md` line 30 が示すように、現行運用では **「完了」 = 「PR準備完了」**（§7.6 で書き込む状態の同義表現）として扱われている。Unit 001 は本同義関係を **明示** することで、AI エージェントが「§7.6 で『完了』にする」「§7.7 でコミットして main 反映」「§7.13 後のマージ後追加更新は不要」と一意に判断できるようにする。状態ラベル一覧自体（5 値）の追加・削除は Unit 001 のスコープ外（境界に明記）であり、「PR準備完了」ラベル自体は現行通り残置する。

## 関連 Issue

- #656（[Backlog] Operations §7 ステップ7「完了」更新タイミングをマージ前に統一（マージ前完結契約整合））
- 関連: DR-001 / Unit 002 / #583 マージ前完結契約

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 規範（手順 SoT） | サブステップ列挙と各サブステップの責務記述、§7.6 「完了」更新の主タイミング表現 | `skills/aidlc/steps/operations/operations-release.md` §7.2〜§7.6 統合節 line 28 / §7.7 line 51 |
| 入口手順 | サブステップ番号の列挙とステップ7開始/完了時の状態遷移宣言 | `skills/aidlc/steps/operations/02-deploy.md` §7（line 183, 199） |
| 完了判定 | Operations Phase 完了基準としての「§7.6 で『完了』 = PR準備完了 / §7.7 で main 反映」整合 | `skills/aidlc/steps/operations/03-release.md` 完了時の確認 line 28-31 |
| 整合性ガード | マージ前完結契約とステップ7「完了」更新タイミングの一致記述（既存禁止項目の理由付け強化） | `skills/aidlc/steps/operations/04-completion.md` §4 マージ前完結ルール line 476-491 |
| テンプレート | ステップ7 行の推移経路コメント（v2.5.4 以降の新規サイクル向け） | `skills/aidlc/templates/operations_progress_template.md` line 13 |
| 履歴 | 実装進捗の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit01.md` |

**ドリフト防止策**:

- `operations-release.md` §7.2〜§7.6 統合節 line 28 を **手順 SoT** として確定する。`02-deploy.md` line 199 / `03-release.md` line 30 / `04-completion.md` §4 はそれぞれ「入口手順」「完了判定」「整合性ガード」の責務に閉じ、`operations-release.md` への参照リンクと「§7.7 Git コミット時に main 反映」のタイミング表現を共通化する。
- 各文書間の整合性は文言マッチ（`grep -n`）で検証する。行番号は改訂直前に再取得し、文言固定で編集箇所を特定する（行番号固定ではない）。

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/steps/operations/operations-release.md` | 改修（手順 SoT） | line 28 の前後と §7.7 line 51 にステップ7「完了」更新タイミング（§7.6 書き込み・§7.7 main 反映）とマージ後編集禁止を追記 |
| `skills/aidlc/steps/operations/02-deploy.md` | 改修（入口手順） | line 199 の「ステップ完了時」記述を §7.7 確定タイミング表現へ書き換え。line 183 のサブステップ列挙の §7.6 行に「『完了』(= PR準備完了) 更新」を補足 |
| `skills/aidlc/steps/operations/03-release.md` | 改修（完了判定） | line 28-31 を「ステップ7「完了」更新は §7.7 Git コミット時で main 反映済み」と明示。「(= PR準備完了)」併記は維持し、§7 サブステップ参照を追加【Round 1 指摘 #3 対応】 |
| `skills/aidlc/steps/operations/04-completion.md` | 改修（整合性ガード） | §4 マージ前完結ルール（line 476-491）の line 484 「**理由**」段落の延長として、ステップ7「完了」更新は §7.7 で main 反映済みであり、マージ後の `progress.md` 編集は二重更新となるため禁止である旨を追記【Round 1 指摘 #4 対応】 |
| `skills/aidlc/templates/operations_progress_template.md` | 改修（テンプレート） | line 13 のステップ7 行直後に推移経路を示す HTML コメントを追加 |
| `.aidlc/cycles/v2.5.4/history/construction_unit01.md` | 新規作成 | Unit 001 の進捗履歴（変更ファイル一覧 / レビュー round / 整合性検証結果） |

> 編集箇所の正確な文言・差分は **論理設計** で確定する（grep 検証クエリと併せて定義）。本計画では編集対象ファイルと SoT 構造のみを宣言する【Round 1 指摘 #7 対応 / 計画文書冗長性削減】。

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_001_operations_step7_completion_timing_domain_model.md`）: ステップ7「完了」状態のドメイン語彙（状態ラベル / 「完了」と「PR準備完了」の同義関係 / 遷移点 / マージ前完結契約との関係 / 各文書層の責務境界）を整理
- 論理設計（`design-artifacts/logical-designs/unit_001_operations_step7_completion_timing_logical_design.md`）: 各変更対象ファイルの編集箇所（行番号 + 既存文言 + 改訂後文言）を確定し、grep ベースの整合性検証クエリと markdownlint 通過条件を定義

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `operations-release.md` line 28 / line 51 改訂（手順 SoT を先に確定）
2. `02-deploy.md` line 199 / line 183 改訂（入口手順を SoT へ整合）
3. `03-release.md` line 28-31 改訂（完了判定を SoT へ整合）
4. `04-completion.md` §4 マージ前完結ルール改訂（整合性ガードを追加）
5. `templates/operations_progress_template.md` line 13 改訂（テンプレートに推移経路コメント追加）
6. 整合性検証（論理設計で確定した grep クエリ）+ markdownlint 実行
7. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
8. 履歴記録の補足追加（変更ファイル / レビュー round / 検証結果）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `operations-release.md` §7.2〜§7.6 統合節の見出しが将来分割される | 編集箇所は line 28（progress.md 更新行）の文言を起点とする文言固定方式。grep 検証クエリは「ステップ7「完了」更新は §7.7」「マージ前完結契約の成立点」を対象とすることで見出し名変更に追従可能 |
| 論理設計で確定した行番号が後続コミットでズレる | 改訂直前に `grep -n` で行番号を再取得し、文言マッチで編集箇所を特定する |
| マージ前完結契約のルール本体（マージ後改変禁止）の解釈変更 | 本 Unit のスコープ外（境界に明記）。本 Unit はステップ7「完了」更新タイミングの一意化のみを行う |
| markdownlint 失敗 | 該当ルール（MD013 line-length / MD031 等）に応じて改行・コードフェンス周辺を調整。lint 通過後に AI レビューへ進む |
| `scripts/` / `bats` への波及 | 本 Unit は docs / template 改訂のみ。`scripts/` 内挙動は変えないため bats 追従は不要。実装直後に `git diff --name-only` で `skills/aidlc/scripts/**` / `bin/tests/**` / `tests/**` が含まれないことを確認 |
| 既存サイクル成果物（v2.5.3 以前の `operations/progress.md`）への遡及書き換え | 禁止。template / docs のみ改訂。実装直後に `git diff --name-only -- ".aidlc/cycles/**"` が空（または `v2.5.4/history/` のみ）であることを確認【Round 1 指摘 #6 対応】 |

## NFR

- **パフォーマンス**: docs / template 改訂のみのため、ランタイム性能影響なし
- **セキュリティ**: 機密情報の取り扱いに変更なし
- **後方互換**: 既存 Operations Phase の progress.md / history / `operations-release.sh` の挙動を破壊しない（記述変更のみで構造変更なし）。`scripts/write-history.sh` の exit 3 ガード（`completion_gate_ready=true` AND PR `MERGED`）は §7.7 で `completion_gate_ready=true` が main 反映される現行 invariant に依存しており、本 Unit の改訂はその invariant を強化（明示化）するもので、ガード仕様との論理整合は維持される（完了条件チェックリストで明示確認）

## 完了条件チェックリスト

### 文書整合（grep 検証ベース）

- [x] `operations-release.md` §7.2〜§7.6 統合節 line 28 周辺に「ステップ7「完了」更新は §7.6 で書き込み・§7.7 で main 反映」「マージ後編集禁止（DR-001 整合）」の旨が明示されている
- [x] `operations-release.md` §7.7 セクション冒頭（line 51 周辺）に「本コミットでステップ7「完了」更新が main に反映される（マージ前完結契約の成立点）」が 1 文追記されている
- [x] `02-deploy.md` line 199 が「ステップ完了時（§7.7 Git コミット時に確定）」へ書き換えられ、SoT（`operations-release.md`）への参照リンクとマージ後編集禁止の補足を含む
- [x] `02-deploy.md` line 183 のサブステップ列挙の §7.6 行説明文に「『完了』(= PR準備完了) 更新」が補足されている
- [x] `03-release.md` line 28-31 に「ステップ7「完了」更新は §7.7 Git コミット時で main 反映済み」「(= PR準備完了)」併記の整合と、§7 サブステップへの参照が含まれている
- [x] `04-completion.md` §4 line 484 「**理由**」段落の延長として「ステップ7「完了」更新は §7.7 で main 反映済みのため、マージ後の `progress.md` 編集は二重更新となり禁止」が追記されている
- [x] `templates/operations_progress_template.md` line 13 直後に HTML コメント（`§7.7 Git コミット時に「完了」更新` / `02-deploy.md §7 / operations-release.md §7.6-§7.7 参照` / `DR-001 / Unit 002 / #583`）が追加されている

### 既存ガード仕様との論理整合【Round 1 指摘 #5 対応】

- [x] `scripts/write-history.sh` の exit 3 ガード仕様（`04-completion.md` line 486-491、`completion_gate_ready=true` AND PR `MERGED`）と、本 Unit の新文言「ステップ7「完了」更新は §7.7 Git コミット時に main 反映済み」が論理整合することを確認（§7.7 で `completion_gate_ready=true` が main 反映される invariant の維持により、PR マージ後の `write-history --phase operations` 呼び出しが exit 3 を引く因果連鎖が成立）
- [x] `scripts/write-history.sh` 自体への変更は行っていない（`git diff --name-only` で確認）

### スコープ保護【Round 1 指摘 #6 対応】

- [x] v2.5.3 以前の `.aidlc/cycles/*/operations/progress.md` への遡及編集が含まれていない（`git diff --name-only -- ".aidlc/cycles/**"` の出力が `.aidlc/cycles/v2.5.4/history/construction_unit01.md` および `.aidlc/cycles/v2.5.4/plans/unit-001-plan.md` 等 v2.5.4 サイクルアーティファクトのみであることを確認）
- [x] `scripts/` 配下に変更を加えていない（`git diff --name-only -- "skills/aidlc/scripts/**"` が空）
- [x] `bin/tests/` / `tests/` 配下に変更を加えていない（`git diff --name-only -- "bin/tests/**" "tests/**"` が空）
- [x] `progress.md` 状態ラベル一覧（5 値）の追加・削除を行っていない（`templates/operations_progress_template.md` の固定スロット構造変更なし、`02-deploy.md` line 11-17 のラベルテーブル行数不変を `grep -c "^|" -- ファイル` 等で確認）

### 履歴

- [x] `.aidlc/cycles/v2.5.4/history/construction_unit01.md` が新規作成され、変更ファイル一覧 / レビュー round / 整合性検証結果が追記されている

### 品質ゲート

- [x] 整合性検証 grep（論理設計で確定したクエリ）が全て pass する
- [x] markdownlint（`markdown_lint=true` 設定）が変更対象 5 ファイル全てで pass する
- [x] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（最後 2 round 連続で指摘ゼロまたは defer 化）を満たす
- [x] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み

## 見積もり

- 設計フェーズ: 0.5 日（domain model / logical design / 編集箇所の確定）
- 実装フェーズ: 0.5 日（docs 改訂 5 ファイル / 整合性検証 / lint / レビュー）
- 合計: **1 日**（Unit 定義の見積もりと一致。Round 1 指摘 #3 で対象ファイル 1 件追加（`03-release.md`）したが、編集量は line 28-31 の最小改訂のため見積もり影響なし）
