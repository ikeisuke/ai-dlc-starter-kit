# 実装計画: Unit 003 — CycleResolver 明示指定優先の回帰テスト（T6）

- **サイクル**: v3.0.0-alpha.4
- **対象 Unit**: 003-cycle-resolution-regression-test
- **関連 Issue**: #733（部分対応 / T6 のみ / Relates、Closes ではない）
- **depth_level**: standard（Phase 1 設計あり。ただしテスト追加主体のため設計は軽量）
- **実装優先度**: Medium
- **依存**: なし（cycle 解決は frontmatter parser 集約と独立。Unit 001/002 と並行実装可能）

## 1. 目的

v3 の cycle 解決入口が `.aidlc/state.json` の `current_cycle`（明示指定）を唯一の真実源として解決し、git 履歴・周辺ファイル名・ディレクトリ走査順に影響されないことを固定する回帰テストを追加する。

v3 本体は既に明示指定一本化済み（`state-read.sh current_cycle` 読取のみ / gitlog 推定ロジックなし / RFC DG-6）であり、本 Unit はその仕様を**回帰テストとして固定**して #733 P4 クラス（framework 側が古い `v2.6.6` を返した実体）の v3 における再発を防止する。

**性質**: 回帰テストの追加のみ。production code（`state-read.sh` 等）の変更は想定しない。既存仕様が既に明示指定一本化のため、テスト追加で挙動変更は発生しない想定（差分が出た場合は要調査）。

## 2. 現状（調査結果サマリ）

- **cycle 解決入口**: `skills/aidlc-v3/scripts/state-read.sh`。`current_cycle` フィールドを `.aidlc/state.json` から jq で読取り stdout へ出力する read-only スクリプト。git 履歴・ファイル名走査・gitlog 推定は一切行わない（コード上、git 関連呼び出しなし）。
  - `current_cycle` 欠落時: キー存在確認（`has()`）で `exit 1`（`error: field not present in state`）。
  - 明示 `null` 時: `"null"` を出力して `exit 0`（欠落とは区別）。
  - ファイル不存在: `exit 1`。JSON 不正: `exit 1`。jq 未導入: `exit 2`。
- **schema 妥当性検証**: `state-validate.sh` の責務。`current_cycle` 必須・string 型必須（非 string は `exit 1`）。
- **既存テスト**: `skills/aidlc-v3/scripts/tests/test-state-scripts.sh`（308 行 / 自己完結ハーネス）。
  - `make_valid_state()` fixture（`current_cycle: "v3.0.0"`）。
  - `assert_rc` / `assert_out` ヘルパ。`mktemp -d` サンドボックス + `trap 'rm -rf' EXIT`。先頭で `bash -n` / `shellcheck` 静的検査。
  - 既に部分的に関連カバー: `current_cycle を読める`（`assert_out "v3.0.0" ... READ current_cycle`）、`current_cycle 欠落 → validate 無効`、`current_cycle 非 string → 無効`。
  - **未カバー（本 Unit の新規価値）**: 「git 履歴・周辺ファイル名が `current_cycle` と異なっても解決が影響されない」という gitlog 非依存の明示的回帰検証。
- **テストランナー / CI**: `skills/aidlc-v3/scripts/tests/*.sh` を集約実行する CI ワークフローは存在しない（`pr-check.yml` / `migration-tests.yml` いずれも対象外）。これらは開発時にローカル実行する自己完結ハーネス。→ **新規テストファイル追加に CI 登録は不要**。実行は各 `test-*.sh` を直接起動する運用。

## 3. スコープ

### 含む（T6）

- `skills/aidlc-v3/scripts/tests/` への cycle 解決回帰テスト追加。**新規 `test-cycle-resolution.sh`** として追加する（理由は §4.1 参照）。
- **検証軸 1（明示指定優先）**: `current_cycle` 設定時、`state-read.sh current_cycle` がその値を解決する。
- **検証軸 2（gitlog 非依存 / 本 Unit の中核）**: mktemp サンドボックス内に git リポジトリを作り、`current_cycle` と**異なる** cycle 名を含む commit 履歴・周辺ファイル/ディレクトリ（例: `.aidlc/cycles/v2.6.6/`、別 cycle 名のコミットメッセージ・ファイル）を作成しても、解決結果が `state.json` の `current_cycle` 値に一致し、git 履歴・ファイル名に影響されないことを検証する。
- **検証軸 3（未設定/欠損時の既存仕様）**: `current_cycle` 欠落時に `state-read.sh` が `exit 1`（明示エラー）すること、`state-validate.sh` が無効判定すること。明示 `null` の扱い（`"null"` 出力 + `exit 0`）も固定する。
- 既存ハーネス様式への準拠（`assert_rc` / `assert_out` / `mktemp -d` + `trap` / 先頭 `bash -n`・`shellcheck` 静的検査 / 終了コード 0=全成功 / 1=失敗あり / 2=前提不備）。

### 含まない（境界 / Unit 定義「扱わない」+ Intent 除外）

- framework 側（`skills/aidlc/`）の CycleResolver 修正（#733 P4 で `v2.6.6` を返した実体は framework 側ツールの可能性が高いが、本サイクル GA スコープ外 / Intent 除外事項）。
- v3 cycle 解決ロジックの新規実装・変更（既存仕様の回帰テスト固定のみ。production code 変更が不要なら追加しない）。
- 共有 parser（Unit 001）/ CI ガード（Unit 002）。
- `skills/aidlc-v3/scripts/tests/*.sh` を集約する CI ランナーの新設（本 Unit スコープ外 / 既存運用に合わせる）。

## 4. 実装アプローチ

### Phase 1: 設計（軽量）

1. **ドメインモデル**: 検証概念（`CycleResolution` = state.json 明示指定一本 / `ExplicitCurrentCycleWins` / `GitlogIndependence` / `MissingCycleRejection`）と、回帰テストで固定する不変条件を定義。
2. **論理設計**: 新規 `test-cycle-resolution.sh` の構成（ハーネス様式・assert ヘルパ・サンドボックス手順）、3 検証軸のテストケース表、gitlog 非依存を証明するサンドボックス構築手順を確定。

#### 4.1 設計判断: 新規ファイル vs 既存追加（Phase 1 で最終確定 / 暫定第一候補を明示）

Unit 定義は「新規 `test-cycle-resolution.sh` または既存 `test-state-scripts.sh` への追加」を許容。**暫定第一候補: 新規 `test-cycle-resolution.sh`**。

- 理由: (a) 「cycle 解決 / gitlog 非依存」は `state-*.sh` の汎用 CRUD/終了コードテストとは関心が異なる独立した回帰の固定であり、#733 P4 の回帰テストとして単独ファイルの方が指し示しやすい。(b) gitlog 非依存テストは git サンドボックス構築という重めのセットアップを伴い、既存 308 行ファイルへの混入よりも分離した方が見通しがよい。(c) 既存 `make_valid_state` / assert ヘルパは新規ファイルにも自己完結で再定義（既存ハーネスはフレームワーク非依存方針のため、共通 source 化はしない）。
- Phase 1 で最終確定する（既存追加に倒す場合も、テストケースの内容・網羅は不変）。

#### 4.2 gitlog 非依存テストの設計（中核 / Phase 1 で手順確定）

「解決が git 履歴・周辺ファイル名に影響されない」ことを**積極的に証明**するため、解決入口を意図的に「騙そうとする」サンドボックスを構築して、それでも `current_cycle` 値が返ることを示す:

1. `sandbox="$(mktemp -d)"`、`trap` で除去。
2. サンドボックス内の git 操作は **サブシェルで `cd "$sandbox"` してから実行**する（`git -C` は使わない / AGENTS.md「git はカレントディレクトリで実行する / `-C` 不使用」規約に準拠）。`git init` + ローカル `user.email` / `user.name` / `commit.gpgsign=false` を `git -c key=val` で明示設定（環境非依存）。例: `( cd "$sandbox" || exit 2; git init -q; git -c user.email=t@example.com -c user.name=test -c commit.gpgsign=false commit -q -m ... )`。
3. **誤誘導要素**を作る:
   - `current_cycle` と異なる cycle 名（例: `v2.6.6`、`v1.0.0`）を含むコミットメッセージ / ファイル名（例: サンドボックス内に `.aidlc/cycles/v2.6.6/` ディレクトリ・別 cycle 名ファイルを commit）。
   - 周辺に複数の cycle ディレクトリを作りディレクトリ走査順の影響有無を確認。
4. サンドボックス内 `.aidlc/state.json` に `current_cycle: "v3.0.0"`（誤誘導要素と異なる値）を書く。
5. `state-read.sh current_cycle <state.json>` を実行し、`assert_out "v3.0.0"` で解決値が state.json 値に一致することを検証（git 履歴・ファイル名の `v2.6.6` 等に**ならない**ことを固定）。
6. 補強: `current_cycle` を別の値（例: `v9.9.9`）に書き換えても、その state.json 値が返る（解決が state.json driven であることの двойной確認）。

> 注: v3 の `state-read.sh` はそもそも git を参照しないため、本テストは「現仕様が壊れていないこと」を恒久的に固定する回帰テスト。万一将来 gitlog 推定が混入したら本テストが赤になる。

#### 4.3 テストケース表（Phase 1 で確定 / 暫定）

| # | 検証軸 | ケース | 期待 |
|---|--------|--------|------|
| 1 | 明示指定優先 | `current_cycle="v3.0.0"` の state.json を read | `out=v3.0.0` / `rc=0` |
| 2 | 明示指定優先 | `current_cycle="v9.9.9"`（任意値）を read | `out=v9.9.9` / `rc=0` |
| 3 | gitlog 非依存 | git 履歴・周辺に `v2.6.6` 誤誘導要素、state.json は `v3.0.0` | `out=v3.0.0`（`v2.6.6` にならない）/ `rc=0` |
| 4 | gitlog 非依存 | 同サンドボックスで state.json を `v9.9.9` に変更 | `out=v9.9.9` / `rc=0` |
| 5 | 未設定時拒否 | `current_cycle` キー欠落 | `state-read.sh` `rc=1` |
| 6 | 未設定時拒否 | `current_cycle` 欠落 | `state-validate.sh` `rc=1`（無効） |
| 7 | 明示 null 区別 | `current_cycle: null` | `state-read.sh` `out=null` / `rc=0` |

（最終ケース数・文言は Phase 1/実装で微調整。ケース 7 は欠落と明示 null の区別を固定する既存仕様の念押し。）

### Phase 2: 実装

1. `skills/aidlc-v3/scripts/tests/test-cycle-resolution.sh` を実装（既存ハーネス様式準拠: shebang `#!/usr/bin/env bash` + `set -uo pipefail` / `SCRIPT_DIR`・`SCRIPTS_DIR` 解決 / `READ`・`VALIDATE` パス / jq 前提チェック（未導入 `exit 2`）/ `PASS`・`FAIL` カウンタ / `mktemp -d` + `trap` / `assert_rc`・`assert_out` / 先頭 `bash -n`・`shellcheck`（導入時）静的検査 / 末尾サマリ + 終了コード）。
2. §4.2 の gitlog 非依存サンドボックスヘルパ（`make_gitlog_decoy_sandbox()` 等）を実装。**サンドボックス git 操作はサブシェル `( cd "$sandbox" || exit 2; ... )` 内で実行し `git -C` は使わない**（AGENTS.md 規約準拠）。git 設定は `git -c user.email=... -c user.name=... -c commit.gpgsign=false ...` で環境非依存化。
3. §4.3 のテストケースを実装。
4. 新規テストを実行 → **緑**（現仕様は明示指定一本化のため全ケース合格が完了条件）。
5. v3 全テストスイート（`test-*.sh` 6 本 + 新規 1 本）+ 既存 check スクリプト（`bin/check-*.sh`）を実行し回帰緑を確認。
6. `bash -n` / `shellcheck`（導入時）緑を確認。

#### 4.4 opt-in シグナル原則の遵守

「ドッグフーディング特殊処理を本体に埋めない」原則に従い、テストはサンドボックス内で完結し、本体スクリプトに「starter kit / consumer 判定」分岐を追加しない（本 Unit はテスト追加のみで本体不変のため自然に充足）。

#### 4.5 production code 差分が出た場合の扱い

Unit 定義の想定は「既存仕様が既に明示指定一本化のため挙動変更なし」。万一テスト作成過程で `state-read.sh` 等に gitlog 推定の残骸や想定外挙動が見つかった場合は、それは回帰テスト追加の枠を超える**スコープ判断事項**として作業を止めてユーザーに報告する（独自判断で production code を修正しない）。

## 5. 完了条件チェックリスト

Unit 定義「責務」+ ストーリー 4 + Intent T6 から抽出:

- [ ] `skills/aidlc-v3/scripts/tests/` に cycle 解決回帰テスト（新規 `test-cycle-resolution.sh` または既存追加）が追加されている
- [ ] 「`current_cycle` 設定時はその値が解決される」検証が含まれている（明示指定優先）
- [ ] 「git 履歴・周辺ファイル名が `current_cycle` と異なっても解決結果が影響されない」検証が含まれている（gitlog 推定非依存 / mktemp+git サンドボックスで誤誘導要素を作って固定）
- [ ] `current_cycle` 未設定/欠損時の既存仕様（`state-read.sh` `exit 1` 拒否 / `state-validate.sh` 無効判定）の確認が含まれている
- [ ] 明示 `null` と欠落の区別（`"null"` 出力 + `exit 0`）を固定している
- [ ] 既存ハーネス様式に準拠（`assert_rc`/`assert_out` / `mktemp -d`+`trap` / 終了コード 0/1/2 / 先頭静的検査）
- [ ] git サンドボックスが環境非依存（`user.email`/`user.name`/`commit.gpgsign=false` を明示設定、グローバル git 設定に依存しない）
- [ ] サンドボックス git 操作は **サブシェル `( cd "$sandbox" ... )` 内で実行し `git -C` を使わない**（AGENTS.md「git はカレントディレクトリで実行 / `-C` 不使用」規約準拠）
- [ ] 新規テストが緑（現仕様 = 明示指定一本化のため全ケース合格）
- [ ] v3 全テストスイート + 既存 check スクリプトが緑（回帰なし）
- [ ] `bash -n` / `shellcheck`（導入時）緑
- [ ] production code（`state-read.sh` 等）に挙動変更を加えていない（差分が出た場合は§4.5 に従いユーザー報告）
- [ ] bash 3.2/4.0+ 互換 / `set -uo pipefail` を維持
- [ ] Bash ツール経由のコマンド置換禁止規約（CLAUDE.md）に違反しない

## 6. リスクと留意点

- **「証明」の強度**: v3 `state-read.sh` は元々 git を参照しないため、gitlog 非依存テストは「壊れていないことの固定」。誤誘導要素（別 cycle 名の git 履歴・ファイル）を実際に作り、それでも state.json 値が返ることを示すことで、将来 gitlog 推定が混入したら赤になる**実効的な回帰ガード**にする（単に `assert_out` するだけの空虚なテストにしない）。
- **git サンドボックスの環境依存**: グローバル `user.name`/`user.email` 未設定環境や `commit.gpgsign` 設定で commit が失敗しうる。→ `git -c` で明示設定 + `-c commit.gpgsign=false` 等で環境非依存化。CI/ローカル両方で緑にする。
- **mktemp / trap の確実な後始末**: サンドボックスは `trap 'rm -rf "$TMPDIR_TEST"' EXIT` で確実に除去（既存ハーネス踏襲）。テスト内で `cd` する場合はサブシェルに閉じ込め、カレントディレクトリ汚染を避ける。
- **production code 差分**: §4.5 のとおり、想定外差分はスコープ判断事項としてユーザー報告（独自修正しない）。
- **コマンド置換禁止規約**: テストスクリプト内部のコマンド置換はファイル実行であり対象外だが、Bash ツール引数・コミットメッセージ・codex レビュープロンプトに `$(...)` / backtick を含めない（zsh OOM 回避 / CLAUDE.md）。

## 7. AI レビュー

- `review_mode=required`（tools=codex）。設計 / コード / 統合の各承認前に AI レビューを実施（スキップ不可）。計画承認前レビューも本ステップで実施。
- 外部 CLI（codex）呼び出し前に必ずローカル `git diff` レビューを実施（`.aidlc/rules.md`「ローカルレビュー必須ルール」）。
- codex は非対話環境で `</dev/null` で stdin を閉じる（stdin 待ちガード / CLAUDE.md）。
