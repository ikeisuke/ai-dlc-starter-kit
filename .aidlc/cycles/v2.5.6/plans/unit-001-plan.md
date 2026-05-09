# Unit 001 計画: cycle/* PR の 3 Phase 完了 CI ガード追加

## 概要

cycle/* ブランチの PR マージ前に Inception / Construction / Operations 3 Phase の完了状態を CI で自動検証するガードを追加する。`bin/check-cycle-phase-completion.sh <cycle>` を新設し、`pull_request` workflow で `head_ref` が `cycle/*` のときに本スクリプトを実行する。Branch protection / Repository Ruleset での必須化手順は doc 化し、Operations Phase 完了直前に適用する（A-2 適用責務）。

### CLI 入力契約（Round 2 codex 指摘 #1 対応）

CLI は **bare cycle ID** のみを受け付ける（例: `v2.5.6` / `waf/v1.0.0`）。`cycle/` prefix を含む branch 名はそのまま渡せない。これは既存 `validate_cycle()` の契約に準拠する（内部で `cycle/${cycle}` を `git check-ref-format` に渡すため、引数は bare ID 想定）。

- workflow 側: `${GITHUB_HEAD_REF#cycle/}` で `cycle/` prefix を剥がして CLI に渡す
- ローカル dry-run: ユーザーが直接 `bin/check-cycle-phase-completion.sh v2.5.6` のように bare ID で起動
- **`cycle/` prefix の明示的拒否（Round 4 codex 指摘 #1 対応）**: 既存 `validate_cycle()` は 1〜2 セグメントを許容するため `cycle/v2.5.6` のような「`cycle/` prefix が剥がれていない値」も形式上は受理してしまう（実体は `.aidlc/cycles/cycle/v2.5.6/` を探しに行き cycle-not-found となるが、誤渡しを早期検知できない）。本 CLI では bare ID 契約を厳格化するため、**`validate_cycle()` 呼び出しの前段に「先頭が `cycle/` で始まる値を reject する分岐」を設ける**。違反時は exit 2 + `error:cycle-prefix-not-allowed:<value>:hint=strip-cycle-prefix-before-passing`。テストケース (h) として後述

## 関連 Issue

- #672（cycle/* ブランチで Inception / Construction / Operations Phase 未完了時のマージブロック）

## スコープ境界

| 範囲 | 含む / 含まない |
|------|----------------|
| `bin/check-cycle-phase-completion.sh <cycle>` 新規作成（CLI + `--help`） | 含む |
| 3 Phase 完了判定関数（Inception / Construction / Operations） | 含む |
| Operations 固定スロット 3 項目（`release_gate_ready` / `completion_gate_ready` / `pr_number`）の値検証 + `--pr-number` 指定時のみ `pr_number` 一致検証 | 含む |
| `.github/workflows/cycle-phase-completion-check.yml` 新設（`pull_request` イベント、`head_ref` が `cycle/*` のときのみ実行） | 含む |
| ローカル dry-run コマンド提供（CLI 単独実行で十分。`--help` で使用例提示） | 含む |
| bats テスト 11 ケース（completion / Inception 未完 / Construction 未完 / Operations スロット未充足 / pr_number 不一致 / invalid cycle / `--pr-number` 未指定 + `pr_number` 行欠損 / `cycle/` prefix 拒否 / Unit 定義 0 件異常 / step7 PR準備完了正常系 / grammar v1 詳細仕様 fixture） | 含む |
| Repository Ruleset / Branch protection 必須化手順 doc（`docs/` 配下、`gh api` スクリプト化と UI 手順併記） | 含む |
| `migration-tests.yml` の `PATHS_REGEX` / 実行行への新規 bats / スクリプト登録 | 含む（CI 実行エントリへの接続） |
| Repository Ruleset の実適用作業 | 含まない（A-2、Operations Phase 完了直前で実施。本 Unit はスクリプト・workflow・doc のみ） |
| cycle/* 以外のブランチパターン（chore/* / fix/* 等）への CI ガード拡張 | 含まない |
| 既存 workflow（pr-check / migration-tests / auto-tag / skill-reference-check）の改修 | 含まない（PATHS_REGEX 追加除く） |

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 実装 SoT（CLI 判定オーケストレーション） | 3 Phase 完了判定の **オーケストレーション**（cycle 名検証は共有ヘルパー、固定スロット grammar は文書 SoT、Unit 実装状態抽出は単純パターン化）。CLI は判定の組み立てとエラーメッセージ整形に責務を限定 | `bin/check-cycle-phase-completion.sh` |
| 共有ヘルパー（cycle 名検証） | 既存の `validate_cycle()`（`skills/aidlc/scripts/lib/validate.sh:39`）を **再利用**。独自正規表現は使わない（多セグメント `cycle/waf/v1.0.0` 等の正当性を維持） | `skills/aidlc/scripts/lib/validate.sh`（既存、再利用のみ） |
| 固定スロット grammar SoT | grammar v1（`<!-- fixed-slot-grammar: v1 -->` 直下の `release_gate_ready=` / `completion_gate_ready=` / `pr_number=` 形式）の正規定義 | `skills/aidlc/steps/common/phase-recovery-spec.md §5.3.5`（既存、参照のみ） |
| CI 実行 SoT | `pull_request` イベントで `head_ref` ガード判定 → CLI 起動 | `.github/workflows/cycle-phase-completion-check.yml` |
| テスト SoT | bats 受け入れテスト 11 ケース | `tests/check-cycle-phase-completion.bats` |
| 適用手順 SoT | Repository Ruleset 必須化手順（gh api / UI 両論併記） | `docs/cycle-phase-completion-check-ruleset.md` |
| 履歴 | 実装進捗・レビュー round・検証結果記録 | `.aidlc/cycles/v2.5.6/history/construction_unit01.md` |
| CI wiring | bats を migration-tests CI で実行する登録 | `.github/workflows/migration-tests.yml` |

### Phase 1 で固定する責務境界（中指摘 #4 対応）

設計フェーズで以下を明文化し、CLI が「判定オーケストレーション」を超えないよう SoT を一箇所に固定する:

- **cycle 名検証**: `validate_cycle()` を `source` して呼び出す（独自正規表現禁止）。invalid 時は `error:invalid-cycle:<value>` を stdout 出力 + exit 2
- **Operations 固定スロット読み取り**: `skills/aidlc/steps/common/phase-recovery-spec.md §5.3.5` の grammar に従い **awk 単一プロセス**（`parse_fixed_slots()` 関数）で `release_gate_ready` / `completion_gate_ready` / `pr_number` を抽出。grammar v1 マーカー必須・コメント除去・カンマ区切り併記対応・重複キー first-win・未知キー無視を実装。`grep -E` 単独では grammar 詳細仕様を満たせないため使わない。`dasel` には依存しない
- **Inception progress.md の状態抽出**: `## ステップ一覧` 配下の `| ステップ | 状態 |` テーブルから「完了」「スキップ」以外の状態が 1 つでもあれば未完了
- **Construction units/*.md の状態抽出**: 判定対象は **`.aidlc/cycles/{cycle}/story-artifacts/units/*.md`**（Unit 定義ファイル群）に限定する。`construction/units/` 配下の `*-review-summary.md` / `*_implementation.md` 等の派生ファイルは判定対象外（これらは `## 実装状態` セクションを持たない）。各 Unit 定義ファイルの `## 実装状態` セクション内 `- **状態**: <値>` 行から「完了」「取り下げ」以外なら未完了
- **Unit 定義ファイル 0 件時の扱い（Round 4 codex 指摘 #2 対応）**: `story-artifacts/units/*.md` が **0 件** の場合は「Construction 完了」ではなく異常として扱う（Inception で Unit 定義された前提で Construction が走るため、0 件は構造異常）。exit 1 + `construction:incomplete:reason=no_units_defined`。テストケース (i) として後述
- **0 件判定の実装方式（Round 5 codex 指摘 #1 対応）**: bash 3.2 互換を維持するため、`*.md` グロブの `nullglob` 未指定時の挙動（リテラル残留）に依存しない方式で実装する。**`find "{units_dir}" -maxdepth 1 -type f -name '*.md' -print -quit` の出力有無で判定** することを Phase 1 論理設計で固定する（`-quit` で 1 件見つかった時点で終了、0 件なら空出力）。代替として bash 配列 + `[[ -e "${files[0]}" ]]` も許容するが、`find` ベースを推奨する

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `bin/check-cycle-phase-completion.sh` | 新規作成 | 3 Phase 完了検証 CLI。`bin/check-cycle-phase-completion.sh <cycle> [--pr-number N]` |
| `.github/workflows/cycle-phase-completion-check.yml` | 新規作成 | `pull_request` で `startsWith(head_ref, 'cycle/')` のときに CLI 実行 |
| `tests/check-cycle-phase-completion.bats` | 新規作成 | 11 ケース（上記スコープ参照、step7 PR準備完了正常系 / grammar v1 詳細仕様 fixture を含む） |
| `tests/fixtures/cycle-phase-completion/` | 新規作成 | 各テストケースの fixture cycle ディレクトリ群 |
| `docs/cycle-phase-completion-check-ruleset.md` | 新規作成 | Branch protection / Repository Ruleset 必須化手順（`gh api` スクリプト化と UI 操作両論併記、適用証跡保存規約含む） |
| `.github/workflows/migration-tests.yml` | 改修（CI wiring） | (1) `bats` 実行行に `tests/check-cycle-phase-completion.bats` 追加 / (2) `PATHS_REGEX` に `tests/check-cycle-phase-completion\.bats`、`bin/check-cycle-phase-completion\.sh`、`tests/fixtures/cycle-phase-completion/.+`、`\.github/workflows/cycle-phase-completion-check\.yml` を追加（fixture のみ変更でも CI が起動する慣習に整合） |
| `.aidlc/cycles/v2.5.6/history/construction_unit01.md` | 新規作成 | Unit 001 の進捗履歴 |

> 編集箇所の正確な diff（CLI 関数構造、エラーメッセージフォーマット、bats fixture 配置）は **論理設計** で確定する。

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 はスキップしない。設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_001_cycle_phase_completion_check_domain_model.md`）: 検証対象ドメインの語彙整理
  - cycle / Phase / progress.md / 固定スロット / pr_number / 完了状態 / 検証結果 / エラー分類
- 論理設計（`design-artifacts/logical-designs/unit_001_cycle_phase_completion_check_logical_design.md`）:
  - CLI 引数仕様（`<cycle>` 必須、`--pr-number N` オプション、`--help`）
  - 3 Phase 検証関数の擬似コード（入力パス / 期待状態 / 失敗時メッセージ）
  - progress.md パース手法選択（dasel TOML 抽出 vs awk 直接パース vs grep）と既存 helper 流用判断
  - workflow YAML 構造（`if: startsWith(head_ref, 'cycle/')`、`pr_number` 渡し方）
  - bats 11 ケースの入出力定義（fixture 構造、期待 stdout / exit code）
  - Repository Ruleset 適用手順 doc の章立て

設計レビュー（`reviewing-construction-design`）を 5R 内で実施。

### Phase 2（実装）

実装順序:

1. `bin/check-cycle-phase-completion.sh` を作成し、3 Phase 検証関数を実装
2. `tests/fixtures/cycle-phase-completion/` の fixture cycle ディレクトリ群を作成
3. `tests/check-cycle-phase-completion.bats` に 11 ケース追加
4. ローカル bats 実行（regression 確認 + 新規 11 ケース PASS）
5. `.github/workflows/cycle-phase-completion-check.yml` 新設
6. `.github/workflows/migration-tests.yml` に CI wiring 追加
7. `docs/cycle-phase-completion-check-ruleset.md` 作成
8. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
9. 履歴記録（変更ファイル / レビュー round / 検証結果）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 指定 cycle が `validate_cycle()` で invalid | 終了コード 2 + `error:invalid-cycle:<value>` |
| 指定 cycle が存在しない（valid だが directory なし） | 終了コード 2 + `error:cycle-not-found:.aidlc/cycles/<cycle>` |
| `inception/progress.md` が存在しない | 終了コード 1 + `inception:incomplete:reason=progress_md_missing` 形式 |
| `operations/progress.md` の固定スロット行そのものが欠損（`release_gate_ready=` 等の行が見つからない） | 終了コード 1 + `operations:incomplete:reason=fixed_slot_missing:slot=<name>` |
| `operations/progress.md` の固定スロット値が満たされていない（`release_gate_ready=false` 等） | 終了コード 1 + `operations:incomplete:reason=fixed_slot_unmet:slot=<name>:expected=true:actual=<value>` |
| `pr_number` 不一致（`--pr-number` 指定時） | 終了コード 1 + `operations:incomplete:reason=pr_number_mismatch:expected=<N>:actual=<M>` |
| `--pr-number` 未指定（ローカル dry-run） | `pr_number` 一致検証はスキップし、それ以外（progress.md ステップ7・固定スロット 3 行の存在 + true 値）は **CI と同等判定**を実施 |
| BSD/GNU sed/awk 差 | POSIX awk のみ使用、sed は `-i` 不使用 |
| PR head_ref に shell metacharacter（注入攻撃） | workflow 側で `${GITHUB_HEAD_REF}` を quote、シェルでは `"$1"` で受ける。eval 不使用。さらに `validate_cycle()` で形式検証 |
| `dasel` 不在環境 | progress.md パースは `awk` 直接解析（依存追加なし） |
| `head_ref` が `cycle/*` 以外 | workflow 側 job 条件 `if: startsWith(github.head_ref, 'cycle/')` で job 自体を skip（CLI は呼ばれない） |

## NFR

- **パフォーマンス**: CI ジョブ実行時間 30 秒以内（軽量チェックのみ、外部 API 呼び出しなし）
- **セキュリティ**: PR `head_ref` 由来の cycle 名は **既存の `validate_cycle()` ヘルパー（`skills/aidlc/scripts/lib/validate.sh:39`）を再利用**してサニタイズ。1〜2 セグメント・パストラバーサル拒否・git ref 形式適合・`.lock` 拒否を統一的に検証。独自正規表現は使わず（多セグメント `cycle/waf/v1.0.0` 等の正当値を維持）。eval / 動的 source 不使用
- **可用性**: 既存 workflow（pr-check / migration-tests / auto-tag / skill-reference-check）と独立、コンフリクトなし
- **互換性**: bash 3.2+（macOS デフォルト）と bash 5.x（GitHub Actions ubuntu-latest）両対応

## 完了条件チェックリスト

### 機能整合

- [x] `bin/check-cycle-phase-completion.sh <cycle>` が新規作成され `--help` を持つ
- [x] Inception 完了判定: `inception/progress.md` の全ステップが「完了」or「スキップ」
- [x] Construction 完了判定: `story-artifacts/units/*.md`（Unit 定義ファイル）全件の「実装状態」が「完了」or「取り下げ」（`construction/units/` 配下の派生ファイルは対象外）
- [x] Operations 完了判定: `operations/progress.md` ステップ7行存在 + ステップ7状態が「完了」または「PR準備完了」（SoT: `operations-release.md §7.6` 同義）+ 固定スロット 3 項目（`release_gate_ready=true` / `completion_gate_ready=true` / `pr_number=<N>` の存在と値）。**完了判定の実体は固定スロット 3 項目で担保**。`--pr-number` 指定時のみ `pr_number` の値一致を追加検証
- [x] `--pr-number N` オプションで PR 番号一致検証可能（CI で `${{ github.event.pull_request.number }}` を渡す）
- [x] `--pr-number` 未指定時は **`pr_number` の値一致検証のみスキップ**し、それ以外（progress.md ステップ7「完了」、固定スロット 3 行の存在、`release_gate_ready=true` / `completion_gate_ready=true`、`pr_number=<N>` 形式の存在）は CI と同等判定を実施（ローカル dry-run）
- [x] CI 失敗時のエラーメッセージで「どの phase / どのファイル / どの欠損か」が特定できる
- [x] `.github/workflows/cycle-phase-completion-check.yml` が `pull_request` イベントで `head_ref` が `cycle/*` のときのみ実行する

### テスト

- [x] `tests/check-cycle-phase-completion.bats` に 11 ケース追加され PASS する:
  - (a) completion: 3 Phase 全完了 → exit 0
  - (b) Inception 未完: progress.md 一部ステップが「未完了」→ exit 1, `inception:incomplete:...`
  - (c) Construction 未完: units/*.md の一つが「未着手」→ exit 1, `construction:incomplete:...`
  - (d) Operations スロット未充足: `release_gate_ready=false` → exit 1, `operations:incomplete:reason=fixed_slot_unmet:slot=release_gate_ready:expected=true:actual=false`
  - (e) pr_number 不一致: `--pr-number 999` を指定（progress.md は `pr_number=668`） → exit 1, `operations:incomplete:reason=pr_number_mismatch:expected=999:actual=668`
  - (f) invalid cycle: `validate_cycle()` で reject される値（例: `..`、空文字、`UPPER`） → exit 2, `error:invalid-cycle:<value>`
  - (g) `--pr-number` 未指定 + `pr_number` 行欠損: `--pr-number` を渡さず progress.md から `pr_number=<N>` 行を削除した fixture → exit 1, `operations:incomplete:reason=fixed_slot_missing:slot=pr_number`（Round 2 で追加した「未指定時でも `pr_number` 行存在は必須」分岐の直接検証）
  - (h) `cycle/` prefix 拒否: 引数として `cycle/v2.5.6` を渡す → exit 2, `error:cycle-prefix-not-allowed:cycle/v2.5.6:hint=strip-cycle-prefix-before-passing`（Round 4 codex 指摘 #1 対応、bare ID 契約の強制）
  - (i) Unit 定義 0 件: `story-artifacts/units/` ディレクトリが空（または `*.md` ファイルが 1 件も存在しない）fixture → exit 1, `construction:incomplete:reason=no_units_defined`（Round 4 codex 指摘 #2 対応、構造異常検知）
  - (j) ステップ7状態が「PR準備完了」: progress.md ステップ7行が「PR準備完了」状態で完了として通る fixture → exit 0（設計レビュー Round 1 高指摘 #1 対応の回帰防止）
  - (k) 固定スロット grammar v1 詳細: 1 行内カンマ区切り併記 + 行内 `#` コメント + 重複キー first-win + 未知キーが含まれる progress.md fixture でも 3 項目が正しく抽出される → exit 0（設計レビュー Round 1 高指摘 #2 + Round 2 中指摘 #1 対応の回帰防止）
- [x] 既存 BATS シナリオ（migration-tests workflow 配下）が引き続き PASS（regression なし）

### Workflow 例外パス検証（中指摘 #3 対応）

- [x] `.github/workflows/cycle-phase-completion-check.yml` の job レベル条件 `if: startsWith(github.head_ref, 'cycle/')` を確認し、`chore/*` / `fix/*` / `feature/*` の head_ref では job がスキップされる仕様であることを doc / コメントで明記
- [x] PR テスト時に「`cycle/*` 以外の head_ref で当該 workflow が `skipped` 表示になる」ことを Phase 2 検証で確認（手元の dry-run または draft PR を `cycle/*` 以外のブランチ名で立てて目視確認、もしくは `act` で擬似 event 実行）

### CI 実行エントリへの接続

- [x] `.github/workflows/migration-tests.yml` の `bats` 実行コマンドに `tests/check-cycle-phase-completion.bats` が追加されている
- [x] `migration-tests.yml` の `PATHS_REGEX` に以下 4 パターンが追加されている:
  - `tests/check-cycle-phase-completion\.bats`
  - `bin/check-cycle-phase-completion\.sh`
  - `tests/fixtures/cycle-phase-completion/.+`
  - `\.github/workflows/cycle-phase-completion-check\.yml`
- [x] fixture のみ変更した PR で `migration-tests` が起動することを Phase 2 検証で確認
- [x] PR 差分が上記いずれかを含む状態で `migration-tests` workflow がトリガされ、新規 11 ケースを含む全シナリオが PASS することを Phase 2 の検証で確認

### ドキュメント

- [x] `docs/cycle-phase-completion-check-ruleset.md` に以下が含まれる:
  - Repository Ruleset / Branch protection 必須化手順
  - `gh api` REST/GraphQL スクリプト化サンプル
  - GitHub UI 操作手順（スクリーンショット参照placeholderでも可）
  - 適用証跡（設定 JSON / スクリーンショット）の保存先規約
  - 暫定完了経路（A-2 暫定: follow-up Issue 起票 + 適用予定マイルストーン明記）の言及

### 履歴

- [x] `.aidlc/cycles/v2.5.6/history/construction_unit01.md` が新規作成され、変更ファイル一覧 / レビュー round / 検証結果が含まれる

### 品質ゲート

- [x] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（`is_completed()` 単一仕様: 1R clean 特例または直近 round clean）を満たす
- [x] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み
- [x] markdownlint（`markdown_lint=true`）が変更対象 markdown ファイル（plan / domain model / logical design / doc / history）で pass する
- [x] shellcheck で `bin/check-cycle-phase-completion.sh` が clean（warning も含む）

### 適用責務（A-2、本 Unit では未完了で OK）

- [x] Repository Ruleset / Branch protection 必須化の実適用は Operations Phase 完了直前に実施する旨を Unit 定義の「実装状態」セクションに明記
- [x] 暫定完了経路を取った場合の follow-up Issue 起票テンプレを doc に含める

## 見積もり

- 設計フェーズ: 0.2 日（domain model / logical design / 共有ヘルパー再利用範囲確定 / workflow 設計）
- 実装フェーズ: 0.6 日（CLI + workflow + bats fixture/11 ケース + doc + CI wiring + 3 段レビュー + lint/shellcheck + Codex review）
- 合計: **0.8 日**（Round 1 codex 指摘 #6 を受け再見積。Unit 定義の見積もり「中、0.5〜1 日」に収まる範囲で 0.6 → 0.8 に上振れ）
