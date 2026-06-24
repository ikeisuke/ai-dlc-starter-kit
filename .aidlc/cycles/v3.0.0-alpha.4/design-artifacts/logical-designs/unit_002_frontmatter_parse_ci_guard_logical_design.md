# 論理設計: Unit 002 — 禁止パースパターンの CI 機械検出（T4）

## 概要

frontmatter 構造解釈の禁止パターンを CI で機械検出する検出スクリプト・テスト・CI step の論理設計。既存 `bin/check-*.sh` 様式を踏襲し、トークンベース検出 + 限定 allow マーカー（候補 C）で false positive / false negative を両立回避する。

**重要**: 本設計では**コードは書かず**、コンポーネント構成・インターフェース・検出アルゴリズム・テストマトリクスのみを定義する。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み

ドメインモデル §ステップ0 (a)(b)(c) を SoT とする（重複記載しない）。確定事実: consumer は全移行済み（違反 0）/ 最重要分岐点は C2（status.sh atomic write awk）の誤検出回避 / 検出アルゴリズムは候補 C 採用。

## アーキテクチャパターン

**パイプライン + ルールエンジン**（既存 `bin/check-*.sh` 流用 / refactor 方針）:

```text
ファイル走査（find） → 論理コマンド単位構築（build_logical_units: 継続行連結） → 文脈判定（トークン照合 + 除外コンテキスト判定〔データ文字列のみ除外 / grep・sed・awk regex 引数は検出対象〕 + allow マーカー） → 違反収集 → 終了コード決定
```

選定理由: 既存 3 つの check スクリプト（`check-skill-references` / `check-bash-substitution` / `check-test-isolation`）と同一様式に揃えることで、CI 統合・保守・レビューの一貫性を確保する。新規アーキテクチャを導入しない（過剰設計回避）。

## コンポーネント構成

### モジュール構成

```text
bin/check-frontmatter-parse-guard.sh   （検出スクリプト本体）
├── usage/引数処理         （-h/--help, -v/--verbose, [target_dir]）
├── resolve_repo_root      （git rev-parse --show-toplevel / cwd 非依存）
├── collect_scan_targets   （find -print0 で対象 *.sh を列挙、lib//tests/ 除外、自スクリプト除外）
├── build_logical_units    （物理行を論理コマンド単位に連結: backslash 継続 / pipe 継続 / $(...) 複数行 / awk プログラム）
├── scan_file              （論理コマンド単位ごとに detect_violation を適用、違反行番号は unit 先頭行を採用）
├── detect_violation       （ForbiddenPattern × FrontmatterContext 照合）
├── is_excluded_context    （除外対象は実行されないデータ文字列のみ: フルラインコメント / heredoc / echo・printf 出力文字列。grep・sed・awk の regex 引数は除外せず検出対象。allow マーカー判定も担う）
└── resolve_exit_code      （違反件数 → 0/1/2）

bin/tests/check-frontmatter-parse-guard.sh   （自己完結型 bash テスト）
└── mktemp サンドボックス + assert ヘルパ + 合格/違反 fixture マトリクス

.github/workflows/skill-reference-check.yml  （既存単一ジョブへ step 追加）
└── "Check frontmatter parse guard" step（既存 Detect skip / checkout / permissions 共有）
```

### コンポーネント詳細

#### check-frontmatter-parse-guard.sh（検出スクリプト本体）

- **責務**: 走査対象スクリプトを論理コマンド単位（build_logical_units で継続行連結）でスキャンし、frontmatter 構造解釈の禁止パターンを検出して違反報告 + 終了コードを返す
- **依存**: bash 3.2+、`grep`/`sed`/`awk`（検出ロジック実装。**本体スクリプト自身が grep/sed/awk を使うのは正当 — 検出対象は v3 consumer であり本 check スクリプト自身ではない**）、`git`（ルート解決）、`find`
- **公開インターフェース**: CLI（後述「スクリプトインターフェース設計」）
- **配置理由**: `bin/`（リポジトリレベル check ツール群）。`skills/aidlc-v3/scripts/` を走査対象とするが、ツール本体は consumer プロジェクトに配布されない `bin/` に置くため、**走査対象 `skills/aidlc-v3/scripts/` が存在しない環境では自然に違反 0 = exit 0**（opt-in シグナル / ドッグフーディング特殊分岐を埋めない）

#### bin/tests/check-frontmatter-parse-guard.sh（テスト）

- **責務**: 検出スクリプトの合格/違反/システムエラー挙動を自己完結型 bash ハーネスで検証
- **依存**: bash、検出スクリプト本体、`mktemp`
- **配置理由**: 既存 `bin/tests/` 配下に check テストを置く前例（`bin/tests/check-test-isolation/`）に準拠

#### skill-reference-check.yml への step 追加（R1#3）

- **責務**: PR で検出スクリプトを実行し違反を fail させる
- **方式**: **既存単一ジョブ `skill-reference-check` 内に step を 1 つ追加**（別ジョブ化しない）。既存 `Detect skip` / `Checkout` / `permissions` をそのまま共有
- **依存**: 既存ジョブ構造

## インターフェース設計

### スクリプトインターフェース設計

#### check-frontmatter-parse-guard.sh

##### 概要

`skills/aidlc-v3/scripts/`（`lib/` `tests/` 除く）の個別 consumer スクリプトに frontmatter 構造解釈の禁止パターンが混入していないか機械検出する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `[target_dir]` | 任意 | 走査ルート（デフォルト: `skills/aidlc-v3/scripts`）。テストで一時ディレクトリを指定するため |
| `-v`, `--verbose` | 任意 | 走査ファイル数・詳細出力 |
| `-h`, `--help` | 任意 | usage 表示（exit 0） |

##### 成功時出力

```text
（違反なし時は無出力、または --verbose 時にサマリ）
Scanned N file(s) in skills/aidlc-v3/scripts. No forbidden frontmatter parse patterns found.
```

- 終了コード: `0`
- 出力先: stdout（サマリ）

##### エラー時出力（違反検出）

```text
<file>:<line>: forbidden frontmatter parse pattern (<command>): use shared parser (fm_* in lib/frontmatter.sh) instead. matched: <token>
...
N violation(s) found in M file(s).
```

- 終了コード: `1`（違反検出）
- 出力先: stderr（違反行）+ stdout/stderr（サマリ）

##### システムエラー出力

```text
error: <reason>（例: not a git repository / find failed）
```

- 終了コード: `2`（システムエラー）
- 出力先: stderr

##### 終了コード規約（`guides/exit-code-convention.md` / 既存 check 整合）

| exit | 意味 |
|------|------|
| 0 | 違反なし（走査対象不在の opt-in skip を含む） |
| 1 | 違反検出（+ 違反箇所報告） |
| 2 | システムエラー（git repo 外 / find 失敗 / 必須コマンド不在 等） |

##### 使用コマンド

```bash
# 通常実行（リポジトリルートから）
bash bin/check-frontmatter-parse-guard.sh

# テスト用に走査ルートを指定
bash bin/check-frontmatter-parse-guard.sh /tmp/sandbox/scripts

# 詳細表示
bash bin/check-frontmatter-parse-guard.sh --verbose
```

## 検出アルゴリズム（本 Unit の核 / 候補 C）

### 走査対象の決定（AllowlistResolver）

1. `target_dir`（デフォルト `skills/aidlc-v3/scripts`）が存在しなければ **違反 0 件で exit 0**（opt-in skip / `--verbose` 時のみ info 出力）。
2. `find "$target_dir" -type f -name '*.sh' -print0` で列挙。
3. 除外: パスに `/lib/` または `/tests/` を含むもの、本 check スクリプト自身、テストスクリプト自身。

### 違反判定（ViolationDetector）

各 **論理コマンド単位**（§コンポーネント `scan_file` が物理行を連結して構築 / 後述「複数行・継続行の扱い」）に対し:

1. **除外コンテキスト判定（`is_excluded_context` / R-design#1 反映）**: 除外するのは **「実行されないデータ文字列」のみ** に限定する。具体的には:
   - 行頭 `#` のコメント行（フルラインコメント）
   - heredoc / fixture データブロック内のテキスト（`<<EOF` 〜 `EOF` 等）
   - `echo` / `printf` の **出力データ文字列**（実行されないログ/メッセージ文字列）
   - **重要**: `grep` / `sed` / `awk` の **正規表現引数（クォート内を含む）は除外しない = 検出対象**。frontmatter トークン（`^status:` 等）は通常 `grep '^status:'` のようにクォートされた regex 引数内に現れるため、「クォート内一律除外」にすると違反①②④を取りこぼす。`is_excluded_context` は「コマンドの regex 引数」と「実行されないデータ文字列」を区別する責務を持つ（前者は検出対象 / 後者のみ除外）。
2. **allow マーカー除外**: 同一行または直前行に `# parse-guard: allow=<理由> (issue: #NNN, ref: <根拠>)` があり、かつ対象が **非構造 write idiom** であれば除外（後述 §allow マーカー統制）。
3. **生コマンド + frontmatter トークン照合**:
   - 対象コマンド: `grep` / `sed` / `awk`（`jq` は別ルール）
   - **frontmatter フィールドトークン**（ERE）: `\^(status|id|dependencies|size|risk|assigned|complexity|title|created|updated)[A-Za-z0-9_]*:` を含む正規表現リテラル、**または** 汎用フィールドキー抽出 `\^\[?[A-Za-z_].*:` を frontmatter 抽出文脈で使用、**または** `---` delimiter ブロック抽出（`$0=="---"` / `^---$` を NR/ブロック制御と併用して frontmatter ブロックを切り出す idiom）
   - これらを生コマンドで参照していれば違反
4. **permissive jq（frontmatter 文脈限定）**: `jq` が **frontmatter テキストを入力**（`<<< "$fm"` / `<<< "$block"` / frontmatter 変数のヒアストリング / `.md` ファイルを直接 jq）とし、かつ permissive coerce（`//`（既定値）/ `?`（型エラー抑制））を含む場合のみ違反。**`.json` ファイル / state 変数を入力とする jq は対象外**（B カテゴリ = state-*.sh の正当用途）。

### 複数行・継続行の扱い（`build_logical_units` / R-design#2 反映）

物理行単位の評価では「コマンド行に token が無く、token 行に command が無い」分割ケース（例: `sed -nE \` の次行に `'s/^dependencies:...//'`）で検出根拠が成立しない。よって `scan_file` は **物理行ではなく論理コマンド単位**で `detect_violation` に渡す。論理コマンド単位の構築規則:

- **backslash 行継続**: 行末 `\` は次行と連結
- **pipe 継続**: 行末 `|` は次行と連結（パイプライン全体を 1 単位）
- **`$(...)` / `<<<` 複数行**: コマンド置換・ヒアストリングが複数行にまたがる場合は閉じるまで連結
- **awk プログラム**: `awk '` から閉じ `'` までの複数行プログラムを 1 単位に連結

連結後の論理単位に対しコマンド（grep/sed/awk/jq）と frontmatter トークンの共起を判定する。違反行番号は論理単位の先頭物理行を採用。

> 本規則により T-09（変数経由 READ）/ T-10（複数行パイプ・関数経由）/ ⑤ を確実に検出する（R2: 違反は全て RC=違反 必須）。T-10 は `sed -nE \`（行末 backslash）→ 次行 `'s/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p' "$f"` の具体 fixture、および `grep '^id:' "$f" \|`（行末 pipe）→ 次行 `sed 's/^id://'` の具体 fixture を含める。

### トークンベースが正当パターンを除外する根拠（経験的検証）

| パターン | 検出されるか | 理由 |
|---------|------------|------|
| C1 `echo "$body" \| grep -Eq "^## ${sec}$"` | **されない** | トークンが `^##`（markdown 見出し）であり frontmatter フィールドキー（`^key:`）でも `---` でもない |
| C2 `awk ... /^status:/ {print "status: " newstatus} ... > "$tmp"` | **マーカーで除外** | `^status:` `---` を参照するが atomic write（Unit 001 carve-out）。allow マーカー付与で除外 |
| C3 `printf '%s' "$v" \| tr -d '[:cntrl:]'` | **されない** | `tr` は検出コマンド集合外、frontmatter トークンなし |
| B `jq -r '.schema_version' "$file"`（file=.json） | **されない** | 入力が `.json`、permissive coerce なし、frontmatter 文脈外 |
| ① `grep '^status:' "$file" \| sed 's/^status:...//'` | **される** | `^status:` を生 grep/sed で抽出 |
| ② `sed -nE 's/^dependencies:...\[([^]]*)\].*/\1/p' "$file"` | **される** | `^dependencies:` 配列の生パース |
| ③ `jq -r '.assigned // empty' <<< "$fm"` | **される** | frontmatter テキスト（`$fm`）への permissive jq |
| ④ `s="$(echo "$block" \| sed -n 's/^status:.*//p')"`（変数経由 READ） | **される** | 変数入力でも `^status:` 抽出トークンで検出（R1#1 / file-vs-variable に依存しない token 判定） |
| ⑤ 複数行パイプ / 関数内での同型 READ | **される** | `build_logical_units` が backslash/pipe 継続・`$(...)`・awk プログラムを論理コマンド単位に連結してから評価（§複数行・継続行の扱い）。R2: 全て RC=違反 必須 |

### allow マーカー統制（R1#2 + R-design#3 反映）

計画の完了条件「理由/Issue 必須 / 期限 or stale 検出」を、インライン方式で以下のとおり満たす（`check-test-isolation.allowlist` の 6 列ファイル機構は単一例外には過剰なため、同等統制をインライン + テストで担保する）:

- **付与可能対象**: 非構造 write idiom のみ（frontmatter の書き換え = atomic write）。**frontmatter 構造解釈の READ（スカラー抽出・配列パース）には付与不可**。READ idiom 行に marker があっても検出スクリプトは別途警告（marker 誤用検出 = T-11）。
- **必須要素（構文強制）**: `# parse-guard: allow=<理由> (issue: #NNN, ref: <根拠>)`。
  - `reason`（非空）/ `issue`（`#NNN` 形式の tracking reference・必須）/ `ref`（根拠参照）。いずれか欠落・空のマーカーは **無効 = 違反として扱う**（T-12 / 計画「Issue 必須」を構文レベルで強制）。
- **stale 検出（機械的）**: テスト（`bin/tests/check-frontmatter-parse-guard.sh`）で、許可 marker 付与行から **marker を除去した場合に当該行が違反として検出されること**を検証する。検出されない（= marker が対応する検出候補を失っている）場合はテストが fail = **stale marker** として弾く（`check-test-isolation` の「violation 再現しない stale 検出」に相当）。
- **既知集合の固定**: テストで「現行リポジトリで許可される marker の既知集合 = `work-item-status.sh` の atomic write awk の 1 件のみ」を固定アサート。新規 marker 追加時はテストが落ちる → レビューゲート通過を強制。
- **現行で許可される唯一の marker**: `work-item-status.sh:150` 付近の awk に
  `# parse-guard: allow=atomic frontmatter status write (not a parse/read) (issue: #733, ref: Unit 001 frontmatter.sh:20 atomic-write carve-out)`
  を付与（Phase 2 で 1 行追加。実行挙動は不変）。issue は v3.0.0 系 umbrella #733（T4 出典）を tracking reference とする。
- **計画との差分明記**: 計画の「期限（expiry）」は本設計では採用しない（単一インライン例外に日付管理は過剰 / stale 検出を「marker 除去で違反再現」の機械検証で代替）。Issue 必須・stale 検出は上記で充足する。

## データモデル概要

### 走査対象ファイル形式

- **形式**: bash スクリプト（`*.sh`）
- **主要フィールド**: 行番号付きテキスト行。frontmatter トークン照合の対象

### allow マーカー形式

- **形式**: bash コメント
- **構文**: `# parse-guard: allow=<理由文字列> (issue: #NNN, ref: <根拠>)`（reason / issue / ref すべて必須）

## 処理フロー概要

### 検出実行の処理フロー

1. 引数パース（`-h`→usage exit 0 / `-v` / `[target_dir]`）。
2. `git rev-parse --show-toplevel` でリポジトリルート解決（失敗 → exit 2）。
3. `target_dir` 不在 → 違反 0 で exit 0（opt-in skip）。
4. `find -print0` で対象 `*.sh` 列挙（`lib/` `tests/` / 自身を除外）。
5. 各ファイルを `build_logical_units` で論理コマンド単位に連結（backslash/pipe 継続・`$(...)`・awk プログラム）。
6. 各論理単位を評価: 除外コンテキスト判定（データ文字列のみ除外 / regex 引数は対象）/ allow マーカー除外 → ForbiddenPattern × FrontmatterContext 照合 → Violation 収集。
7. Violation を `<file>:<line>: <message>` で stderr 出力 + サマリ。
8. ExitCodeResolver: 違反 ≥1 → exit 1 / システムエラー → exit 2 / それ以外 → exit 0。

**関与コンポーネント**: collect_scan_targets / build_logical_units / scan_file / detect_violation / is_excluded_context / resolve_exit_code

### CI step 追加フロー

1. 既存 `skill-reference-check` ジョブの `Detect skip` step の `PATHS_REGEX` に以下を追加:
   - `bin/check-frontmatter-parse-guard\.sh`（本体）
   - `bin/tests/check-frontmatter-parse-guard\.sh`（テスト / **テスト変更のみの PR で skip されないため必須 / R1#3**）
   - （`skills/.+` は既存パターンに含まれるため v3 consumer 変更は既にカバー済み）
2. 既存 check step 群の末尾に step 追加:
   ```yaml
   - name: Check frontmatter parse guard (forbidden parse patterns in aidlc-v3 consumers)
     if: steps.detect.outputs.should_skip != 'true'
     run: bash bin/check-frontmatter-parse-guard.sh
   ```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: CI ジョブとして許容範囲（高速走査）
- **対応策**: `find -print0` + 論理コマンド単位スキャンのみ。対象は `skills/aidlc-v3/scripts/` 配下の数ファイル。外部プロセス起動は最小化

### セキュリティ
- **要件**: 特になし（Unit NFR）
- **対応策**: 走査のみ（読み取り専用）。検出スクリプトは対象ファイルを編集しない

### スケーラビリティ
- **要件**: 将来 consumer 追加時も自動的に走査対象に含まれる
- **対応策**: ディレクトリベース走査（`find`）。新 consumer は追加設定なしで対象化。テストに「新規ファイル自動対象化」ケースを含める

### 可用性
- **要件**: false positive を抑え正当な共有 parser 利用をブロックしない
- **対応策**: トークンベース検出 + allow マーカー（候補 C）。C1/C2/C3/B を fixture で「検出されないこと」を固定

## 技術選定
- **言語**: bash 3.2/4.0+ 互換（`set -euo pipefail`）
- **フレームワーク**: なし（既存 `bin/check-*.sh` 様式）
- **ライブラリ**: `grep`/`sed`/`awk`/`find`/`git`（POSIX + git）
- **テスト**: 自己完結型 bash ハーネス（`mktemp` サンドボックス + `trap rm -rf EXIT` / 既存 v3 tests 様式準拠）

## テストマトリクス（conformance / R2: 違反は全て RC=違反 必須）

| # | fixture | 期待 | 種別 |
|---|---------|------|------|
| T-01 | 共有 parser のみ利用する consumer（fm_* 呼び出し） | 違反 0 / exit 0 | 合格 |
| T-02 | C1: `echo "$body" \| grep -Eq "^## sec$"` | 検出されない / exit 0 | 合格（markdown 見出し） |
| T-03 | C2: status.sh 型 atomic write awk + allow マーカー | 検出されない / exit 0 | 合格（marker 除外） |
| T-04 | C3: `tr -d '[:cntrl:]'` | 検出されない / exit 0 | 合格（非対象コマンド） |
| T-05 | B: `.json` への jq（coerce 有無問わず） | 検出されない / exit 0 | 合格（JSON 文脈） |
| T-06 | ①: `grep '^status:' "$file"` 抽出 | 検出 / exit 1 | 違反（ファイル直接） |
| T-07 | ②: `sed -nE 's/^dependencies:...//' "$file"` | 検出 / exit 1 | 違反（配列生パース） |
| T-08 | ③: `jq '.assigned // empty' <<< "$fm"` | 検出 / exit 1 | 違反（frontmatter 文脈 permissive jq） |
| T-09 | ④: 変数経由 READ `echo "$block" \| sed -n 's/^status:.*//p'` | 検出 / exit 1 | 違反（R1#1 変数経由） |
| T-10 | ⑤: 複数行パイプ / 関数内での `^id:` 生抽出 | 検出 / exit 1 | 違反（R1#1 複数行・関数経由） |
| T-11 | allow マーカーを READ idiom（①型）に付与 | 検出（marker 誤用） / exit 1 | 違反（R1#2 構造解釈は allow 不可） |
| T-12 | reason 空 / issue 欠落の allow マーカー | 検出（無効 marker） / exit 1 | 違反（R1#2 + R-design#3 理由・Issue 必須） |
| T-13 | 走査対象ディレクトリ不在 | 違反 0 / exit 0 | opt-in skip |
| T-14 | 新規 consumer ファイル追加（違反含む） | 検出 / exit 1 | スケーラビリティ（自動対象化） |
| T-15 | システムエラー（git repo 外） | exit 2 | システムエラー |
| T-16 | 許可 marker 既知集合の固定アサート（status.sh の 1 件のみ） | 一致 / それ以外で fail | 既知集合固定（R1#2） |
| T-17 | 許可 marker 行から marker を除去すると違反検出されること | marker 除去で exit 1 / 除去前は exit 0 | stale 検出（R-design#3） |

## 実装精緻化（コードレビュー反映 / R-code R1〜R5）

実装・コードレビューを通じて以下を確定・追加した（設計-実装整合性のため記録）:

- **strip_comment 簡易 lexer（R-code#1）**: 単一/二重引用符状態を追跡し、クォート外の行コメント（先頭または空白直後の `#`）以降を除去してから論理単位に連結する。これにより末尾インラインコメント中のアポストロフィ（`# don't` 等）で単一引用符パリティが崩れない。マーカーは strip 前の原文で検出する。`END` で末尾の未評価 acc も評価する。
- **継続ゲートに jq を含める（R-code#2 / `has_quote_cmd`）**: grep/sed/awk に加え jq の単一引用符プログラムが行をまたぐ場合も論理単位に連結する。
- **汎用 `^key:` の文脈シグナル（R-code#3 / R2 / R3）**: 未知/将来キーの raw 抽出は、frontmatter 文脈シグナル（`.md` リテラル〔境界は `["')]`・空白・行末・閉じ括弧を許容〕/ fm 系 here-string / `---` delimiter / work item パス変数 `$file`・`$f`・`$wi`・`$item`・`$md` 等〔語境界判定で `$logfile` は誤一致しない〕）がある場合のみ違反扱いとし、非 frontmatter ファイルへの汎用 grep の誤検出を抑制する。
- **find 失敗の捕捉（R-code#4）**: `find` をプロセス置換から一時ファイル経由に変更し、失敗時 exit 2。
- **heredoc 引用符タグ（R-code#5）**: `<<"EOF"` / `<<'EOF'` / `<<-'EOF'`（dash 変種）の両クォートで heredoc 本文をデータとして除外し、説明文中のサンプルコードを false positive にしない。
- **allow marker 集合のリポジトリ全体固定（R-code#5）**: テストで `grep -rl 'parse-guard: allow=' skills bin`（自スクリプト/テスト除外）が `work-item-status.sh` の 1 件のみであることを固定アサート。
- **`$()` 複数行の paren 深さ継続（R-int#1）**: 論理コマンド単位の継続判定は (a) grep/sed/awk/jq を含み単一引用符が奇数（単一引用符 awk プログラム）に加え、(b) `$(` コマンド置換の net 深さ（`$(` 数 − `)` 数）> 0 で継続する。二重引用符は `$()` ネストでパリティが破綻するため使わない。これにより `status="$(sed -nE "..." "$f")"` のような二重引用符複数行 sed/jq を 1 論理単位に連結して検出する。
- **allow marker は awk atomic write idiom のみ（R-int#2 / r2）**: marker による除外は **awk の atomic write idiom に限定**。判定は構文シグネチャ `is_atomic_write` =「リテラル `print "<key>: " 値`（全行 passthrough + key 書き換え）」を持つこと。grep/sed は本質的に READ で redirect 型（`> "$tmp"`）でも除外しない。awk でも単なる行フィルタ READ（`/^status:/{print}`）や値捕捉抽出（is_extraction）は除外不可。jq は frontmatter に対する正当な write idiom が存在しないため marker でも常に違反。これにより「構造解釈 READ は allow 不可」を厳密化する。

### テストマトリクス追補（実装で確定した fixture）

論理設計 §テストマトリクス T-01〜T-17 に加え、コードレビュー反映で以下を追加（合計 33 アサート / PASS=33）:

| # | fixture | 期待 |
|---|---------|------|
| T-18 / T-18b | 末尾インラインコメント apostrophe で違反取りこぼさない / コメント内 token は非検出 | 1 / 0 |
| T-19 / T-19b / T-19c | 複数行 jq / 単一引用符 .md / 未引用符 .md の permissive jq | 1 / 1 / 1 |
| T-20 / T-20b / T-20c / T-20d / T-20e | 汎用キー: .md 文脈 / 文脈なし非検出 / `$file` 変数 / 単一引用符 .md / 未引用符 .md | 1 / 0 / 1 / 1 / 1 |
| T-22 / T-22b | single-quoted heredoc / `<<-'EOF'` 本文は除外 | 0 / 0 |
| T-23 / T-23b | 二重引用符複数行 sed / jq（`$()` paren 深さで連結 / R-int#1） | 1 / 1 |
| T-24 / T-24b | redirect 型 grep READ + marker / sed + marker は除外不可（R-int#2） | 1 / 1 |

## 実装上の注意事項

- **検出スクリプト自身の grep/sed/awk は正当**: 本 check スクリプトは検出ロジックとして grep/sed/awk を使うが、検出対象は v3 consumer であり自身は対象外（`bin/` 配下 / 走査対象は `skills/aidlc-v3/scripts/`）。
- **コマンド置換禁止規約（CLAUDE.md）**: 検出スクリプト・テスト内のコマンド置換 `$(...)` はファイル実行であり Bash ツール引数ではないため許容。ただし AI エージェントが Bash ツール引数文字列に `$(...)` / backtick を含めない（コミットメッセージ・テスト実行コマンド等）。なお `bin/check-bash-substitution.sh` は **markdown の bash ブロック**が対象でありシェルスクリプトの `$(...)` は対象外。
- **bash 3.2 互換**: 連想配列を使わない。`mapfile`/`readarray` を避けるか bash バージョンガード。
- **false positive 最小化**: トークン語彙は frontmatter フィールドに限定。汎用 `^[a-z_]+:` の過剰一致を避けるため、frontmatter 抽出文脈（`grep -E "^key:"` / `sed -nE "s/^key:..."` / awk frontmatter ブロック idiom）に紐づけて判定する。
- **C2 への marker 付与は実行挙動不変**: コメント 1 行追加のみ。計画 §3「既存 consumer の挙動変更を含まない」に抵触しない。

## 不明点と質問（設計中に記録）

[Question] テスト配置は `bin/tests/check-frontmatter-parse-guard.sh`（単一自己完結 bash）で良いか、`bin/tests/check-frontmatter-parse-guard/`（ディレクトリ + 複数ファイル）にすべきか。
[Answer] 単一自己完結 bash ファイル（`bin/tests/check-frontmatter-parse-guard.sh`）とする。fixture は mktemp サンドボックス内に都度生成し、外部ファイル化しない（v3 tests 様式準拠 / `check-test-isolation` の BATS とは別系統だが自己完結型 bash の方が plan「自己完結型 bash テスト」に整合）。

[Question] squash-unit の `internal_ci_checks` に本検出スクリプトを追加するか（計画 §4.3）。
[Answer] **追加しない**（初版）。理由: (1) CI（skill-reference-check.yml）で PR ごとに担保される、(2) `internal_ci_checks` は Unit 完了 squash 時のリポジトリ構造チェックであり、本検出は v3 consumer 専用で squash 時の必須性が低い、(3) 二重実行コスト回避。将来必要なら別 Unit で追加（opt-in シグナルは設定リスト追記のみで可能）。設計レビューで再確認する。
