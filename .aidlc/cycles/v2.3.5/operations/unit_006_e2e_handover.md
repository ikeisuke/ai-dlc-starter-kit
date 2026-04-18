# Unit 006 E2E 検証引き継ぎ（Operations Phase / 次サイクル Inception Phase）

## 概要

Unit 006「設定保存フローの暗黙書き込み防止」（Issue #578）の実装は Construction Phase で完了したが、3 場面の `AskUserQuestion` 起動・デフォルト選択挙動の**実機 E2E 検証**は Construction Phase セッション内で実行不能（各場面は別 Phase での自然発火を要する）。そのため、以下の観点を Operations Phase / 次サイクル Inception Phase に引き継ぎ、自然発火のタイミングで目視確認する。

## 引き継ぎの根拠

- Construction Phase セッションでは 3 場面のフロー（`branch_mode` / `draft_pr` / `merge_method`）いずれも発火しない
- 記述ベース（grep + コンテキストトレース）の静的検証で見出し・注記・選択肢順序・`(Recommended)` サフィックスの一貫性は確認済み（Unit 006 実装記録 H セクション参照）
- 実機起動時の `AskUserQuestion` UI は Claude Code ランタイム依存のため、実フロー実行時の目視確認が必要
- Codex 統合レビュー R2 で「静的確認のみでは受入基準不十分」との指摘があり、ユーザー判断で「Operations Phase / 次サイクルで E2E を自然通過させる」方針に合意

## 検証対象と実行タイミング

| 場面 | トリガー条件 | 実行タイミング | 検証位置 |
|------|------------|---------------|---------|
| `merge_method` の設定保存 | `rules.git.merge_method=ask` + ユーザーがマージ方法を選択 | **当サイクル v2.3.5 Operations Phase（7.13 PR マージ）** | `skills/aidlc/steps/operations/operations-release.md` |
| `branch_mode` の設定保存 | `rules.git.branch_mode=ask` + `branch` / `worktree` 選択時（`current-branch` はスキップ） | **次サイクル Inception Phase（01-setup.md §9-1）** | `skills/aidlc/steps/inception/01-setup.md` |
| `draft_pr` の設定保存 | Inception Phase ステップ 5d で `action=ask_user` | **次サイクル Inception Phase（05-completion.md §5d-1）** | `skills/aidlc/steps/inception/05-completion.md` |

## 検証観点（全 3 場面共通）

各場面の `AskUserQuestion` 起動時、以下を目視確認する:

### 観点 1: 見出し・注記の表示

- 質問直前の markdown で「**設定保存フロー【ユーザー選択】**」見出しが Claude Code 側でユーザーに示されている（または内部的に認識されている）
- 「`automation_mode` に関わらず `AskUserQuestion` 必須（詳細は SKILL.md 参照）」の注記が反映されている

### 観点 2: AskUserQuestion 必須化（マトリクス B）

- `automation_mode` 設定に関わらず `AskUserQuestion` が起動する（`semi_auto` / `full_auto` でセミオートゲート扱いで自動承認されない）
- `SKILL.md` の「ユーザー選択」種別ルールに従い、対話が必須となる

### 観点 3: デフォルト選択（マトリクス A）

- 選択肢 1 番目（先頭）が「**いいえ（今回のみ使用） (Recommended)**」
- 選択肢 2 番目が「**はい（保存する）**」
- Enter キー（デフォルト承認）で「いいえ（今回のみ使用）」が選択される
- 「いいえ」選択時、`scripts/write-config.sh` が実行されず、`.aidlc/config.local.toml` への書き込みが発生しない

### 観点 4: 「はい」選択時の保存先選択と write-config.sh 整合

- 「はい（保存する）」選択時、保存先選択（`config.local.toml` / `config.toml`）が続けて提示される
- 選択に応じて `scripts/write-config.sh <key_name> "<value>" --scope <local|project>` が実行される
- 成功時「設定を保存しました」、失敗時は警告表示して続行

### 観点 5: 保存値マッピング（`draft_pr` のみ）

- `draft_pr` 場面のみ: ユーザー選択「はい（作成）」→ `always` / 「いいえ（作成しない）」→ `never` に変換されて保存される
- `branch_mode` / `merge_method` は選択値そのまま保存

## 検証結果の記録方法

### 当サイクル v2.3.5 Operations Phase での検証

`merge_method` の E2E 結果は `.aidlc/cycles/v2.3.5/history/operations.md` に記録する（`/write-history` 経由）。該当エントリで以下を明示:

- 検証実施日時
- `merge_method` 値の事前設定（`ask` である必要あり。未設定時は `AskUserQuestion` が起動しないため、検証できないことを明記）
- 観点 1〜4 の OK / NG
- NG の場合はバックログ Issue 起票

### 次サイクル Inception Phase での検証

次サイクル（v2.4.0 相当）の Inception Phase 実行時、`.aidlc/cycles/<next>/history/inception.md` に以下を記録:

- `branch_mode` 場面: `branch` または `worktree` 選択時の観点 1〜4 検証結果
- `draft_pr` 場面: ステップ 5d で `ask_user` に分岐した場合の観点 1〜5（マッピング含む）検証結果
- Unit 006 Construction Phase 実装の事後 E2E 確認が完了した旨を明記

### 受入基準（E2E パス条件）

- 3 場面すべてで観点 1〜4（`draft_pr` のみ 1〜5）が OK
- 1 件でも NG があればバックログ登録 → 次期 Construction Phase で修正

## 前提条件の注意

- `merge_method=ask` / `branch_mode=ask` / `draft_pr=ask` のいずれかが `.aidlc/config.toml` / `config.local.toml` で有効化されていないと当該フローは発火せず E2E にならない
- 既存の保存値（`.aidlc/config.local.toml` 内の `rules.git.*` エントリ）が入っていると自動解決されて `AskUserQuestion` をバイパスするため、検証前に**保存値をクリアするか `ask` に書き換える**こと
- 本 handover は「次サイクルでの Inception / Operations 実行時に自然発火する」前提のため、プロジェクト運用が 3 キーの `ask` モードを長期に使わない場合、E2E 検証機会が来ない可能性がある。その場合は明示的に `ask` へ切り替えた専用検証サイクルを検討する

## 関連ドキュメント

- Unit 定義: `.aidlc/cycles/v2.3.5/story-artifacts/units/006-settings-save-flow-explicit-opt-in.md`
- ドメインモデル: `.aidlc/cycles/v2.3.5/design-artifacts/domain-models/unit_006_settings_save_flow_explicit_opt_in_domain_model.md`
- 論理設計: `.aidlc/cycles/v2.3.5/design-artifacts/logical-designs/unit_006_settings_save_flow_explicit_opt_in_logical_design.md`
- 実装記録: `.aidlc/cycles/v2.3.5/construction/units/settings_save_flow_explicit_opt_in_implementation.md`
- レビューサマリ: `.aidlc/cycles/v2.3.5/construction/units/006-review-summary.md`
- 変更ファイル:
  - `skills/aidlc/SKILL.md`（「AskUserQuestion 使用ルール」テーブル）
  - `skills/aidlc/steps/inception/01-setup.md` §9-1
  - `skills/aidlc/steps/inception/05-completion.md` §5d-1
  - `skills/aidlc/steps/operations/operations-release.md` 7.13

## Issue / バックログ参照

- 関連 Issue: #578（本 Unit）
- E2E 検証で NG が出た場合の起票先: 新規 Issue を `[Bug] Unit 006 E2E 検証 NG: <観点>` の形で作成
