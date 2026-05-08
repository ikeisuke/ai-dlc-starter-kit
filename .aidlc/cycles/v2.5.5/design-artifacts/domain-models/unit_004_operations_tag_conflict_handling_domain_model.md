# ドメインモデル: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加

## 概要

Operations Phase 04-completion ステップ 3（バージョンタグ付け）における「リモート CI 自動 tag 機構との衝突」を観測・分類・適切に処理するためのドメイン。リモート tag の状態（不在 / 同 SHA 衝突 / 異 SHA 衝突）を 3 ケースの **判定マトリクス** として定式化し、各ケースに対する fallback 手順を文書化する責務を扱う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2（文書追加のみ）で行います。

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| リリース tag | `vX.X.X` 形式の semver アノテーション付き git tag（`git tag -a vX.X.X -m "..."` で作成） |
| マージコミット SHA | `cycle/vX.X.X` ブランチを `main` にマージした直後の `git rev-parse HEAD` の値（40 文字の full SHA） |
| tag object SHA | annotated tag に対して `git ls-remote --tags origin vX.X.X` が返す **タグオブジェクト自身の SHA**（コミット SHA とは別物。lightweight tag の場合は commit SHA と一致する） |
| peeled commit SHA | annotated tag が指す対象コミットの SHA。`git ls-remote origin "refs/tags/vX.X.X^{}"` または `git fetch origin tag vX.X.X` 後に `git rev-parse vX.X.X^{commit}` で取得（40 文字 full SHA） |
| ローカル tag | ローカル git リポジトリに作成したタグオブジェクト（`git tag -a` で作成、未 push 状態） |
| CI 自動 tag 機構 | GitHub Actions 等で auto-merge 後にリリース tag を自動作成するワークフロー。tagger は `github-actions[bot]` 等の bot アカウント |
| tag push reject | `git push origin vX.X.X` 実行時にリモートに同名 tag が既存することにより `! [rejected] vX.X.X -> vX.X.X (already exists)` エラーで拒否される現象 |
| 不在ケース | リモートに `vX.X.X` が存在しない状態（`git ls-remote` 出力が空）。標準パス |
| 同 SHA 衝突 | リモート tag が指す SHA がローカルのマージコミット SHA と一致する状態。CI 自動 tag が正規版である運用での典型ケース |
| 異 SHA 衝突 | リモート tag が指す SHA がローカルのマージコミット SHA と不一致な状態。誤操作 / 古い CI 実行 / 別ブランチ tag 等の異常パターン |
| fallback 手順 | 各衝突ケースに対する 3 項目固定の復旧手順（同 SHA / 異 SHA で項目構造は異なる）|
| 判定マトリクス | 3 ケース（不在 / 同 SHA / 異 SHA）× 4 列以上（ケース名 / 検出コマンド出力 / 期待結果 / 次アクション）の markdown table |

## 値オブジェクト（Value Object）

### LocalMergeCommitSha

- **属性**: `value: String40Hex` — `git rev-parse HEAD` の出力（40 文字の hex 文字列）
- **不変性**: ステップ 1（`git checkout main`）+ ステップ 2（`git pull`）完了後の HEAD は ステップ 3 の処理中変化しない（前提）
- **等価性**: 文字列完全一致

### RemoteTagPresence

- **属性**: `value: Optional<TagObjectSha>` — `git ls-remote --tags origin vX.X.X` の第 1 列（**存在検出のみに使用**）
  - `Some(_)`: リモートに tag 存在
  - `None`: リモートに tag 不在（`git ls-remote` 出力が空）
- **不変性**: 1 回の判定処理中（ms 〜 数秒オーダー）はリモートが変化しない前提（race condition は許容範囲外として扱う）

### RemoteTagCommitSha（**SHA 比較に使う正規値**）

- **属性**: `value: Optional<String40Hex>` — リモート tag が指す **peeled commit SHA**
  - `Some(sha)`: リモートに tag 存在し、かつ対象コミットを取得できた場合
  - `None`: リモートに tag 不在の場合
- **取得方式**（annotated / lightweight 両対応）:

  ```text
  # 推奨パス（annotated でも lightweight でも commit SHA が返る）
  git ls-remote origin "refs/tags/vX.X.X^{}"   # annotated tag → peeled commit SHA
  # 出力が空（lightweight tag）の場合のみ、上の存在検出（RemoteTagPresence）の値を採用
  ```

  ローカル取得後検証（fallback 経路）: `git fetch origin tag vX.X.X` → `git rev-parse vX.X.X^{commit}`

- **不変性**: 同一 git index / 同一 ref に対して同一値（決定論的）
- **等価性**: `Some(a) == Some(b)` ⇔ 文字列完全一致、`None == None` は真
- **不変条件**: `RemoteTagSha` を tag object SHA としてコミット SHA と直接比較してはならない（誤分類防止 / Round 1 指摘 #1 対応）

### TagConflictCase

- **属性**: `kind: Enum { absent, same_sha_conflict, diff_sha_conflict }`
- **判定規則**（**peeled commit SHA 同士の比較**を強制 / Round 1 指摘 #1 対応）:

  | RemoteTagPresence | RemoteTagCommitSha と LocalMergeCommitSha の関係 | TagConflictCase |
  |-------------------|---------------------------------------------------|-----------------|
  | `None` | 比較対象なし（tag 不在） | `absent` |
  | `Some(_)` | `RemoteTagCommitSha == Some(local_sha)` | `same_sha_conflict` |
  | `Some(_)` | `RemoteTagCommitSha != Some(local_sha)`（None / 異なる SHA を含む） | `diff_sha_conflict` |

- **不変性**: 同一 `(RemoteTagPresence, RemoteTagCommitSha, LocalMergeCommitSha)` 入力に対して同一結果（純粋関数）
- **誤分類防止契約**: tag object SHA とコミット SHA の比較は禁止。`RemoteTagCommitSha` は必ず peeled 形式（`refs/tags/vX.X.X^{}` または `vX.X.X^{commit}`）で取得した値を使用する

### FallbackProcedure

- **属性**: `case: TagConflictCase`, `steps: List<ProcedureStep>`（3 項目固定）
- **構造規則**:

  | TagConflictCase | 必須 3 項目（順序固定） |
  |-----------------|----------------------|
  | `absent` | 既存手順（`git tag -a` + `git push origin vX.X.X`） |
  | `same_sha_conflict` | (1) ローカル tag 削除 / (2) `git fetch origin tag vX.X.X` / (3) 同期後検証 |
  | `diff_sha_conflict` | (1) 自動 push 中止 / (2) 差分提示 / (3) ユーザー選択肢提示（i / ii / iii） |

- **不変性**: 各ケースの 3 項目構造は Unit 004 計画書 §「文書構造設計」を SoT として固定

### UserChoice（`diff_sha_conflict` の選択肢のみ）

- **属性**: `kind: Enum { remote_priority, local_priority, abort }`
- **動作マトリクス**:

  | UserChoice | 動作 | 破壊性 | 確認フロー |
  |-----------|------|-------|----------|
  | `remote_priority` | ローカル tag 削除 + `git fetch origin tag vX.X.X`（推奨） | 非破壊 | 標準（auto） |
  | `local_priority` | `git push --force origin vX.X.X` | **破壊的** | 明示確認必須（CI / 他リリース成果物との整合性破壊リスクを警告） |
  | `abort` | tag 操作スキップ + Operations Phase 中断 → 調査モード | 非破壊 | 標準（auto） |

## ドメインサービス

### TagConflictDetector

- **責務**: 以下 3 コマンドを実行し、`(RemoteTagPresence, RemoteTagCommitSha, LocalMergeCommitSha)` を取得して `TagConflictCase` を判定する:
  1. `git ls-remote --tags origin vX.X.X` → `RemoteTagPresence`（存在検出のみ）
  2. `git ls-remote origin "refs/tags/vX.X.X^{}"` → `RemoteTagCommitSha`（peeled。出力空かつ手順 1 が非空なら lightweight tag として手順 1 の SHA を採用）
  3. `git rev-parse HEAD` → `LocalMergeCommitSha`
- **操作**: `detect(version: String) -> Result<TagConflictCase, DetectionError>`
- **エラー条件**:
  - `git ls-remote` がネットワーク失敗 → `DetectionError::network`（既存 `git push` 失敗時と同等扱い、ユーザー判断にフォールバック）
  - `git rev-parse HEAD` 失敗 → `DetectionError::head_missing`（直前ステップへの差し戻しを案内）
- **適用条件**: ステップ 3 の `version_tag = true` 経路のみ。`version_tag = false` 経路には適用しない

### FallbackResolver

- **責務**: `TagConflictCase` を入力に対応する `FallbackProcedure` をユーザーに提示し、`absent` 以外では fallback 手順を実行する
- **操作**: `resolve(case: TagConflictCase) -> ResolutionOutcome`
- **判定の冪等性**: 同一ケースに対して同一手順（手順自体は決定的）

### UserDecisionService（`diff_sha_conflict` 時のみ）

- **責務**: 異 SHA 衝突時に 3 つの `UserChoice` を提示し、`local_priority` 選択時は **破壊的操作** であることを明示確認する
- **操作**: `present_choices(diff: TagDiffSummary) -> UserChoice`
- **確認契約**: `local_priority` 選択時は `automation_mode` に関わらず **常に明示確認必須**（破壊的操作のため `rules-core.md` 「実行するアクション」のリスク扱いに該当）

## エンティティ（Entity）

このドメインは「文書追加が主作業」のため、永続的なエンティティは存在しない（手順実行時の状態は git index / リモート refs に外部化される）。

## 集約（Aggregate）

`TagConflictDetector` の検出結果（`TagConflictCase`）と `FallbackResolver` が提示する `FallbackProcedure` は、**1 サイクル 1 リリース tag** という運用境界で 1 つの集約として扱える（`vX.X.X` バージョン文字列を集約ルート）。同一サイクル内で複数 tag を扱うシナリオは Unit 境界外（OUT_OF_SCOPE）。

## ドキュメント不変条件（文書 SoT）

文書追加が主作業のため、以下を「ドメイン不変条件」として `04-completion.md` ステップ 3 の改修箇所に組み込む:

1. **3 ケース必須**: 判定マトリクスは `absent` / `same_sha_conflict` / `diff_sha_conflict` の 3 ケースを **すべて** 含む（欠落不可）
2. **4 列以上必須**: 判定マトリクス table のカラム数は ≥ 4（ケース名 / 検出コマンド出力 / 期待結果 / 次アクション）
3. **fallback 手順 3 項目固定**: 同 SHA / 異 SHA いずれも 3 項目（順序付き）。項目数の増減は計画変更が必要
4. **`diff_sha_conflict` 選択肢 3 つ固定**: `remote_priority` / `local_priority`（破壊的・明示確認）/ `abort` の 3 つを **すべて** 提示する
5. **既存構造の非破壊**: `version_tag = false`/`true` の二択構造は変更しない（Unit 境界。設定値追加 / 構造変更は OUT_OF_SCOPE）

## ドリフト検知

文書追加後の検証用 grep クエリ（責務ごとに分割 / Round 1 指摘 #2 対応）。各クエリは少なくとも 1 件 hit することを期待値とする:

| 責務 | 検証クエリ | 期待 hit 内容 |
|------|----------|-------------|
| 1: 事前確認 | `grep -nE 'git ls-remote --tags origin vX\.X\.X' skills/aidlc/steps/operations/04-completion.md` | 事前確認手順での tag 存在検出コマンド |
| 1: peeled 取得 | `grep -nE 'refs/tags/vX\.X\.X\^\{\}\|vX\.X\.X\^\{commit\}' skills/aidlc/steps/operations/04-completion.md` | peeled commit SHA 取得コマンド（誤分類防止） |
| 2: 3 ケース | `grep -nE 'ケース A\|ケース B\|ケース C' skills/aidlc/steps/operations/04-completion.md` | 3 ケース見出し |
| 2: tagger 例 | `grep -nE 'github-actions\[bot\]' skills/aidlc/steps/operations/04-completion.md` | 同 SHA 衝突の典型 tagger 例示 |
| 3: 同 SHA 3 項目 | `grep -nE '同 SHA' skills/aidlc/steps/operations/04-completion.md` および同セクション内の `1\.`/`2\.`/`3\.` を順序付きリストとして確認 | 同 SHA fallback の 3 項目 |
| 4: 異 SHA 3 項目 | `grep -nE '異 SHA' skills/aidlc/steps/operations/04-completion.md` および同セクション内の `1\.`/`2\.`/`3\.` を順序付きリストとして確認 | 異 SHA fallback の 3 項目 |
| 4: 選択肢 (i)(ii)(iii) | `grep -nE '\(i\)\|\(ii\)\|\(iii\)' skills/aidlc/steps/operations/04-completion.md` | 3 つの選択肢 |
| 4: 破壊的明示確認契約 | `grep -nE '破壊的\|明示確認' skills/aidlc/steps/operations/04-completion.md` | (ii) ローカル優先の破壊性 + 明示確認必須記述 |

各クエリが期待 hit 数を満たせば、ドメイン不変条件 1〜5 が文書に組み込まれていることを機械的に確認できる。Unit 履歴に各クエリの hit 件数を記録すること。
