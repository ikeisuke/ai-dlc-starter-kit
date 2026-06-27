# Unit 004 実装計画: SKILL.md 統合・express 整合・テスト・回帰

## 対象 Unit

`004-skill-integration-express-and-tests` — release フロー実装の仕上げ。`SKILL.md` の `release` 公開フリップ、express ラッパが release まで到達することの整合確認、release フロー新規分のテスト追加、既存 v3 テスト green 維持、SoT 非再定義の最終確認、release フロー全体（Step 1→4）の整合性検証を担う。

- **サイクル**: v3.0.0-alpha.6 / **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required
- **依存 Unit**: 001 / 002 / 003（すべて完了 / Step 1–4 実装済みが前提）
- **関連 Issue**: #736（部分対応 / Relates）

## スコープ

### 含まれるもの（本 Unit で実装）

1. **`SKILL.md` の `release` 公開フリップ**
   - コマンド表の `release` 行を「予約（後続 Phase で実装）」→「`steps/release.md`（実在 / Unit 001–003 で実装）」に更新。
   - 「パス解決」セクションの `steps/` リストに `release.md` を、`templates/` リストに `release.md` を追加。`scripts/` リストは既存（state / work-item 系）で充足。
   - 冒頭の「位置づけ」注記・frontmatter description を現状（define / status / develop / release 実装済み、reflect / doctor は予約）に同期。**stale 注記を残さない**（`test-activation.sh` の stale 注記チェックと整合）。develop の「tiny のみ」表記は alpha.5 で normal/risky 実装済みのため実態に合わせて訂正する（SKILL.md 注記同期の一環）。
2. **express ラッパ整合の確認・修正**
   - SKILL.md の express 経路（work item 1 つ・risky なし時の `define → develop → release` 連続実行）が release まで到達する記述になっていることを確認。release.md 実装により初めて連続実行が release まで到達する（Intent「既存機能との関連」）。記述に不足があれば修正。
3. **release フロー新規分のテスト追加**
   - `skills/aidlc-v3/scripts/tests/test-release-flow.sh` を新規作成（既存 `test-activation.sh` / `test-*-flow.sh` と同型の自己完結ハーネス / jq 前提）。構造・契約を検証する（実 gh/merge は行わない）:
     - `steps/release.md` が存在し Step 1–4 の見出しを持つ。
     - `templates/release.md` が存在し、review 結果サマリの固定マーカー（`<!-- aidlc-release-review:start/end -->`）を持ち、**マーカー間が純 YAML 契約に近い構造であることを静的検証**する（コードフェンス・Markdown 見出しがない / マーカー重複なし / 必須フィールド存在 / 主要 enum・boolean 文字列）。jq は YAML 非対応のため「parse」ではなく構造検証（Unit 002→003 契約）。
     - `SKILL.md` の `release` が `steps/release.md` を指す（「予約」表記が release 行に残っていない）。
     - release.md が依存スクリプト契約（`state-write.sh release.pr_number`/`release.ready`/`release.merge_approved` / `state-read.sh` / `work-item-validate.sh` / `work-item-status.sh`）と merge ゲート要素（`merge_blocker_any` / `--match-head-commit` / `gh pr checks --required`）を参照している。
     - release.md が review ルーティング条件（premerge 常時 / integration は `status:done` 2 件以上 / deploy は risky done 1 件以上）、post-merge の opt-in 正常完了（`version_tag`/`changelog` false でも完了）、tag は merge commit 対象、journal は統合先 branch 方針、を契約文字列として記述している。
4. **回帰**: 既存 v3 テスト 7 スイート + 新規 test-release-flow.sh がすべて green。
5. **SoT 非再定義の確認**: state.json schema・フェーズ導出（`data-model.md §5`）・review perspective（`workflow.md §6`）を本サイクルで再定義していないことを確認（release.md / templates が参照に留まる）。
6. **release フロー全体整合**: Step 1→4 の通し（Step 間の入出力契約 / Unit 002→003 の review サマリ契約 / state フィールドの段階的書き込み）の整合を確認。

### 含まれないもの（境界 / 非スコープ）

- 各 Step の機能実装そのもの（Unit 001–003 / 実装済み）。
- v2（`skills/aidlc`）側の変更・本流化（Phase 7）。
- alpha.6 自身のリリースを v3 release フローで実行すること（dogfooding は Phase 7）。本サイクルの実リリースは v2 Operations。
- reflect / doctor の実装（Phase 6）。state.json schema の拡張。

## 設計 SoT（再定義せず参照）

- `docs/v3/workflow.md §2`（コマンド体系 / express）/ `§3.3`（release Step 1–4）/ `§6`（review perspective）
- `docs/v3/data-model.md §3`（state.json schema / release fields）/ `§5`（フェーズ導出 / 再定義しない）
- 既存 `skills/aidlc-v3/scripts/tests/` ハーネス方式（`test-activation.sh` 等）

本 Unit は release.md / templates/release.md / SKILL.md 側で上記 SoT への**参照同期のみ**を行い、state schema や review perspective 条件・フェーズ導出規則を再定義しない。

## 実装アプローチ

1. **SKILL.md 更新**: release 行のフリップ + パス解決リスト追記 + 位置づけ注記/frontmatter の実態同期。stale 注記（`本 Unit で作成` / `Unit 005 で行う` / 旧 Phase 表記等）を残さない。
2. **express 整合**: express セクションの `define → develop → release` 記述を確認。release 実装済みを反映（連続実行が release 到達可能になった旨が矛盾しないこと）。
3. **テスト追加**: `test-release-flow.sh` を `test-activation.sh` のスタイル（pass/fail カウンタ / bash -n / shellcheck / jq）で実装。マーカー間 YAML の parse は jq では YAML 非対応のため、**マーカー抽出 + 必須キー文字列存在 + 構造（perspective/merge_blocker_any 等）の grep 検証**で代替（YAML parser 非依存・ネットワーク非依存）。
4. **回帰実行**: 全 `test-*.sh` を実行し green を確認。
5. **Bash ツール安全規約**（`$(...)` / backtick の **AI Bash ツール引数**での禁止）/ **result-out 関数の local 命名規約**（新規 sh にあれば）/ **クロスプラットフォーム**（BSD/GNU 差注意）。

## 変更ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `skills/aidlc-v3/SKILL.md` | 編集 | release 公開フリップ + パス解決リスト + 位置づけ注記/frontmatter 同期 |
| `skills/aidlc-v3/scripts/tests/test-release-flow.sh` | 新規作成 | release フロー構造・契約検証（自己完結 / jq 前提） |

## テスト方針

- 本 Unit はテスト追加が責務。`test-release-flow.sh` は実 gh / merge / ネットワークに依存せず、release.md / templates/release.md / SKILL.md の構造・契約を静的検証する。
- マーカー間 YAML は jq が YAML 非対応のため「parse」ではなく**構造の静的検証**で代替する: マーカー抽出 + マーカー間にコードフェンス（` ``` `）・Markdown 見出しがない + マーカー重複なし + 必須フィールド（`schema_version` / `perspective` / `status` / `unresolved_count` / `max_severity` / `merge_blocker` / `skip_reason` / `merge_blocker_any`）の存在 + 主要 enum/boolean 文字列（`passed` / `skipped` / `true` / `false` 等）の確認。
- review ルーティング条件・post-merge opt-in 正常完了・tag merge commit 対象・journal 統合先方針の契約文字列も検証する。
- 既存 v3 テスト 7 スイート + 新規 1 = 計 8 がすべて green。

## NFR

- **品質**: 新規テストが Step 1–4 の主要要素（ゲート・契約・マーカー）をカバーする。
- **互換性**: 既存テスト green 維持（回帰ゼロ）。state schema・既存スクリプト不変。
- **クロスプラットフォーム**: テスト・スクリプトは macOS / Linux 両対応。

## 完了条件チェックリスト

- [ ] `SKILL.md` の `release` 行が「予約」から `steps/release.md`（実在）に更新されている
- [ ] パス解決セクションの `steps/` に `release.md`、`templates/` に `release.md` が追加されている
- [ ] 位置づけ注記・frontmatter が実態同期され、stale 注記（`test-activation.sh` のチェック対象パターン含む）が残っていない
- [ ] express ラッパが release まで到達する記述になっている（確認・必要なら修正）
- [ ] `test-release-flow.sh` が新規作成され、release.md の Step 1–4・templates/release.md のマーカー + 必須フィールド（構造静的検証 / parse ではない）・SKILL.md の release ルーティング・依存契約参照を検証する
- [ ] `test-release-flow.sh` が review ルーティング条件（premerge 常時 / integration done≥2 / deploy risky）・post-merge opt-in 正常完了・tag merge commit 対象・journal 統合先方針の契約文字列も検証する
- [ ] `test-release-flow.sh` 自身が bash -n / shellcheck（あれば）で静的検査を通る
- [ ] 既存 v3 テスト 7 スイート + 新規 = 全 green（回帰ゼロ）
- [ ] SoT（data-model §5 / workflow §6 / state schema）を本サイクルで再定義していないことを確認
- [ ] release フロー全体（Step 1→4）の整合（state 段階書き込み / Unit 002→003 review サマリ契約）を確認
- [ ] Bash ツール安全規約（`$(...)` / backtick を AI Bash ツール引数で不使用）/ クロスプラットフォーム

## 見積もり

0.5〜1 日（統合・テスト・回帰）
