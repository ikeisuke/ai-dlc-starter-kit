# Unit 004 計画: predecessor-issue.sh の retrospective-issue.sh 横依存解消（#643）

## 概要

`skills/aidlc/scripts/lib/predecessor-issue.sh` が `retrospective-issue.sh` を直接 source して関数を借用する横依存構造を解消する。借用関数（`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries`）を責務別の独立 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）に分離し、両ファイルがそれぞれ独立して新 helper を source する構造に再構成する。

## 関連 Issue

- #643（predecessor-issue.sh の retrospective-issue.sh 横依存解消）
- 関連（参考 / 既存独立例）: v2.5.2 Unit 003 で新設の `aidlc-paths.sh`

## SoT 参照（計画レビュー Round 1 指摘 #1 + Round 2 指摘 #1 反映）

本 Unit の SoT は以下の絶対パス + line 番号で固定:

- Intent: `/Users/keisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/.worktree/dev/.aidlc/cycles/v2.5.3/requirements/intent.md` line 75-86（「Unit 004(c) 検証コマンド」セクション）
- ストーリー: `/Users/keisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/.worktree/dev/.aidlc/cycles/v2.5.3/story-artifacts/user_stories.md` line 118-143（「ストーリー 4」セクション本体 / `---` 区切りまで）
- Unit 定義: `/Users/keisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/.worktree/dev/.aidlc/cycles/v2.5.3/story-artifacts/units/004-predecessor-helper-split.md` line 1-82（ファイル全体 / 「責務」「境界」「依存関係」「NFR」「技術的考慮事項」「実装状態」セクションを含む）

## Unit 001 申し送り受け入れ条件の取り込み

`.aidlc/cycles/v2.5.3/plans/unit-001-plan.md` の「申し送り対象計画ファイル + 受け入れ条件 ID」表に従い、本 Unit の完了条件チェックリストに以下を含める:

- **AC-U004-RETRO-GUARD-IMMUTABLE-1**: `retrospective-issue.sh` の関数移管 / refactor 時、Unit 001 で追加された `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` 関数と `retrospective_issue_create` への組み込みが破壊されないこと
- **AC-U004-RETRO-GUARD-IMMUTABLE-2**: 新 helper 群（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）への関数移管対象に Unit 001 で追加した対話確認トークン関連関数を含めない（`retrospective-issue.sh` 残置）

本 Unit の関数移管対象は `__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries` の 3 関数のみ。Unit 001 で追加された `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` / `retrospective_dialog_token_path` / `retrospective_iso8601_to_epoch` および `retrospective_issue_create` 内の verify 呼出は `retrospective-issue.sh` に残置し、新 helper への移管対象としない。

## 変更操作の境界（Unit 001 不変条件保持）

| 操作種別 | 許容/禁止 | 適用対象 |
|---------|---------|---------|
| 新規 helper 作成（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`） | **許容** | Unit 004 のスコープ |
| `__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries` の移管 | **許容** | retrospective-issue.sh から新 helper へ |
| `retrospective-issue.sh` の関数定義削除（移管対象 3 関数のみ） | **許容** | 上記 3 関数の元定義のみ |
| `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` 関数の削除・移管 | **禁止** | retrospective-issue.sh に残置必須 |
| `retrospective_issue_create` 内の verify 呼出削除 | **禁止** | Unit 001 ガード保持必須 |
| `predecessor-issue.sh` から `retrospective-issue.sh` への直接 source | **禁止** | Unit 004 の主目的（解消対象） |

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/scripts/lib/aidlc-validate.sh` | 新規作成 | `__retro_validate_cycle` 関数（cycle 命名・存在チェック）を移管。多重 source ガード `__AIDLC_VALIDATE_SH_LOADED=1` |
| `skills/aidlc/scripts/lib/aidlc-gh.sh` | 新規作成 | `__retro_gh_status` 関数（gh CLI 可用性チェック）を移管。多重 source ガード `__AIDLC_GH_SH_LOADED=1` |
| `skills/aidlc/scripts/lib/aidlc-spool.sh` | 新規作成 | `_spool_extract_entries` 関数（NDJSON spool パース）を移管。多重 source ガード `__AIDLC_SPOOL_SH_LOADED=1` |
| `skills/aidlc/scripts/lib/retrospective-issue.sh` | 改修 | 移管対象 3 関数の元定義を削除し、新 helper 3 つを source。Unit 001 関数 / verify 組込は維持 |
| `skills/aidlc/scripts/lib/predecessor-issue.sh` | 改修 | `retrospective-issue.sh` への直接 source を撤去し、新 helper 3 つを source |
| `.aidlc/cycles/v2.5.3/history/construction_unit04.md` | 新規作成 | Unit 004 の進捗履歴 |

> **既存 `validate.sh` との混同注意**: `skills/aidlc/scripts/lib/validate.sh` は write-history.sh 用の既存ファイル（Unit 002 で `validate_write_history_mode` 等を追加済み）。本 Unit で新規作成する `aidlc-validate.sh` は **別ファイル** であり、`__retro_validate_cycle` 専用。命名は紛らわしいが Unit 定義で確定済み。

## 実装計画

### Phase 1（設計）

設計成果物:

- ドメインモデル（`design-artifacts/domain-models/unit_004_predecessor_helper_split_domain_model.md`）: 関数分類とモジュール境界
- 論理設計（`design-artifacts/logical-designs/unit_004_predecessor_helper_split_logical_design.md`）: 関数移管手順 / 多重 source ガード設計 / 相互 source 禁止検証

### Phase 2（実装）

#### 1. `aidlc-validate.sh` 新規作成

- `__retro_validate_cycle` 関数を `retrospective-issue.sh` から移管（line 102-）
- 多重 source ガード: `__AIDLC_VALIDATE_SH_LOADED=1`
- 他 helper への source 依存なし（境界完全分離）

#### 2. `aidlc-gh.sh` 新規作成

- `__retro_gh_status` 関数を `retrospective-issue.sh` から移管（line 686-）
- 多重 source ガード: `__AIDLC_GH_SH_LOADED=1`
- 他 helper への source 依存なし

#### 3. `aidlc-spool.sh` 新規作成

- `_spool_extract_entries` 関数を `retrospective-issue.sh` から移管（line 611-）
- 多重 source ガード: `__AIDLC_SPOOL_SH_LOADED=1`
- 他 helper への source 依存なし

#### 4. `retrospective-issue.sh` 改修

- 移管対象 3 関数の元定義を削除
- ファイル冒頭付近で新 helper 3 つを source（aidlc-paths.sh と同等のパターン）
- Unit 001 で追加された関数（`retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` / `retrospective_dialog_token_path` / `retrospective_iso8601_to_epoch` / `AIDLC_RETRO_TOKEN_TTL_SECONDS`）は **完全保持**
- `retrospective_issue_create` 内の verify 呼出は **完全保持**

#### 5. `predecessor-issue.sh` 改修

- `retrospective-issue.sh` への直接 source（line 33-36）を撤去
- 代わりに新 helper 3 つを source

#### 6. 既存 BATS テスト回帰確認

- `bats tests/` 全体を実行し、回帰がないことを確認
- `tests/predecessor-issue-handoff.bats` などの既存テストが pass することを確認

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 新 helper の多重 source ガードが機能せず関数重複定義エラー | 各 helper 冒頭で `if [[ "${__AIDLC_*_SH_LOADED:-}" == "1" ]]; then return 0; fi` のパターン採用 |
| 関数移管漏れ（`__retro_validate_cycle` 等） | 完了処理で `grep -EHn "^(source\|\.)[[:space:]]+.*(retrospective-issue\|predecessor-issue)\.sh" skills/aidlc/scripts/lib/aidlc-{validate,gh,spool}.sh` を実行、0 件確認（AC-U004(c) / Intent §「Unit 004(c) 検証コマンド」） |
| Unit 001 関数の誤移管 | 完了処理で `grep "retrospective_dialog_token_(verify\|record_response\|path)" skills/aidlc/scripts/lib/retrospective-issue.sh` を実行、関数定義が retrospective-issue.sh に残置されていることを確認（AC-U004-RETRO-GUARD-IMMUTABLE-1 / -2） |
| 既存テスト破壊 | 完了処理で `bats tests/` 全体実行、全件 pass 確認 |
| API 互換性破壊 | 関数名・引数・stderr 文言は維持（user_stories.md ストーリー 4 受け入れ基準 (a)-(f)） |

## NFR

- **パフォーマンス**: source 構造の変更のみで関数実体は不変、性能影響なし
- **セキュリティ**: 既存の機密情報マスク・gh API 利用パターンを維持
- **後方互換**: CLI 引数互換 / exit code 互換 / stderr 文言互換のすべてを維持
- **可用性**: 影響なし

## 完了条件チェックリスト

### 新 helper 作成

- [x] `skills/aidlc/scripts/lib/aidlc-validate.sh` が新規作成され、`__retro_validate_cycle` が移管されている
- [x] `skills/aidlc/scripts/lib/aidlc-gh.sh` が新規作成され、`__retro_gh_status` が移管されている
- [x] `skills/aidlc/scripts/lib/aidlc-spool.sh` が新規作成され、`_spool_extract_entries` が移管されている
- [x] 各 helper に多重 source ガード（`__AIDLC_VALIDATE_SH_LOADED` / `__AIDLC_GH_SH_LOADED` / `__AIDLC_SPOOL_SH_LOADED`）が設定されている

### 既存ファイル改修

- [x] `retrospective-issue.sh` から移管対象 3 関数（`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries`）の元定義が削除されている
- [x] `retrospective-issue.sh` が新 helper 3 つを source している
- [x] `predecessor-issue.sh` から `retrospective-issue.sh` への直接 source が撤去されている
- [x] `predecessor-issue.sh` が新 helper 3 つを source している

### 相互 source 禁止（AC-U004(c)）

- [x] 新 helper 群（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）が `retrospective-issue.sh` / `predecessor-issue.sh` をいずれの記法でも読み込まないこと（`grep -EHn "^(source|\.)[[:space:]]+.*(retrospective-issue|predecessor-issue)\.sh" skills/aidlc/scripts/lib/aidlc-validate.sh skills/aidlc/scripts/lib/aidlc-gh.sh skills/aidlc/scripts/lib/aidlc-spool.sh` で **0 件**）

### Unit 001 申し送り受け入れ条件（不変条件保持）

- [x] **AC-U004-RETRO-GUARD-IMMUTABLE-1**: `retrospective-issue.sh` の `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` 関数定義および `retrospective_issue_create` への verify 呼出組み込みが保持されている（grep 確認）
- [x] **AC-U004-RETRO-GUARD-IMMUTABLE-2**: 新 helper 群への関数移管対象に Unit 001 関数が含まれていない（`grep -EHn "retrospective_dialog_token" skills/aidlc/scripts/lib/aidlc-{validate,gh,spool}.sh` で **0 件**）

### API 互換性（AC-U004 (a)-(f) / user_stories.md ストーリー 4 / 計画レビュー Round 1 指摘 #2 反映）

機械検証手順を具体化し主観判定リスクを排除する:

- [x] **(d) CLI 引数互換**: 既存 BATS テスト `tests/predecessor-issue-handoff.bats` および `tests/retrospective-issue-create.bats` が pass（既存テストが引数列・引数名・必須/任意フラグを検証している）
- [x] **(e) exit code 互換**: 上記 BATS テストの全 exit code 検証行（`[ "$status" -eq N ]`）が pass
- [x] **(f) stderr 文言互換**: 上記 BATS テストの stderr 文字列検証行が pass（`predecessor_candidates_emitted` / `info` / `warn` プレフィックス含む）
- [x] **(g) 関数レベル契約テスト追加（設計レビュー Round 1 指摘 #3 反映）**: `tests/aidlc-helpers-migration.bats`（新規）に移管対象 3 関数の最小契約テストを追加:
  - `__retro_validate_cycle "v2.5.3"` → exit 0、`__retro_validate_cycle "../etc"` → exit 2（移管前と同一）
  - `__retro_gh_status` → stdout が `available` / `unavailable` / `not-installed` のいずれか
  - `_spool_extract_entries` → 不在 spool で exit 2、ヘッダ無しで exit 2、有効 spool で exit 0 + NDJSON 出力
- [x] **回帰検証**: `git stash` で本 Unit の変更を退避した状態と適用済み状態で `bats tests/predecessor-issue-handoff.bats` 出力差分が無いことを確認（オプション / レビュー対応として実施）

### source 読込順序（計画レビュー Round 1 指摘 #3 反映）

新 helper および既存 helper の source 順序を以下に固定する:

- `retrospective-issue.sh` 冒頭での source 順: (1) `aidlc-paths.sh`（既存 / Unit 003 で v2.5.2 サイクル追加）→ (2) `aidlc-validate.sh` → (3) `aidlc-gh.sh` → (4) `aidlc-spool.sh`
- `predecessor-issue.sh` 冒頭での source 順: (1) `aidlc-paths.sh` → (2) `aidlc-validate.sh` → (3) `aidlc-gh.sh` → (4) `aidlc-spool.sh`
- 各新 helper は他の helper を source しない（境界完全分離 / aidlc-paths.sh の source も含めて禁止）

- [x] `retrospective-issue.sh` / `predecessor-issue.sh` の source 順序が上記順に従っている
- [x] 各新 helper が他 helper への source 依存なし（grep で 0 件確認）

### 移行完結性（計画レビュー Round 1 指摘 #4 反映）

- [x] **同一コミット切替**: `retrospective-issue.sh` の関数移管 + 新 helper source 化 + `predecessor-issue.sh` の `retrospective-issue.sh` 直接 source 撤去 + 新 helper source 化 を **すべて同一コミット** で完結する。中間コミットで「旧 source + 新 helper 併存」状態を作らない（二重読込による多重定義エラー / テスト不安定回避）

### 検証 + 履歴

- [x] `bats tests/` 全体が pass する（件数は固定しない / 既存全件 + 本 Unit 新規追加分のすべて pass）
- [x] `tests/predecessor-issue-handoff.bats` が pass する
- [x] `.aidlc/cycles/v2.5.3/history/construction_unit04.md` に対話必須ガード強化反映の記録（Unit 002 short note モードで self-apply）が追記されている

### 品質ゲート

- [x] markdownlint が pass する（該当 .md なし or pass）
- [x] AI レビュー（design / code / integration）が完了条件（最後 2 round 連続 clean）を満たす
- [x] Codex レビューでも追加指摘なし、または defer 化済み

## 見積もり

- 設計フェーズ: 0.5 日
- 実装フェーズ: 1.5 日（新 helper 3 ファイル作成 + retrospective-issue.sh / predecessor-issue.sh 改修 + 回帰テスト）
- 合計: **2 日**
