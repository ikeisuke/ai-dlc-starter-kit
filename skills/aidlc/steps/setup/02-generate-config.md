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
starter_kit_version = "[version.txt の内容]"
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

```
config/aidlc.toml.template
```

**プレースホルダーの置換**:

テンプレートファイルには以下のプレースホルダーが含まれています。収集した情報で置換してください:

| プレースホルダー | 置換する値 | 取得元 |
|------------------|-----------|--------|
| `[現在日時]` | YYYY-MM-DD形式の日付 | `date +%Y-%m-%d` |
| `[version.txt の内容]` | スターターキットバージョン | `scripts/read-version.sh` |
| `[プロジェクト名]` | プロジェクト名 | セクション5で収集 |
| `[プロジェクト概要]` | プロジェクト概要 | セクション5で収集 |
| `[プロジェクトタイプ]` | プロジェクトタイプ | セクション6で選択 |
| `[[言語リスト]]` | 使用言語の配列 | セクション5で収集（例: `["TypeScript", "JavaScript"]`） |
| `[[フレームワークリスト]]` | フレームワークの配列 | セクション5で収集（例: `["React", "Next.js"]`） |
| `[命名規則]` | 命名規則 | セクション5で収集（デフォルト: `lowerCamelCase`） |

**生成手順**:

1. テンプレートファイルを読み込む
2. 各プレースホルダーを収集した情報で置換
3. `.aidlc/config.toml` として保存

**手順**: AIがテンプレートファイルを読み込み、各プレースホルダーを収集した情報で置換して `.aidlc/config.toml` として保存してください。sedコマンドではなく、AIのWriteツールで直接生成します。

### 7.3 starter_kit_versionの更新【アップグレードモードのみ】

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

### 7.4 設定マイグレーション【アップグレードモードのみ】

新しいバージョンで追加された設定セクションを既存の `.aidlc/config.toml` に追加し、廃止設定の移行も行います。

**マイグレーション実行**:

```bash
scripts/migrate-config.sh
```

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

Claude CodeとKiroCLIの設定ファイルをセットアップします。

```bash
scripts/setup-ai-tools.sh
```

このスクリプトは以下を行います:

1. **KiroCLI エージェント**: `.kiro/agents/aidlc.json` を実ファイルとして配置（既存シンボリックリンクは実ファイルに置換）
2. **Claude Code 許可設定**: `.claude/settings.json` に許可ルールを設定

**注意**: KiroCLI設定はテンプレートからコピーされ、アップグレード時に自動更新されます

---

