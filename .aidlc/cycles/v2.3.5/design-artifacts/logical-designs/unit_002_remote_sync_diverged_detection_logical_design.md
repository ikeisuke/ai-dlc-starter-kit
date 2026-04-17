# 論理設計: リモート同期チェックの squash 後 divergence 対応

## 概要

`validate-git.sh remote-sync` サブコマンドを 2 ビット ancestry 分類ベースに再構築し、`diverged` ステータスと `upstream-resolve-failed` / `merge-base-failed` の新規 error code を導入する。`operations-release.sh cmd_verify_git()` は既存のパススルー契約を維持しつつ `diverged` を透過する。`steps/operations/01-setup.md` §6a および `steps/operations/operations-release.md` 7.9〜7.11 の UI 層は、`validate-git.sh` stdout を表示する責務に限定し、独自の文字列加工を行わない。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な実装（shell 関数本体、markdown 分岐テーブル等）は Phase 2（コード生成）で作成する。

## Unit 定義・計画との責務境界（方針確定経緯）

Unit 定義（`.aidlc/cycles/v2.3.5/story-artifacts/units/002-remote-sync-diverged-detection.md`）は要件視点で `scripts/operations-release.sh の verify-git remote-sync サブルーチン` を改修対象として主語化している。これは Unit 定義が外部インターフェース（`operations-release.sh verify-git`）の観点から書かれているためである。

計画段階（`plans/unit-002-plan.md`）および本設計では、**`operations-release.sh verify-git` は既存 `validate-git.sh remote-sync` を呼び出すパススルーラッパー**である実装事実に基づき、実際の判定ロジックは `validate-git.sh run_remote_sync()` 層に集約する方針を確定した。`operations-release.sh cmd_verify_git()` は `diverged` ステータスを透過するため**コード変更不要**で、サマリ集約・動作確認のみが責務となる。

この責務境界は以下の通り統一される:

| レイヤー | 責務 | 本 Unit での変更 |
|---------|------|----------------|
| 一次ソース層 | `validate-git.sh run_remote_sync()`: 2 ビット分類・error code 判定・`recommended_command` 生成 | **コード改修** |
| サマリ集約層 | `operations-release.sh cmd_verify_git()`: `validate-git.sh` stdout のパススルー + サマリ行生成 | コード改修なし（動作確認のみ） |
| UI 層 | `steps/operations/01-setup.md` §6a / `operations-release.md` 7.9-7.11: `validate-git.sh` stdout の表示のみ | **ドキュメント改修** |
| Git Gateway | `git` CLI | 変更なし |

Unit 定義の主語が `operations-release.sh` になっているのは外部 API 観点のみの記述であり、内部実装責務は本設計および計画の方針（`validate-git.sh` 主体）に従う。

---

## アーキテクチャパターン

### 1. パススルー契約（Transparent Pass-Through）

`operations-release.sh cmd_verify_git()` は `validate-git.sh` の stdout / exit code を**透過する責務**のみを持ち、ステータス値の再解釈・書き換えを行わない。`diverged` / `behind_commits:N` / `recommended_command:<実値>` 等の新規出力も awk による `^status:` 行抽出ルールで自動的に透過される（既存パーサを壊さない）。

### 2. 一次ソース固定（Single Source of Truth）

`recommended_command` 等のユーザー向け文字列は `validate-git.sh` の stdout を**一次ソース**とし、UI 層（`01-setup.md` / `operations-release.md`）はその実値をそのまま表示する。UI 層でのプレースホルダー展開・文字列再構築は禁止する。

### 3. レイヤード責務分離

```text
+---------------------------------------+
| UI 層: 01-setup.md §6a                 |
|   / operations-release.md 7.9-7.11    |  ← 表示のみ（一次ソースを透過）
+---------------------------------------+
             ↑ 表示用文字列・正規化状態
             |
+---------------------------------------+
| サマリ集約層: operations-release.sh    |
|   cmd_verify_git()                    |  ← ステータス集約 / exit code max
+---------------------------------------+
             ↑ stdout 行 + exit code
             |
+---------------------------------------+
| 一次ソース層: validate-git.sh          |
|   run_remote_sync()                   |  ← 2 ビット分類 + error code 判定
+---------------------------------------+
             ↑ git CLI 呼び出し
             |
+---------------------------------------+
| Git Gateway: git CLI                  |
+---------------------------------------+
```

- **単方向依存**: UI 層 → サマリ集約層 → 一次ソース層 → Git Gateway（循環なし）
- **障害分離**: Git Gateway 失敗（fetch / merge-base / rev-list 失敗）は一次ソース層で `ResolverError` に正規化され、上位層へは `status:error` + `error:<code>` として 1 種類のインターフェースで伝達される

### 4. 2 ビット真理値表分類

`AncestryTruthTable(A, B)` の 4 状態を排他的に分類し、`Ok` / `Unpushed` / `Behind` / `Diverged` に射影する。`A` のみで早期 return する分岐は禁止（計画 Round 1 指摘反映）。

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/
├── validate-git.sh                 (改修対象: 一次ソース層)
│   └── run_remote_sync()           (本 Unit で改修)
│       ├── CurrentBranchResolver   (既存、微修正)
│       ├── UpstreamResolver        (新規ドメインサービス相当)
│       ├── FetchExecutor           (既存、現状維持)
│       ├── AncestryResolver        (新規、2 ビット判定)
│       ├── CommitCountResolver     (既存 rev-list を再利用、射影追加)
│       ├── RemoteSyncStateClassifier (新規、4 状態分類)
│       ├── RecommendedCommandFactory (新規、Diverged 時のみ起動)
│       └── StatusLineRenderer      (新規、出力行生成)
│
├── operations-release.sh           (改修不要: サマリ集約層)
│   └── cmd_verify_git()            (diverged 透過動作を検証のみ)
│
skills/aidlc/steps/operations/
├── 01-setup.md                     (改修対象: UI 層)
│   └── §6a リモート同期チェック     (diverged 分岐追加・マッピング表整合)
└── operations-release.md           (改修対象: UI 層)
    └── 7.9-7.11 事前チェック        (diverged 透過・プレースホルダー禁止)
```

### コンポーネント詳細

#### CurrentBranchResolver（既存、微修正）

- **責務**: `git branch --show-current` の結果を `CurrentBranch` 値として返し、空文字列時は `ResolverError:branch-unresolved` で短絡する
- **依存**: Git Gateway (`git branch --show-current`)
- **公開インターフェース**: `resolve() -> CurrentBranch | ResolverError:branch-unresolved`
- **現状維持**: 既存 `run_remote_sync()` のステップ 0 をそのまま使う

#### UpstreamResolver（新規ドメインサービス相当、shell 関数として実装）

- **責務**: `CurrentBranch` から `UpstreamRef` を構築する。`branch.<current>.merge` を一次ソースとする
- **依存**: Git Gateway (`git config --get`, `git show-ref`, `git rev-parse --abbrev-ref`（参考情報用のみ）)
- **公開インターフェース**:
  - `resolve(currentBranch) -> UpstreamRef | ResolverError:{no-upstream,upstream-resolve-failed}`
- **処理手順（論理）**:
  1. `remote := git config --get branch.<currentBranch>.remote`（未設定時は `origin` を fallback。既存挙動維持）
  2. `merge_ref := git config --get branch.<currentBranch>.merge`
  3. `merge_ref` が取得不能 or `refs/heads/` プレフィックス不在 → `ResolverError:upstream-resolve-failed`
  4. `upstream_branch := merge_ref` から `refs/heads/` プレフィックスを除去
  5. 存在確認として `git show-ref --verify refs/remotes/<remote>/<upstream_branch>` を実行（**異名 upstream 対応**: ローカル branch 名ではなく upstream branch 名を使う）。失敗 → `ResolverError:no-upstream`
  6. `UpstreamRef(remote, upstream_branch)` を返す
- **注**:
  - ステップ 5 の存在確認は **upstream branch 名**（`upstream_branch`）を使う。ローカル branch 名（`currentBranch`）を使わない（計画の一次ソース固定契約と整合）
  - `git rev-parse --abbrev-ref @{u}` は情報取得経路として参考情報のみの扱い。`recommended_command` 生成にも no-upstream 判定にも一次ソースとして使用しない

#### FetchExecutor（既存、現状維持）

- **責務**: `GIT_TERMINAL_PROMPT=0 git fetch -- <remote>` を実行し、失敗時は `ResolverError:fetch-failed` で短絡する
- **依存**: Git Gateway
- **公開インターフェース**: `execute(remote) -> ExitCode`（0=成功、非 0=失敗）
- **現状維持**: 既存 `run_remote_sync()` のステップ A をそのまま使う

#### AncestryResolver（新規）

- **責務**: `UpstreamRef.trackingRef` と `HEAD` の双方向 ancestry を評価し `AncestryTruthTable` を構築する
- **依存**: Git Gateway (`git merge-base --is-ancestor`)
- **公開インターフェース**:
  - `resolve(upstreamRef) -> AncestryTruthTable | ResolverError:merge-base-failed`
- **処理手順（論理）**:
  1. `a_ec := git merge-base --is-ancestor <upstreamRef.trackingRef> HEAD; echo $?`
  2. `b_ec := git merge-base --is-ancestor HEAD <upstreamRef.trackingRef>; echo $?`
  3. `a_ec` / `b_ec` のいずれかが `>= 2` → `ResolverError:merge-base-failed`
  4. それ以外 → `AncestryTruthTable(a = (a_ec == 0), b = (b_ec == 0))`
- **重要**: 2 回の `merge-base` を**両方**実行してから分類する。片方の結果で早期 return しない（計画 Round 1 指摘反映）
- **exit code 解釈**: `set +e` で囲み、`$?` を変数取得してから `set -e` の文脈へ戻す（既存スクリプトの `set -e` 下での誤判定を防ぐ）

#### CommitCountResolver（既存 rev-list を再利用、射影を追加）

- **責務**: `CommitCount(ahead, behind)` を `git rev-list --count` で取得する
- **依存**: Git Gateway (`git rev-list --count`)
- **公開インターフェース**:
  - `resolve(upstreamRef) -> CommitCount | ResolverError:log-failed`
- **処理手順（論理）**:
  1. `ahead := git rev-list --count <upstreamRef.trackingRef>..HEAD`
  2. `behind := git rev-list --count HEAD..<upstreamRef.trackingRef>`
  3. いずれか失敗 → `ResolverError:log-failed`（既存 error code を流用）
- **現状拡張**: 既存 `run_remote_sync()` は `git log ${remote_ref}..HEAD --oneline` で ahead のみを数えていた。本 Unit で `rev-list --count` の両方向呼び出しに置き換える
- **パフォーマンス**: 2 回の `rev-list --count` はいずれも軽量（`merge-base` と同程度）。NFR「パフォーマンス同等」を満たす

#### RemoteSyncStateClassifier（新規、純関数）

- **責務**: `AncestryTruthTable` と付随値から `RemoteSyncState` を構築する
- **依存**: `AncestryTruthTable`, `UpstreamRef`, `CommitCount`, `RecommendedCommandFactory`
- **公開インターフェース**:
  - `classify(ancestry, upstreamRef, commitCount) -> Ok | Unpushed | Behind | Diverged`
- **処理手順（論理、真理値表）**:

  | `ancestry.a` | `ancestry.b` | 出力 |
  |-----------|-----------|------|
  | `true` | `true` | `Ok` |
  | `true` | `false` | `Unpushed(unpushed_commits = commitCount.ahead)` |
  | `false` | `true` | `Behind(behind_commits = commitCount.behind)` |
  | `false` | `false` | `Diverged(diverged_ahead = commitCount.ahead, diverged_behind = commitCount.behind, recommended_command = RecommendedCommandFactory.build(upstreamRef))` |

- **副作用なし**: git 呼び出しを行わない純関数

#### RecommendedCommandFactory（新規、純関数）

- **責務**: `UpstreamRef` から `RecommendedCommand` を構築する
- **公開インターフェース**:
  - `build(upstreamRef) -> RecommendedCommand`
- **処理手順（論理）**:
  - `command := "git push --force-with-lease " + upstreamRef.remote + " HEAD:" + upstreamRef.branch`
  - 文字列に含める値は `upstreamRef.remote` と `upstreamRef.branch` のみ。`CurrentBranch.name` は使用しない（一次ソース契約）
- **副作用なし**

#### StatusLineRenderer（新規、純関数）

- **責務**: `RemoteSyncState` を stdout に出力する行リストへ変換する
- **公開インターフェース**:
  - `render(state, currentBranch | null, upstreamRef | null) -> List<string>`
  - `currentBranch` が `null` の場合: `branch:unknown` を出力（ステップ 1 失敗時のみ発生）
  - `upstreamRef` が `null` の場合: `remote:unknown` を出力（ステップ 1 または 2 の一部失敗時に発生）
  - `state` が `ResolverError` の場合のみ `currentBranch` / `upstreamRef` が `null` になりうる。`Ok` / `Unpushed` / `Behind` / `Diverged` の場合は両者とも非 null が保証される（エントリ条件）
- **出力行仕様（状態ごと）**:

  | 状態 | 出力行（上から順に） | exit code |
  |------|-------------------|-----------|
  | `Ok` | `status:ok` | 0 |
  | `Unpushed` | `status:warning` / `remote:<upstream.remote>` / `branch:<currentBranch.name>` / `unpushed_commits:<ahead>` | 0 |
  | `Behind` | `status:warning` / `remote:<upstream.remote>` / `branch:<currentBranch.name>` / `behind_commits:<behind>` | 0 |
  | `Diverged` | `status:diverged` / `remote:<upstream.remote>` / `branch:<currentBranch.name>` / `diverged_ahead:<ahead>` / `diverged_behind:<behind>` / `recommended_command:<command>` | 0 |
  | `ResolverError` | `status:error` / `remote:<upstream.remote\|unknown>` / `branch:<currentBranch.name\|unknown>` / `error:<code>:<message>` | 2 |

- **後方互換【重要】**:
  - `remote:` フィールドは **upstream remote 名**（`upstream.remote` = `git config branch.*.remote`）を出力する（既存実装と完全互換）
  - `branch:` フィールドは **ローカル current branch 名**（`currentBranch.name` = `git branch --show-current`）を出力する（既存実装と完全互換）。異名 upstream（例: `feature-x` → `origin/release-x`）の場合でも `branch:feature-x` が出力され、**既存契約を破らない**
  - upstream branch 名（`upstream.branch`）は `recommended_command:` 行の構築にのみ使用され、独立フィールドとしては**出力しない**（既存パーサ互換のため新フィールド追加を最小化）
  - `Unpushed` の出力は既存 `status:warning` + `remote:` + `branch:` + `unpushed_commits:N` と完全一致。既存パーサ（`awk '/^status:/'`）を壊さない

- **契約変更の明示**:
  - `branch:` フィールドの値は v2.3.4 以前と同じ（ローカル current branch）。本 Unit で意味を変更しない
  - 新規フィールドは `behind_commits:N`（Behind のみ）/ `diverged_ahead:N` / `diverged_behind:M` / `recommended_command:<実値>`（Diverged のみ）の 4 種
  - 新規ステータス値は `status:diverged` の 1 種
  - 新規 error code は `merge-base-failed` / `upstream-resolve-failed` の 2 種

#### RemoteSyncStateResolver（オーケストレーター）

- **責務**: 上記コンポーネントを順序付けて呼び出し、`run_remote_sync()` のエントリポイントとして機能する
- **公開インターフェース**:
  - `run() -> (status_lines: List<string>, exit_code: int)`
- **処理手順（論理、全体フロー）**:
  1. `current := CurrentBranchResolver.resolve()` → エラーなら `StatusLineRenderer.render(error, null, null)` で short circuit（`branch:unknown` / `remote:unknown` を出力）
  2. `upstream := UpstreamResolver.resolve(current)` → エラーなら `StatusLineRenderer.render(error, current, null_or_partial_upstream)` で short circuit（`branch:<current.name>` を出力、`remote:` は解決済み範囲で）
  3. `FetchExecutor.execute(upstream.remote)` → 失敗なら `StatusLineRenderer.render(ResolverError:fetch-failed, current, upstream)` で short circuit
  4. `ancestry := AncestryResolver.resolve(upstream)` → エラーなら `StatusLineRenderer.render(ResolverError:merge-base-failed, current, upstream)` で short circuit
  5. `count := CommitCountResolver.resolve(upstream)` → エラーなら `StatusLineRenderer.render(ResolverError:log-failed, current, upstream)` で short circuit
  6. `state := RemoteSyncStateClassifier.classify(ancestry, upstream, count)`
  7. `StatusLineRenderer.render(state, current, upstream)` を返す

- **エラー短絡時の `current` / `upstream` 受け渡し規約**:
  - `current` が未解決（ステップ 1 失敗）の場合: `StatusLineRenderer` は `branch:unknown` を出力
  - `current` は解決済みだが `upstream` が未解決（ステップ 2 失敗）の場合: `branch:<current.name>` を出力、`remote:` は `UpstreamResolver` が `branch.*.remote` まで解決済みなら `remote:<partial.remote>`、それ以前で失敗なら `remote:unknown`
  - `current` / `upstream` ともに解決済みの場合（ステップ 3 以降の失敗）: `branch:<current.name>` / `remote:<upstream.remote>` を出力
  - 成功時（ステップ 7）: `branch:<current.name>` / `remote:<upstream.remote>`（既存互換）

---

## インターフェース設計

### スクリプトインターフェース: `validate-git.sh remote-sync`

#### 概要

ローカル HEAD と upstream の同期状態を 2 ビット ancestry 分類で判定し、stdout にステータス行を出力する。

#### 引数

既存どおり。オプションなし（`validate-git.sh` のサブコマンド `remote-sync` のみで動作）。

#### 成功時出力（状態別）

**Ok（完全一致）**:

```text
status:ok
```

**Unpushed（HEAD が upstream を追い越し）**:

```text
status:warning
remote:<upstream_remote>
branch:<current_branch>
unpushed_commits:<N>
```

**Behind（upstream が HEAD を追い越し、新規分類）**:

```text
status:warning
remote:<upstream_remote>
branch:<current_branch>
behind_commits:<N>
```

**Diverged（双方向に差分、新規状態）**:

```text
status:diverged
remote:<upstream_remote>
branch:<current_branch>
diverged_ahead:<N>
diverged_behind:<M>
recommended_command:git push --force-with-lease <upstream_remote> HEAD:<upstream_branch>
```

- 終了コード: `0`
- `branch:` フィールドは**ローカル current branch 名**（既存互換）。異名 upstream 時は `branch:<current_branch>`（例: `branch:feature-x`）となり、`recommended_command` の `HEAD:<upstream_branch>`（例: `HEAD:release-x`）とは別値である点に注意
- `recommended_command:` の `<upstream_remote>` / `<upstream_branch>` は実値（例: `origin` / `release-x`）。リテラルプレースホルダー文字列は出力しない

#### エラー時出力

```text
status:error
remote:<name|unknown>
branch:<name|unknown>
error:<code>:<message>
```

- 終了コード: `2`
- `<code>` ∈ `{ fetch-failed, no-upstream, branch-unresolved, merge-base-failed, upstream-resolve-failed, log-failed }`
- `<name|unknown>`: 解決済みなら実値、未解決なら `unknown`

#### 使用コマンド

```bash
./validate-git.sh remote-sync
```

既存の呼び出し側（`operations-release.sh cmd_verify_git()` / 手動実行）は改修不要。

### スクリプトインターフェース: `operations-release.sh verify-git`（改修不要、挙動確認のみ）

#### サマリ行の仕様

```text
verify-git:summary:uncommitted=<s>:remote-sync=<s>:default-branch=<s>
```

- `remote-sync=<s>` の `<s>` は `validate-git.sh` の `status:<s>` 行から awk で抽出（既存ロジック、コード変更なし）
- `<s>` ∈ `{ ok, warning, diverged, error }`

#### exit code 集約

- 既存通り `max(uncommitted_ec, remote_sync_ec)` を返す
- `status:diverged` は exit 0 なので `remote_sync_ec=0`。`diverged` はマージ停止しない（`cmd_verify_git()` は warning 相当として扱う）

### Markdown インターフェース: `01-setup.md` §6a

UI 表示の分岐テーブル（§6a 状態テーブル）を下表に置換する（計画マッピング表と 1:1 対応）:

| `validate-git.sh` 出力 | §6a 正規化状態 | 表示・動作 |
|----------------------|---------------|-----------|
| `status:ok` | `up-to-date` | 「✓ リモートブランチと同期済みです」表示、続行 |
| `status:warning` + `unpushed_commits:N` | `up-to-date`（§6a は push 漏れを扱わない） | 続行 |
| `status:warning` + `behind_commits:N` | `behind` | 「⚠ リモートブランチに未取得のコミットが {N} 件あります」表示 → `AskUserQuestion`「取り込む／スキップして続行」（従来挙動維持） |
| `status:diverged` + `diverged_ahead:A` + `diverged_behind:B` + `recommended_command:<実値>` | `diverged`（新規） | 「⚠ リモートとローカルの履歴が分岐しています（ahead={A}, behind={B}）。squash 後などで履歴が書き換わった状態が想定されます。」表示 + `recommended_command:` 行の**実値**をそのまま推奨コマンドとして表示 → `AskUserQuestion`「force push を実行する（手動）／スキップして続行／中断」 |
| `status:error` + `error:fetch-failed:...` | `skipped`（reason=fetch-failed） | 「⚠ リモート同期チェックをスキップしました（リモート接続失敗）」表示、続行 |
| `status:error` + `error:no-upstream:...` | `skipped`（reason=no-upstream） | 「⚠ リモート同期チェックをスキップしました（upstream 未設定）」表示、続行 |
| `status:error` + `error:branch-unresolved:...` | `skipped`（reason=detached-head） | 「⚠ リモート同期チェックをスキップしました（detached HEAD）」表示、続行 |
| `status:error` + `error:merge-base-failed:...` / `error:log-failed:...` / `error:upstream-resolve-failed:...` | `skipped`（reason={code}） | 「⚠ リモート同期チェックをスキップしました（git 内部エラー: {reason}）」表示、続行 |

**UI 層の責務限定**:

- `recommended_command:` 行の実値をそのまま表示する
- プレースホルダー展開・文字列加工は行わない
- force push 自動実行は禁止

**AskUserQuestion の必須性**: `diverged` 時は `automation_mode=semi_auto` / `full_auto` でも**必ず**ユーザー確認を取る（SKILL.md「AskUserQuestion 使用ルール」の「ユーザー選択」分類）

### Markdown インターフェース: `operations-release.md` 7.9〜7.11

現行記述「`warning` は追加コミット / `git push` / merge-rebase を案内、`error` はマージ停止」に `diverged` の扱いを追記:

- `diverged`: マージ停止しない（exit 0 扱い）。`recommended_command:` 行の実値を手動実行してから再チェック、または中断

**新規 error code の扱い**: `merge-base-failed` / `upstream-resolve-failed` も既存 error code 同様にマージ停止扱い（7.9〜7.11 の層では `error` は一律 blocking）

**UI 表示の文字列契約**: `operations-release.md` も `recommended_command:` の実値をそのまま透過し、markdown 内にリテラル `<remote> <branch>` プレースホルダー文字列を書かない

---

## データモデル概要

本 Unit では永続化対象のデータモデル（DB・ファイル形式）は存在しない。

ランタイムで扱うのは以下の構造化された shell 変数群（論理モデル上の値オブジェクトに対応）:

| 変数名（shell） | 論理モデル名 | 型（shell 表現） | 備考 |
|---------------|-------------|---------------|------|
| `branch` | `CurrentBranch.name` | string | 既存 |
| `remote` | `UpstreamRef.remote` | string | 既存 |
| `upstream_branch` | `UpstreamRef.branch` | string | **新規**（`branch.*.merge` から解決） |
| `remote_ref` | `UpstreamRef.trackingRef` | string | 既存（`${remote}/${upstream_branch}` へ意味変更） |
| `ancestry_a` | `AncestryTruthTable.a` | boolean（0/1） | **新規** |
| `ancestry_b` | `AncestryTruthTable.b` | boolean（0/1） | **新規** |
| `ahead_count` | `CommitCount.ahead` | integer | **新規**（既存の `count` 変数を明示リネーム） |
| `behind_count` | `CommitCount.behind` | integer | **新規** |
| `recommended_cmd` | `RecommendedCommand.command` | string | **新規**（Diverged 時のみ） |

**変数命名規則**: shell script 内の変数名は上表に従う。既存の `count` 変数は `ahead_count` にリネームする（可読性向上、意味明確化）。

### `remote_ref` の意味変更に関する注意

現行コードでは `remote_ref` は `git rev-parse --abbrev-ref @{u}` の結果（例: `origin/cycle/v2.3.5`）をそのまま使っていた。本 Unit で `${remote}/${upstream_branch}` へと意味を変更する:

- **同名 upstream 時**: 結果は変わらない（`origin/cycle/v2.3.5` と同値）
- **異名 upstream 時**: `${remote}/${upstream_branch}` は `origin/release-x` となり、`rev-parse @{u}` の結果と一致する
- **既存の `merge-base` / `rev-list` 呼び出しへの影響**: いずれも `remote_ref` を使うため、意味変更後も正しく動作する（`remote_ref` は upstream tracking ref として機能する）

---

## 処理フロー概要

### ユースケース1: 完全同期状態（Ok）

**ステップ**:

1. `CurrentBranchResolver.resolve()` → `CurrentBranch("cycle/v2.3.5")`
2. `UpstreamResolver.resolve(current)` → `UpstreamRef("origin", "cycle/v2.3.5")`
3. `FetchExecutor.execute("origin")` → 成功
4. `AncestryResolver.resolve(upstream)` → `AncestryTruthTable(true, true)`
5. `CommitCountResolver.resolve(upstream)` → `CommitCount(0, 0)`
6. `RemoteSyncStateClassifier.classify(...)` → `Ok`
7. `StatusLineRenderer.render(Ok, current, upstream)` → `["status:ok"]`, exit 0

**関与するコンポーネント**: 全コンポーネント（エラーなし経路）

### ユースケース2: unpushed 状態（従来互換）

**ステップ**:

1-3. 同上
4. `AncestryResolver.resolve(upstream)` → `AncestryTruthTable(true, false)`
5. `CommitCountResolver.resolve(upstream)` → `CommitCount(3, 0)`
6. `RemoteSyncStateClassifier.classify(...)` → `Unpushed(unpushed_commits=3)`
7. `StatusLineRenderer.render(Unpushed, current, upstream)` → `["status:warning", "remote:origin", "branch:cycle/v2.3.5", "unpushed_commits:3"]`, exit 0

**後方互換性**: 出力は既存 v2.3.4 以前と同一

### ユースケース3: behind 状態（新規分類）

**ステップ**:

1-3. 同上
4. `AncestryResolver.resolve(upstream)` → `AncestryTruthTable(false, true)`
5. `CommitCountResolver.resolve(upstream)` → `CommitCount(0, 2)`
6. `RemoteSyncStateClassifier.classify(...)` → `Behind(behind_commits=2)`
7. `StatusLineRenderer.render(Behind, current, upstream)` → `["status:warning", "remote:origin", "branch:cycle/v2.3.5", "behind_commits:2"]`, exit 0

**従来との差分**: 現行実装ではこの状態は「behind」として扱われていなかった（`git log remote..HEAD` が空 → `status:ok` と誤判定）。本 Unit で正しく検出

### ユースケース4: diverged 状態（新規ステータス、本 Unit の中心）

**ステップ**:

1-3. 同上
4. `AncestryResolver.resolve(upstream)` → `AncestryTruthTable(false, false)`
5. `CommitCountResolver.resolve(upstream)` → `CommitCount(1, 3)`（squash 後: 新 1 コミット / 旧 3 コミット）
6. `RemoteSyncStateClassifier.classify(...)` → `Diverged(diverged_ahead=1, diverged_behind=3, recommended_command=...)`
7. `RecommendedCommandFactory.build(upstream)` → `RecommendedCommand("git push --force-with-lease origin HEAD:cycle/v2.3.5")`
8. `StatusLineRenderer.render(Diverged, current, upstream)` →

   ```text
   status:diverged
   remote:origin
   branch:cycle/v2.3.5
   diverged_ahead:1
   diverged_behind:3
   recommended_command:git push --force-with-lease origin HEAD:cycle/v2.3.5
   ```

   exit 0

**UI 層の動作**:

- `01-setup.md` §6a: `status:diverged` → 正規化 `diverged` → `AskUserQuestion`「force push を実行する（手動）／スキップして続行／中断」
- `operations-release.md` 7.9-7.11: サマリに `remote-sync=diverged` を含めて表示、マージは停止しない

### ユースケース5: 異名 upstream + diverged（計画 Round 2 追加シナリオ）

**前提**: local branch `feature-x` が upstream `origin/release-x` を追跡

**ステップ**:

1. `CurrentBranchResolver.resolve()` → `CurrentBranch("feature-x")`
2. `UpstreamResolver.resolve(current)`:
   - `remote := git config branch.feature-x.remote` → `origin`
   - `merge_ref := git config branch.feature-x.merge` → `refs/heads/release-x`
   - `upstream_branch := "release-x"`（プレフィックス除去）
   - 存在確認 `git show-ref --verify refs/remotes/origin/release-x` → 成功
   - 返却: `UpstreamRef("origin", "release-x")`
3. `FetchExecutor.execute("origin")` → 成功
4. `AncestryResolver.resolve(upstream)` → `AncestryTruthTable(false, false)`（diverged）
5. `CommitCountResolver.resolve(upstream)` → `CommitCount(2, 5)`
6. `RemoteSyncStateClassifier.classify(...)` → `Diverged(...)`
7. `RecommendedCommandFactory.build(upstream)` → `RecommendedCommand("git push --force-with-lease origin HEAD:release-x")` ← 重要: `HEAD:release-x`（upstream branch 名）を指定、`HEAD:feature-x` ではない
8. `StatusLineRenderer.render(Diverged, current, upstream)` →

   ```text
   status:diverged
   remote:origin
   branch:feature-x          ← ローカル current branch 名（既存互換）
   diverged_ahead:2
   diverged_behind:5
   recommended_command:git push --force-with-lease origin HEAD:release-x   ← upstream branch 名
   ```

**検証**: ユーザーが `recommended_command` のコマンドをコピペ実行すれば、意図通り `origin/release-x` への force push になる（`origin/feature-x` を誤って破壊しない）。`branch:` フィールド（`feature-x`）と `recommended_command` の `HEAD:release-x` が異なる値を取るのは異名 upstream の正常挙動

### ユースケース6: upstream 解決失敗（新規 error code）

**前提**: `git config branch.*.merge` が未設定、または `refs/heads/` プレフィックスを持たない

**ステップ**:

1. `CurrentBranchResolver.resolve()` → `CurrentBranch("cycle/v2.3.5")`
2. `UpstreamResolver.resolve(current)`:
   - `remote := origin`
   - `merge_ref := git config branch.cycle/v2.3.5.merge` → 空または不正値
   - → `ResolverError:upstream-resolve-failed`
3. 以降のステップをスキップ（short circuit）
4. `StatusLineRenderer.render(ResolverError:upstream-resolve-failed, current, null_or_partial_upstream)` →

   ```text
   status:error
   remote:origin
   branch:cycle/v2.3.5
   error:upstream-resolve-failed:branch.cycle/v2.3.5.merge is not set or invalid
   ```

   exit 2

（`upstream.remote` は解決済みなので `remote:origin` を出力、`upstream.branch` が未解決のため `branch:` は `current.name` の `cycle/v2.3.5` を出力）

**UI 層の動作**:

- `01-setup.md` §6a: 正規化 `skipped`（reason=upstream-resolve-failed）、続行
- `operations-release.md` 7.9-7.11: `error` 扱いでマージ停止

### ユースケース7: merge-base 内部失敗（新規 error code）

**前提**: リポジトリ破損等で `git merge-base` が exit 2 以上を返す

**ステップ**:

1-3. 正常
4. `AncestryResolver.resolve(upstream)`:
   - `a_ec := 2`（例: `git merge-base` がリポジトリ内部エラー）
   - → `ResolverError:merge-base-failed`
5-6. スキップ（short circuit）
7. `StatusLineRenderer.render(ResolverError:merge-base-failed, current, upstream)` → `status:error` + `remote:<upstream.remote>` + `branch:<current.name>` + `error:merge-base-failed:...`, exit 2

### ユースケース8: fetch 失敗（既存互換）

**ステップ**:

1-2. 正常
3. `FetchExecutor.execute("origin")` → 非 0 exit
4. → `ResolverError:fetch-failed`
5-6. スキップ
7. `StatusLineRenderer.render(ResolverError:fetch-failed, current, upstream)` → `status:error` + `remote:<upstream.remote>` + `branch:<current.name>` + `error:fetch-failed:...`, exit 2

**既存互換**: 出力形式・exit code とも v2.3.4 以前と同一

---

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 現行と同等の応答時間（Unit 定義 NFR）
- **対応策**:
  - `git merge-base --is-ancestor` は 1 回あたり数 ms オーダー（軽量）。2 回呼び出しても実用上無視できる
  - `git rev-list --count` は既存も使っており追加負荷なし
  - 追加 fetch は発生しない（既存の `fetch -- <remote>` を再利用）
  - 総じて既存の `git log remote..HEAD` 1 回呼び出しとほぼ同等のコスト

### セキュリティ

- **要件**: 新規機密情報を扱わない。`gh` / `git` 認証トークンは既存と同じ扱い（Unit 定義 NFR）
- **対応策**:
  - `git push --force-with-lease` は `--force` と異なりリモートの現状を検査してから上書きするため、他者コミット破壊リスクを低減
  - 自動実行は禁止（ユーザー承認必須）。AI エージェントが `recommended_command` を**表示のみ**行う契約を 01-setup.md / operations-release.md / RecommendedCommandFactory の 3 箇所で徹底
  - 異名 upstream での誤 push 先案内を防ぐため `HEAD:<upstream_branch>` 形式を採用
  - upstream 解決失敗時は `status:error` で短絡し、構文的に壊れた推奨コマンドを表示しない

### スケーラビリティ

- **要件**: N/A（Unit 定義）
- **対応策**: 該当なし

### 可用性

- **要件**: fetch 失敗時は従来通り `fetch-failed` を返す（Unit 定義 NFR）
- **対応策**:
  - 既存の `FetchExecutor` をそのまま使用（挙動変更なし）
  - 新規 error code（`merge-base-failed` / `upstream-resolve-failed`）も `status:error` + exit 2 として既存の可用性保証モデル（短絡して安全側に倒す）を踏襲

---

## 技術選定

- **言語**: POSIX sh 互換の Bash（既存 `validate-git.sh` が `#!/usr/bin/env bash`、`set -euo pipefail` ベース）
- **フレームワーク**: なし（単体 shell script）
- **ライブラリ**: なし
- **外部依存**:
  - `git` CLI（`branch --show-current`, `config --get`, `fetch`, `rev-parse`, `show-ref`, `merge-base`, `rev-list`）
  - `awk`（`operations-release.sh` 既存パーサ、本 Unit では改修不要）
- **データベース**: N/A

---

## 実装上の注意事項

### Shell スクリプト固有の注意

- **`set -e` 下の `merge-base --is-ancestor` 呼び出し**: `is-ancestor` は exit 1 を「祖先でない」の正常シグナルとして返すため、`set -e` 下では誤ってスクリプト終了してしまう。呼び出しは `set +e; git merge-base --is-ancestor ...; ec=$?; set -e` のパターン、または `|| true` で囲む必要がある。実装時は既存コードの `set -euo pipefail` を維持しつつ、`merge-base` ブロックのみ一時解除する
- **`git config --get branch.<name>.merge` の戻り値**:
  - 未設定時: exit 1 + 空 stdout
  - 設定済み: exit 0 + `refs/heads/<name>` stdout
  - `set -euo pipefail` 下では `|| true` 等で errexit を回避する
- **変数命名の一貫性**: 既存の `count` を `ahead_count` にリネーム、新規 `behind_count` / `upstream_branch` / `ancestry_a` / `ancestry_b` / `recommended_cmd` を追加。論理モデル名と 1:1 対応させる
- **`remote_ref` の意味変更**: 現行の「`rev-parse @{u}` の結果そのまま」から「`${remote}/${upstream_branch}` の構築値」に変更する。呼び出し箇所（`merge-base` / `rev-list` の引数）は全て文字列として使われているため、意味変更後も整合

### 既存パーサとの互換性

- `operations-release.sh cmd_verify_git()` の awk 抽出ルール `awk -F':' '/^status:/ {print $2; exit}'` は新ステータス `diverged` もそのまま透過する（コード変更なし）
- 新規フィールド `behind_commits` / `diverged_ahead` / `diverged_behind` / `recommended_command` は **行頭が `status:` ではない**ため、awk 抽出ルールに影響しない（安全）
- 既存フィールド `unpushed_commits` / `remote:` / `branch:` / `error:` の出力条件・フォーマットは完全維持

### markdown 側の表示契約

- `01-setup.md` §6a / `operations-release.md` 7.10 は `validate-git.sh` の stdout から `^recommended_command:` 行を抽出し、コロン以降を**そのまま**表示する
- AI エージェントが表示時にプレースホルダー展開・文字列加工を行うことを禁止する旨を明記する
- force push 自動実行を禁止する旨を明記する（ユーザー手動実行）

### テスト観点（Phase 2 で確認）

計画の「手動検証シナリオ」に挙げた以下のシナリオを Phase 2 の動作検証で網羅する:

1. 完全同期（`Ok`）: `status:ok` 出力、exit 0
2. 通常 unpushed（`Unpushed`、従来互換）: `status:warning` + `unpushed_commits:N`
3. behind（`Behind`、新規分類）: `status:warning` + `behind_commits:N`
4. squash 後 diverged（`Diverged`、同名 upstream）: `status:diverged` + `recommended_command:git push --force-with-lease origin HEAD:cycle/v2.3.5`
5. 異名 upstream + diverged（`Diverged`、計画 Round 2 追加）: `recommended_command` が upstream branch 名 (`HEAD:release-x` 等) を含むこと
6. squash 後に force-with-lease 実行 → 再チェックで `Ok` に戻ること
7. fetch 失敗: `status:error` + `error:fetch-failed` / exit 2（従来互換）
8. detached HEAD: `status:error` + `error:branch-unresolved` / exit 2（従来互換）
9. upstream 解決失敗（`branch.*.merge` 破損）: `status:error` + `error:upstream-resolve-failed` / exit 2（新規）
10. `01-setup.md` §6a: `diverged` / `behind` / `skipped` の各分岐がユーザー対話フローとして正しく案内されること
11. `operations-release.sh verify-git` のサマリに `remote-sync=diverged` が含まれること（透過確認）

---

## 不明点と質問（設計中に記録）

計画段階で以下が確定しており、追加の不明点はなし:

- 2 ビット ancestry 分類の適用順序（両方取得後の分類）
- upstream 解決の一次ソース（`branch.*.merge`）
- `recommended_command` のフォーマット（`HEAD:<upstream_branch>` 形式）
- 新規 error code 2 種（`merge-base-failed` / `upstream-resolve-failed`）
- §6a / 7.9-7.11 の二層挙動（skipped / blocking）
- 既存出力フィールドの後方互換（`status:` / `remote:` / `branch:` / `unpushed_commits:` / `error:`）

設計レビューで追加の観点があれば本セクションに追記する。
