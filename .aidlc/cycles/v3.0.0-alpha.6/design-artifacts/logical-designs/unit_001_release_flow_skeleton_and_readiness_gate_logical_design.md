# 論理設計: Unit 001 release フロー骨格 + リリース準備ゲート

## 概要

`skills/aidlc-v3/steps/release.md`（新規）の構成と、Step 1「リリース準備」の手順インターフェース（判定セマンティクス・依存スクリプト契約・停止/警告/継続の出力）を定義する。Step 2–4 は骨格（プレースホルダ見出し）のみ。

**重要**: この論理設計では**コードは書かず**、release.md の章構成・各 Step の手順契約・依存スクリプトの呼び出し契約のみを定義する。具体的なコマンド文字列の最終整形は実装（Phase 2 / コード生成）で行う。

## アーキテクチャパターン

- **手順ドキュメント + 安全境界スクリプト委譲**（既存 `define.md` / `develop.md` と同一パターン）。判定・案内は Markdown 手順で表現し、atomic 性・パース安全性が必要な処理（state 読取・frontmatter 構造解釈）は既存 `scripts/` へ委譲する（RFC P4）。
- **read-only ゲート**: Step 1 は状態を変更しない。stop 条件でも副作用を残さない（fail-closed / mutation なし）。
- **SoT 非再定義**: フェーズ導出（`data-model.md §5`）・state schema（§3）・review perspective（`workflow.md §6`）は再定義せず参照する。

## コンポーネント構成

### ドキュメント構成（`steps/release.md`）

```text
steps/release.md
├── 位置づけ注記（v3.0.0-alpha.6 / 本 Unit は骨格 + Step 1 / Step 2–4 は後続 Unit）
├── 目的
├── フロー全体（Step 1–4 表: 内容 / ゲート・成果物）
├── パス解決
├── Step 0: 前提確認（clean-worktree + cycle 解決）   ← develop.md Step 0 踏襲
├── Step 1: リリース準備（★ ゲートなし / 停止パターンあり）  ← 本 Unit で実装
│   ├── 1-1 state 前提確認（define_completed / state.json 不在）
│   ├── 1-2 全 work item 完了確認（done/withdrawn / 未完了一覧提示で停止）
│   ├── 1-3 git status 確認（dirty=停止）
│   └── 1-4 test・CI 状態確認（test fail / CI failure=停止 / CI 未実行=警告継続）
├── Step 2: PR 整備 ★ PR ready 確認        ← プレースホルダ（Unit 002 で実装）
├── Step 3: Merge 承認 + 実行 ★ merge 承認  ← プレースホルダ（Unit 003 で実装）
├── Step 4: Post-merge                      ← プレースホルダ（Unit 003 で実装）
└── 完了後のフェーズ導出                      ← data-model §5 参照
```

### コンポーネント詳細

#### Step 0: 前提確認（前段ガード）

- **責務**: Step 1 以降の前提（clean-worktree / active cycle 解決）を確認する
- **依存**: `git status --porcelain` / `state-read.sh current_cycle`
- **公開インターフェース**: `<cycle>` の確定、または案内して終了（mutation なし）
- **挙動**（develop.md Step 0 と同一写像）:
  - `state-read.sh current_cycle` exit 0 + 値 → `<cycle>` 確定
  - exit 1（state.json 不在 / current_cycle 欠落）→「先に `/aidlc-v3 define` / `develop` を実行」と案内して終了
  - exit 2（jq 不在 / 読取不可）→ エラー提示して終了
  - clean-worktree は Step 1 の 1-3 と重複するが、Step 0 は「フロー開始の前提」、1-3 は「リリース準備としての明示確認」として両建てする（develop.md は Step 0 のみ。release は dirty を停止理由として Step 1 に明記する SoT 要件があるため 1-3 に再掲）

#### Step 1: リリース準備（read-only ゲート）

- **責務**: ドメインモデルの ReleaseReadinessGate を手順として表現。各観点を評価し continue / stop / warn_continue を決める
- **依存**: `state-read.sh`（state 前提）/ `work-item-validate.sh`（schema preflight）/ `work-item-status.sh --read`（各 item status 読取）/ `git status --porcelain`（事前 + test 後再評価）/ プロジェクトの test 入口・`gh`（CI）
- **公開インターフェース**: Step 2 へ continue、または案内提示して停止（mutation なし）、または警告して継続

#### Step 2–4: プレースホルダ（骨格のみ）

- **責務**: 章立て・ゲート(★)位置・成果物の明示のみ。実装は後続 Unit
- **記法**: 各見出しに「（Unit 002 で実装）」「（Unit 003 で実装）」を明記し、本文は 1–2 文の要約に留める（誤って未実装手順が実行されないよう、実装対象外であることを明示）

## インターフェース設計

### Step 1 の判定セマンティクス（手順契約 / 評価順）

| 順 | 評価対象 | 入力 | continue 条件 | stop 条件 | warn_continue 条件 |
|----|---------|------|--------------|----------|-------------------|
| 1 | state 前提 | `state-read.sh current_cycle` / `define_completed` | `define_completed=true` | state.json 不在（exit 1）/ `define_completed=false` → define/develop 案内 / exit 2 → system error | - |
| 2a | work item schema preflight | `work-item-validate.sh "<work-items-dir>"` | exit 0（`status:valid`）→ 2b へ | exit 1（schema 違反 / 0 件 / dir 不在）= validation stop / exit 2 = system error stop | - |
| 2b | work item 完了集計 | 各 `work-items/*.md` を `work-item-status.sh --read <path>` で読取し集計 | 全 item が `done`/`withdrawn` | 未完了（`pending`/`in_progress`/`blocked`）あり → 未完了一覧提示 / 個別 read の exit 1・2 → stop | - |
| 3 | worktree（事前） | `git status --porcelain` | 空（clean） | 非空（dirty） | - |
| 4 | test | プロジェクトのテスト入口を実行 | exit 0 | non-zero | - |
| 5 | worktree（test 後再評価） | `git status --porcelain` | 空（clean） | 非空（test 生成物等で dirty）→ gitignore 等で解消を案内 | - |
| 6 | CI | `gh`（`gh_status=available` 時） | conclusion=success | conclusion=failure | pending / 未実行 / 取得不能 / `gh` 不在 / CI 未設定 |

- **fail-closed**: stop 条件が 1 つでも成立すれば release は中断（後続評価へ進まなくてよい）。順 1→6 で最初の stop を提示する。
- **read-only スコープ**: いずれの stop でも aidlc state.json / frontmatter / journal / commit を変更しない。test 実行は worktree を汚し得るため `read-only` は「aidlc 管理状態を変更しない」意味に限定し、test 後の worktree dirty（順 5）で副作用混入を検出する（設計レビュー R1 #1）。

### 依存スクリプト契約（既存 / read-only 利用）

#### state-read.sh（既存）

- **引数**: `<field> [file]`（`current_cycle` / `define_completed`）
- **exit**: 0=値出力 / 1=未知 field・ファイル不在・キー欠落・JSON 不正 / 2=jq 不在・読取不可
- **release Step 1 での写像**: `current_cycle` exit 1 → active cycle なし（define/develop 案内）/ `define_completed` 値が `false` → define 未完了案内 / exit 2 → システムエラー停止

#### work-item-validate.sh（既存 / read-only）

- **引数**: `<work-items-dir> [expected_status]`
- **exit**: 0=`status:valid` / 1=schema 違反・0 件・dir 不在 / 2=読取不可
- **release Step 1 での利用**: 順 2a の schema preflight として利用。exit 0 のみ status 集計（順 2b）へ進む。exit 1=validation stop / exit 2=system error stop。**未完了 item の一覧は返さない**ため、status 集計は順 2b の `work-item-status.sh --read` 結果から手順側で行う

#### work-item-status.sh --read（既存 / read-only）

- **引数**: `--read <path>`
- **出力**: `status:<value>` / **exit**: 0=読取成功 / 1=status 行 0 or 複数・malformed・enum 不正 / 2=読取不可
- **release Step 1 での利用**: 各 work item の status 読取（develop.md Step 1 と同じ安全境界）。手順側は全 `work-items/*.md` に適用し未完了（`done`/`withdrawn` 以外）を集計する。個別 read の exit 1/2 は stop

### work item status 集計（新規スクリプトなし / 安全境界委譲）

- **目的**: 未完了 work item の id + status を一覧提示する（停止メッセージ用）
- **方針**: `.aidlc/cycles/<cycle>/work-items/*.md` を列挙し、各ファイルの status を既存 `scripts/work-item-status.sh --read <path>` で読み取って集計する。`done`/`withdrawn` 以外を未完了として抽出する。release.md 本体で grep/sed/awk による frontmatter 生パースをしない（`lib/frontmatter.sh` 直叩き・parser 重複も避ける / develop.md Step 1 と同じ安全境界）
- **責務分界**: `work-item-validate.sh`=schema 健全性 / `work-item-status.sh --read`=status 読取 / 手順側=集計のみ（設計レビュー R1 #2/#3）
- **Bash ツール安全規約**: 手順内コマンド例に `$(...)` / backtick を使わない（リポジトリ規約）

## スクリプトインターフェース設計

本 Unit では**新規スクリプトを作成しない**（Unit 境界 / read-only / テスト追加は Unit 004）。`steps/release.md` は既存スクリプト（`state-read.sh` / `work-item-validate.sh` / `work-item-status.sh --read`）の read-only 呼び出しと手順側の status 集計のみで Step 1 を構成する。

## データモデル概要

本 Unit はデータモデルを変更しない（read-only）。参照のみ:

- state.json schema（`release.pr_number` / `release.ready` / `release.merge_approved`）は Step 2–4 で使用（後続 Unit）。Step 1 は `current_cycle` / `define_completed` のみ read
- 完了判定の正本: `docs/v3/data-model.md §5.1` 評価順（`done`/`withdrawn` = 完了扱い）

## 処理フロー概要

### リリース準備（Step 1）の処理フロー

**ステップ**:
1. Step 0 で `<cycle>` を解決済み（未解決なら Step 1 に入らない）
2. state 前提確認（`define_completed=true` か）→ 不成立なら define/develop 案内で停止（exit 2 は system error 停止）
3. work item schema preflight（`work-item-validate.sh`）→ exit 1 は validation 停止 / exit 2 は system error 停止
4. 全 work item の status を `work-item-status.sh --read` で集計 → 未完了あれば一覧提示で停止
5. `git status --porcelain`（事前）→ dirty なら停止
6. test 実行（プロジェクトのテスト入口）→ non-zero なら停止
7. `git status --porcelain`（test 後再評価）→ test 生成物等で dirty なら停止（gitignore 解消を案内）
8. CI conclusion 参照（`gh` 利用可時）→ failure なら停止 / pending・未実行・取得不能なら警告継続
9. すべて充足 → Step 2（PR 整備 / 後続 Unit）へ案内

**関与するコンポーネント**: ReleaseReadinessGate / GateDecisionService / 既存 state-read.sh / work-item-validate.sh / work-item-status.sh --read

## 非機能要件（NFR）への対応

### 互換性
- **要件**: 既存 v3 テストを壊さない / state.json 非書込（read-only）
- **対応策**: 新規スクリプト・state schema 変更なし。release.md 追加は既存スクリプト挙動を変えない。完了後に既存 `scripts/tests/test-*.sh` 群を実行し回帰 sanity 確認（新規テスト追加は Unit 004）

### 保守性
- **要件**: SoT を再定義しない
- **対応策**: フェーズ導出・state schema・review perspective は `docs/v3/*` を参照。release.md には判定セマンティクスのみ置き、導出規則本体は持たせない

### クロスプラットフォーム
- **要件**: コマンド例は macOS / Linux 両対応
- **対応策**: `git status --porcelain` / `gh` / POSIX 互換の手順記述。BSD/GNU 差のあるオプションを避ける

### 可用性
- **要件**: CI 未設定・`gh` 不在環境でも release を不当にブロックしない
- **対応策**: CI の pending・未実行・取得不能・`gh` 不在は warn_continue（停止しない）。test fail / CI failure のみ stop

## 技術選定

- **言語**: Markdown（手順）+ 既存 bash スクリプト（read-only 呼び出し）
- **依存ツール**: git / `gh`（CI 確認 / 任意）/ jq（既存 state-read.sh 内部）
- **新規ライブラリ**: なし

## 実装上の注意事項

- **ドッグフーディング特殊処理の禁止**: 「自リポジトリが starter kit 自身か consumer か」の判定を release.md 本体に埋め込まない。test 入口は「プロジェクトで定義されたテスト」と汎用表現する
- **Step 2–4 はプレースホルダ**: 実行されないよう「（Unit NNN で実装）」を明示し、本文を最小化する
- **review-flow / commit 規約の二重定義回避**: Step 2 以降の review ルーティングは `workflow.md §6` / 既存 review-routing.md を参照（本 Unit では骨格のみ）
- **Bash ツール安全規約**: 手順内コマンド例に `$(...)` / backtick を含めない

## 不明点と質問（設計中に記録）

[Question] Step 0 の clean-worktree 確認と Step 1-3 の dirty 確認が重複しないか。
[Answer] 両建てする。Step 0 は「フロー前提」、Step 1-3 は workflow §3.3 が Step 1 の明示要件として「git status 確認」を挙げているため再掲。Step 1-3 は Step 0 を通過済みでも再評価する（release 準備中の差分検出）。

[Question] test/CI 確認の対象は v3 フレームワークのテストか、リリース対象プロジェクトのテストか。
[Answer] リリース対象プロジェクトのテスト/CI。release.md は consumer 向け手順のため汎用表現する。Unit 001 自身の回帰 sanity に使う `scripts/tests/` とは別レイヤ。

[Question] read-only と test 実行（worktree を汚し得る）の整合は。
[Answer] `read-only` は「aidlc state.json / frontmatter / journal / commit を変更しない」意味に限定。test 実行は worktree を汚し得るため、test 後に `git status --porcelain` を再評価し dirty なら stop（判定セマンティクス順 5 / 処理フロー 7）。設計レビュー R1 #1 反映。

[Question] 未完了 work item の status 読取を安全に行う方法は。
[Answer] 既存 `work-item-status.sh --read <path>`（develop.md Step 1 と同じ安全境界）で各 item を読み、手順側で集計。schema 健全性は `work-item-validate.sh`（順 2a）で preflight し exit 0/1/2 を区別。release.md 本体で frontmatter を生パースしない。設計レビュー R1 #2/#3 反映。
