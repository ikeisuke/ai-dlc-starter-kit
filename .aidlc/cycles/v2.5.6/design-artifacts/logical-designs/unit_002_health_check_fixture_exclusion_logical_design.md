# 論理設計: main-repo-health-check の fixture 誤検出除外

## 概要

`check_conflict_marker()` の `git grep` 呼び出しに pathspec exclusion を 2 件追加し、bats 受け入れテスト 2 種で「除外パスは warning にならない」「非除外パスは warning が立つ」ことを検証する。CI wiring を `migration-tests.yml` に追加して当該 bats を継続実行する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（diff 行、bats `@test` 本文、yaml 編集 diff 等）は Phase 2 の実装ステップで作成します。

## アーキテクチャパターン

**Filter Pipeline（フィルタパイプライン）**を採用する。`git grep` の native な pathspec exclude を「フィルタ適用層」として活用し、`check_conflict_marker()` のロジック本体（出力フォーマッタ + exit code 決定）は不変に保つ。

選定理由:

- 既存実装（`check_conflict_marker()`）は `git grep` の単純呼び出し → 出力整形 → 戻り値決定という直線パイプライン。pathspec exclude は git native 機能のため、新規モジュール導入なしで「フィルタ層」を追加可能
- 代替案（`git ls-files` で対象ファイル列挙 → `awk`/`grep` で検索）は POSIX 互換性 / パフォーマンス両面で劣化する。pathspec native は git 2.13+ で動作保証
- BATS fixture 側 escape 案（heredoc 連結 / unicode 置換）は責務違反（テストの意図を壊す）として Unit 境界外

## コンポーネント構成

### モジュール構成

```text
skills/aidlc/scripts/main-repo-health-check.sh
└── check_conflict_marker()         # 改修対象（line 139-160）
    └── git grep（pathspec フィルタ層）  # 改修箇所: line 145

tests/main-repo-health-check.bats
├── 既存 5 シナリオ（不変）
├── @test "exclusion: fixture/docs paths..."  # 新規 (a)
└── @test "warning: non-excluded path..."     # 新規 (b)

.github/workflows/migration-tests.yml
├── PATHS_REGEX (line 25)            # 改修: 2 パターン追記
└── bats run line (line 66)           # 改修: 1 ファイル追記
```

### コンポーネント詳細

#### `check_conflict_marker()`（既存関数の改修）

- **責務**: main worktree に未解決コンフリクトマーカーが残存しないかを scan し、出力フォーマット 1 行を返す（変更なし）
- **依存**: `git grep`, `printf`, `wc`, `tr`（変更なし）
- **公開インターフェース**: シェル関数として `check_conflict_marker "$main_repo_path"` 形式で呼び出される（変更なし）。戻り値 0=OK / 1=warning / 2=error も維持

改修ポイント: `git grep` の引数末尾に pathspec separator `--` と除外指定 2 件を追加する 1 行差分。

#### `tests/main-repo-health-check.bats`（既存テストファイルへ追記）

- **責務**: `check_conflict_marker` を含む `main-repo-health-check.sh` 全体の挙動を bats フレームワークで検証する
- **依存**: bats-core、`git`、`mktemp`、`BATS_TEST_TMPDIR` 環境変数（既存と同等）
- **公開インターフェース**: `bats tests/main-repo-health-check.bats` で起動。新規 `@test` 2 件は既存 setup/teardown を共有する

#### `.github/workflows/migration-tests.yml`（CI wiring 追加）

- **責務**: PR 差分が `PATHS_REGEX` にマッチした場合に bats を実行し、対象テスト群が PASS することを検証する
- **依存**: GitHub Actions、`bats@1.11.1` セットアップステップ（line 46-48 既存）
- **公開インターフェース**: `pull_request` event でトリガ。Required check として運用される想定（branch protection 設定は本 Unit の境界外）

## インターフェース設計

### スクリプトインターフェース設計

#### `check_conflict_marker()`（改修後）

- **概要**: 未解決コンフリクトマーカーの scan、ただし fixture/docs を除外
- **引数**:

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (`main_repo_path`) | 必須 | main worktree のルート絶対パス |

- **成功時出力**:
  - count=0: `health-check:conflict-marker:ok:count=0`（exit 0）
  - count≥1: `health-check:conflict-marker:warning:count=N`（exit 1）
- **エラー時出力**: `health-check:conflict-marker:error:git-grep-failed`（exit 2）
- **出力先**: 標準出力（既存と同等）

#### git grep コマンド（改修前後）

**改修前**（`main-repo-health-check.sh:145`）:

```text
git -C "$main_repo_path" grep -I -n -E "^<<<<<<< |^>>>>>>> |^=======$"
```

**改修後**:

```text
git -C "$main_repo_path" grep -I -n -E "^<<<<<<< |^>>>>>>> |^=======$" \
    -- ':(exclude)tests/main-repo-health-check.bats' \
    ':(exclude).aidlc/cycles/**/design-artifacts/**'
```

評価順:

1. `git grep` は worktree のすべての tracked ファイルを対象とする（`--cached` なしのため worktree 状態を読む）
2. `-I` バイナリ除外 + `-n` 行番号付与 + `-E` 拡張正規表現が適用される
3. `--` 以降が pathspec として評価される。`:(exclude)` magic は git 2.13+ で標準サポート
4. exclusion パターンに合致するファイルは検索対象から除外される
5. 残ったファイルから正規表現にヒットする行を出力。exit 0=ヒットあり / 1=ヒットなし / ≥2=エラー

改修箇所の **行数差分**: 1 行 → 3 行（line continuation 2 行追加）。BSD/GNU `grep` 共に動作（pathspec は `git` の責務）。

#### bats 新規テスト 2 件のインターフェース定義

**(a) 除外サンプル検証**

- **`@test` タイトル**: `exclusion: tests/.bats and design-artifacts paths are not flagged as warning`
- **入力**:
  - `FIXTURE_REPO` 直下に `tests/main-repo-health-check.bats` を作成し conflict marker 6 件含むコンテンツで commit
  - `FIXTURE_REPO` 直下に `.aidlc/cycles/v2.5.7/design-artifacts/logical-designs/sample.md` を作成し conflict marker 6 件含むコンテンツで commit
- **期待出力**: `status:ok` / `health-check:conflict-marker:ok:count=0` / exit 0
- **検証 assertion**:
  - `[ "$status" -eq 0 ]`
  - `[[ "$output" =~ "status:ok" ]]`
  - `[[ "$output" =~ "health-check:conflict-marker:ok:count=0" ]]`

**(b) 実コンフリクト検出維持**

- **`@test` タイトル**: `warning: conflict marker in non-excluded tracked path is still detected`
- **入力**:
  - `FIXTURE_REPO` 直下に **除外パターンに該当しない path**（例: `docs/sample-conflict.md` または `bin/conflict-fixture.txt`）を作成し conflict marker 6 件含むコンテンツで commit
  - 同時に除外対象 path（`tests/main-repo-health-check.bats`）にも conflict marker を含むファイルを commit して「混在状態でも除外と検出が両立する」ことを確認する（compound test pattern）
- **期待出力**: `status:warning` / `health-check:conflict-marker:warning:count=N`（N≥1）/ exit 0
- **検証 assertion**:
  - `[ "$status" -eq 0 ]`
  - `[[ "$output" =~ "status:warning" ]]`
  - `[[ "$output" =~ "health-check:conflict-marker:warning" ]]`
  - `[[ "$output" =~ count=[1-9] ]]`

両テストとも既存 setup（`FIXTURE_REPO=${BATS_TEST_TMPDIR}/fake-main-repo`）/ teardown を共有し、追加の環境変数や fixture ファイルは導入しない。`mktemp -d` 等の追加リソースは不要。

#### 既存テスト (4) との差別化

既存 `@test "warning: conflict marker残骸 (v2.5.3 reproduction)"` は **除外実装の有無に関わらず warning が立つ位置** に fixture を作成しており、本 Unit の改修後も合格する（regression なし）。新規テスト (b) は (4) と類似するが、(4) が `review-flow-mock.md` という任意 path であるのに対し、(b) は **「除外対象 path と非除外 path の混在」** を明示的に検証する点で目的が異なる。

#### `.github/workflows/migration-tests.yml` 改修（CI wiring）

**PATHS_REGEX 追加パターン**（line 25 の正規表現末尾の `|` 連結に追加）:

- `tests/main-repo-health-check\.bats`
- `skills/aidlc/scripts/main-repo-health-check\.sh`

`.bats` / `.sh` のドット escape は既存パターン（例: `tests/operations-uncommitted-detection\.bats`）と整合させる。

**bats 実行行追加**（line 66 の bats 引数末尾に追加）:

- `tests/main-repo-health-check.bats`

実行行の他テスト引数は既存順序を保ち、新規はリストの末尾追加で衝突回避する。

## データモデル概要

本 Unit はデータモデル変更を伴わない（永続化対象なし）。

### ファイル形式

- pathspec 文字列: `:(exclude)<glob>` 形式の単純文字列リテラル。`<glob>` 部は `**` と通常 glob を含む（git pathspec の glob magic は `:(glob)` だが、`:(exclude)` はデフォルトで pattern matching を提供するため `**` 表記が動作する）
- 既存出力フォーマット（`health-check:conflict-marker:{status}:count={N}`）は維持

## 処理フロー概要

### scan 実行フロー（改修後）

1. `main-repo-health-check.sh` が `check_conflict_marker "$MAIN_REPO_PATH"` を呼び出す
2. `git -C "$MAIN_REPO_PATH" grep ... -- ':(exclude)tests/main-repo-health-check.bats' ':(exclude).aidlc/cycles/**/design-artifacts/**'` を実行
3. git は tracked ファイルを列挙し、pathspec exclusion を適用
4. 残ったファイルから正規表現にヒットする行を抽出
5. ヒット件数を `wc -l` でカウント
6. `health-check:conflict-marker:{ok|warning}:count=N` を出力し戻り値を決定（exit 0/1/2）

**関与するコンポーネント**: `check_conflict_marker` / `git grep` / `printf` / `wc` / `tr`

### bats テスト実行フロー（CI 経由）

1. PR 作成時に GitHub Actions が `pull_request` event を受信
2. `migration-tests.yml` の PATHS_REGEX が PR の changed files と照合
3. マッチした場合のみ job 実行が trigger される（`tests/main-repo-health-check.bats` または `skills/aidlc/scripts/main-repo-health-check.sh` の変更でトリガ）
4. `bats@1.11.1` セットアップ
5. `bats ... tests/main-repo-health-check.bats` を実行
6. 全 `@test`（既存 5 + 新規 2 = 7 件）が PASS することを検証

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: health-check 実行時間に有意な差が出ないこと
- **対応策**: pathspec 引数 2 件追加のみ。git grep 内部で除外フィルタが適用されるため、CPU/IO コストは tracked ファイル数に対して微小増。`time` 計測の必要なし

### セキュリティ

- **要件**: 既存 health-check のセキュリティ姿勢を維持（外部入力なし、ローカル git 操作のみ）
- **対応策**: pathspec 文字列はリテラル定数。ユーザー入力からの構築なし。command injection リスクなし

### 互換性

- **要件**: BSD/GNU `git` 両対応、bash/zsh 両対応、git 2.13+ サポート
- **対応策**: pathspec `:(exclude)` magic は git 2.13+ 標準サポート。`**` 表記もサポート対象。本リポジトリの CI ランナー（ubuntu-latest）と macOS 開発環境ともに git 2.13+ を満たす

### 可用性

- **要件**: 既存出力フォーマット維持、既存全シナリオ regression なし
- **対応策**: 既存 `@test` 5 件は除外パターンに該当しない fixture path（`review-flow-mock.md` 等）を使用しているため、改修後も合格する

## 技術選定

- **言語**: bash（既存準拠、POSIX 互換ライン優先）/ bats-core 1.11.1（既存準拠）
- **フレームワーク**: Git 2.13+ pathspec / bats / GitHub Actions ubuntu-latest（既存準拠）
- **ライブラリ**: 追加なし
- **データベース**: 該当なし

## 実装上の注意事項

- **pathspec 引数の順序**: `git grep` の `--` separator 後に exclusion パターンを並べる順序は git の評価結果に影響しない（exclude は AND 結合）。可読性のため「specific path（`tests/main-repo-health-check.bats`）→ glob pattern（`.aidlc/cycles/**/...`）」順で記述
- **既存 setup の活用**: 新規 `@test` は既存 setup の `FIXTURE_REPO` を再利用するため、bats teardown による `rm -rf` cleanup が自動適用される
- **`tests/main-repo-health-check.bats` という path の冪等性**: 新規テストは fixture repo 内に `tests/main-repo-health-check.bats` という同名 path を作成するが、これは fixture 内のテンポラリパスであり実際の本 bats ファイル本体とは別物。両者の衝突はない（bats 実行時 cwd は `BATS_TEST_TMPDIR/fake-main-repo` 内）
- **CI wiring の保守性**: 将来 `tests/main-repo-health-check.bats` 以外に health-check 関連テストが増えた場合は本 PATHS_REGEX 更新が必要。本 Unit では現状必要分のみを追加し、汎用的な `tests/main-repo-health-check-.*\.bats` 等の wildcard 化は将来 Unit に委ねる
- **既存テスト regression 確認の手順**: Phase 2 step 4 で `bats tests/main-repo-health-check.bats` をローカル実行し、新規 2 件含む全 7 件が PASS することを確認する。失敗時はテスト fixture の作り方を見直し、必要に応じて (a)(b) の path を調整する

## 不明点と質問

[Question] CI wiring 追加で `migration-tests.yml` の job 名が `migration-tests` のまま（health-check 関連も含む形に変更すべき？）

[Answer] 現状維持で進める。job 名を変更すると branch protection の Required status check 設定（GitHub UI 側）にも影響が及ぶため、本 Unit のスコープ外（境界外）として扱う。`migration-tests` job は元々 migration 以外の bats も実行する汎用 job として運用されているため、health-check を加えることで命名と実態のズレが少し拡大するが、現サイクル内では許容する。

[Question] `bats tests/main-repo-health-check.bats` を `migration-tests` job に追加するか、別 step / job に分離するか？

[Answer] 既存 `migration-tests` job の bats 実行行に追加する形を採用する（line 66 末尾追記）。理由: (1) 同 job 内で bats セットアップが既に完了しているため重複セットアップを避けられる、(2) 別 job 化のメリット（並列実行、独立 fail）は本リポジトリのテスト総量では発現しない、(3) Required status check の追加が不要。
