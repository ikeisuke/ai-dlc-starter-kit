# Unit 002 実装計画: operations-release.sh への validate_cycle 検証拡張

## 対象 Unit

- **Unit**: 002 - operations-release.sh への validate_cycle 検証拡張
- **関連 Issue**: #708（クローズ対象）
- **元 Issue**: #701（v2.6.3 Unit 002 で `cmd_squash_712` のみ対応）
- **優先度**: High（security / patch スコープ）
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v2.6.3 Unit 002 で `cmd_squash_712` の `--cycle` には `validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）による検証を導入したが、同じ `operations-release.sh` 内の他サブコマンドは未対応のまま残っている。

- `cmd_record_release_prep_commit`: `--cycle` を `__operations_release_progress_path` でパス展開（`.aidlc/cycles/<cycle>/operations/progress.md`）する経路を持つ。`cmd_squash_712` と同種のパストラバーサル経路
- `cmd_pr_ready`: `--cycle` を `pr-ops.sh get-related-issues "$cycle"` に渡す。`cmd_get_related_issues` 内で `${AIDLC_CYCLES}/${cycle}/story-artifacts/units` というパス展開に使われており、パストラバーサル経路を持つ

本 Unit は v2.6.3 Unit 002 で確立した `validate_cycle` 適用パターンを上記必須経路へ網羅的に拡張する。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `cmd_record_release_prep_commit` への `validate_cycle` 検証導入
  - `-z "$cycle"` チェック直後・`__operations_release_progress_path` 呼び出し前に `validate_cycle "$cycle"` を挿入
  - 不正値時は exit 1 + tab 区切り stderr `error\trecord-release-prep-commit:invalid-cycle\t<value>`
- **必須対応 2**: `cmd_pr_ready` への `validate_cycle` 検証導入
  - 影響範囲調査により `pr-ops.sh get-related-issues` 経由でパス展開に使われることを確認済み（計画策定時点）
  - body-file 検証直後、`resolve_cycle_from_branch` で cycle が確定した直後（`get-related-issues` 呼び出し前）に `validate_cycle "$cycle"` を挿入
  - 不正値時は exit 1 + tab 区切り stderr `error\tpr-ready:invalid-cycle\t<value>`
- **bats テスト追加**: 境界ケースを両サブコマンドで網羅する。最小ケースセットを以下に固定する:

  | 入力値 | 期待 exit | 期待 stderr | 検証経路 |
  |-------|----------|-------------|---------|
  | `../etc`（パストラバーサル） | 1 | `error\t{cmd}:invalid-cycle\t../etc` | `validate_cycle` |
  | `/abs/path`（先頭スラッシュ） | 1 | `error\t{cmd}:invalid-cycle\t/abs/path` | `validate_cycle` |
  | `v2.6 4`（空白） | 1 | `error\t{cmd}:invalid-cycle\tv2.6 4` | `validate_cycle` |
  | `v2.6\t4`（制御文字 tab） | 1 | `error\t{cmd}:invalid-cycle\tv2.6\t4` | `validate_cycle` |
  | `V2.6.4`（大文字、予約名相当の形式不一致） | 1 | `error\t{cmd}:invalid-cycle\tV2.6.4` | `validate_cycle` |
  | `v2.6.4`（正常値） | 0 系（後続処理へ） | invalid-cycle なし | 検証通過 |

  - `{cmd}` は `cmd_record_release_prep_commit` / `cmd_pr_ready` でそれぞれ `record-release-prep-commit` / `pr-ready` に展開

  **空文字 / 未指定ケース（サブコマンド別の経路分岐）**: `validate_cycle` 呼び出しより前段で停止するため本 Unit では `invalid-cycle` を返さない。bats では責務境界を明確化するため以下を別テストとして固定する:

  | サブコマンド | ケース | 期待 exit | 期待 stderr | 検証経路 |
  |-------------|-------|----------|-------------|---------|
  | `cmd_record_release_prep_commit` | `--cycle ""`（空値指定） | 1 | `record-release-prep-commit:error:missing-value:--cycle` | `require_option_value`（既存） |
  | `cmd_record_release_prep_commit` | `--cycle` 未指定 | 1 | `record-release-prep-commit:error:cycle-required` | `-z "$cycle"`（既存） |
  | `cmd_pr_ready` | `--cycle ""`（空値指定） | 1 | `pr-ready:error:missing-value:--cycle` | `require_option_value`（既存） |
  | `cmd_pr_ready` | `--cycle` 未指定 + `cycle/v2.6.4` ブランチ上 | 0 系（後続処理へ） | invalid-cycle なし | `resolve_cycle_from_branch` で `v2.6.4` 解決後 `validate_cycle` 通過 |
  | `cmd_pr_ready` | `--cycle` 未指定 + 非 cycle ブランチ上 | 1（validate_cycle 検証） | `error\tpr-ready:invalid-cycle\t` （空文字 or 解決失敗値） | `resolve_cycle_from_branch` 解決後 `validate_cycle` で停止 |

  - `cmd_pr_ready` のブランチ解決経路は bats で一時 git リポジトリのブランチ名を `cycle/v2.6.4` 等に固定して検証する
  - `cmd_pr_ready` の非 cycle ブランチ経路（最終行）は本 Unit の `validate_cycle` 追加で新たに保護される経路であり、本 Unit のセキュリティ価値の中核を成す
- 影響範囲調査の判断根拠を `.aidlc/cycles/v2.6.4/inception/decisions.md` に DR として記録
- 既存 bats 群（`tests/operations-release-*.bats`, `tests/migration/*.bats` 含む）の回帰なし確認

### 含まれないもの（境界）

- `validate_cycle` 関数本体（`skills/aidlc/scripts/lib/validate.sh`）の改修（v2.6.3 Unit 002 で導入済みの実装をそのまま流用）
- `cmd_squash_712` の既存検証への追加変更
- `operations-release.sh` の他のサブコマンド（`--cycle` を受け取らないもの: `pr-create-from-draft` 等）
- `pr-ops.sh` 側での `validate_cycle` 導入（呼び出し側 `cmd_pr_ready` で検証する方針）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**: `--cycle` 引数の検証ドメイン（valid / invalid 判定）と、`cmd_record_release_prep_commit` / `cmd_pr_ready` 各起動シーケンスにおける検証ポイントの位置づけを整理
- **論理設計**:
  - `cmd_record_release_prep_commit` への `validate_cycle` 呼び出し挿入位置（`-z "$cycle"` チェック直後）の確定
  - `cmd_pr_ready` への `validate_cycle` 呼び出し挿入位置（body-file 検証後・`resolve_cycle_from_branch` 後・`get-related-issues` 呼び出し前）の確定
  - エラー出力フォーマットの確定（`error\t{サブコマンド名}:invalid-cycle\t<value>`、v2.6.3 Unit 002 パターン踏襲）
  - DRY_RUN モードでも検証を実行する方針（実行前検証目的、v2.6.3 Unit 002 の `__squash_712_check_history_clean` と同方針）
  - bats テストケース設計（不正 cycle: `..` 含む / 先頭スラッシュ / 空白 / 制御文字 / 予約名、正常 cycle: 従来どおり後続処理）
  - 既存 bats `operations-release-squash712-cycle-validation.bats` のパターンを踏襲し、新規ファイル 2 本（`operations-release-record-release-prep-commit-cycle-validation.bats` / `operations-release-pr-ready-cycle-validation.bats`）として追加

### Phase 2: 実装

1. `cmd_record_release_prep_commit` に `validate_cycle` 検証を追加（不正値 → exit 1 + tab 区切り stderr）
2. `cmd_pr_ready` に `validate_cycle` 検証を追加（同上）
3. 新規 bats テスト 2 本追加（不正値 / 正常値の両ケース）
4. 既存 bats テスト群（`operations-release-*.bats`, `migration/*.bats`）の回帰確認
5. 影響範囲調査結果と挿入位置の選択根拠を `decisions.md` に DR として記録

## 完了条件チェックリスト

### #708 受け入れ基準

- [x] `cmd_record_release_prep_commit` 起動時に `--cycle` 引数が `validate_cycle` で検証される
- [x] `cmd_pr_ready` 起動時に `--cycle` 引数が `validate_cycle` で検証される
- [x] `cmd_record_release_prep_commit` の不正 cycle 値で exit 1 + stderr `error\trecord-release-prep-commit:invalid-cycle\t<value>` が出力される
- [x] `cmd_pr_ready` の不正 cycle 値で exit 1 + stderr `error\tpr-ready:invalid-cycle\t<value>` が出力される
- [x] 両サブコマンドが正常 cycle 値で従来どおり後続処理に進む（回帰なし）
- [x] 不正 cycle / 正常 cycle の両ケースをカバーする bats テストが追加されている（両サブコマンド分、上記「最小ケースセット」表を網羅 / 17 ケース pass）
- [x] 既存の `operations-release-*.bats` を含む bats テスト群が引き続き pass する（49/49）
- [x] `tests/migration/*.bats` を含むその他 bats 群の回帰がない（49/49）
- [x] `cmd_pr_ready` の影響範囲調査結果と挿入位置選択根拠が `decisions.md` に DR として記録されている（DR-007）

### 共通

- [x] markdownlint で新規エラー 0 件（ドキュメント変更がある場合）
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い実施されている（Set 1: 設計 2R / 1件解消, Set 2: コード 1R clean, Set 3: 統合 2R / 1件解消）

## リスク・考慮事項

- `operations-release.sh` 冒頭で既に `source "${SCRIPT_DIR}/lib/validate.sh"` 済み（v2.6.3 Unit 002 で導入）のため、source 追加は不要
- `cmd_pr_ready` は `cycle` が空の場合 `resolve_cycle_from_branch` で解決する経路を持つ。検証はこの解決後に実施することで、ブランチ由来の cycle 値も同じ検証で保護される
- `cmd_pr_ready` の body-file 検証（`_pr_ready_validate_body_file`）は cycle 解決より前に位置しており、本 Unit の検証挿入はその後ろ・`get-related-issues` 呼び出し前に位置する（最も早い fail-fast ポイント）
- `validate_cycle` の許可パターンは「1〜2 セグメントの汎用ラベル」であり、`cycle/v2.6.x` 形式と整合
- 新規 `printf -v` 系 result-out 関数の導入予定なし（既存パターンの呼び出し追加のみ）
- 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（本リポジトリ規約）
