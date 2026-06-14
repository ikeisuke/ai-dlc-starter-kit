# Unit 001 計画: v3 define フロー実行実装

## 対象 Unit

- **Unit**: 001-v3-define-flow（v3 define フロー実行実装）
- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **依存 Unit**: なし（alpha.2 成果物の state スクリプト群 / テンプレートを利用）
- **関連 Issue**: なし
- **depth_level**: standard（設計フェーズあり）/ **review_mode**: required

## 目的（1 文）

`skills/aidlc-v3/steps/define.md` を「読める手順」から「実行可能なフロー」へ具体化し、cycle ディレクトリ作成・`intent.md` / `work-items/*.md` 生成・`state.json` 初期化・`journal.md` 追記・branch / 初回 commit を AI エージェントが実際に実行できるようにする。

## 設計方針（前提認識）

- v3 は v2 と同様、**AI エージェント駆動の Markdown 手順 + 安全境界スクリプト**の構成。`define.md` は AI が各 Step で実行する手順書であり、`state.json` 書き込みのような atomic 性が必要な操作のみ `scripts/state-*.sh` を経由する（RFC P4）。
- 本 Unit の主成果物は **`define.md` の実行手順化**（コマンド・分岐・成果物パス・スクリプト呼び出しを具体化）であり、Python オーケストレータや変数展開エンジンの新規実装ではない。
- cycle ディレクトリ作成は安全境界不要な単純処理（`mkdir -p`）で AI inline 実行可。`state.json` 書き込みは `state-write.sh`（既存）経由。

## 主要な実装対象

1. **`skills/aidlc-v3/steps/define.md` の実行手順化**: Step 1〜4 を「AI が何をするか」の説明から「実際にどのコマンド・どのファイル生成・どのスクリプト呼び出しを行うか」へ具体化。
2. **cycle ディレクトリ作成ロジック**: v3 フラット構造（`.aidlc/cycles/{cycle}/intent.md` / `work-items/` / `journal.md`、v2 の inception/construction/operations サブディレクトリは持たない）。`state.json` は **cycle dir 配下ではなくリポジトリ直下 `.aidlc/state.json`**（data-model §2）。
3. **初期 `state.json` 生成方法の確定**: `state-write.sh` は「既存 state 更新専用」で初期生成は本フローへ defer されている（state-write.sh L7 / state-validate.sh で valid 必須）。初期生成の atomic 手段を設計フェーズで決定（下記「設計判断」参照）。
4. **`journal.md` 追記ロジック**: テンプレート `templates/journal.md` を基に作成し、define 完了を追記。
5. **branch 作成 + 初回 commit**: define Step 4 で対象 cycle ブランチ作成・初回 commit。`early_pr: true` 時のみ Draft PR（本 Unit は通常パス = PR 作らないを実装。Draft PR 詳細は release フェーズ責務）。
6. **検証ハーネス**: alpha.2 の `scripts/tests/test-state-scripts.sh` を踏襲したサンドボックス（`mktemp -d`）で、v2 `.aidlc/` を破壊せず define フローの成果物生成・state 整合を検証。

## 設計フェーズで確定すべき主要判断

| # | 論点 | 選択肢候補 | 備考 |
|---|------|-----------|------|
| D1 | 初期 `state.json` の atomic 生成方法 | **(a)（推奨）`state-init.sh` 新規追加で atomic 生成**（temp ファイルへ生成 → `state-validate.sh` 検証 → atomic `mv`）/ (b) define 手順で AI が**一時ファイルへ**初期 JSON を Write → `state-validate.sh` 検証 → atomic `mv` で配置 → `state-write.sh define_completed true` | Unit NFR「state 書き込みは atomic / 直接編集禁止」との整合。**いずれの案でも final path（`.aidlc/state.json`）へ直接 Write しない**（temp → validate → mv 経由）。新規ファイル生成は競合がなく atomic 重要度は低いが、規約整合と既存 `state-write.sh` の atomic 方式（temp+mv）との一貫性のため (a) を推奨。設計フェーズで確定 |
| D2 | `define_completed: true` の書き込みタイミング | Step 4 完了時（single-actor moment / define.md L63） | branch/commit との順序（commit 前か後か）を確定 |
| D3 | `journal.md` 追記方式 | 日付見出し `## YYYY-MM-DD` 配下に箇条書き append | 既存見出し検出 vs 常に新規見出し |
| D4 | cycle 識別子の決定方法 | define Step 2/4 で確定（current_cycle） | サンドボックス検証では固定値を注入 |
| D5 | サンドボックス検証の範囲 | Step 4 の成果物生成（dir / intent / work-items / state / journal / branch / commit）の検証 | AI 対話を伴う Step 2/3 承認ゲートはハーネス対象外（非対話部分を検証） |

> 設計判断は `define.md` 実行実装の正本 `docs/v3/workflow.md` §3.1、`state.json` の場所・schema は `docs/v3/data-model.md` §2/§3、frontmatter は §4、フェーズ導出は §5.1 を正本として確定する。

## 完了条件チェックリスト

Unit 001「責務」 + Intent 受け入れ基準（define 該当分）から抽出:

- [ ] `define.md` の Step 1〜4 が実行手順として具体化されている（環境チェック / Intent 定義 + 承認ゲート / Work Item 分割 + 承認ゲート / 初期化）
- [ ] cycle ディレクトリ作成ロジックが v3 フラット構造で実装され、`state.json` がリポジトリ直下 `.aidlc/state.json` に配置される
- [ ] 初期 `state.json` が生成され、`schema_version: "3.0"` / `current_cycle` / `define_completed` / `release{pr_number,ready,merge_approved}` / `updated_at` を持ち、`state-validate.sh` で valid と判定される
- [ ] 初期 `state.json` の生成が final path へ直接 Write されず、temp → `state-validate.sh` 検証 → atomic `mv` 経由で行われる（NFR「atomic / 直接編集禁止」整合）
- [ ] `define_completed: true` が `state-write.sh` 経由の atomic 書き込みで設定される
- [ ] 生成される各 `work-items/*.md` が data-model §4 準拠: frontmatter 必須キー（`id` / `status` / `size` / `risk` / `assigned` / `dependencies`）を持ち、enum 値域（`status∈{pending,...}` / `size∈{tiny,normal,risky}` / `risk∈{low,medium,high}`）に従う
- [ ] 生成される各 `work-items/*.md` の `status` 初期値が `pending`、本文に必須 6 セクション（Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies）を持つ（data-model §4.2）
- [ ] 各 work item の `dependencies` が実在する work item ID を参照する（存在しない ID 参照は data-model §6 の trace 整合エラー。後続 develop の依存解決 §5.2 / status のフェーズ導出 §5 の入力健全性を担保）
- [ ] `journal.md` がテンプレートから生成され、define 完了が追記される
- [ ] define Step 4 で cycle ブランチ作成 + 初回 commit が行われる（`git status` / `git log` で確認可能）
- [ ] 通常パスでは Draft PR を作成しない（`early_pr: true` 時のみ作成の分岐が記述されている）
- [ ] サンドボックス検証ハーネスで上記成果物生成が v2 `.aidlc/` を破壊せず検証される
- [ ] **v2 非影響**: `skills/aidlc/`（v2）配下に変更がない（`git diff` で確認）
- [ ] markdownlint を通過し、追加シェルスクリプトは `bash -n` / shellcheck（利用可能時）を通過する

## 検証方針

- サンドボックス（`mktemp -d`）に最小 v3 環境を構築し、define Step 4 の成果物生成手順を実行 → 生成ファイル・`state-validate.sh` 結果・git 状態をアサート。
- v2 ドッグフーディング用 `.aidlc/`（`config.toml` / `cycles/`）は一切変更しない（alpha.2 の test-state-scripts.sh 踏襲）。
- `bash -n` / shellcheck（利用可能時）/ markdownlint。

## スコープ境界（本 Unit に含まれないもの）

- develop / release / reflect フローの実装（後続 Unit / Phase）
- `early_pr: true` 時の Draft PR 作成詳細（release フェーズ責務）
- `status` 実行実装（Phase 6 / 本 Unit は「導出できる状態」までを検証対象に留める）
- `work-item-next.sh`（Unit 002）/ develop tiny（Unit 003）/ #731（Unit 004）/ marketplace 登録（Unit 005）

## リスク

- **R1**: 初期 state.json 生成方法（D1）が未確定。設計フェーズで確定しなければ実装が分岐 → 設計レビューで解消。
- **R2**: define の対話部分（Step 2/3 承認ゲート）はハーネスで自動検証しにくい → 非対話の成果物生成部分に検証を絞り、対話部分は手順記述の妥当性レビューで担保。
- **R3**: v2 `.aidlc/` 破壊リスク → サンドボックス隔離を徹底（既存ハーネス方式を踏襲）。
