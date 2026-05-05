# Unit 005 計画: #616 マージ前 write-history 追加コミット漏れガード

> **用語注記**（v2.5.1 統合レビュー反映 / 2026-05-05）: 本文中の `dirty` は `validate-git.sh uncommitted` が出力する `status:warning`（未コミット差分検出）の口語表現です。canonical 値域は domain model（[unit_005_write_history_uncommitted_guard_domain_model.md §1](../design-artifacts/domain-models/unit_005_write_history_uncommitted_guard_domain_model.md)）の `OK | WARNING | ERROR` を参照。

## 1. 目的とスコープ

### 解決する問題（#616 顕在化シナリオ）

1. `/write-history` で `history/operations.md` に追記（exit 0 / append 完了）
2. **追加コミットを実施せずに push → マージ**
3. マージ後に未コミット差分として残存（post-merge では cycle 配下改変禁止 / DR-001 / Unit 002 で導入）→ 破棄しか選択肢がない

`review-flow.md` L50「レビュー後コミット」がフローのどの段階で発火するか曖昧で、AI エージェントがフロー漏れを起こす。

### スコープ

- Operations Phase §7.12 PR マージ前レビュー反映後の「履歴記録 → 履歴コミット」フロー漏れ検出ガード追加
- `review-flow.md` L50 の「レビュー後コミット」手順明確化
- BATS テスト `tests/operations-uncommitted-detection.bats`（最小契約 verify）
- 既存 Issue #579（マージ後 write-history 禁止 exit 3）整合維持

### スコープ外

- 振り返り Issue 起票（Unit 002）
- マージ後フェーズの動作変更（既存 #579 ガードと整合させるのみ）
- write-history.sh 本体ロジック変更（Option B 不採用）
- §7.13 既存 `.aidlc/config.toml` 差分ガード（#601 案 B / 既存ロジックそのまま / 本 Unit 新規ガードと併存）

### スコープ内（境界更新）

- `operations-release.sh merge-pr` への構造的事前ガード追加（**Round 1 P1 対応**: 文書改修だけでは「機械的に防げない」指摘を受け、`merge-pr` 実行直前で `validate-git.sh uncommitted` を呼び `status:warning` 検出時は exit 1 で停止する script-level ガードを追加）

## 2. Option 評価

#616 で挙げられた 4 つの実装 Option について trade-off 分析:

| Option | 概要 | Pros | Cons | 採用判定 |
|--------|------|------|------|---------|
| A | `review-flow.md` のレビュー反復完了処理を「修正 → 一次コミット → 履歴記録 → 二次コミット（履歴のみ）」と明示し、二次コミット未実施でフェーズ完了に進めないガード追加 | 既存フロー差分最小 / シェル変更不要 | AI エージェントが手順を見落とす余地が残る（人/AI 規律依存）/ 自動検出ではない | **補助採用**（手順明確化のみ）|
| B | `write-history.sh` に `--commit` オプション追加（追記直後に自動コミット） | 構造的にフロー漏れ防止 / 完全自動化 | 単一責任違反（追記 + コミット同時責務）/ 既存 invocation 全箇所に互換性影響 / コミットメッセージ規約をスクリプトに埋込む密結合 | **不採用** |
| C | `scripts/operations-release.sh verify-git` を §7.12 後に再実行 + `merge-pr` への構造的事前ガード（`validate-git.sh uncommitted` 呼出 + `status:warning` 検出時 exit 1）追加 | 既存 verify-git / validate-git 再利用（Single Source of Truth）/ **script-level の構造的防御線**（AI 規律不要）| `merge-pr` コマンドに新規 pre-flight check 追加（既存 `--skip-checks` 互換維持） | **主軸採用（強化版）** |
| D | AI レビュー完了の write-history 呼び出しを「再レビュー 0 件確定時の 1 回のみ」に限定（コミット直前） | フロー漏れ構造的防止 / write-history.sh 不変 | review-flow.md フロー全体改変 / 「レビュー反復ごとに履歴記録」運用と非互換 / 既存 v2.4.x 履歴粒度変更 | **不採用** |

### 推奨: ハイブリッド (A 補助 + C 主軸 / **script-level 構造ガード強化版**)

**主軸 = Option C 強化版**: `operations-release.sh merge-pr` に script-level の pre-flight check を追加し、`validate-git.sh uncommitted` で `dirty` 検出時は exit 1 で `merge-pr` 自体を停止する。AI エージェントが手順を漏らしても、`merge-pr` 実行時点で構造的にブロックされる（**Round 1 P1 対応**）。

**補助 = Option A**: `review-flow.md` L50 を「修正コミット → 履歴記録 → 履歴コミット」三段階フロー明示に書換、AI エージェント側の手順保護を強化（**「パス 1/2 完了時」の既存記述を維持し、パス 3（ユーザー）への適用範囲は L50 の元の境界を踏襲 / Round 1 P2 対応**）。

**Option B / D 不採用理由**:
- B: 責務肥大化と既存全箇所への影響範囲が大きい / write-history 単体テスト境界がぼやける
- D: 履歴粒度変更は v2.5.x 系の他 Unit / 過去サイクルとの互換影響が大きい

### 二重ガードの優先順位（Round 1 P2 対応）

§7.13 新規 `merge-pr` pre-flight ガード（汎用 uncommitted）と §7.13 既存ガード（`.aidlc/config.toml` 特化 / #601 案 B）の関係（**Round 3 P3 対応**: §7.12 / §7.13 のラベル混在を §7.13 内併存に統一）:

| 順序 | ガード | 検出対象 | 発火タイミング | exit code |
|------|--------|----------|----------------|-----------|
| 1 | §7.13 `merge-pr` pre-flight（**本 Unit 新規**）| 全未コミット差分（`git diff` / `git status` baseline）| `merge-pr` コマンド実行直後 | 1 + `pre-merge-uncommitted-detected` |
| 2 | §7.13 `.aidlc/config.toml` 特化（#601 案 B 既存）| 設定保存後の `config.toml` 差分のみ | `write-config.sh --scope project` 実行直後（AskUserQuestion 介入）| 0（AskUserQuestion で対話処理）|

**判定順**: 1 が広範ガード（マージ実行直前の最終防衛線）/ 2 は特化ガード（設定保存フローの専用案内）。両者は対象が異なり競合せず、独立して動作する。

`merge-pr` 実行時に未コミット差分があれば、`config.toml` 差分でも他のファイル差分でも 1 で停止する（実行優先順位は 1 のみで完結）。

## 3. 実装スコープ

### 改修対象（A + C 強化版）

1. **`skills/aidlc/scripts/operations-release.sh` `merge-pr` コマンド** 改修（**Round 1 P1 対応 / script-level 構造ガード**）
   - `merge-pr` 実行時の pre-flight check として `validate-git.sh uncommitted` を呼出
   - 戻り値が `status:warning` 検出時は exit 1 + stderr `error\tpre-merge-uncommitted-detected\t<diagnostics>` で停止
   - `--skip-checks` フラグで明示バイパス可能（既存 `--skip-checks` 規約踏襲 / 緊急時の escape hatch）
   - `--dry-run` 時は実際にマージしないが pre-flight check 自体は実行する（テスト容易性）

2. **`skills/aidlc/steps/operations/operations-release.md` §7.12 / §7.13** 改修
   - §7.12 PR マージ前レビュー完了条件として `verify-git` 再実行を AI エージェント手順として案内（補助）
   - §7.13 PR マージ実行ステップに「`merge-pr` コマンドが pre-flight check で `status:warning` 検出時 exit 1 で停止する」旨を明記
   - レビュー反映 → 一次コミット（修正）→ `/write-history` AIレビュー完了記録 → 二次コミット（履歴のみ）→ `verify-git` 再実行 → `uncommitted=ok` 確認 → §7.13 `merge-pr` 実行（pre-flight check が最終防衛線として機能）の流れを明示

3. **`skills/aidlc/steps/common/review-flow.md` L50** 改修
   - 現状「(2) レビュー後コミット」が単一行で曖昧 → 三段階フロー明示
   - 「(2a) 修正コミット（コードベース変更を反映）/ (2b) 履歴記録 (`/write-history`) / (2c) 履歴コミット（`history/*.md` のみ）」と分割明示
   - **適用範囲**: 既存記述「パス 1/2 完了時」を踏襲（Round 1 P2 対応 / パス 3（ユーザー主導）はユーザー責任で行う既存仕様を維持）

4. **`tests/operations-uncommitted-detection.bats`** 新規作成
   - **U1（実行系）**: TMP 内 git リポで `merge-pr --dry-run` を未コミット差分残存状態で実行 → exit 1 + stderr `pre-merge-uncommitted-detected` を assert（**Round 1 P1 対応 / 文書 grep でなく実行フロー verify**）
   - **U2（実行系）**: TMP 内 git リポで `merge-pr --dry-run` をクリーン状態で実行 → exit 0 + pre-flight pass を assert
   - **U3（実行系）**: `merge-pr --dry-run --skip-checks` で dirty 状態でも pass する（escape hatch verify）
   - U4（文書）: review-flow.md L50 の三段階フローキーワード grep 検証
   - U5（文書）: operations-release.md §7.12 の verify-git 再実行案内 + §7.13 の merge-pr pre-flight 記述 grep 検証
   - **U6（回帰）**: 既存 `#579` post-merge `write-history` exit 3 ガードに影響なし（write-history 単体実行 + post-merge 判定経路で既存挙動を assert）

### 観測点（Option 非依存の最小契約）

- `merge-pr --dry-run` exit code: クリーン時 exit 0 / dirty 時 exit 1
- stderr フォーマット: `error\tpre-merge-uncommitted-detected\t<diagnostics>`（既存 stderr 規約踏襲）
- `--skip-checks` バイパス（escape hatch / 緊急時用）
- review-flow.md L50 の三段階フロー grep 検証
- 既存 `verify-git` / `validate-git.sh uncommitted` 出力フォーマット不変

### 改修対象外（境界保護）

- `skills/aidlc/scripts/write-history.sh`: 本体ロジック変更しない（Option B 不採用 / 既存 post-merge exit 3 ガードはそのまま）
- `skills/aidlc/scripts/validate-git.sh`: 変更なし（uncommitted 判定は既存実装そのまま再利用）
- `operations-release.sh verify-git` コマンド: 変更なし（merge-pr のみに pre-flight 追加 / verify-git 既存契約は不変）
- §7.13 既存 `.aidlc/config.toml` 特化ガード（#601 案 B）: 変更なし（広範ガードと併存 / 二重ガード優先順位は §2 で定義）

## 4. 受け入れ基準（DoD）

### 機能要件

- [ ] **AC1 (Option C 強化版 / script-level 構造ガード)**: `operations-release.sh merge-pr` 実行時に `validate-git.sh uncommitted` が `dirty` を返した場合、exit 1 + stderr `error\tpre-merge-uncommitted-detected\t...` で停止する
- [ ] **AC2 (escape hatch)**: `merge-pr --skip-checks` で dirty 状態でもバイパス可能（緊急時用 / 既存 `--skip-checks` 規約踏襲）
- [ ] **AC3 (Option C / 文書)**: `operations-release.md §7.12` に `verify-git` 再実行案内 / §7.13 に `merge-pr` pre-flight check 記述
- [ ] **AC4 (Option A)**: `review-flow.md` L50 が「(2a) 修正コミット / (2b) 履歴記録 (`/write-history`) / (2c) 履歴コミット」の三段階で明示されている（適用範囲: 既存「パス 1/2 完了時」踏襲）
- [ ] **AC5 (二重ガード優先順位)**: §7.13 新規 pre-flight ガードと既存 `.aidlc/config.toml` 特化ガード（#601 案 B）の併存ルールが §2 に定義されている

### テスト要件

- [ ] **AC6 (実行系テスト)**: `tests/operations-uncommitted-detection.bats` U1-U3 で `merge-pr --dry-run` の構造的ガードが実フロー verify される（文書 grep でない）
- [ ] **AC7 (文書テスト)**: U4-U5 で review-flow / operations-release 文言が三段階フロー記述を含む
- [ ] **AC8 (回帰テスト)**: U6 で既存 #579 post-merge `write-history` exit 3 ガードに影響なし
- [ ] **AC9**: 既存 BATS 全テスト pass（回帰ゼロ / Unit 004 の 305 件 + Unit 005 新規）
- [ ] **AC10**: `shellcheck --severity=warning` で warning 0
- [ ] **AC11**: `bin/check-bash-substitution.sh skills/aidlc/steps/` で違反 0

### 文書要件

- [ ] **AC12**: 既存 `#579` post-merge ガード（exit 3）動作と整合（破壊しないことを review-summary に明記）
- [ ] **AC13**: `review-summary.md` に Option 選定根拠（A+C 強化版 採用 / B+D 不採用）+ 二重ガード設計の記録

## 5. 境界（Unit 001-004 との関係）

### 参照のみ（変更しない）

- Unit 001: `feedback-mode.sh` / config 読込 → 本 Unit は触れない
- Unit 002: `retrospective-issue.sh` + `_spool_extract_entries` → 本 Unit は触れない
- Unit 003: `retrospective-llm-draft.sh` / `retrospective-human-review.sh` → 本 Unit は触れない
- Unit 004: `predecessor-issue.sh` / 01-setup §4a → 本 Unit は触れない

### 共有契約（読み取り）

- `scripts/operations-release.sh verify-git` exit code 規約（既存）
- `validate-git.sh uncommitted` 出力フォーマット（既存）
- review-flow.md パス 1/2/3 の意味論（既存）
- exit code 規約（`guides/exit-code-convention.md`）: 0=success / 1=runtime error / 2=arg error / 3=DR-001 post-merge ガード

## 6. テスト戦略

### BATS テスト構成（U1-U6 / §3 / §4 と整合）

```text
tests/operations-uncommitted-detection.bats
├── setup: TMP cd / git init / 初期コミット作成 / 必要に応じて gh shim 配置
├── U1（実行系）: TMP リポで未コミット差分残存 → merge-pr --dry-run → exit 1 + stderr `pre-merge-uncommitted-detected`
├── U2（実行系）: TMP リポでクリーン状態 → merge-pr --dry-run → exit 0 + pre-flight pass 表示
├── U3（実行系）: TMP リポで dirty 状態 + --skip-checks → exit 0（escape hatch / 既存規約踏襲）
├── U4（文書）: review-flow.md L50 三段階フロー（(2a)/(2b)/(2c)）grep 検証
├── U5（文書）: operations-release.md §7.12 verify-git 再実行案内 + §7.13 merge-pr pre-flight 記述 grep 検証
└── U6（回帰）: write-history.sh 単体実行で post-merge 判定経路の exit 3 ガード（#579）が変更前後で同一動作
```

**重要**: U3 は §3 / AC2 / AC6 と完全整合。Round 1 で残存していた U3 「文書 grep」記述は U4 / U5 に整理済（Round 2 P1 対応）。

### モック戦略

- `git` コマンド: 実 git を使用（TMP 配下で `git init` した一時リポを操作）
- `gh` コマンド: shim 不要（本 Unit は gh を呼ばない / verify-git も gh 不要）
- `validate-git.sh`: 実装そのまま使用（境界外）

### セキュリティ / 正確性

- TMP 配下で完結（`cd "$TMP"` で実リポを汚染しない / Unit 004 で発見した致命バグの再発防止）
- shellcheck `severity=warning` で 0 件
- `$()` 規約準拠（CLAUDE.md / `bin/check-bash-substitution.sh`）

## 7. 実装順序

1. **Phase 1 設計**: ドメインモデル + 論理設計
   - PreCommitHistoryGuard（pre-merge 履歴コミット漏れ検出 / verify-git 再利用 / フロー三段階記述）
   - 純粋関数なし（既存 verify-git の再呼び出し + 文書改修のみ）
2. **Phase 1 設計レビュー**（codex）
3. **Phase 2 実装**: §7.12 文書改修 + review-flow.md L50 改修 + BATS テスト
4. **Phase 2 コードレビュー + 統合レビュー**
5. **04-completion**: history / progress / commit / push

## 8. リスク評価

| リスク | 影響度 | 対策 |
|--------|--------|------|
| review-flow.md L50 改修が AI レビュー反復の解釈に影響 | 中 | 既存「パス 1/2 完了時」境界を維持（Round 1 P2 対応）/ Set 1 計画レビューで明示確認 |
| §7.12 完了条件追加で既存 Operations フロー実行時間が増加 | 低 | `verify-git` 再実行は既存 7.9-7.11 と同手段 / 増加分は秒単位で許容範囲 |
| BATS テストで実 git を使う分の不安定性 | 中 | TMP 内に独立リポ構築 / 各テストで完全 setup/teardown |
| 既存 #579 post-merge exit 3 ガード破壊 | 高 | U6 で回帰テスト + Set 4 統合レビューで write-history 呼出順序の整合確認 |
| **`merge-pr --dry-run` 制御フロー reorder（Round 2 P2 対応）**: 既存実装は `--dry-run` 時に pre-flight check 前に early return する可能性あり / pre-flight 追加時は `--dry-run` も pre-flight check を必ず通すよう reorder 必須 | 高 | Phase 1 設計で `merge-pr` 内の制御フロー（引数 parse → pre-flight check → dry-run early return → 実マージ）の順序を明示 / Phase 2 実装後 U2 で `--dry-run` + clean / U1 で `--dry-run` + dirty / U3 で `--skip-checks` の 3 ケースを実行検証 |

## 9. 完了後の Operations フロー（変更後の流れ）

```text
§7.9-7.11 verify-git（事前）
   ↓ uncommitted=ok / remote-sync=ok / default-branch=ok
§7.12 PR マージ前レビュー
   ↓ 指摘あり: 修正 → (2a) 修正コミット → (2b) /write-history AIレビュー完了 → (2c) 履歴コミット → 再レビュー
   ↓ 指摘0件確定
§7.12 完了条件: verify-git 再実行 → uncommitted=ok 確認【新規】
   ↓ uncommitted=dirty: §7.13 進行ブロック → §7.12 (2c) に戻る
   ↓ uncommitted=ok
§7.13 PR マージ実行
   ↓
post-merge: write-history 呼出は exit 3（既存 #579 ガード）
```
