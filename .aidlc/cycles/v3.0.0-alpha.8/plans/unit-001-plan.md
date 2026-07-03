# Unit 001 実装計画: doctor `[phase]` / `[trace]` 領域実装 + 契約テスト

## 対象 Unit

- **Unit**: 001-doctor-phase-trace-areas
- **関連 Issue**: #741（Epic: #736 / Phase 6 必須 follow-up）
- **depth_level**: standard（Phase 1 設計あり）
- **実装優先度**: High / 見積もり: 中

## 目的

v3 診断コマンド `doctor`（`skills/aidlc-v3/scripts/doctor.sh`）に `[phase]`（フェーズ導出の整合診断）と `[trace]`（design 必須 work item の design ファイル存在診断）の 2 領域を追加し、shallow 9 領域から完全 11 領域へ拡張する。read-only / 自動修正なしを維持する。契約テスト（`tests/test-doctor.sh`）を 11 領域化する。

## 編集対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-v3/scripts/doctor.sh` | `diagnose_phase` / `diagnose_trace` 追加、順序実行ブロックへ組込、wrap 契約コメント追記、領域カウント「9 領域」→「11 領域」（3 / 5-7 / 355 行目周辺） |
| `skills/aidlc-v3/scripts/tests/test-doctor.sh` | `[phase]` 各導出ケース + 異常系 WARN、`[trace]` 各ケース、「全領域 OK 正常系」を 11 領域化 |

> SoT ドキュメント（`steps/doctor.md` / `docs/v3/workflow.md` / `docs/v3-renewal-plan.md`）反映は **Unit 002 の責務**。本 Unit は `doctor.sh` ヘッダコメント内のカウント・wrap 契約コメントのみ更新する。

## 実装方針（設計フェーズで詳細化）

### `[phase]` 領域（`diagnose_phase`）

- `data-model.md §5.1` の first-match 導出（complete → define → develop → release 可能）を code 化。
- 前段ゲート: `STATE_PRESENT==0`（state.json 不在）→ define フォールバック。既存慣習に従い state 依存領域として扱う。さらに `WORK_ITEMS_VALID==0`（work-items が ERROR で invalid、レビュー#3 反映）→ SKIP/WARN（壊れた入力で導出しない）。
- 入力取得: `state-read.sh` で `define_completed` / `release.merge_approved` / **`release.pr_number`**（レビュー#1 反映）を取得。work item の `status` は `lib/frontmatter.sh` を source し `fm_scalar` で取得（新規 grep/sed 禁止規約遵守）。
- `complete` 導出条件（レビュー#1 で精緻化）: `release.merge_approved=true` **かつ** `release.pr_number` 非 null **かつ** `gh pr view <pr_number> --json merged,state`（read-only）で `merged=true` 確認成功時のみ。`gh pr list`（open 固定）では merged PR を拾えないため、対象 PR は必ず `pr_number` で一意特定する。
- 異常系 WARN 分岐:
  - `merge_approved=true` ×（`pr_number=null` / gh 不可 / PR 未 merged）→ complete 非導出 + フォールバック（release 可能 or 安全側）+ WARN。
  - `define_completed=false` × `done` work item 矛盾 → 安全側導出（define 継続側）+ WARN（`data-model.md §6` 整合）。
- 出力: `report phase <severity> <detail>`（導出フェーズと根拠を detail に記載）。

### `[trace]` 領域（`diagnose_trace`）

- `data-model.md §8` の size×depth_level マトリクスで design 要否を判定。
- `depth_level` は `read-config.sh rules.depth_level.level`（取得不能時 standard フォールバック）。取得成功しても enum（`minimal`/`standard`/`comprehensive`）外の値の場合は standard フォールバック + WARN 併記（レビュー#2 反映 / `data-model.md §6` 安全側原則）。フル enum バリデーション機構の新設はスコープ外（config 値検証の第一義的責務は `[config]` 領域）。`size` は work item frontmatter（`fm_scalar`）。
- design 必須 work item に対応する `designs/<id>-<slug>.md` の存在を確認。
- 欠落 / 不正組み合わせ（`risky × minimal`）は WARN（exit 0 維持）。
- 前段ゲート: state なし / cycle dir 未解決 / work-items 不在 → SKIP。さらに `WORK_ITEMS_VALID==0`（work-items invalid、レビュー#3 反映）→ SKIP/WARN。

### 共通

- 既存 wrap パターン（exit code / stdout prefix を severity に写像）を踏襲。
- `report()` 契約（`printf '%-14s%-6s%s'`）厳守。`[phase]`（7 文字）/ `[trace]`（7 文字）は既存固定幅に収まる。
- 総合 exit code 集約は既存 2 フラグ（`HAS_UNDIAGNOSABLE` > `HAS_ERROR` > OK）を流用。WARN は exit 0、診断不能のみ exit 2。
- 領域間ゲート（レビュー#3 反映）: `diagnose_work_items` に結果伝播グローバル変数 `WORK_ITEMS_VALID`（既存 `STATE_PRESENT` / `CYCLE_DIR` / `GH_AVAILABLE` と同パターン）を追加し、ERROR（rc1/rc2）時に invalid フラグを立てる。`[phase]` / `[trace]` は前段でこれを参照する。
- 挿入位置: `diagnose_work_items` の後（`CYCLE_DIR` / `STATE_PRESENT` / `WORK_ITEMS_VALID` 解決済み）。

## 完了条件チェックリスト

Unit 定義「責務」セクション + Issue #741 受け入れ基準より抽出:

- [ ] `doctor.sh` に `diagnose_phase` を追加し、`§5.1` first-match 導出（define / develop / release 可能 / complete）を実装、導出フェーズと根拠を `report phase` で出力
- [ ] `complete` 導出は `merge_approved=true` **かつ** `pr_number` 非 null **かつ** `gh pr view <pr_number> --json merged,state` で merged=true 確認成功時のみ（レビュー#1）。入力取得に `release.pr_number` を含める
- [ ] `[phase]` 異常系 WARN 分岐（`merge_approved=true` × pr_number=null/gh 不可/未 merged → complete 非導出 + fallback + WARN、`define_completed=false` × done 矛盾 → 安全側導出 + WARN）を実装
- [ ] `diagnose_work_items` に `WORK_ITEMS_VALID` グローバル変数を追加し ERROR 時に invalid フラグを立てる。`[phase]` / `[trace]` の前段ゲートで参照し invalid 時は SKIP/WARN（レビュー#3）
- [ ] `doctor.sh` に `diagnose_trace` を追加し、`§8` size×depth_level マトリクスで design 要否判定 + `designs/<id>-<slug>.md` 存在確認、欠落/`risky × minimal` は WARN（exit 0）
- [ ] `[trace]` で `depth_level` enum 外値は standard フォールバック + WARN（レビュー#2 / フル enum 検証はスコープ外）
- [ ] 両領域を順序実行ブロックへ組込み、wrap 契約コメント・領域カウント（9→11）を更新
- [ ] 入力取得は既存スクリプト（`state-read.sh` / 共有パーサ `fm_scalar`）+ `read-config.sh`（depth_level）を再利用、新規パース禁止規約遵守
- [ ] `report()` 固定幅契約を厳守、総合 exit code 集約（WARN=exit 0 / 診断不能=exit 2）に正しく反映
- [ ] `test-doctor.sh` に `[phase]` 各導出ケース + 根拠検証 + 異常系 WARN 分岐（pr_number=null / gh 不可 / 未 merged / define_completed×done 矛盾）を追加
- [ ] `test-doctor.sh` に `[trace]` 各ケース（必須×存在/欠落、不要、`normal × comprehensive`、`risky × minimal`、depth_level 未設定 / enum 外）を追加
- [ ] `test-doctor.sh` に work item invalid 時の `[phase]` / `[trace]` SKIP/WARN ゲートのケースを追加（レビュー#3）
- [ ] 「全領域 OK 正常系」を 11 領域化（`assert_area phase` / `assert_area trace` 追加）
- [ ] `test-doctor.sh` が全件 PASS
- [ ] markdownlint 整合（編集ファイルに md がある場合）/ 既存テスト群が壊れていない

## スコープ外（境界）

- SoT ドキュメント反映（Unit 002）
- フェーズ導出規則 / size×depth 規則そのものの仕様変更
- doctor の自動修正機能（read-only 厳守）
- trace chain 後段（reviews / journal / release / reflect）診断、intent refs / Traceability 意味検証

## 依存

- 依存 Unit: なし
- 外部依存: `state-read.sh` / `work-item-status.sh` / `work-item-validate.sh` / `lib/frontmatter.sh` / `read-config.sh` / `git` / `gh` / `jq`（テスト）
