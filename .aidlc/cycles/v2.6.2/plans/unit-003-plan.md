# Unit 003 計画: Operations §7.12.5 squash-712 と write-history operations-round の整合性

## 対象

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/003-fix-squash712-history-integration.md`
- 関連 Issue: #677（致命的バグ）
- 関連先行 Issue: #639（§7.12.5 導入起点）, #654（Construction Phase 側で同根の問題を解決した先行事例）

## 目的

Operations Phase §7.12.5 PR レビュー反映 commit Squash 統合（`scripts/operations-release.sh squash-712`）が、§7.12 PR マージ前レビュー後の `write-history.sh --mode operations-round` で append された **unstaged history 差分**を取り込めず、レビュー反映 commit が squash 後に分離する構造的バグを解消する。

`merge_method=merge` 下で main 履歴に「Operations Phase完了 commit / squash 統合 commit / レビュー反映 history commit」の 3 commit 残存（本来は 1 squash 統合 commit に集約されるべき）を撲滅する。

## スコープ

### 含まれるもの

採用案は Construction 設計レビューで確定する（Unit 定義の制約に従い、案 C 単独不可、補助併用のみ可）。**現時点の暫定推奨は「A + B 併用」**（多層防御）。設計レビューで確定する。

#### 共通（採用案によらず実施）

1. 採用案決定の意思決定を `.aidlc/cycles/v2.6.2/inception/decisions.md` 末尾または `design-artifacts/decisions/` に追記（Construction Phase 設計レビュー時に確定）
2. 影響する手順書（`steps/operations/operations-release.md` §7.12 / §7.12.5）の SoT 明示化更新（採用案を反映）
3. CHANGELOG.md に v2.6.2 Unit 003 として変更内容を追記

#### 案 A（`write-history.sh --mode operations-round` の auto-commit 化）

採用時に実施:

1. `scripts/write-history.sh` の `--mode operations-round` 経路に **auto-commit ロジック**を追加:
   - append 後、`history/operations.md` を `git add`
   - commit message: `chore: [<cycle>] §7.12 レビュー round <N> 履歴記録`（フォーマットは設計時に確定）
   - `--no-commit` フラグで opt-out 可能（既存 append-only 動作を維持）
2. 既存 `check_history_staged_status()` 警告経路（#654）との関係整理:
   - 現行実装では `check_history_staged_status()` は `--mode base` 経路のみで呼び出される（[`write-history.sh:1077`](../../../skills/aidlc/scripts/write-history.sh) 確認済）
   - **案 A 採用時の方針**: `--mode operations-round` の安全網は新設する **auto-commit ロジック自体**が担い、`check_history_staged_status()` 警告経路には依存しない
   - `--no-commit` opt-out 時は append のみとなり、commit 漏れは後段の **案 B（squash-712 fail-fast）または §7.13 pre-flight check `validate-git.sh uncommitted`** が検知層となる（案 A 単独採用時は §7.13 pre-flight check のみが検知層、A+B 併用時は §7.12.5 段階でも早期検知）
   - `operations-round` 経路への `check_history_staged_status()` 呼び出し追加は本 Unit のスコープ外（必要に応じて別 Issue で追加検討）
3. **副作用契約の明文化**: `--mode operations-round` のみ auto-commit、`--mode base` / `--mode unit-complete-short-note` は従来通り append のみ（Construction Phase 側は #654 でフロー側 commit に統合済みのため変更しない）

#### 案 B（`squash-712` の fail-fast 化）

採用時に実施:

1. `cmd_squash_712()` 冒頭（Step 1 の `squash_enabled` 取得後、Step 2 以降の前）に **dirty 検出ガード**を追加:
   - `git status --porcelain` で `history/operations.md` の unstaged / staged 差分を検出
   - 差分検出時: exit 1 + stderr `error\tsquash-712:uncommitted-history\t<path>` + 案内 `recommended_command:cd <repo> && git add <path> && git commit -m "<message>" の後に再実行` を出力
   - dry-run モード（`--dry-run`）でも検証を行う（実行前検証のため）
2. dirty 判定対象パターンの確定（設計時、最低限 `.aidlc/cycles/<cycle>/history/operations.md`）
3. escape hatch（`--allow-dirty-history` 等）は **導入しない**（運用ミス検出が目的のため）

#### 案 A + B 併用

採用時に実施:

1. 案 A と案 B を両方実装
2. 通常運用では案 A が auto-commit するため案 B の fail-fast は発火しない
3. `--no-commit` opt-out 時 / write-history.sh 経路を経由しなかった場合 / バグ回帰時に案 B が最終検知層として機能

### 含まれないもの

- Construction Phase 側の `--mode unit-complete-short-note` 経路の auto-commit 化（#654 で既に構造解決済み、再設計不要）
- 他フェーズ（Inception Phase）の write-history 振る舞い変更
- `--mode base` の auto-commit 化（履歴 append の汎用入口であり、commit タイミング判断は呼び出し側責務）
- `merge_method=squash` / `rebase` のフローでの動作変更（本 Unit は `merge_method=merge` 下での問題解消）
- §7.12.5 内部の `git reset --soft` / `git commit` ロジックそのものの再設計（dirty 検出のみ追加、本体ロジックは維持）

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [x] Construction 設計レビューで採用案（**A+B 併用**）が確定し、`decisions.md` に記録されている
- [x] 採用案実装が `scripts/write-history.sh`（`_commit_operations_round_history` + `--no-commit` + main フック 2 箇所）および `scripts/operations-release.sh`（`__squash_712_check_history_clean` + `cmd_squash_712` ガード）に反映されている
- [x] 採用案ごとの bats テストが追加され、各 AC を網羅している（`write-history-operations-round-commit.bats` 6 ケース / `operations-release-squash712-dirty-history.bats` 7 ケース）
- [x] integration テスト（`§7.12 → write-history → squash-712 → git log` で 1 squash commit を確認）が追加されている（`operations-release-squash712-integration.bats` 2 ケース）
- [x] CHANGELOG.md / 関連手順書（`steps/operations/operations-release.md`）が採用案に応じて更新されている（手順書 §7.12 / §7.12.5 更新済。CHANGELOG.md は Operations Phase の §7.2 で一括対応する既存方針に従う）

### Issue #677 受け入れ基準（観測現象の解消）

- [x] §7.12 → §7.12.5 の正常運用フローで、レビュー反映 commit が squash 統合 commit に取り込まれることが integration テストで検証されている（`integration: A+B normal 経路` ケース）
- [x] `merge_method=merge` 下で main 履歴に分離 commit が残らないことが integration テストで検証されている（同上、`git log <RELEASE_PREP_SHA>..HEAD --oneline` 行数 = 1 を観測点として明示）
- [x] **案 A 採用時**: `--no-commit` フラグで従来 append-only 挙動が維持されることが bats テストで検証されている（`operations-round: --no-commit opt-out` ケース）
- [x] **案 B 採用時**: history dirty 状態で `squash-712` 実行時に exit 1 + tab 区切り stderr (`error\tsquash-712:uncommitted-history\t...`) + 案内が出力されることが bats テストで検証されている（`squash-712: history unstaged/staged dirty` ケース）
- [x] **A+B 併用時**: 上記 A / B の双方条件を満たす（integration テスト 2 ケースで連鎖検証）

### 非機能要件（NFR）

- [x] **可搬性**: macOS / Linux 双方の bash で動作（既存 `git status --porcelain` / `git add` / `git commit` のみ使用、stat -c %s 等の非可搬コマンドは使用していない）
- [x] **後方互換性**:
  - 案 A 採用時: `--no-commit` で従来挙動を完全保持（bats `--no-commit opt-out` ケースで検証）
  - 案 B 採用時: dirty 状態でない正常運用は影響を受けない（bats `clean` ケースで検証）
- [x] **テスタビリティ**: 採用案ごとの専用 AC が bats / integration テストで自動検証可能（合計 15 ケース、全 pass）
- [x] **エラー出力の機械可読性**: tab 区切り `error\t<code>\t<context>` 形式を維持（既存 `operations-release.sh` 規約踏襲）

### Intent 制約

- [x] **破壊的変更なし**:
  - 案 A 採用時: `--no-commit` で opt-out 可能 + 事前 staged ガード + 非 git 環境ガードの 3 層で互換性保護
  - 案 B 採用時: エラー検出のみ追加で正常系には影響しない（bats `clean` ケースで非干渉確認）
- [x] **ドッグフーディング特殊処理なし**: 採用案ロジックは consumer プロジェクトでも同一動作。自リポジトリ判定による分岐は導入していない
- [x] **コマンド置換禁止**: 実装内で `$(...)` 形式のコマンド置換を新規導入していない（既存 `write-history.sh` / `operations-release.sh` の規約踏襲、新規追加コードはすべて変数代入 + パイプ経由）

## 実装方針（概略 / 設計レビューで詳細化）

### 案 A 採用時

1. **検証ヘルパー** `_write_history_commit_operations_round()` を `write-history.sh` 内に追加:
   - 入力: `$1=filepath`, `$2=cycle`, `$3=round`
   - 動作: `git add <filepath>` → `git commit -m "<message>"` → 結果出力
   - 戻り値: 成功 0 / 失敗 1
   - dry-run 時は `git add` / `git commit` をスキップして `would-commit` ログのみ出力
2. **`main` の append 完了後（appended 出力直前）**に `--mode operations-round` 分岐で `_write_history_commit_operations_round` 呼び出し（`--no-commit` フラグなしの場合のみ）
3. **bats**: `write-history-modes.bats` または新規 `write-history-operations-round-commit.bats` に「auto-commit / `--no-commit` opt-out / dry-run」3 ケース追加

### 案 B 採用時

1. **検証ヘルパー** `__squash_712_check_history_clean()` を `operations-release.sh` 内に追加:
   - 入力: `$1=cycle`
   - 動作: `git status --porcelain -- ".aidlc/cycles/${cycle}/history/operations.md"` の出力チェック
   - 戻り値: clean 0 / dirty 1
   - 出力: dirty 時に tab 区切り stderr + 案内
2. **`cmd_squash_712()` の Step 1 完了直後**にヘルパー呼び出し
3. **bats**: 既存 `operations-release-*.bats` パターンに準じて新規 `operations-release-squash712-dirty-history.bats` 追加（dirty / clean 2 ケース）

### A + B 併用時

両方を実装。テストは各案の bats + 「auto-commit 経路後に squash-712 が dirty 検出しない（clean）こと」の integration ケース追加。

### integration テスト方針

- 一時 git リポジトリで `.aidlc/cycles/v2.6.2/history/operations.md` を含む最小構成を再現
- `release_prep_commit` slot を持つ progress.md を配置
- 「§7.7 commit → §7.12 codex review → write-history → squash-712 → `git log` で 1 squash commit 確認」を再現
- **観測点（明確化）**: 検証は **`git log <release_prep_commit>..HEAD --oneline` の出力行数が 1** であることを確認する（local 一時リポジトリ内で完結。main 側履歴は使わない）。受け入れ基準対応:
  - 入力ステート: `release_prep_commit` 時点を起点とした feature ブランチ上に「修正コミット 1 件以上」+「`history/operations.md` への append（auto-commit 化済み）」が積まれた状態
  - 出力期待値: `squash-712` 実行後、`git log <release_prep_commit>..HEAD` の行数が `1`、かつ HEAD の `git show --stat HEAD` 出力に `history/operations.md` の差分が含まれる
- 観測点を auto-commit 経路と非 auto-commit 経路（案 A `--no-commit` 経路 / 案 B 単独経路）双方で検証
- bats 形式または別途 shell スクリプト形式（既存テスト構成と整合）

## 依存・前提

- bash + git: 既存 `operations-release.sh` / `write-history.sh` の動作環境
- bats / shellcheck / shellharden: 既存テスト環境
- `scripts/lib/` 配下の既存ユーティリティ（`emit_error`, `validate-git.sh` 等）を再利用

## リスクと緩和

| リスク | 影響 | 緩和策 |
|--------|------|--------|
| 案 A 採用時、auto-commit によって意図しない commit が生成される | 中 | `--no-commit` opt-out 提供。デフォルトは AI-DLC フローでの安全側（auto-commit）を採用 |
| 案 A の commit message フォーマットが他フローと衝突 | 低 | `chore: [<cycle>]` プレフィックス維持で既存規約踏襲。設計時に最終確定 |
| 案 B の dirty 判定が staged 状態を見逃す | 中 | `git status --porcelain` は staged / unstaged 双方を検出する仕様。テストで両ケース網羅 |
| 案 B が `merge_method=squash` 等の正常運用でも誤発火 | 低 | `--cycle` 引数からパス特定 + 対象ファイル明示で範囲を限定 |
| integration テストの再現が壊れやすい | 中 | 一時 git リポジトリ + minimal fixture 構成で隔離。既存 `operations-release-pr-*.bats` の shim パターンを踏襲 |
| A + B 併用時の責務境界が曖昧化 | 低 | 「案 A = 通常運用での自動化」「案 B = 多層防御 / 運用ミス検出」と明示。手順書 SoT 更新で利用者に伝達 |

## 想定タイムライン

採用案ごとに変動:

- **案 A 単独**: Phase 1 設計 0.5 時間 + Phase 2 実装 1 時間 + 完了 0.5 時間 = 約 2 時間（0.5 日相当）
- **案 B 単独**: Phase 1 設計 0.5 時間 + Phase 2 実装 0.5 時間 + 完了 0.5 時間 = 約 1.5 時間
- **A + B 併用**: Phase 1 設計 1 時間 + Phase 2 実装 2 時間 + 完了 0.5 時間 = 約 3.5 時間（最大 1.5 日 / Unit 見積もり上限）

設計レビューで採用案確定後にタイムラインを再確定する。
