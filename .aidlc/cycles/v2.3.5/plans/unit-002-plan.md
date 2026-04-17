# Unit 002 実行計画: リモート同期チェックの squash 後 divergence 対応（runtime 判定修正）

## 対象Unit

- **Unit 定義**: `.aidlc/cycles/v2.3.5/story-artifacts/units/002-remote-sync-diverged-detection.md`
- **関連Issue**: #574（部分対応: (1)(2) を本 Unit で担当、(3) は Unit 004）
- **優先度**: High / 見積もり: M（Medium）
- **依存する Unit**: なし（Unit 001 とは独立レイヤー）

## 背景・目的

v2.3.x で Construction Phase の squash-unit 実行により local ブランチの history rewrite が発生すると、次の Operations Phase 開始時に `validate-git.sh remote-sync` / `steps/operations/01-setup.md` の `rev-list HEAD..@{u} --count` が「リモートに未取得のコミットあり（behind）」として誤検知する不具合が確認された。実態は squash 前の旧コミットが remote に残っているだけで、local HEAD のほうが論理的に新しい状態（diverged）である。

本 Unit では、`merge-base --is-ancestor` による先行チェックを加えて「squash 後の up-to-date 状態」を正しく判定し、真の divergence を `behind` から分離した新ステータス `diverged` として扱えるようにする。`diverged` 時には `git push --force-with-lease` 推奨コマンドを **upstream remote / upstream branch 実値を解決した形式** でメッセージに含め、ユーザーが明示的に force push できるよう誘導する（自動実行はしない）。具体的な出力文字列契約は「`recommended_command` の値展開契約（一次ソース固定）」セクションで固定する。

## スコープ（責務）

Unit 定義「責務」セクションの全項目を本計画のスコープとする。

- `scripts/validate-git.sh run_remote_sync()` に `merge-base --is-ancestor @{u} HEAD` の先行チェックを追加
- divergence を `behind` から分離した独立ステータス `diverged` を導入
- `diverged` 時の stdout メッセージに `recommended_command:` 行を追加し、解決済み upstream remote / upstream branch 実値を埋め込んだ `git push --force-with-lease <resolved_upstream_remote> HEAD:<resolved_upstream_branch>` 形式の推奨コマンドを出力（詳細契約は「`recommended_command` の値展開契約（一次ソース固定）」セクション、異名 upstream 対応）
- `scripts/operations-release.sh cmd_verify_git()` のサマリ行（`verify-git:summary:...remote-sync=<status>...`）で `diverged` を透過
- `steps/operations/01-setup.md` ステップ6a のリモート同期チェック分岐に `diverged` ステータス向けユーザー選択フロー（`recommended_command:` 行の実値をそのまま表示 or スキップ or 中断）を追加
- `steps/operations/operations-release.md` の 7.10 remote-sync 記述を `diverged` に対応させる（`recommended_command:` の実値透過、UI 層でのプレースホルダー展開を禁止）
- 既存ステータス（`up-to-date` / `behind` / `fetch-failed` / `skipped`）の挙動を維持（回帰防止）

## 変更対象ファイル（論理設計でさらに詰める）

- `skills/aidlc/scripts/validate-git.sh`
  - `run_remote_sync()` の判定順改修（fetch → is-ancestor 順序判定 → diverged 検出）
  - `status:diverged` 出力の新規定義（`remote` / `branch` / `recommended_command` 行を含む）
- `skills/aidlc/scripts/operations-release.sh`
  - `cmd_verify_git()` 末尾サマリの `remote-sync=<status>` 欄が `diverged` をそのまま透過することを確認・保証
  - 既存 `remote_sync_ec` による exit code 集約ルール（`status:diverged` は warning 扱い = exit 0）との整合
- `skills/aidlc/steps/operations/01-setup.md`
  - §6a「リモート同期チェック【推奨】」の状態テーブルに `diverged` 行追加、`AskUserQuestion` 分岐明記
- `skills/aidlc/steps/operations/operations-release.md`
  - 7.9〜7.11 事前チェックの解説文に `diverged` ステータスの取扱い追記

## 既存挙動の分析と改修契約

### 現行 `validate-git.sh run_remote_sync()` の判定フロー（現状）

1. `git branch --show-current` でブランチ解決、detached HEAD 時は `status:error` + `error:branch-unresolved` で exit 2
2. `git config branch.${branch}.remote` で remote 解決（fallback `origin`）
3. `GIT_TERMINAL_PROMPT=0 git fetch -- "$remote"` 実行、失敗時は `status:error` + `error:fetch-failed` で exit 2
4. `git rev-parse --abbrev-ref @{u}` で upstream 解決、未設定かつ `refs/remotes/<remote>/<branch>` も無ければ `status:error` + `error:no-upstream` で exit 2
5. `git log ${remote_ref}..HEAD --oneline` で未 push コミット検出
   - 空 → `status:ok`
   - 1件以上 → `status:warning` + `remote:` + `branch:` + `unpushed_commits:<N>`
6. exit 0 を返す（警告含む）

**問題点**: ステップ 5 は「HEAD → upstream 方向の差分」しか見ないため、squash 後に local HEAD が旧コミットを含まない形に書き換えられた場合、`${remote_ref}..HEAD` で squash 後の新コミットが未 push として検出され、同時に upstream の旧コミットは local に存在しない状態となる。現仕様では「`status:warning` + `unpushed_commits:N`」と表記されてしまい、ユーザーには単なる push 漏れに見える。実際には divergence であり、通常の `git push` は rejected となる。

### 改修後の判定順（契約）

**重要**: `upstream → HEAD` の ancestry だけで判定してはならない（`merge-base --is-ancestor upstream HEAD=true` は完全一致と unpushed の両方を含むため、単独では `status:ok` に落とせない）。両方向の ancestry を**必ず両方取得してから** 2 ビット分類で状態を決定する。

**判定フロー**:

`fetch` 成功 → upstream ref 解決成功 の後に以下を実行する:

1. **両方向 ancestry の取得**（片方だけで早期 return しない）:
   - `A := git merge-base --is-ancestor "${remote_ref}" HEAD` の exit code（0=true, 1=false）
   - `B := git merge-base --is-ancestor HEAD "${remote_ref}"` の exit code（0=true, 1=false）
   - `A`/`B` のいずれかが exit 2 以上（システムエラー）→ `status:error` + `error:merge-base-failed:git merge-base failed` を emit し exit 2 で短絡

2. **2 ビット分類（真理値表、下記「ステータス出力仕様」の 4 行と 1:1 対応）**:
   - `A=true ∧ B=true` → 完全一致 → `status:ok`
   - `A=true ∧ B=false` → unpushed → 従来互換 `status:warning` + `unpushed_commits:<N>`
   - `A=false ∧ B=true` → behind → `status:warning` + `behind_commits:<N>`（新規フィールド、下記「ステータス出力仕様」参照）
   - `A=false ∧ B=false` → diverged → `status:diverged` + `diverged_ahead:<N>` + `diverged_behind:<N>` + `recommended_command:<実値>`

3. **`<N>` の算出**: 従来通り `git rev-list --count "${remote_ref}..HEAD"`（ahead）/ `git rev-list --count "HEAD..${remote_ref}"`（behind）を使う。`unpushed_commits`（A=true,B=false 時）は `git rev-list --count "${remote_ref}..HEAD"` の値と一致する（従来互換）。

**fetch 失敗・no-upstream・branch 未解決時の短絡（validate-git.sh の生ステータス）**: 従来通り `status:error` + `error:<code>` を emit し exit 2 で短絡する（上記 2 ビット分類は実行しない）:

- `branch-unresolved`（detached HEAD 等） → `status:error` + `error:branch-unresolved`
- `fetch-failed` → `status:error` + `error:fetch-failed`
- `no-upstream` → `status:error` + `error:no-upstream`

### validate-git.sh の生ステータス → UI 正規化状態のマッピング表

`validate-git.sh run_remote_sync()` の stdout 出力（一次ソース）と、それを消費する `steps/operations/01-setup.md` §6a / `steps/operations/operations-release.md` の UI 正規化状態（二次表現）の対応を下表に固定する。回帰防止のため**既存マッピングは不変**、`diverged` のみ新規追加。

| validate-git.sh stdout（一次ソース） | exit code | `01-setup.md` §6a 正規化状態 | `operations-release.md` サマリ `remote-sync=<s>` | 備考 |
|------------------------------------|----------|------------------------------|---------------------------------------------|------|
| `status:ok`（A=true,B=true） | 0 | `up-to-date` | `ok` | 完全一致 |
| `status:warning` + `unpushed_commits:N`（A=true,B=false） | 0 | `up-to-date`（§6a は push 漏れを扱わない。push 済みの想定で続行。7.9〜7.11 で検出） | `warning` | 従来互換、§6a は未 push を Operations 開始判断に含めない |
| `status:warning` + `behind_commits:N`（A=false,B=true） | 0 | `behind` | `warning` | 従来の behind 表示。`AskUserQuestion`「取り込む／スキップ」 |
| `status:diverged` + `diverged_ahead:N` + `diverged_behind:M` + `recommended_command:<実値>`（A=false,B=false） | 0 | `diverged`（新規） | `diverged`（新規、文字列透過） | `AskUserQuestion`「force push 案内を表示／スキップ／中断」 |
| `status:error` + `error:fetch-failed:...` | 2 | `skipped`（reason=fetch-failed） | `error` | 従来互換、`01-setup.md` §6a は続行 |
| `status:error` + `error:no-upstream:...` | 2 | `skipped`（reason=no-upstream） | `error` | 従来互換、§6a は続行 |
| `status:error` + `error:branch-unresolved:...`（detached HEAD） | 2 | `skipped`（reason=detached-head） | `error` | 従来互換、§6a は続行 |
| `status:error` + `error:merge-base-failed:...`（新規、2 ビット判定失敗） | 2 | `skipped`（reason=merge-base-failed） | `error` | 新規追加、§6a は続行 |
| `status:error` + `error:upstream-resolve-failed:...`（新規、`branch.*.merge` 解決失敗） | 2 | `skipped`（reason=upstream-resolve-failed） | `error` | 新規追加、§6a は続行 |
| `status:error` + `error:log-failed:...` | 2 | `skipped`（reason=log-failed） | `error` | 従来互換（rev-list 失敗時）、§6a は続行 |

**契約の含意**:
- `01-setup.md` §6a は `status:error` 全系統を一律 `skipped` に正規化して**続行**する（既存挙動）。`operations-release.md` の 7.9〜7.11 は `error` を**マージ停止**として扱う（既存挙動）。この 2 層の違いは実行フェーズが異なるため（§6a は開始時の推奨チェック、7.9〜7.11 は最終ゲート）。Unit 002 では両者の挙動を変更せず、`diverged` のみ追加する
- `01-setup.md` §6a と `operations-release.md` 7.9〜7.11 の両方で、`diverged` は **マージ停止しない warning 相当**（exit 0）として扱う。ユーザー判断は AskUserQuestion で誘導する

### ステータス出力仕様（validate-git.sh）

「改修後の判定順（契約）」セクションの 2 ビット分類に対応する出力行仕様を本サブセクションで固定する。

| 真理値（A,B）※ | 状態 | 出力行 | exit code |
|--------------|------|-------|-----------|
| (true, true) | 完全一致（HEAD = upstream） | `status:ok` | 0 |
| (true, false) | unpushed（HEAD が upstream を追い越し、既存互換） | `status:warning` + `remote:<name>` + `branch:<name>` + `unpushed_commits:<N>` | 0 |
| (false, true) | behind（upstream が HEAD を追い越し、新規分類） | `status:warning` + `remote:<name>` + `branch:<name>` + `behind_commits:<N>` ※新規フィールド | 0 |
| (false, false) | diverged（双方向に差分、新規ステータス） | `status:diverged` + `remote:<name>` + `branch:<name>` + `diverged_ahead:<N>` + `diverged_behind:<M>` + `recommended_command:<実値>` | 0 |
| 上記以外（システムエラー） | fetch 失敗・no-upstream・branch 未解決・merge-base 失敗・upstream-resolve 失敗・log 失敗 | `status:error` + `remote:<name\|unknown>` + `branch:<name\|unknown>` + `error:<code>:<message>`（`<code>` ∈ {`fetch-failed`, `no-upstream`, `branch-unresolved`, `merge-base-failed`, `upstream-resolve-failed`, `log-failed`}） | 2 |

※ `A := merge-base --is-ancestor upstream HEAD`、`B := merge-base --is-ancestor HEAD upstream`。両方を**必ず両方取得**してから分類する（片方だけで `status:ok` に落とさない。上の「改修後の判定順（契約）」セクション参照）。

### `recommended_command` の値展開契約（一次ソース固定）

`recommended_command` の文字列契約を以下に固定する。`01-setup.md` / `operations-release.md` はこれを**そのまま表示する**だけの責務とし、独自にプレースホルダー展開しない:

- **一次ソース**: `validate-git.sh run_remote_sync()` が `status:diverged` を emit する際、**upstream remote 名** と **upstream branch 名** を解決済みの実値として埋め込んだ 1 行を出力する（ローカルブランチ名をそのまま使わない）
- **出力形式（契約）**: `recommended_command:git push --force-with-lease <resolved_upstream_remote> HEAD:<resolved_upstream_branch>`
  - 例（同名 upstream）: `recommended_command:git push --force-with-lease origin HEAD:cycle/v2.3.5`
  - 例（異名 upstream、`feature-x` が `origin/release-x` を追跡）: `recommended_command:git push --force-with-lease origin HEAD:release-x`
- **upstream remote / upstream branch の解決方法（実装契約、一次ソース固定）**:
  - `upstream_remote := git config --get branch.<current_branch>.remote`（既存の `$remote` 解決と同等）
  - `upstream_branch := git config --get branch.<current_branch>.merge` から `refs/heads/` プレフィックスを除去した値（例: `refs/heads/release-x` → `release-x`）。**これが `recommended_command` 生成の一次ソースで、他経路からの解決は許容しない**
  - `git rev-parse --abbrev-ref @{u}` は upstream 追跡ブランチの**存在確認**（`run_remote_sync()` 既存ステップ4 の `error:no-upstream` 判定）にのみ使用する参考情報であり、`recommended_command` の文字列組み立てには使用しない（一次ソースではない）
  - ローカルブランチ名（`git branch --show-current`）ではなく、常に **upstream 側の branch 名**を採用する
- **`HEAD:<upstream_branch>` 形式の採用理由**: `git push --force-with-lease <remote> <branch>` の `<branch>` にローカルブランチ名を直接指定すると、異名 upstream では push 先が意図せず `<remote>/<local_branch_name>` になり、upstream と異なる ref を対象としてしまう。`HEAD:<upstream_branch>` 形式ならローカル HEAD を upstream が追跡している branch に明示的に force push でき、同名・異名いずれの構成でも正しく動作する
- **解決失敗時の扱い**:
  - `git config branch.<current_branch>.merge` が取得できない、または `refs/heads/` プレフィックスを持たない異常値の場合 → `status:error` + `error:upstream-resolve-failed:...` を emit し exit 2（`diverged` 判定前に短絡）
- **実値埋め込みの保証**: `run_remote_sync()` 内で解決済みの `$upstream_remote` / `$upstream_branch` シェル変数をそのまま埋め込む（リテラルの `<remote>` / `<branch>` 文字列は出力しない）
- **UI 層の責務**: `01-setup.md` §6a / `operations-release.md` 7.10 は、`validate-git.sh` の stdout から `^recommended_command:` 行を抽出し、コロン以降を**そのまま**ユーザーに表示する。プレースホルダー文字列（`<remote>`, `<branch>`, `<resolved_upstream_remote>`, `<resolved_upstream_branch>`）を見せない
- **計画・仕様ドキュメント内の `<remote>` / `<branch>` / `<resolved_*>` 表記**: 本計画・Unit 定義・設計ドキュメントで `<remote>` / `<branch>` / `<resolved_upstream_remote>` / `<resolved_upstream_branch>` と書かれている箇所は、実装仕様を説明するためのメタ表記であり、ユーザー向け UI 表示そのものではない。UI 表示には常に解決済み実値が入る

**補足**: `behind_commits:N` は新規フィールドだが、既存パーサ（`awk '/^status:/'`）は `status:` 行のみ参照するため互換性を破らない。`recommended_command:` も同様に独立行として出力され、既存パーサに影響しない。

### `operations-release.sh cmd_verify_git()` の整合

現行 `cmd_verify_git()` は `validate-git.sh remote-sync` の stdout から `^status:` を awk で抽出し、末尾サマリに `remote-sync=<status>` として埋め込む。`diverged` は awk マッチ対象となる文字列なので **コード変更は不要**（新ステータスをそのまま透過する）。ただし以下は計画段階で確認・確定する:

- exit code の集約: `remote_sync_ec` は従来通り `validate-git.sh` の return 値（`status:diverged` = exit 0）を採用する。`diverged` は warning と同様に処理継続（マージ停止はしない）。ユーザー判断へのフォールバックは 01-setup.md 側の `AskUserQuestion` で行う
- サマリ出力例: `verify-git:summary:uncommitted=ok:remote-sync=diverged:default-branch=ok`
- 既存の `verify-git:summary:...` を参照しているコード / ドキュメントの影響範囲を確認（論理設計フェーズ）

### `steps/operations/01-setup.md` §6a の分岐追加

上記「マッピング表」に従い、§6a の現行テーブルに `diverged` 行を追加する。`01-setup.md` は `validate-git.sh` の stdout を消費する UI 層の責務に限定し、独自の git 判定は持たない（2 ビット分類は `validate-git.sh` 内に閉じる）:

| validate-git.sh 出力 | §6a 正規化状態 | 表示・動作（確定事項） |
|---------------------|---------------|----------------------|
| `status:ok` | `up-to-date` | 「✓ リモートブランチと同期済みです」表示、続行 |
| `status:warning` + `unpushed_commits:N` | `up-to-date` | （§6a は push 漏れを扱わない。7.9〜7.11 の verify-git で検出）続行 |
| `status:warning` + `behind_commits:N` | `behind` | 「⚠ リモートブランチに未取得のコミットが {N} 件あります」表示 → `AskUserQuestion`「取り込む / スキップして続行」（従来挙動維持） |
| `status:diverged` + `diverged_ahead:A` + `diverged_behind:B` + `recommended_command:<実値>` | `diverged`（新規） | 「⚠ リモートとローカルの履歴が分岐しています（ahead={A}, behind={B}）。squash 後などで履歴が書き換わった状態が想定されます。」表示 + `recommended_command:` 行の**実値**をそのまま推奨コマンドとして表示 → `AskUserQuestion`「force push を実行する（手動）/ スキップして続行 / 中断」 |
| `status:error` + `error:fetch-failed:...` | `skipped`（reason=fetch-failed） | 「⚠ リモート同期チェックをスキップしました（リモート接続失敗）」表示、続行（従来挙動維持） |
| `status:error` + `error:no-upstream:...` | `skipped`（reason=no-upstream） | 「⚠ リモート同期チェックをスキップしました（upstream 未設定）」表示、続行（従来挙動維持） |
| `status:error` + `error:branch-unresolved:...` | `skipped`（reason=detached-head） | 「⚠ リモート同期チェックをスキップしました（detached HEAD）」表示、続行（従来挙動維持） |
| `status:error` + `error:merge-base-failed:...` / `error:log-failed:...` / `error:upstream-resolve-failed:...` | `skipped`（reason=merge-base-failed / log-failed / upstream-resolve-failed） | 「⚠ リモート同期チェックをスキップしました（git 内部エラー: {reason}）」表示、続行 |

**`AskUserQuestion` の扱い**: `diverged` は「ユーザー選択」（SKILL.md の AskUserQuestion 使用ルールで常に対話必須）として扱い、`automation_mode=semi_auto` / `full_auto` の場合でも自動化対象外とする。`01-setup.md` §6a は現行も `AskUserQuestion` を用いているため整合する。

**force push 自動実行の禁止**: ユーザーが「force push を実行する」を選択した場合でも、AI エージェントが自動で `git push --force-with-lease` を実行してはならない。ユーザー自身が `recommended_command:` 行で表示された実値コマンドをコピペ実行する想定とし、案内後は「実行完了後にステップ6aを再実行」を促す。

**UI 表示の文字列契約**: §6a の表示内容は `validate-git.sh` の stdout 行から抽出した値をそのまま使う。`recommended_command:` 行の実値を UI 層が再加工（プレースホルダー展開等）してはならない。これにより一次ソース（shell）と二次表現（markdown 指示）の齟齬を構造的に排除する。

### `operations-release.md` §7.9〜7.11 の整合

7.10 リモート同期確認（`validate-git.sh remote-sync` 呼び出し）は、現行記述:

> `warning` は追加コミット / `git push` / merge-rebase を案内、`error` はマージ停止

に `diverged` ステータスを追記する:

- `diverged`: 「ローカルとリモートの履歴が分岐しています（squash 後の状態の可能性）。`validate-git.sh` の `recommended_command:` 行の**実値**をそのままユーザーに表示して手動実行を促し、完了後に再チェック。または中断してユーザー判断。マージ停止はしない（exit 0 扱い）」

**UI 表示の文字列契約**: `operations-release.md` 追記案は `validate-git.sh` の stdout から `^recommended_command:` 行を抽出して表示する責務に限定する。markdown 内にリテラル `<remote> <branch>` / `<resolved_upstream_remote>` 等のプレースホルダー文字列を**書き込まない**。ユーザーが見る文字列は常に解決済み実値（例: `git push --force-with-lease origin HEAD:cycle/v2.3.5`）となる。

7.9〜7.11 の verify-git サマリ出力の仕様（`remote-sync=<status>` に `diverged` が出現し得る）を明記する。

## 完了条件チェックリスト

### 機能要件（Unit 責務由来）

**判定ロジックの 2 ビット分類**:

- [ ] `scripts/validate-git.sh run_remote_sync()` が `A := merge-base --is-ancestor upstream HEAD` と `B := merge-base --is-ancestor HEAD upstream` の**両方を必ず両方取得**してから分類を行う（片方だけで早期 return しない）
- [ ] 真理値 `(A=true, B=true)` → `status:ok`（完全一致）
- [ ] 真理値 `(A=true, B=false)` → `status:warning` + `unpushed_commits:N`（従来互換、unpushed）
- [ ] 真理値 `(A=false, B=true)` → `status:warning` + `behind_commits:N`（新規フィールド、behind）
- [ ] 真理値 `(A=false, B=false)` → `status:diverged` + `diverged_ahead:N` + `diverged_behind:M` + `recommended_command:<実値>`
- [ ] `merge-base` がシステムエラー（exit 2 以上）で失敗した場合は `status:error` + `error:merge-base-failed:...` を emit し exit 2 で短絡する

**生ステータス → UI 正規化マッピングの整合**:

- [ ] 「validate-git.sh の生ステータス → UI 正規化状態のマッピング表」（本計画書内）を `steps/operations/01-setup.md` §6a と `steps/operations/operations-release.md` の記述が完全に反映している
- [ ] §6a の `status:error` 系統（`fetch-failed` / `no-upstream` / `branch-unresolved` / `merge-base-failed` / `log-failed` / `upstream-resolve-failed`）がすべて `skipped`（reason={code}）として正規化され、Operations Phase 開始は続行される（従来挙動維持 + 新規 `merge-base-failed` / `upstream-resolve-failed` の二層挙動: §6a では `skipped`、`operations-release.md` 7.9〜7.11 では `error=blocking` とマージ停止扱い）
- [ ] `operations-release.md` 7.9〜7.11 の `status:error` 系統（`fetch-failed` / `no-upstream` / `branch-unresolved` / `merge-base-failed` / `log-failed` / `upstream-resolve-failed`）はマージ停止扱い（従来挙動維持 + 新規 error code も同一扱い）、`status:diverged` は**マージ停止しない** warning 相当として扱う
- [ ] §6a の `unpushed_commits:N`（`status:warning` + A=true,B=false）は `up-to-date` として正規化され、続行される（§6a は push 漏れを扱わない。7.9〜7.11 で検出）

**recommended_command の実値契約（upstream 解決ベース）**:

- [ ] `run_remote_sync()` が `status:diverged` 出力時、`recommended_command:git push --force-with-lease <resolved_upstream_remote> HEAD:<resolved_upstream_branch>` 形式で**解決済み upstream 実値**を埋め込む（リテラル `<remote>` / `<branch>` / `<resolved_*>` 文字列は出力しない）
- [ ] `upstream_remote` は `git config branch.<current_branch>.remote` で解決する（既存の `$remote` 解決と同等）
- [ ] `upstream_branch` は `git config branch.<current_branch>.merge` から `refs/heads/` プレフィックスを除去した値を使う（ローカルブランチ名を直接使わない。異名 upstream 対応）
- [ ] `git config branch.<current_branch>.merge` が取得できない、または `refs/heads/` プレフィックスを持たない場合は `status:error` + `error:upstream-resolve-failed:...` を emit し exit 2 で短絡する（`diverged` 判定前）
- [ ] `HEAD:<upstream_branch>` 形式（`<upstream_remote> <upstream_branch>` 形式ではない）を採用し、異名 upstream でも正しい ref を対象とする
- [ ] `01-setup.md` §6a は `recommended_command:` 行のコロン以降を**そのまま**ユーザーに表示する（UI 層での再展開・書き換えを行わない）
- [ ] `operations-release.md` も同様に `recommended_command:` の実値をそのまま透過する（markdown 内にリテラル `<remote> <branch>` プレースホルダー文字列を書かない）
- [ ] 手動検証（同名 upstream）: `origin/cycle/v2.3.5` 追跡ブランチで diverged 再現時、表示コマンドが `git push --force-with-lease origin HEAD:cycle/v2.3.5`（実値）であること
- [ ] 手動検証（異名 upstream）: ローカル `feature-x` が `origin/release-x` を追跡する構成で diverged 再現時、表示コマンドが `git push --force-with-lease origin HEAD:release-x`（upstream branch 名を採用）であること
- [ ] 手動検証（upstream 解決失敗）: `git config branch.*.merge` を一時的に破損させた状態で `status:error` + `error:upstream-resolve-failed:...` を返し exit 2 で終了すること

**出力行・exit code の後方互換**:

- [ ] 既存ステータス（`status:ok` / `status:warning` + `unpushed_commits:N` / `status:error` + `error:fetch-failed` / `error:no-upstream` / `error:branch-unresolved` / `error:log-failed`）の出力形式と exit code が維持されている（`status:error` = exit 2、他 = exit 0）
- [ ] 新規フィールド `behind_commits:N` / `recommended_command:...` / `diverged_ahead:N` / `diverged_behind:M` が既存パーサ（`awk '/^status:/'`）を壊さないこと（行頭 `status:` のみを参照するため影響なし）の動作確認

**operations-release.sh 側の透過**:

- [ ] `scripts/operations-release.sh cmd_verify_git()` のサマリ（`verify-git:summary:...remote-sync=<status>...`）に `diverged` がそのまま透過される（コード変更なし、サマリの動作検証のみ）
- [ ] `cmd_verify_git()` の exit code 集約（`max(uncommitted_ec, remote_sync_ec)`）が `diverged` を warning 相当（exit 0）として扱う

**ドキュメント・分岐追加**:

- [ ] `steps/operations/01-setup.md` §6a の状態テーブルに `diverged` 行が追加され、`AskUserQuestion`「force push を実行する（手動）/ スキップして続行 / 中断」フローが明記されている
- [ ] `01-setup.md` §6a で「force push の自動実行を行わない」旨が明記されている（ユーザー手動実行のみ）
- [ ] `steps/operations/operations-release.md` の 7.10 リモート同期チェック記述に `diverged` 取扱いが追記されている（「マージ停止しない、手動 force push 推奨、再チェック誘導」、`recommended_command` の実値透過）
- [ ] 回帰防止: `01-setup.md` / `operations-release.md` の `up-to-date` / `behind` / `fetch-failed` / `skipped` 既存挙動が変更されていない

**手動検証シナリオ**:

- [ ] squash 実施済み＋未 push（squash 後 divergence）シナリオで `status:diverged` と判定されること
- [ ] squash 後に `git push --force-with-lease` を実行してから再チェックすると `status:ok` に戻ること
- [ ] 通常の未 push コミットあり（squash なし）シナリオで従来通り `status:warning` + `unpushed_commits:N`（+ A=true,B=false の分類）を返すこと
- [ ] リモートが local を追い越した状態（誰かが remote に push した）で `status:warning` + `behind_commits:N`（+ A=false,B=true の分類）を返すこと
- [ ] 完全同期状態で `status:ok` を返すこと（回帰防止）
- [ ] fetch 失敗時に `status:error` + `error:fetch-failed` を返すこと（回帰防止）、01-setup.md §6a では `skipped` として続行されること
- [ ] detached HEAD 時に `status:error` + `error:branch-unresolved` を返すこと、01-setup.md §6a では `skipped` として続行されること

### 整合性・品質要件

- [ ] 設計 / コード / 統合の 3 段階 AI レビューを Codex で実施（`review_mode=required`）
- [ ] markdownlint 実行結果エラー 0
- [ ] Unit 定義ファイルの「実装状態」を「完了」に更新
- [ ] `/write-history` スキルで履歴を記録
- [ ] Construction Phase のコミット規約に従い squash 後にコミット

### 境界（実装対象外）

- `operations-release.sh` の他のサブコマンド（`merge-pr` 等）の変更（Unit 003 のスコープ）
- Construction Phase の squash 完了後の案内追加（Unit 004 のスコープ）
- `force-with-lease` の自動実行（案内のみ、ユーザー手動実行）
- 復帰判定の参照先変更（Unit 001 のスコープ、既完了）
- `merge-base --is-ancestor` 以外の divergence 検出アルゴリズム（例: reflog 参照等）

## 依存関係・実装順序

- 本 Unit は **Unit 001 完了後に着手**（依存なし、しかし Unit 001 で operations/progress.md の固定スロット grammar 等の基盤が整っているため後続として実装）
- 本 Unit 完了後、Unit 003（`merge-pr --skip-checks`）と Unit 004（Construction 側の force-push 案内）が続く
  - Unit 003 は `operations-release.sh` の共有更新対象のため、本 Unit 完了を待って着手（並行実装禁止）
  - Unit 004 は本 Unit で定義する `diverged` ステータス仕様を前提とするため、本 Unit 完了後に着手

## 非機能要件（NFR）

Unit 定義の NFR を踏襲:

- パフォーマンス: `merge-base --is-ancestor` は軽量（既存 fetch + log と同程度）。応答時間は現行と同等
- セキュリティ: `--force-with-lease` は他者コミット上書きリスクを低減。自動実行はしない（ユーザー承認必須）
- スケーラビリティ: N/A
- 可用性: fetch 失敗時は従来通り `fetch-failed` を返す

## リスクと緩和策

| リスク | 影響 | 緩和策 |
|-------|------|--------|
| `merge-base --is-ancestor` の exit code 解釈誤り | 判定反転による誤検知 | `set +e` で囲み exit 0/1 を明示的に比較、ユニットテスト的手動検証で全 4 組み合わせ（ok/warning/behind/diverged）を確認 |
| `diverged` ステータスの既存呼び出し箇所での取扱い漏れ | `behind` と同等扱いされ誤案内 | `grep -r "remote-sync"`, `grep -r "status:warning"` 等で参照箇所を全列挙し、ドキュメント・ステータスパースロジックを個別確認 |
| `behind_commits` フィールド追加で既存パーサが壊れる | `01-setup.md` / `operations-release.md` のステータス抽出が破綻 | 既存パーサは `^status:` 行のみ参照していることを確認。新規フィールドは追加情報として扱われる |
| 推奨コマンドのプレースホルダー展開漏れ | ユーザーがコピペで実行できない | `run_remote_sync()` 内で解決済みの `$upstream_remote` / `$upstream_branch` 変数を展開、テストで実値表示を確認 |
| 異名 upstream（local≠upstream ブランチ名）での誤った push 先案内 | ローカル名ベースで案内すると意図しない ref を破壊しうる | `upstream_branch` を `git config branch.*.merge` から解決し `HEAD:<upstream_branch>` 形式で出力。手動検証ケースとして異名 upstream シナリオを追加 |
| upstream 解決失敗（`branch.*.merge` 未設定等）で不完全な推奨コマンド出力 | 構文的に壊れた案内がユーザーに表示される | `status:error` + `error:upstream-resolve-failed:...` で exit 2 短絡する契約を `validate-git.sh` に追加 |
| force push 自動実行による他者コミット破壊 | データロス | 計画・ドキュメント・ステップファイルで「自動実行禁止」を明記、AI エージェントが推奨コマンド表示のみに留まる契約を徹底 |
| squash 以外の divergence パターン（rebase 等）での誤判定 | 不必要に force push を推奨してしまう | `diverged` の判定条件は「双方向 non-ancestor」のみであり、squash 固有の検出ではない。メッセージ文言も「squash 後の状態が想定されます」と**断定せず**、divergence 一般として案内する |
| 01-setup.md §6a の状態テーブル更新漏れ | ユーザーに対話が提示されない | 完了条件チェックリストで §6a テーブル更新と AskUserQuestion 分岐の両方を別項目で検証 |
| `operations-release.sh cmd_verify_git()` の exit code 集約ロジック崩壊 | `diverged` でマージが停止される | `remote_sync_ec=0` の伝播を手動検証し、サマリに `diverged` が表示されつつ exit 0 を返すことを確認 |
| markdown 側の文言と shell 側のメッセージの不整合 | ユーザーが case-by-case で異なる説明を見る | 推奨コマンド文言・分岐条件は論理設計フェーズで「一次ソース = validate-git.sh stdout」「二次参照 = 01-setup.md テーブル」と責務分離し、齟齬時は一次ソースを優先 |

## AI レビュー計画

- ツール: `codex`（`rules.reviewing.tools[0]`）
- `review_mode=required` のためスキップ不可。設計 / コード / 統合の 3 段階で実施
- 各レビューはフォールバック条件（`review_issues` / `error`）該当時にユーザー確認へ遷移
- コードレビュー観点には、上記「リスクと緩和策」の各項目（特に is-ancestor exit code 解釈、既存パーサ互換、force push 自動実行禁止）を含める

## 完了後の遷移

- Unit 定義「実装状態」を「完了」に更新
- `/write-history` で履歴記録
- markdownlint → squash → commit
- 次 Unit（Unit 003: merge-pr `--skip-checks` オプション追加）へ

## 承認要求

本計画に基づき Unit 002 を開始します。計画に過不足がないか確認してください。
