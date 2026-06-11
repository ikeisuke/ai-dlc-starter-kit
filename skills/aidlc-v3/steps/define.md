# define フロー（手順）

> **位置づけ（v3.0.0-alpha.2 / Phase 2 skeleton）**: 本ファイルは define フローの
> **読める手順**である。フロー実行実装（実際のファイル生成・git 操作・state.json 書き込み）
> は Phase 3 以降で実装する。本ファイルは「AI エージェントが各 Step で何をするか」を
> 把握できる粒度で記述する。

## 目的

作るもの・作らないもの・完了条件・作業単位（work item）を決める（旧 Inception）。

## フロー全体

define は 4 Step で構成される。承認ゲート（★）は Step 2（Intent 承認）と
Step 3（Work Item 承認）にある。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 環境チェック | 前提確認 | - |
| 2 Intent 定義 | 目的・スコープ・完了条件 | ★ Intent 承認 / `intent.md` |
| 3 Work Item 分割 | 作業単位への分割 | ★ Work Item 承認 / `work-items/*.md` |
| 4 初期化 | state / cycle / branch 初期化 | `state.json`・`journal.md`・branch |

## Step 1: 環境チェック

- `.aidlc/config.toml` の存在を確認する。
- git のワーキングツリーが clean かを確認する。
- 前サイクルの `journal.md` / `reflect.md` が存在すれば読み込み、define の入力とする。

## Step 2: Intent 定義 ★ Intent 承認

- 目的を **1 文**で確認する（AI が提案し、人間が承認する）。
- スコープを「含むもの」「含まないもの」で整理する。
- 受け入れ基準（acceptance criteria）を定義する。
- テンプレート `templates/intent.md` を基に `intent.md` を作成する。
- **★ 承認ゲート**: Intent を人間が承認するまで次 Step に進まない。

## Step 3: Work Item 分割 ★ Work Item 承認

- Intent を work item に分割する（AI が提案し、人間が承認する）。
- 各 work item に `size`（`tiny` / `normal` / `risky`）・`risk`（`low` / `medium` / `high`）
  を付与する。
- work item 間の依存（`dependencies`）を整理する。
- テンプレート `templates/work-item.md` を基に `work-items/*.md` を作成する。
- **★ 承認ゲート**: Work Item 分割を人間が承認するまで次 Step に進まない。

## Step 4: 初期化

- `state.json` を初期化する。**必須フィールド**:
  - `schema_version`（初版 `"3.0"`）
  - `current_cycle`（対象サイクル識別子）
  - `define_completed`（**Step 4 完了時に `true` を書き込む**）
  - `release`（`pr_number`: integer or null / `ready`: boolean / `merge_approved`: boolean）
  - `updated_at`（ISO 8601）
- cycle ディレクトリを作成する。
- テンプレート `templates/journal.md` を基に `journal.md` を作成し、define 完了を追記する。
- git branch を作成し、初回 commit を行う。
- `early_pr: true` の場合のみ Draft PR を作成する（**通常時は PR を作らず**、PR 整備は
  release フェーズで行う）。

> **state.json 書き込み・検証の参照**: 状態書き込みは `scripts/state-write.sh`、schema
> 検証は `scripts/state-validate.sh` を用いる（実行実装は Phase 3。本 skeleton は参照に留める）。
> `define_completed` の書き込みタイミングは **Step 4 完了時**（single-actor moment）。

## 完了後のフェーズ導出

`define_completed: true` 書き込み後、フェーズは `state.json` + work item frontmatter から
自動導出される（`current_phase` は保持しない）。導出規則の正本は `docs/v3/data-model.md` §5。
define 完了後に未完了 work item があれば `develop` へ、という導出結果に従う。
