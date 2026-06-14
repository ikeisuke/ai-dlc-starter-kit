# 論理設計: Unit 001 v3 define フロー実行実装

## 概要

v3 `define` フローを「読める手順」から「実行可能な手順」へ具体化するためのコンポーネント構成・インターフェース・処理フローを定義する。成果物は (1) 実行手順化した `steps/define.md`、(2) 新規 `scripts/state-init.sh`（初期 state.json の atomic 生成）、(3) 新規 `scripts/work-item-validate.sh`（work item §4 検証ゲート実体）、(4) サンドボックス検証ハーネスの 4 つ。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコード（シェルスクリプト本体・JSON・手順本文）は Phase 2（コード生成）で作成する。

## 事前コード読込み

ドメインモデル（`unit_001_v3_define_flow_domain_model.md`）の「事前コード読込み」セクション (a)(b)(c) を参照（重複記載しない）。要点: `state-write.sh` は更新専用（初期生成 defer）/ atomic は temp→validate→mv / `.aidlc/state.json` はリポジトリ直下 / work item frontmatter 正本は data-model §4。

## アーキテクチャパターン

- **手順書 + 安全境界スクリプト分離パターン**（v3 共通 / RFC P4）: フロー制御・対話・成果物生成は AI エージェント駆動の Markdown 手順（`steps/define.md`）が担い、atomic 性・検証が必要な state.json 操作のみを安全境界スクリプト（`scripts/state-*.sh`）に隔離する。
- **既存スクリプト再利用 + 最小新規追加**: 初期生成という既存スクリプトで満たせない 1 点のみ `state-init.sh` を新設し、`state-validate.sh`（検証）/ `state-write.sh`（field 更新）は再利用する。

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-v3/
├── steps/
│   └── define.md                     (実行手順化: Step 1〜4 / 本 Unit で改訂)
├── scripts/
│   ├── state-init.sh                 (新規: 初期 state.json の atomic 生成)
│   ├── work-item-validate.sh         (新規: work item §4 検証ゲート実体 / Step 4-2)
│   ├── state-write.sh                (再利用: define_completed=true)
│   ├── state-validate.sh             (再利用: 初期生成後の検証)
│   ├── state-read.sh                 (再利用: 検証・status 用)
│   └── tests/
│       ├── test-state-scripts.sh     (再利用 / state-init テスト追加先 or 隣接)
│       └── test-define-flow.sh       (新規: define Step 4 サンドボックス e2e)
└── templates/
    ├── intent.md / work-item.md / journal.md  (再利用: プレースホルダ展開元)
```

### コンポーネント詳細

#### define.md（実行手順 / 改訂）

- **責務**: define Step 1〜4 を「AI が実際に何を実行するか」のレベルで記述。環境チェック・Intent 定義 + 承認ゲート・Work Item 分割 + 承認ゲート・初期化（cycle dir / 成果物 / state-init / state-write / journal / branch / commit）の具体手順とコマンド・順序・スクリプト呼び出しを規定。
- **依存**: state-init.sh / state-write.sh / templates / git。
- **公開インターフェース**: `/aidlc-v3 define` 起動時に AI が読み込み実行する手順。

#### state-init.sh（新規）

- **責務**: 初期 `state.json` skeleton を atomic に create-only 生成。schema_version=`"3.0"` 固定・current_cycle 確定・define_completed=false・release 初期値・updated_at を書く。
- **依存**: jq / state-validate.sh（確定前検証）。
- **公開インターフェース**: 下記「スクリプトインターフェース設計」参照。

#### work-item-validate.sh（新規）

- **責務**: 指定ディレクトリ内の全 work item（`*.md`）が `docs/v3/data-model.md` §4 schema に準拠するかを検証する読み取り専用スクリプト。define Step 4-2 の検証ゲート実体。`state-validate.sh` が state.json を検証するのと対称な work item frontmatter / 本文の schema validator であり、後続フェーズ（develop / doctor）からも再利用可能。
- **依存**: なし（bash 組み込み + awk / sed / grep のみ / jq 非依存）。
- **公開インターフェース**: `work-item-validate.sh <work-items-dir> [expected_status]`。成功時 stdout `status:valid` / 終了コード 0。違反・0 件・ディレクトリ不在は exit 1、読み取り不可は exit 2。`expected_status` 指定時は全 work item の `status` がその値であることを追加検証（define は `pending` を渡す）。

#### test-define-flow.sh（新規）

- **責務**: define Step 4 の決定的（非対話）部分を隔離サンドボックスで実行し、成果物生成・state 整合・git 状態をアサート。
- **依存**: state-init.sh / state-validate.sh / state-read.sh / git / jq。
- **主要アサート**:
  - 正常系: cycle dir / intent.md / work-items/*.md / journal.md 生成、state.json valid かつ `define_completed=true`、cycle ブランチ + 初回 commit 存在、work item frontmatter が data-model §4 準拠（status=pending 等）。
  - state-init.sh 単体: `status:initialized` + skeleton 値、current_cycle 健全性違反（空 / `/` 含み / 制御文字）は exit 1、create-only（既存 file あり → exit 1）。
  - **race 代替（指摘 #1）**: validate 後に target を先行作成した状態で配置すると、既存 target が保持され exit 1（`ln` create-only の確定）。
  - **同一値整合（指摘 #2）**: cycle ディレクトリ名・`state.current_cycle`・cycle ブランチ suffix が同一値。
  - **work item 検証ゲート（指摘 #3）**: 不正 frontmatter（必須キー欠落 / enum 逸脱 / 必須セクション欠落 / 存在しない dependency ID）のフィクスチャでは `define_completed` が false のまま（state-write を呼ばない）。
  - 終了コード規約 0/1/2 の網羅。

## インターフェース設計

### コマンド（define.md Step 4 が呼び出す操作）

#### `state-init.sh <current_cycle> [file]`

- **パラメータ**: `current_cycle`（必須 / cycle 識別子）/ `file`（任意 / 省略時 `.aidlc/state.json`）
- **戻り値**: stdout に `status:initialized`（成功時）/ 終了コード 0
- **副作用**: 初期 state.json を atomic 生成（create-only）

#### `state-write.sh define_completed true [file]`（既存・再利用）

- **副作用**: define_completed を true に更新 + updated_at 自動更新

## スクリプトインターフェース設計

### state-init.sh

#### 概要

v3 cycle の初期 `state.json` skeleton を atomic（temp→validate→`ln` create-only）に生成する（`mv` は使わない / state-write の atomic-replace と分岐）。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<current_cycle>` | 必須 | 対象サイクル識別子（例 `v3.0.0` / `v3.0.0-alpha.3`）。state.json の `current_cycle` に書く。**入力健全性ガード**: 非空かつ `/`（path separator）・空白・制御文字を含まないこと（cycle ディレクトリ名・ブランチ suffix の同一キーになるため / domain model 集約不変条件）。許容文字集合は `^[A-Za-z0-9][A-Za-z0-9._-]*$`。違反は exit 1。**`vX.Y.Z` 厳密形式の検証は本 Unit では行わない**（consumer の任意識別子余地を残す / 厳密 regex は defer。`schema_version` 値検証を Unit 004 へ defer する設計姿勢と整合） |
| `[file]` | 任意 | 生成先パス（省略時 `.aidlc/state.json`） |

#### 環境変数

| 変数 | 説明 |
|------|------|
| `AIDLC_STATE_NOW` | `updated_at` に使う ISO 8601 文字列（テスト用 / 既存 state-write.sh と同規約）。未設定時は現在 UTC |

#### 生成する skeleton（確定値）

```text
schema_version  = "3.0"        (固定)
current_cycle   = <引数>
define_completed = false       (固定 / true 化は state-write.sh の責務)
release.pr_number = null
release.ready     = false
release.merge_approved = false
updated_at      = AIDLC_STATE_NOW または現在 UTC
```

#### 成功時出力

```text
status:initialized
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
error: <理由>     (stderr)
```

- 終了コード（AI-DLC 終了コード規約準拠 / 既存 state-*.sh と一致）:
  - `1` = バリデーションエラー: 引数不足 / **current_cycle 入力健全性違反**（空 / `/`・空白・制御文字を含む / 許容文字集合外） / **対象ファイルが既に存在（create-only 違反 = atomic create 失敗）** / 生成後 state が invalid（state-validate 失敗）
  - `2` = システムエラー: jq 未導入 / 依存 state-validate.sh 不在・実行不可 / mktemp 失敗 / temp 削除以外の予期せぬ失敗
- 出力先: stderr

#### 処理順序（atomic create-only / state-write.sh の atomic-replace と原子化プリミティブが分岐）

1. jq 存在確認（無→exit 2）
2. 依存 state-validate.sh の存在・実行可能確認（無→exit 2）
3. 引数 current_cycle 必須確認（無→exit 1）
4. **current_cycle 入力健全性ガード**: 非空 + 許容文字集合 `^[A-Za-z0-9][A-Za-z0-9._-]*$`（`/`・空白・制御文字を拒否）。違反→exit 1
5. **対象 file が既存なら exit 1**（create-only の早期フレンドリーエラー。確定ガードは手順 9 の atomic create）
6. `updated_at` 確定（`AIDLC_STATE_NOW` または現在 UTC）
7. 対象ディレクトリに `mktemp` で temp 生成（失敗→exit 2）+ trap で cleanup
8. jq で canonical skeleton を temp に書き出し
9. `state-validate.sh <temp>` で検証（invalid→exit 1 / system→exit 2）
10. **atomic create-only 配置**: `ln <temp> <file>`（ハードリンク / **target が既存なら失敗** → exit 1）。`mv` を使わない（`mv` は無条件上書きで TOCTOU 窓が残るため、create-only の確定操作には不適）。成功後に temp を rm + trap 解除。`ln`/`mktemp`（同一ディレクトリ temp）は macOS BSD / Linux GNU 両対応・同一ファイルシステム制約は temp を target と同一 dir に置く前提で充足
11. `status:initialized` 出力 / exit 0

> **init と write の原子化プリミティブの違い**: `state-init.sh` は **create-only**（既存を上書きしない）なので `ln`（target 存在で失敗）で確定する。一方 `state-write.sh` は既存 state の **atomic-replace**（上書き必須）なので `mv` で確定する。両者は目的が異なるため確定操作が分岐する。

#### 使用コマンド

```bash
# 既定パス（.aidlc/state.json）に生成
state-init.sh v3.0.0

# 明示パス
state-init.sh v3.0.0 /path/to/state.json
```

## データモデル概要

### ファイル形式: state.json

- **形式**: JSON（data-model §3 schema 準拠）
- **主要フィールド**: §3.2 のとおり（schema_version / current_cycle / define_completed / release{pr_number,ready,merge_approved} / updated_at）
- **配置**: リポジトリ直下 `.aidlc/state.json`（cycle dir 外）

### ファイル形式: work-items/{id}-{slug}.md

- **形式**: YAML frontmatter + Markdown 本文（data-model §4）
- **frontmatter 初期値**: `status: pending` / size・risk は分割時に確定 / `dependencies` は実在 ID のみ
- **本文必須 6 セクション**: Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies

## 処理フロー概要

### define フロー（Step 1〜4）の処理フロー

**Step 1: 環境チェック**

1. `.aidlc/config.toml` 存在確認
2. git ワーキングツリー clean 確認
3. 前 cycle の `journal.md` / `reflect.md` があれば読み込み define 入力とする

**Step 2: Intent 定義 ★ 承認ゲート**

1. 目的を 1 文で確認（AI 提案 → 人間承認）
2. スコープ（含む / 含まない）+ 受け入れ基準を整理
3. `templates/intent.md` を基に `intent.md` を作成
4. ★ 人間承認まで Step 3 に進まない

**Step 3: Work Item 分割 ★ 承認ゲート**

1. Intent を work item に分割（AI 提案 → 人間承認）
2. 各 item に size / risk 付与、dependencies 整理（実在 ID のみ）
3. `templates/work-item.md` を基に `work-items/{id}-{slug}.md` を作成（status 初期値 `pending`）
4. ★ 人間承認まで Step 4 に進まない

**Step 4: 初期化（決定的 / 検証対象 / ゲート先行 fail-fast）**

処理順序は**検証ゲートを先行**させ、ゲート通過時のみ state / branch を変更する（fail-fast）。
ゲート失敗時に `state.json` 生成・cycle ブランチ作成・commit のいずれの副作用も発生させないことで、
「`define_completed=true` 時に全 work item が §4 準拠」というドメイン集約不変条件を担保する。

1. **4-1 成果物配置**: cycle ディレクトリ作成（`mkdir -p cycles/{cycle}/work-items` / フラット構造）、承認済み intent / work items を成果物として配置（Step 2/3 で作成済みなら確定配置）、`templates/journal.md` を基に `journal.md` 作成 + define 完了を追記（`## YYYY-MM-DD` 配下に `define completed: intent and N work items created`）
2. **4-2 work item 完了前検証ゲート（決定的 / define 完了の前提条件 / 先行実行）**: **`work-item-validate.sh <work-items-dir> pending`** で全 `work-items/*.md` が data-model §4 準拠であることを検証する（exit 0 = `status:valid` / 違反・0 件・ディレクトリ不在 = exit 1 / 読み取り不可等 = exit 2）。検証項目: (i) frontmatter 必須 6 キー（`id`/`status`/`size`/`risk`/`assigned`/`dependencies`）が存在、(ii) enum 値域に従う（`status`/`size`/`risk`）、(iii) `status` 初期値が `pending`（`expected_status pending` 指定）、(iv) 型制約（`assigned` は string or null / `dependencies` は array `[...]` 形式）、(v) `id` とファイル名が整合、(vi) 本文に必須 6 セクション（Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies）が存在、(vii) `dependencies` が**実在する work item ID のみ**を参照（存在しない ID 参照は data-model §6 trace 整合エラー）。**exit 0 以外（失敗）時は手順 3 以降（state-init / state-write / branch / commit）を一切実行せず define を未完了に留める**（`state.json` は生成されない = `define_completed` は観念上 false のまま）。検証ロジックは安全境界スクリプト `work-item-validate.sh` に隔離し（`state-validate.sh` が state.json を検証するのと対称）、`test-define-flow.sh` がその全項目をアサートする（Unit 002 `work-item-next.sh`〔選定時の読み取り〕とは別レイヤ = 生成時の妥当性検証であり責務非重複）
3. **4-3 `state-init.sh <cycle>`** で `.aidlc/state.json` を生成（define_completed=false / create-only）。**手順 2 を全 work item が通過した場合のみ実行**
4. **4-4 `state-write.sh define_completed true`** で define 完了マーク（single-actor moment）
5. **4-5 branch + commit**: cycle ブランチ作成（`git checkout -b cycle/{cycle}` 相当 / 既に対象ブランチ上なら skip）→ `git add -A` + 初回 commit。`early_pr: true` の場合のみ Draft PR 作成（通常パスは作らない / 詳細 defer）

> **処理順序の根拠（ゲート先行 fail-fast）**: 検証ゲート（手順 2）を `state-init`（手順 3）より前に置くことで、不正な work item がある状態では `state.json` 自体が生成されず（`ln` による create-only 確定もされず）、cycle ブランチ・commit も発生しない。これにより「state が initialize された ⇔ 全 work item が §4 準拠」が常に成立し、中途半端な初期化状態を排除する。

**関与するコンポーネント**: define.md（制御）/ work-item-validate.sh（work item 検証ゲート実体）/ state-init.sh / state-write.sh / state-validate.sh / templates / git

### state.json 初期化の処理フロー（state-init.sh）

スクリプトインターフェース設計「処理順序」を正本とする（重複記載しない）。要点: temp→validate→`ln`（create-only）の atomic 経路で final path へ直接 Write しない。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 1 cycle 作成は数秒以内（Unit NFR）
- **対応策**: state-init.sh は jq 1 回 + validate 1 回の軽量処理。成果物生成は単純ファイル I/O。

### セキュリティ

- **要件**: state.json 書き込みは atomic / 直接編集禁止（Unit NFR）
- **対応策**: state-init.sh は temp→validate→`ln`（create-only）、state-write.sh は temp→validate→`mv`（atomic-replace）。いずれも final path への直接 Write を行わない。create-only ガード（`ln` が target 存在で失敗）で既存 state 誤上書きを防止。

### スケーラビリティ / 可用性

- 該当なし（Unit NFR）。

## 技術選定

- **言語**: Bash（既存 state-*.sh と一致 / `#!/usr/bin/env bash` / `set -euo pipefail`）
- **ツール**: jq（既存と同一前提）/ git
- **手順記述**: Markdown（`steps/define.md`）
- **テスト**: 自己完結ハーネス（外部フレームワーク非依存 / `mktemp -d` + trap / `assert_rc`・`assert_out` 方式の踏襲）

## 実装上の注意事項

- **v2 非影響**: 変更は `skills/aidlc-v3/` 配下のみ。`skills/aidlc/`（v2）に一切触れない（`git diff` で確認）。
- **サンドボックス隔離**: テストは `mktemp -d` 内に隔離 git リポジトリ + `.aidlc/` を構築し、リポジトリ実体の v2 `.aidlc/`（`config.toml` / `cycles/`）を一切変更しない。`AIDLC_STATE_NOW` で時刻を固定し決定的にする。
- **終了コード規約一貫性**: state-init.sh は既存 state-*.sh と同じ 0/1/2 規約。読み取り不可・jq 不在等のシステムエラーを exit 1 に漏らさない（`*)` フォールバック）。
- **bash-tool 安全規約**: スクリプト・手順・テストの記述で、AI エージェントが Bash ツール経由で実行する経路にコマンド置換（`$(...)` / backtick）を埋めない（リポジトリ規約 / #697）。スクリプト内部の `$(...)` はスクリプト自身の実行であり対象外だが、define.md の手順例示では安全パターンを優先する。
- **shellcheck / bash -n / markdownlint** を全成果物で通す。

## 不明点と質問（設計中に記録）

[Question] cycle ブランチ作成手順は、ドッグフーディング（既に v2 cycle ブランチ上にいる）と consumer 新規 cycle の両方をどう扱うか。
[Answer] define.md は consumer の通常フロー（`cycle/{cycle}` を新規作成）を正本手順として記述する。ドッグフーディング特殊処理を define.md 本体に埋めない（リポジトリ規約「ドッグフーディング特殊処理を本体に埋めない」）。サンドボックステストは隔離リポジトリで通常フローを検証する。

[Question] test-define-flow.sh は AI 駆動の Step 2/3（対話）も検証するか。
[Answer] しない。Step 2/3 は AI 提案 + 人間承認の対話ゲートで非決定的。テストは Step 4 の決定的部分（フィクスチャの intent / work items を入力とした成果物生成・state-init・state-write・branch・commit・検証）に絞る（計画 D5 / R2）。対話部分は手順記述の妥当性を設計・統合レビューで担保する。
