# ドメインモデル: Construction Unit 完了処理 step5↔step8 分裂の構造的予防

## 概要

Construction Phase の Unit 完了処理において「ステップ 5（履歴記録 / `write-history.sh`）の成果物がステップ 8（Git コミット）の commit に同期されず別 commit に分裂する事故」を防止するドメイン。三層防御（文書整合 / チェックリスト / 警告経路）の各層が独立に動作し、見落とし耐性を確保する責務を扱う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2 で行います。

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| 履歴ファイル | `.aidlc/cycles/{{CYCLE}}/history/<phase>.md` または `construction_unit{NN}.md`。`write-history.sh` が `--mode base` で生成・追記する Markdown ファイル |
| staged 状態 | git index に履歴ファイルへの変更が登録されている状態（`git diff --cached --name-only -- <path>` で当該パスが出力される） |
| unstaged 状態 | working tree に履歴ファイルへの変更があるが index に未登録の状態。`git add` 未実行を意味する |
| step5↔step8 分裂 | ステップ 5 で履歴ファイルを作成・更新したが、ステップ 8 のコミット時に履歴ファイルが staged されておらず、後続コミットで追加される現象。v1.15.1 cycle で 5 Unit × 2 commit = 10 commit 分裂を発生 |
| 三層防御 | 提案 A（文書）/ B（チェックリスト）/ C（自動警告）の 3 層で同じ事故を多重に予防する設計パターン |
| warning 契約 | `check_history_staged_status()` 関数の出力契約（stderr 一本化 / 文言 `warning: history file unstaged: <絶対パス>` / exit 0 維持）。Unit 003 計画書 § warning 契約を SoT とする |
| ドキュメントドリフト | 文書 A / B が記述する挙動と実装 C の挙動が乖離する現象。grep クエリで機械的に検知する仕組みを Unit 003 で導入 |

## 値オブジェクト（Value Object）

### HistoryFilePath

- **属性**: `path: AbsolutePath` — 履歴ファイルの絶対パス
- **不変性**: `write-history.sh --mode base` の通常パスで決定された値が後続処理で変化しない
- **等価性**: 文字列等価（正規化なし）

### StagedStatus

- **属性**: `kind: Enum { staged, unstaged, unknown }`
  - `staged`: `git diff --cached --name-only -- <path>` の **リポジトリルート相対表現に正規化された出力**に当該パス（同じく相対表現に正規化）が含まれる
  - `unstaged`: 含まれない（working tree 変更あり / 変更なしの両方を含む）
  - `unknown`: `git diff` 自体が exit 非 0（git リポジトリ外、index 破損、権限不足 等）、または `git rev-parse --show-toplevel` での repo-root 取得が失敗。**安全側に倒し warning スキップ**
- **判定方式**:
  1. `git -C "$(dirname "$filepath")" rev-parse --show-toplevel` でリポジトリルート絶対パスを取得（失敗 → `unknown`）
  2. `$filepath`（絶対パス）からリポジトリルートを除去し repo-root 相対パスへ正規化（失敗 → `unknown`）
  3. `git diff --cached --name-only -- "$filepath"` の stdout（こちらは git が repo-root 相対で返す）と上記正規化結果を比較
  4. 完全一致行が含まれれば `staged`、含まれなければ `unstaged`
- **正規化契約**: 「絶対パス vs リポジトリ相対パス」の混在による誤判定を防ぐため、**比較前に必ず両者を repo-root 相対表現へ統一する**（Round 1 指摘 #1 対応）

### WarningOutput

- **属性**: `channel: Enum { stderr }`, `format: String = "warning: history file unstaged: <path>"`, `exit_code: Integer = 0`
- **不変性**: warning 契約 SoT（計画書 § warning 契約）に固定。仕様変更には Unit 計画変更が必須

## ドメインサービス

### HistoryStagedStatusChecker

- **責務**: `HistoryFilePath` を入力に `StagedStatus` を判定し、`unstaged` の場合は `WarningOutput` を発行する。判定不能（`unknown`）時は warning スキップ
- **操作**: `check(filepath: HistoryFilePath) -> Optional<WarningOutput>`
- **適用条件**: `write-history.sh` の `--mode base` 通常パス完了直後（mode unit-complete-short-note / operations-round には適用しない）
- **判定の冪等性**: 同一 git index 状態に対して同一結果（`git diff` 結果が決定的）

### CommitFlowChecker（既存ステップ 8 内の人間操作）

- **責務**: コミット前確認チェックリスト（`commit-flow.md`）に従って履歴ファイルが staged であるかを **人間が** 確認する
- **判定**: `HistoryStagedStatusChecker` の自動警告と独立した「人間チェック層」。両者の指摘が一致する設計を取り、ドリフト時は両層で別々に検知される

## 三層防御の構造図

```text
[ステップ 5] write-history.sh --mode base
  └─ 履歴ファイル更新
  └─ HistoryStagedStatusChecker.check() ← レイヤー C（自動警告 / 構造的）
       └─ unstaged → stderr に warning（exit 0 維持）
       └─ staged   → 警告なし
       └─ unknown  → 警告スキップ（後方互換）

[ステップ 5 → ステップ 8 移行]
  └─ 04-completion.md（提案 A: ステップ 5 / ステップ 8 注記）← レイヤー A（文書 / 啓発）
  └─ 履歴ファイル整合性表現を読むことで「git add」を意識化

[ステップ 8] Git コミット
  └─ commit-flow.md（提案 B: チェックリスト + ドライラン手順）← レイヤー B（人間操作 / 確認）
       └─ 「履歴ファイル staged 確認」項目で人間が再チェック
       └─ ドライラン手順 3 点固定（write-history 実行参照 / git status または git diff --cached --name-only / git add）
```

**多重防御の意味**（Round 1 指摘 #2 対応 / 独立性の再定義）:

各層は「**実装主体 / 検知トリガー / 失敗モード**」が異なることで独立性を担保する:

| 層 | 実装主体 | 検知トリガー | 主な失敗モード |
|----|---------|------------|--------------|
| A | 文書（04-completion.md）/ 人間の読み手 | ユーザーがステップ 5 / ステップ 8 の説明文を読む | 文書未参照、ドキュメントドリフト |
| B | 文書（commit-flow.md チェックリスト）/ 人間の手動確認 | ユーザーがコミット前にチェックリストを実行する | 手順スキップ、チェックリスト読み飛ばし |
| C | 実装（write-history.sh / `check_history_staged_status()`）/ 自動判定 | `--mode base` 完了時に git diff で機械判定 | git リポジトリ外実行（unknown 判定で warning スキップ）、stderr 抑制環境 |

**A / B 層の共通故障モード**（独立性の不完全性の明示）:

- 同一文書群（`skills/aidlc/steps/`）に依存し、ドキュメントドリフトが両層を同時に汚染する可能性
- 同一運用者の認知負荷で「ドキュメント全体を読み飛ばす / 確認を急ぐ」と両層同時に機能不全
- 言い換えれば A / B は **実装主体としては類似（人間の確認）** であり、C 層の **機械的判定**（自動）と種類が異なる

→ **真の独立性は A 系（人間）と C 系（機械）の 2 系統**。本設計は「C 層を起点に、A / B が読み手の意識化を促す」構造であり、3 層すべてが同時に偽となるケースは「git リポジトリ外実行 + 文書未参照 + チェックリスト未実施」という極めて稀な複合条件のみ。

**B 層の機械判定化（将来拡張点）**: pre-commit hook で `git diff --cached --name-only` を確認し、履歴ファイル更新があったが staged されていない場合に commit を中断する半自動化が考えられる。本 Unit のスコープ外（次サイクル候補、計画書「フォローアップ事項」相当）。論理設計に将来拡張として記録する。

## 不変条件

1. **後方互換**: `write-history.sh` の stdout 出力（`history:<path>:created/appended` 等）と exit code（0）は本 Unit 改修で変化しない。stderr 警告のみ追加
2. **mode 適用境界**: `check_history_staged_status()` は `--mode base` 経路のみで呼ばれる。`--mode unit-complete-short-note` / `--mode operations-round` の経路には影響を与えない
3. **判定不能時の安全側挙動**: `git diff` が exit 非 0 を返す場合は warning スキップで exit 0 維持。git リポジトリ外でも write-history は失敗しない
4. **warning 契約の固定**: stderr 一本化 / 文言 / exit code は Unit 計画書 § warning 契約 を SoT とする
5. **三層独立性**: 提案 A / B / C のどれか 1 層が欠落しても残り 2 層で検知できる構造を維持

## 関連する意思決定（DR）

- **DR-002（write-history.sh 自身が判定主体）**: write-history.sh が外部呼び出し（caller 側で git status を確認する形）でなく、内部判定として `git diff --cached --name-only -- <path>` を実行する。単一責任とテスト対象明確化のため。本 Unit で実装
- **Unit 定義の「stdout/stderr」表現の読み替え**: Unit 定義「責務」の「警告を stdout/stderr に出力」は、計画書 § warning 契約で **stderr 一本化** に確定する（Unit 履歴で経緯記録）

## 不明点と質問（設計中に記録）

[Question] `git diff --cached --name-only -- "$filepath"` で `$filepath` が絶対パスの場合と相対パスの場合で挙動が異なるか
[Answer] **絶対パスで動作する**。`git diff` は絶対パス引数を受理し、リポジトリルート相対に変換した上で index と比較する。`write-history.sh` 内部でも `$filepath` は絶対パスで保持されているため、そのまま渡して問題ない。テスト fixture も絶対パスで構築する。

[Question] 履歴ファイルが `.gitignore` に含まれている場合の挙動
[Answer] **本ドメインでは想定外**。`.aidlc/cycles/` は通常 `.gitignore` から除外されない（履歴を git 管理する前提）。仮に gitignore された場合は `git diff --cached --name-only` の出力に含まれず unstaged 判定 → warning 出力となるが、これは通常運用外のため許容する。
