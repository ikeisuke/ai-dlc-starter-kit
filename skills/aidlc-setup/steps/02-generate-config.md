## モード分岐ガイド

本ステップファイルのセクションは実行モードに応じて選択的に実行する。

| セクション | 初回 | 移行 | アップグレード |
|-----------|:----:|:----:|:------------:|
| 3. ファイル移行 | - | ✓ | - |
| 4. Git環境の確認 | ✓ | ✓ | ✓ |
| 5. プロジェクト情報の収集 | ✓ | - | - |
| 6. プロジェクトタイプの設定 | ✓ | - | - |
| 7. aidlc.toml の生成 (7.1-7.2) | ✓ | - | - |
| 7.4 設定マイグレーション | - | - | ✓ |
| 7.4b 欠落キー検出 | - | - | ✓ |
| 7.4c no-op 判定 | - | - | ✓ |
| 7.3 starter_kit_version更新（条件実行） | - | - | ✓ |
| 7.5 旧形式バックログ移行 | - | - | ✓ |
| 8. 追加ファイルの配置 (8.1) | ✓ | ✓ | ✓ |
| 8.2 プロジェクト固有ファイル配置 | ✓ | - | - |
| 8.4 AIツール設定セットアップ | ✓ | - | ✓ |

各セクションのタグ（`【初回のみ】`/`【移行モードのみ】`/`【アップグレードモードのみ】`）が正本。上記テーブルはナビゲーション用。

---

## 3. ファイル移行【移行モードのみ】

旧形式のファイルを新形式に移行します。

### 3.1 移行処理

```bash
# 1. project.toml → aidlc.toml に移行
if [ -f docs/aidlc/project.toml ] && [ ! -f .aidlc/config.toml ]; then
  mv docs/aidlc/project.toml .aidlc/config.toml
  echo "MIGRATED: docs/aidlc/project.toml → .aidlc/config.toml"
fi

# 2. additional-rules.md → rules.md に移行
if [ -f docs/aidlc/prompts/additional-rules.md ] && [ ! -f .aidlc/rules.md ]; then
  mkdir -p .aidlc/cycles
  mv docs/aidlc/prompts/additional-rules.md .aidlc/rules.md
  echo "MIGRATED: docs/aidlc/prompts/additional-rules.md → .aidlc/rules.md"
fi

# 3. cycles配下のファイルを .aidlc/ 直下に移行
if [ -f .aidlc/cycles/rules.md ] && [ ! -f .aidlc/rules.md ]; then
  mv .aidlc/cycles/rules.md .aidlc/rules.md
  echo "MIGRATED: .aidlc/cycles/rules.md → .aidlc/rules.md"
fi
if [ -f .aidlc/cycles/operations.md ] && [ ! -f .aidlc/operations.md ]; then
  mv .aidlc/cycles/operations.md .aidlc/operations.md
  echo "MIGRATED: .aidlc/cycles/operations.md → .aidlc/operations.md"
fi

# 4. version.txt を削除（バージョン情報は aidlc.toml に統合）
if [ -f docs/aidlc/version.txt ]; then
  rm docs/aidlc/version.txt
  echo "REMOVED: docs/aidlc/version.txt (バージョン情報は aidlc.toml に統合)"
fi
```

<!-- AIDLC-PATH: physical-path-required (reason: v1-migration) -->

### 3.2 移行通知

移行が実行された場合、以下のメッセージを表示：

```text
ファイル構成の変更に伴い、以下のファイルを移行しました：

| 移行元 | 移行先 |
|--------|--------|
| docs/aidlc/project.toml | .aidlc/config.toml |
| docs/aidlc/prompts/additional-rules.md | .aidlc/rules.md |
| .aidlc/cycles/rules.md | .aidlc/rules.md |
| .aidlc/cycles/operations.md | .aidlc/operations.md |
| docs/aidlc/version.txt | （削除: aidlc.toml に統合） |
<!-- AIDLC-PATH: physical-path-required (reason: v1-migration) -->

これにより、docs/aidlc/ ディレクトリはスターターキットと完全同期可能になりました。
<!-- AIDLC-PATH: physical-path-required (reason: rsync-target) -->
```

### 3.3 aidlc.toml のバージョン情報更新

移行後、`.aidlc/config.toml` に `starter_kit_version` フィールドを追加（存在しない場合）:

```toml
# ファイル先頭に追記
starter_kit_version = "[marketplace.json metadata.version の内容]"
```

---

## 4. Git環境の確認

### 4.1 Gitリポジトリの確認

```bash
git rev-parse --git-dir 2>/dev/null && echo "GIT_REPO" || echo "NOT_GIT_REPO"
```

**Gitリポジトリでない場合**:
- 警告を表示: 「このディレクトリはGitリポジトリではありません」
- `git init` での初期化を提案
- ユーザーに「初期化する / バージョン管理なしで続行」を選択させる

### 4.2 現在のブランチ確認

Gitリポジトリの場合:

```bash
git branch --show-current
```

---

## 5. プロジェクト情報の収集【初回のみ】

複数の情報源からプロジェクト情報を推測し、不足分のみ質問します。

### 5.1 情報源の探索

以下の情報源を確認し、存在するものを収集します：

```bash
# 1. README.md の確認
ls README.md 2>/dev/null
# → 存在すれば README_EXISTS=yes、なければ README_EXISTS=no

# 2. 設定ファイルの確認（優先順位順）
# package.json, go.mod, Cargo.toml, pyproject.toml, composer.json, Gemfile の順にチェック
ls package.json go.mod Cargo.toml pyproject.toml composer.json Gemfile 2>/dev/null | head -1
# → 最初に見つかったものを CONFIG_FILE として記録

# 3. docs/ ディレクトリの確認（aidlc/, cycles/ を除外）
# これらはセットアップで作成されるため探索対象外
find docs -maxdepth 2 -name "*.md" -not -path "docs/aidlc/*" -not -path ".aidlc/cycles/*" 2>/dev/null | head -5
# → 結果をAIが DOCS_FILES / DOCS_COUNT として記録

# 4. ソースコードディレクトリの確認
SRC_DIR=""
for d in src lib app cmd pkg; do
  if [ -d "$d" ]; then
    SRC_DIR="$d"
    break
  fi
done

echo "情報源: README=${README_EXISTS}, CONFIG=${CONFIG_FILE:-none}, DOCS=${DOCS_COUNT}files, SRC=${SRC_DIR:-none}"
```

**探索結果の表示**:
```text
プロジェクトの情報源を確認しました：

| 情報源 | 状態 |
|--------|------|
| README.md | [あり/なし] |
| 設定ファイル | [ファイル名/なし] |
| docs/（プロジェクト固有） | [N件/なし] |
| ソースコード | [ディレクトリ名/なし] |
```

### 5.2 プロジェクト情報の推測

収集した情報源から以下の情報を推測します：

| フィールド | 推測方法（優先順位順） |
|-----------|----------------------|
| name | 1. package.json等のname 2. README.mdのタイトル 3. ディレクトリ名 |
| description | 1. package.json等のdescription 2. README.mdの冒頭 |
| languages | 1. 設定ファイルの種類から推測 2. ソースコードの拡張子から推測 |
| frameworks | 1. 依存関係から推測（package.json, go.mod等） |
| namingConvention | 1. 既存コードのスタイルから推測 2. デフォルト: lowerCamelCase |

**設定ファイルからの言語推測**:
| 設定ファイル | 言語 |
|-------------|------|
| package.json | JavaScript/TypeScript |
| go.mod | Go |
| Cargo.toml | Rust |
| pyproject.toml | Python |
| composer.json | PHP |
| Gemfile | Ruby |

**追加ドキュメントの読み込み**（必要に応じて）:

情報が不足している場合、以下の順序で追加ドキュメントを読み込みます：
1. CONTRIBUTING.md, ARCHITECTURE.md（ルート直下）
2. docs/ 配下の .md ファイル（aidlc/, cycles/ を除く）

**読み込み制限**（コンテキスト溢れ防止）:
- 最大5ファイルまで
- 各ファイル100行まで

### 5.3 推測結果の確認

推測した情報をテーブル形式で表示し、ユーザーに確認を求めます：

```text
プロジェクト情報を推測しました：

| 項目 | 推測値 | 根拠 |
|------|--------|------|
| プロジェクト名 | [推測値] | [情報源] |
| プロジェクト概要 | [推測値 or 「-」] | [情報源] |
| 使用言語 | [推測値 or 「-」] | [情報源] |
| フレームワーク | [推測値 or 「-」] | [情報源] |
| 命名規則 | [推測値 or lowerCamelCase] | [情報源/デフォルト] |

上記の内容で問題ありませんか？変更したい項目があれば教えてください。
```

**応答パターン**:
- 「OK」「はい」「問題ない」→ 推測値を採用し、次のステップへ
- 変更がある場合 → 指定された項目のみ更新

### 5.4 不足項目の質問

推測値が「-」の項目について、aidlc.toml構成に必要な情報が不足している場合のみ質問します。

**必須フィールド**: name（必須）、description（推奨）

```text
[項目名]が推測できませんでした。入力してください（スキップする場合は「スキップ」）:
```

**注意**: すべての項目はスキップ可能です。後から `.aidlc/config.toml` を直接編集することもできます。

---

## 6. プロジェクトタイプの設定【初回のみ】

プロジェクトタイプを選択してください:

```text
プロジェクトタイプを選択してください:

1. web - Webアプリケーション
2. backend - バックエンドAPI/サーバー
3. cli - コマンドラインツール
4. desktop - デスクトップアプリ
5. ios - iOSアプリ
6. android - Androidアプリ
7. general - 汎用/未分類（デフォルト）

どれを選択しますか？
```

選択後、`.aidlc/config.toml` の `[project]` セクションに `type = "{選択した値}"` を追加します。

---

## 7. aidlc.toml の生成【初回のみ】

収集した情報を元に `.aidlc/config.toml` を生成します。

### 7.1 ディレクトリ作成

```bash
mkdir -p .aidlc
mkdir -p .aidlc/cycles
```

### 7.2 aidlc.toml の生成

テンプレートファイルを使用して `.aidlc/config.toml` を生成します。

**テンプレートファイルの取得**:

テンプレートファイルはスキルディレクトリ内に配置されています:

```text
templates/config.toml.template
```

**プレースホルダーの置換**:

テンプレートファイルには以下のプレースホルダーが含まれています。収集した情報で置換してください:

| プレースホルダー | 置換する値 | 取得元 |
|------------------|-----------|--------|
| `[現在日時]` | YYYY-MM-DD形式の日付 | `date +%Y-%m-%d` |
| `[marketplace.json metadata.version の内容]` | スターターキットバージョン | `scripts/read-version.sh`（内部で `.claude-plugin/marketplace.json` の `metadata.version` を抽出） |
| `[プロジェクト名]` | プロジェクト名 | セクション5で収集 |
| `[プロジェクト概要]` | プロジェクト概要 | セクション5で収集 |
| `[プロジェクトタイプ]` | プロジェクトタイプ | セクション6で選択 |
| `[[言語リスト]]` | 使用言語の配列 | セクション5で収集（例: `["TypeScript", "JavaScript"]`、1件: `["TypeScript"]`、0件: `[]`） |
| `[[フレームワークリスト]]` | フレームワークの配列 | セクション5で収集（例: `["React", "Next.js"]`、1件: `["React"]`、0件: `[]`） |
| `[命名規則]` | 命名規則 | セクション5で収集（デフォルト: `lowerCamelCase`） |

**生成手順**:

1. テンプレートファイルを読み込む
2. 各プレースホルダーを収集した情報で置換
3. `.aidlc/config.toml` として保存

**手順**: AIがテンプレートファイルを読み込み、各プレースホルダーを収集した情報で置換して `.aidlc/config.toml` として保存してください。sedコマンドではなく、AIのWriteツールで直接生成します。

### 7.4 設定マイグレーション【アップグレードモードのみ】

新しいバージョンで追加された設定セクションを既存の `.aidlc/config.toml` に追加し、廃止設定の移行も行います。

> **ステップ順序の補足（v2.6.0 / Unit 004）**: アップグレードモードでは「7.4 → 7.4b → 7.4c (no-op 判定) → 7.3 (条件実行) → 7.5」の順で実行する。`starter_kit_version` の値更新（旧 7.3）は 7.4c の判定後にのみ実行され、適用変更が無い場合（no-op）はスキップされる。
>
> AI agent はステップ 7.4 / 7.4b の出力を後続ステップ 7.4c で参照するため、**`mktemp -d` で生成した一時ディレクトリ配下のファイル**に結果を書き出すこと（共有 `/tmp` での予測可能ファイル名は symlink/race 攻撃のリスクがあるため固定パスは使用しない）。AI agent はディレクトリパスを 7.4 / 7.4b / 7.4c の各 Bash 呼び出しで同一の文字列として渡すこと（ツール呼び出しを跨いで shell 変数は共有されないため、リテラル展開で受け渡す）。
>
> **セッションディレクトリの作成（7.4 開始時に 1 回のみ実行）**:
>
> ```bash
> umask 077
> AIDLC_SETUP_SESSION_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aidlc-setup.XXXXXXXX")
> echo "AIDLC_SETUP_SESSION_DIR=${AIDLC_SETUP_SESSION_DIR}"
> ```
>
> - `umask 077`: 後続のファイル作成で他ユーザーの読み取り/書き換えを禁止
> - `mktemp -d ... .XXXXXXXX`: ランダムサフィックス付きの一時ディレクトリを `0700` モードで生成（mktemp の標準動作）
> - `echo` で出力されたパスを AI agent が記憶し、後続ステップで `${AIDLC_SETUP_SESSION_DIR}` を**リテラル展開済みの絶対パス文字列**として再利用する
>
> セッションディレクトリ配下で使用するファイル:
>
> - `${AIDLC_SETUP_SESSION_DIR}/migrate-config-result.txt`: ステップ 7.4 の `migrate-config.sh` stdout 全体（`result:` 行を含む）
> - `${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt`: ステップ 7.4b の対話結果として `0` または `1` の 1 文字（追加が実行されたら `1`、それ以外は `0`）

**マイグレーション実行**:

```bash
scripts/migrate-config.sh | tee "${AIDLC_SETUP_SESSION_DIR}/migrate-config-result.txt"
```

`tee` で stdout を一時ファイル（セッションディレクトリ配下、`0700` 親 + `umask 077` で他ユーザー読書禁止）に保存しつつ、ユーザーにも従来通り表示する。本ファイルはステップ 7.4c で `result:` 行抽出に使用される。

出力例:
```text
mode:execute
config:.aidlc/config.toml
skip:not-found:rules.mcp_review
skip:already-exists:rules.reviewing
skip:already-exists:rules.worktree
skip:already-exists:rules.history
skip:already-exists:rules.backlog
skip:already-exists:rules.linting
skip:already-exists:rules.reviewing.tools
skip:already-exists:rules.commit
skip:not-found:inception.dependabot
```

**出力の解釈**:

| プレフィックス | 意味 |
|-------------|------|
| `migrate:add-section:<name>` | 新セクションを追加した |
| `migrate:rename:<from->to>` | セクションをリネームした |
| `migrate:add-key:<name>` | 既存セクションにキーを追加した |
| `migrate:deprecate:<detail>` | 廃止設定をrules.mdに移行した |
| `skip:already-exists:<name>` | 既に存在するためスキップ |
| `skip:not-found:<name>` | 移行元が存在しないためスキップ |
| `warn:override-old-keys:<file>` | オーバーライドファイルに旧キーが残っている（手動更新が必要） |

**終了コード**:
- `0`: 正常完了
- `1`: エラー（ファイル不在等）
- `2`: 正常完了だがユーザー対応が必要な警告あり（`warn:` 行を確認）

`warn:override-old-keys` が出力された場合、該当ファイル内の旧キーを手動で更新するようユーザーに案内してください:
- `[rules.mcp_review]` → `[rules.reviewing]`
- `ai_tools` → `tools`

**注意**: 今後のバージョンで新しい設定セクションが追加された場合、`migrate-config.sh` にマイグレーション処理を追加してください。

**注意**: 廃止された設定は `aidlc.toml` から削除せず、そのまま残しても問題ありません（無視されます）。ユーザーが明示的に削除するまで保持されます。

### 7.4b. 欠落キー検出【アップグレードモードのみ】

**スキップ条件**: 新規セットアップ時（アップグレードモードでない場合）はこのステップを完全にスキップする。アップグレードモードかどうかは、ステップ 7 冒頭で判定済みのモードフラグを参照する。

`defaults.toml` をスキーマとして、`config.toml` に欠落しているキーを検出します。

**defaults.toml パスの解決**: `{aidlc-setupスキルのベースディレクトリ}/config/defaults.toml` のパスを構築し、Read ツールで存在確認する（Glob/Search ではなく Read で直接パスを指定すること）。存在すればそのパスを `--defaults` に使用する。見つからない場合は「defaults.toml が見つかりません。欠落キー検出をスキップします。」と表示してこのステップをスキップする。

**実行**:

```bash
scripts/detect-missing-keys.sh --defaults <defaults.tomlパス> --config .aidlc/config.toml
```

**出力の解釈**:

出力はタブ区切り形式です:

| フィールド1 | フィールド2 | フィールド3 | 意味 |
|------------|------------|------------|------|
| `missing` | `<key>` | `<default_value>` | config.toml に欠落しているキーとデフォルト値 |
| `summary` | `total` | `<N>` | 欠落キーの総数 |
| `error` | `<type>` | `<message>` | スクリプトエラー |

対応値型: boolean, integer, string, array。値は dasel 生出力（クォート除去済み）。

**欠落キーが 0 件の場合**: 「欠落キーなし。config.toml は最新です。」と表示して次のステップへ進む。

**欠落キーがある場合**: 欠落キーの一覧テーブルをテキスト出力した後、`AskUserQuestion` ツールで追記するかを確認する（テキスト出力のみで選択肢を提示してはならない）:

テーブル出力:
```text
config.toml に以下のキーが欠落しています（defaults.toml に存在するがconfig.toml に未設定）:

| キー | デフォルト値 |
|------|------------|
| <key1> | <value1> |
| <key2> | <value2> |
```

`AskUserQuestion` の選択肢:
1. はい - すべて追記する
2. 選択して追記する - 追記するキーを選択
3. いいえ - スキップする

- **「1. はい」**: 全キーを `config.toml` に追記する。AIが直接TOMLファイルを編集して追記する（Editツール等を使用。dasel v3では `put` サブコマンドが廃止されているため）。追記後に `追記完了: N 件のキーを追加しました` と表示する。**追記完了後**、Bashツールで `printf '1' > "${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"` を実行する
- **「2. 選択して追記する」**: ユーザーに追記するキーを選択させ、選択されたキーのみ追記する。**選択追記が 1 件以上行われた場合**は `printf '1' > "${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"`、**0 件選択（実質スキップ）の場合**は `printf '0' > "${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"` を実行する
- **「3. いいえ」**: 「欠落キーの追記をスキップしました。」と表示し、Bashツールで `printf '0' > "${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"` を実行してから次のステップへ進む

**欠落キーが 0 件の場合の補足**: 上記の「欠落キーなし。config.toml は最新です。」表示と同時に `printf '0' > "${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"` を実行する（7.4c で必ず読み取られるため）。

**エラー時**: 「⚠ 欠落キー検出でエラーが発生しました。スキップして次のステップへ進みます。」と表示し、`printf '0' > "${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"` を実行してスキップする（追加が行われていないため `0`）。

### 7.4c no-op 判定【アップグレードモードのみ】

ステップ 7.4 と 7.4b の結果を集約し、`.aidlc/config.toml` の `starter_kit_version` 値更新（旧 7.3、後続の条件実行ブロック）の要否を判定します。

**入力**:

- `${AIDLC_SETUP_SESSION_DIR}/migrate-config-result.txt`: 7.4 の `migrate-config.sh` stdout（`result:` 行を含む）
- `${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt`: 7.4b の対話結果集約値（`0` または `1`）

**実行**:

```bash
RESULT_FILE="${AIDLC_SETUP_SESSION_DIR}/migrate-config-result.txt"
APPLIED_FILE="${AIDLC_SETUP_SESSION_DIR}/detect-missing-applied.txt"

# result: 行抽出（複数行ある場合は最初の 1 行）。grep が一致しない場合も後続のフォールバックで救済。
RESULT_LINE=$(grep -E '^result:' "$RESULT_FILE" 2>/dev/null | head -1 || true)
DETECT_APPLIED=$(cat "$APPLIED_FILE" 2>/dev/null || echo "")

scripts/check-noop-upgrade.sh \
    --migrate-config-result "$RESULT_LINE" \
    --detect-missing-applied "$DETECT_APPLIED"
NOOP_EXIT=$?
```

**出力解釈**:

`check-noop-upgrade.sh` は stdout に必ず以下 3 行を出力する:

```text
noop=<true|false|>
reason=<no-changes|migrate-config-changed|missing-keys-applied|>
error=<error-detail|>
```

| 終了コード | noop / reason | アクション |
|-----------|---------------|----------|
| `0` + `noop=true` + `reason=no-changes` | 適用変更なし | 7.3（starter_kit_version 更新）を **スキップ** + 通知メッセージ表示 |
| `0` + `noop=false` + `reason=migrate-config-changed` または `reason=missing-keys-applied` | 適用変更あり | 7.3 を **通常実行** |
| `2` + `error=*` | 判定不能（フォールバック） | 警告表示 + 7.3 を **通常実行**（既存挙動維持） |

AI agent は exit code を一次判定に使い、`noop=` の値を補助的に確認する。フラグ `should_update_starter_kit_version` を以下のように決定する:

- exit 0 + `noop=true` → `should_update_starter_kit_version=false`（7.3 スキップ）
- exit 0 + `noop=false` → `should_update_starter_kit_version=true`（7.3 実行）
- exit 2（フォールバック） → `should_update_starter_kit_version=true`（7.3 実行 + 警告表示）

**スキップ時の表示**:

```text
.aidlc/config.toml の starter_kit_version 更新をスキップしました（差分なし）
- migrate-config: 適用変更なし
- detect-missing-keys: 追加なし
- 注意: .claude/settings.json (8.4) は別責務として通常通り適用されます
```

**フォールバック時の警告表示**:

```text
⚠ no-op 判定に失敗しました（{error の値}）。安全側として starter_kit_version を通常通り更新します。
```

**一時ファイルのクリーンアップ**: 7.4c の判定完了後（7.3 の条件実行終了後でも可）に以下を実行し、セッションディレクトリごと除去する。**変数受け渡しミスや空展開による誤削除を防ぐためのガードを必ず付ける**:

```bash
# ガード: 変数が空/未設定 / 想定プレフィックス外 / ディレクトリでない場合は何もしない
_tmp_base="${TMPDIR:-/tmp}"
if [[ -n "${AIDLC_SETUP_SESSION_DIR:-}" ]] \
   && [[ -d "${AIDLC_SETUP_SESSION_DIR}" ]] \
   && [[ "${AIDLC_SETUP_SESSION_DIR}" == "${_tmp_base%/}/aidlc-setup."* ]]; then
    rm -rf -- "${AIDLC_SETUP_SESSION_DIR}"
fi
unset AIDLC_SETUP_SESSION_DIR _tmp_base
```

- ガード条件 (3 つすべて満たした場合のみ削除):
  - `-n`: 変数が非空（未設定 / 空文字列での `rm -rf "/"` 級事故を防ぐ）
  - `-d`: 実体がディレクトリ（シンボリックリンクや単体ファイルへの誤削除を防ぐ）
  - プレフィックス一致: `${TMPDIR:-/tmp}/aidlc-setup.` で始まる（mktemp で生成した本セッション専用パスのみ）
- セッションディレクトリは毎回異なるランダムサフィックス付き（mktemp -d）であるため、クリーンアップを忘れても他の setup 実行と衝突しない。明示削除により残置を防ぐ。

### 7.3 starter_kit_version の更新【アップグレードモードのみ / 条件実行】

> **実行条件（v2.6.0 / Unit 004 で追加）**: 直前の 7.4c 判定で `should_update_starter_kit_version=true` の場合のみ実行する。`false` の場合は本ステップ全体をスキップして 7.5 へ進む。

`.aidlc/config.toml` の `starter_kit_version` フィールドを最新バージョンに更新:

`.aidlc/config.toml` を開き、`starter_kit_version` の値を `[新バージョン]` に更新してください。

`starter_kit_version` フィールドが存在しない場合は、ファイル先頭に以下を追加:

```toml
starter_kit_version = "[新バージョン]"
```

**更新確認**:

更新後、以下のコマンドで正しく反映されたことを確認してください:

```bash
grep "^starter_kit_version" .aidlc/config.toml
```

期待される出力: `starter_kit_version = "[新バージョン]"`

正しく更新されていない場合は、手動で `.aidlc/config.toml` を編集してください。

### 7.5 旧形式バックログ移行【アップグレードモードのみ】

> **DEPRECATED (v1.9.0)**: v2.0.0 で削除予定

旧形式の `.aidlc/cycles/backlog.md` が存在する場合、新形式への移行を提案：

```bash
scripts/migrate-backlog.sh --dry-run
```

**出力例**:
```text
status:no_file
migrated_count:0
skipped_completed:0
skipped_duplicate:0
deleted:false
message:旧形式バックログが存在しません
```

- `status:no_file`: スキップ（次のセクションへ進む）
- `status:migrated`: 移行完了を表示（`--dry-run` なしで実行した場合）

**移行実行時**: ユーザーに確認後、`scripts/migrate-backlog.sh` を実行

---

## 8. 共通ファイルの配置

### 8.1 ディレクトリ構造の作成

```bash
mkdir -p .aidlc
mkdir -p .aidlc/cycles
```

### 8.2 プロジェクト固有ファイルの配置【初回のみ】

以下のファイルはプロジェクト固有の設定を含むため、**既に存在する場合はコピーしない**。
テンプレートはスキルディレクトリ内にあるため、Readツールで読み込んでWriteツールで書き出す。

| ファイル | テンプレート |
|--------|-------------|
| `.aidlc/rules.md` | `templates/rules_template.md` |
| `.aidlc/operations.md` | `templates/operations_handover_template.md` |

```bash
# 存在確認
[ -f .aidlc/rules.md ] && echo "EXISTS:rules" || echo "NEEDS:rules"
[ -f .aidlc/operations.md ] && echo "EXISTS:operations" || echo "NEEDS:operations"
```

`NEEDS` のファイルのみ、テンプレートを読み込んで書き出す。

### 8.3 Issue用基本ラベルの作成

GitHub CLIが利用可能な場合、バックログ管理用の共通ラベルを作成します。

**前提条件**:
- `gh:available` であること

**前提条件を満たさない場合**: このステップをスキップ。

**ラベル作成**:

```bash
scripts/init-labels.sh
```

**注意**: 既存のラベルはスキップされます（冪等性あり）。

### 8.4 AIツール設定のセットアップ【初回・アップグレード共通】

Claude Codeの設定ファイルをセットアップします。

```bash
scripts/setup-ai-tools.sh
```

このスクリプトは以下を行います:

1. **Claude Code 許可設定**: `.claude/settings.json` に許可ルールを設定

**注意**: KiroCLIエージェント設定は `/install-kiro-agent` スキルで別途インストールしてください

---

