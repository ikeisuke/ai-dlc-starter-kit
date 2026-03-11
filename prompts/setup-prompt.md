# AI-DLC セットアップ

このファイルは AI-DLC セットアップのエントリーポイントです。
プロジェクトの状態を判定し、初回セットアップ、アップグレード、または移行を実行します。

---

## 共通ルール

- **Overconfidence Prevention原則【重要】**: 確信度が低い場合は推測や仮定で進めず、必ずユーザーに質問する。確信度が判定できない場合のデフォルト動作は「質問する」。

  **質問フロー（ハイブリッド方式）**:
  1. まず質問の数と概要を提示する
  2. 1問ずつ詳細を質問し、回答を待つ
  3. 回答を得てから次の質問に進む
  4. 回答に基づく追加質問が発生した場合は「追加で確認させてください」と明示して質問する

---

## 0. 必要ツールの準備

AI-DLCの実行には、以下のツールが必要です。セットアップ前にインストールしてください。

### 必須ツール

| ツール | 用途 |
|--------|------|
| gh (GitHub CLI) | GitHub Issue/PR操作、バックログ管理（issue-only モード時） |

### オプションツール

以下のツールはオプションです。インストールされていない場合、AIが代替処理を行います。

| ツール | 用途 | 代替手段 |
|--------|------|----------|
| ghq | リポジトリ管理（スターターキットパス解決） | 手動でパスを指定 |
| dasel | TOML設定ファイルの解析 | AIが直接ファイルを読み取り |
| jq | JSON解析 | AIが直接解析 |
| curl | Webリソース取得 | AIのWebFetch機能（Claude Code等） |

### インストールコマンド

**macOS (Homebrew)**:

```bash
# 必須
brew install gh

# オプション
brew install ghq
brew install dasel
brew install jq
# curl は通常プリインストール済み
```

**Ubuntu/Debian (APT)**:

```bash
# 必須
sudo apt install gh

# オプション
# ghq: https://github.com/x-motemen/ghq/releases からダウンロード
# dasel: https://github.com/TomWright/dasel/releases からダウンロード
sudo apt install jq
# curl は通常プリインストール済み
```

**GitHub CLI の認証**:

インストール後、以下のコマンドで認証を行ってください。

```bash
gh auth login
```

---

## 1. 実行環境の確認

**まず最初に、現在のカレントディレクトリを確認してください**:

```bash
pwd
```

**このセットアップは、対象プロジェクトのルートディレクトリで実行する必要があります。**

もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合:
- **メタ開発モード**: `prompts/package/` ディレクトリが存在する場合は、スターターキット自体の開発として続行できます
- **通常利用**: 対象プロジェクトのルートディレクトリに移動してから、このファイルのフルパスを指定して再度実行してください

**確認が完了したら、以下をユーザーに表示してください**:

```text
現在のディレクトリ: [pwd の結果]

このディレクトリで AI-DLC セットアップを実行してよろしいですか？
```

ユーザーが「はい」と明示的に承認するまで、次のステップに進まないでください。

---

## 2. セットアップ種類の判定

セットアップ種類判定スクリプトを実行してください。

**スクリプトのパス判定**:
- このファイル（setup-prompt.md）と同じディレクトリの `setup/bin/check-setup-type.sh` を使用
- メタ開発モード（`prompts/package/` が存在）: `prompts/setup/bin/check-setup-type.sh`
- 通常利用: スターターキットの `prompts/setup/bin/check-setup-type.sh`

```bash
# メタ開発モードの場合
prompts/setup/bin/check-setup-type.sh

# 通常利用の場合
# setup-prompt.mdを読み込んだスターターキットの基底パスから実行
# 例: [スターターキットパス]/prompts/setup/bin/check-setup-type.sh
```

**注意**: 通常利用では、AIがsetup-prompt.mdを読み込んだパスからスターターキットの基底パスを推定してください。

**出力例**:

```text
setup_type:cycle_start
```

**dasel未インストールの場合**（`setup_type:` と空値が返る場合）: AIは `docs/aidlc.toml` を読み込み、`starter_kit_version` の値を取得してください。また、プロジェクトルートの `version.txt`（リポジトリルート直下）を読み込み、スターターキットのバージョンと比較してください。

### 判定結果に基づく対応

#### ケース A: `setup_type:initial`（初回セットアップ）

以下のメッセージを表示してください:

```text
AI-DLC の初回セットアップを行います。
```

**次のアクション**: セクション3（ファイル移行）をスキップし、セクション4（Git環境の確認）へ進んでください。

---

#### ケース B: `setup_type:cycle_start`（サイクル開始）

以下のメッセージを表示してください:

```text
AI-DLC は最新です。新しいサイクルを開始します。
```

**次のアクション**:
1. `docs/aidlc/prompts/inception.md` の存在を確認
2. 存在する場合: プロジェクト内の `docs/aidlc/prompts/inception.md` を読み込む
3. 存在しない場合: このファイル（setup-prompt.md）と同じディレクトリにある `package/prompts/inception.md` を読み込む

ユーザーの操作を待たずに自動で読み込むこと。

---

#### ケース C: `setup_type:upgrade:{project}:{kit}`（アップグレード可能）

以下のメッセージを表示し、ユーザーの選択を待ってください:

```text
AI-DLC のアップグレードが利用可能です。

現在のバージョン: {project}
最新バージョン: {kit}

選択してください:
1. アップグレードする（プロンプト・テンプレートを更新）
2. 現在のバージョンのまま新しいサイクルを開始する

どちらを選択しますか？
```

**次のアクション**: ユーザーの選択後:
- **1 を選択**: セクション3（ファイル移行）をスキップし、セクション4（Git環境の確認）へ進む（アップグレードモード）
- **2 を選択**:
  1. `docs/aidlc/prompts/inception.md` の存在を確認
  2. 存在する場合: プロジェクト内の `docs/aidlc/prompts/inception.md` を読み込む
  3. 存在しない場合: このファイル（setup-prompt.md）と同じディレクトリにある `package/prompts/inception.md` を読み込む

---

#### ケース D: `setup_type:warning_newer:{project}:{kit}`（プロジェクトが新しい）

以下のメッセージを表示してください:

```text
警告: プロジェクトのバージョンがスターターキットより新しいです。

プロジェクト: {project}
スターターキット: {kit}

スターターキットのアップデートを推奨します。
現在のバージョンで続行しますか？
```

**次のアクション**: ユーザーが続行を承認した場合:
1. `docs/aidlc/prompts/inception.md` の存在を確認
2. 存在する場合: プロジェクト内の `docs/aidlc/prompts/inception.md` を読み込む
3. 存在しない場合: このファイル（setup-prompt.md）と同じディレクトリにある `package/prompts/inception.md` を読み込む

---

#### ケース E: `setup_type:migration`（旧形式からの移行）

`docs/aidlc.toml` は存在しないが `docs/aidlc/project.toml` が存在する場合:
- これは旧バージョンの AI-DLC でセットアップされたプロジェクトです
- セクション3（ファイル移行）へ進んでください（移行モード）

### 後方互換性

#### さらに古い形式（version.txt のみ）が存在する場合

`docs/aidlc/project.toml` も `docs/aidlc.toml` も存在しないが `docs/aidlc/version.txt` が存在する場合:
- これはさらに旧バージョンの AI-DLC でセットアップされたプロジェクトです
- ケース A（初回セットアップ）として扱い、移行を案内してください

---

## 3. ファイル移行【移行モードのみ】

旧形式のファイルを新形式に移行します。

### 3.1 移行処理

```bash
# 1. project.toml → aidlc.toml に移行
if [ -f docs/aidlc/project.toml ] && [ ! -f docs/aidlc.toml ]; then
  mv docs/aidlc/project.toml docs/aidlc.toml
  echo "MIGRATED: docs/aidlc/project.toml → docs/aidlc.toml"
fi

# 2. additional-rules.md → rules.md に移行
if [ -f docs/aidlc/prompts/additional-rules.md ] && [ ! -f docs/cycles/rules.md ]; then
  mkdir -p docs/cycles
  mv docs/aidlc/prompts/additional-rules.md docs/cycles/rules.md
  echo "MIGRATED: docs/aidlc/prompts/additional-rules.md → docs/cycles/rules.md"
fi

# 3. version.txt を削除（バージョン情報は aidlc.toml に統合）
if [ -f docs/aidlc/version.txt ]; then
  rm docs/aidlc/version.txt
  echo "REMOVED: docs/aidlc/version.txt (バージョン情報は aidlc.toml に統合)"
fi
```

### 3.2 移行通知

移行が実行された場合、以下のメッセージを表示：

```text
ファイル構成の変更に伴い、以下のファイルを移行しました：

| 移行元 | 移行先 |
|--------|--------|
| docs/aidlc/project.toml | docs/aidlc.toml |
| docs/aidlc/prompts/additional-rules.md | docs/cycles/rules.md |
| docs/aidlc/version.txt | （削除: aidlc.toml に統合） |

これにより、docs/aidlc/ ディレクトリはスターターキットと完全同期可能になりました。
```

### 3.3 aidlc.toml のバージョン情報更新

移行後、`docs/aidlc.toml` に `starter_kit_version` フィールドを追加（存在しない場合）:

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
README_EXISTS=$(ls README.md 2>/dev/null && echo "yes" || echo "no")

# 2. 設定ファイルの確認（優先順位順）
CONFIG_FILE=""
for f in package.json go.mod Cargo.toml pyproject.toml composer.json Gemfile; do
  if [ -f "$f" ]; then
    CONFIG_FILE="$f"
    break
  fi
done

# 3. docs/ ディレクトリの確認（aidlc/, cycles/ を除外）
# これらはセットアップで作成されるため探索対象外
DOCS_FILES=$(find docs -maxdepth 2 -name "*.md" -not -path "docs/aidlc/*" -not -path "docs/cycles/*" 2>/dev/null | head -5)
DOCS_COUNT=$(echo "$DOCS_FILES" | grep -c . 2>/dev/null || echo "0")

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

**注意**: すべての項目はスキップ可能です。後から `docs/aidlc.toml` を直接編集することもできます。

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

選択後、`docs/aidlc.toml` の `[project]` セクションに `type = "{選択した値}"` を追加します。

---

## 7. aidlc.toml の生成【初回のみ】

収集した情報を元に `docs/aidlc.toml` を生成します。

### 7.1 ディレクトリ作成

```bash
mkdir -p docs/aidlc
mkdir -p docs/cycles
```

### 7.2 aidlc.toml の生成

テンプレートファイルを使用して `docs/aidlc.toml` を生成します。

**重要**: `[setup_prompt パス]` の値はセクション7.2.1で判定します。プレースホルダー置換の前に7.2.1を先に実施してください。

**テンプレートファイルの取得**:

テンプレートファイルのパスはセクション8.1.1で判定した `[スターターキットパス]` を使用:

```bash
# テンプレートファイルを読み込み
TEMPLATE_FILE="[スターターキットパス]/prompts/setup/templates/aidlc.toml.template"

# テンプレートが存在するか確認
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file not found: $TEMPLATE_FILE"
    # フォールバック: テンプレートファイルがない場合は手動で作成を案内
fi
```

**プレースホルダーの置換**:

テンプレートファイルには以下のプレースホルダーが含まれています。収集した情報で置換してください:

| プレースホルダー | 置換する値 | 取得元 |
|------------------|-----------|--------|
| `[現在日時]` | YYYY-MM-DD形式の日付 | `date +%Y-%m-%d` |
| `[version.txt の内容]` | スターターキットバージョン | `[スターターキットパス]/version.txt` |
| `[プロジェクト名]` | プロジェクト名 | セクション5で収集 |
| `[プロジェクト概要]` | プロジェクト概要 | セクション5で収集 |
| `[プロジェクトタイプ]` | プロジェクトタイプ | セクション6で選択 |
| `[[言語リスト]]` | 使用言語の配列 | セクション5で収集（例: `["TypeScript", "JavaScript"]`） |
| `[[フレームワークリスト]]` | フレームワークの配列 | セクション5で収集（例: `["React", "Next.js"]`） |
| `[命名規則]` | 命名規則 | セクション5で収集（デフォルト: `lowerCamelCase`） |
| `[setup_prompt パス]` | セットアッププロンプトのパス | セクション7.2.1で判定 |

**生成手順**:

1. テンプレートファイルを読み込む
2. 各プレースホルダーを収集した情報で置換
3. `docs/aidlc.toml` として保存

```bash
# 例: テンプレートから生成（AIが置換処理を実行）
cat "$TEMPLATE_FILE" | \
  sed "s/\[現在日時\]/$(date +%Y-%m-%d)/g" | \
  sed "s/\[version.txt の内容\]/$(cat [スターターキットパス]/version.txt)/g" | \
  # ... 他のプレースホルダーも同様に置換 ...
  > docs/aidlc.toml
```

**注意**: 上記のsedコマンドは参考例です。AIが直接ファイルを読み込み、プレースホルダーを置換して `docs/aidlc.toml` を生成してください。

### 7.2.1 setup_prompt パスの設定【初回・移行のみ】

`[paths].setup_prompt` には、このセットアッププロンプトファイルのパスを設定します。

**パス形式の判定**（優先順位順）:

1. **同一リポジトリ内の場合**: 相対パスを使用
   - このファイル（setup-prompt.md）がプロジェクトルート配下にある場合
   - **基準**: `docs/aidlc.toml` が配置されるディレクトリ（プロジェクトルート）
   - 例: `prompts/setup-prompt.md`

2. **外部リポジトリの場合**: ghq形式を使用
   - このファイルが別のリポジトリにある場合（ghq管理下）
   - 形式: `ghq:{host}/{owner}/{repo}/{path}`
   - 例: `ghq:github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md`

3. **上記以外の場合**: 絶対パスを使用（フォールバック、非推奨）
   - ghq未使用環境でのフォールバック

**判定補助**:
- プロジェクトルートは `docs/aidlc.toml` が作成されるディレクトリ
- 外部リポジトリの場合、`resolve-starter-kit-path.sh` でスターターキットパスを自動解決可能:
  ```bash
  # 同期済み環境: docs/aidlc/bin/resolve-starter-kit-path.sh
  # メタ開発: prompts/package/bin/resolve-starter-kit-path.sh
  ```
  `mode:GHQ` の場合のみ、`path:` 値からghq形式パスを構築（完成形: `ghq:github.com/[owner]/[repo]/prompts/setup-prompt.md`）。`mode:META_DEV` の場合はghq形式不要（同一リポジトリ内）。

**アップグレードモードの場合**: 既存の `[paths].setup_prompt` を保持（変更しない）

### 7.3 starter_kit_versionの更新【アップグレードモードのみ】

`docs/aidlc.toml` の `starter_kit_version` フィールドを最新バージョンに更新:

`docs/aidlc.toml` を開き、`starter_kit_version` の値を `[新バージョン]` に更新してください。

`starter_kit_version` フィールドが存在しない場合は、ファイル先頭に以下を追加:

```toml
starter_kit_version = "[新バージョン]"
```

**更新確認**:

更新後、以下のコマンドで正しく反映されたことを確認してください:

```bash
grep "^starter_kit_version" docs/aidlc.toml
```

期待される出力: `starter_kit_version = "[新バージョン]"`

正しく更新されていない場合は、手動で `docs/aidlc.toml` を編集してください。

### 7.4 設定マイグレーション【アップグレードモードのみ】

新しいバージョンで追加された設定セクションを既存の `docs/aidlc.toml` に追加し、廃止設定の移行も行います。

**マイグレーション実行**:

セクション8.1.1で判定した `[スターターキットパス]` を使用してスクリプトを実行:

```bash
[スターターキットパス]/prompts/package/bin/migrate-config.sh
```

**注意**: アップグレードモード（同期済み）の場合は `docs/aidlc/bin/migrate-config.sh` を使用。

出力例:
```text
mode:execute
config:docs/aidlc.toml
skip:not-found:rules.mcp_review
skip:already-exists:rules.reviewing
skip:already-exists:rules.worktree
skip:already-exists:rules.history
skip:already-exists:rules.backlog
skip:already-exists:rules.jj
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

旧形式の `docs/cycles/backlog.md` が存在する場合、新形式への移行を提案：

```bash
docs/aidlc/bin/migrate-backlog.sh --dry-run
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

**移行実行時**: ユーザーに確認後、`docs/aidlc/bin/migrate-backlog.sh` を実行

---

## 8. 共通ファイルの配置

### 8.1 ディレクトリ構造の作成

```bash
mkdir -p docs/aidlc/prompts
mkdir -p docs/aidlc/templates
```

### 8.1.1 スターターキットパスの判定【重要】

rsync実行前に、スターターキットパスを特定してください。

**環境判定**:

```bash
# スターターキットパス解決スクリプトを実行
# メタ開発モード: prompts/package/bin/resolve-starter-kit-path.sh
# アップグレードモード（同期済み）: docs/aidlc/bin/resolve-starter-kit-path.sh
# 初回セットアップ: [スターターキットパス]/prompts/package/bin/resolve-starter-kit-path.sh
```

出力例:
```text
path:.
mode:META_DEV
```

スクリプトの終了コードを確認し、`path:` の値を `[スターターキットパス]` として以降の手順で使用する。

- 終了コード0 + `mode:META_DEV`: メタ開発モード（`path:` は `.`）
- 終了コード0 + `mode:GHQ`: ghq経由で自動解決（`path:` は絶対パス）
- 終了コード1 + `mode:MANUAL_REQUIRED`: 自動解決失敗。ユーザーにスターターキットの絶対パスを確認する

**パス参照の読み替え**:

| 環境 | `[スターターキットパス]` の実際の値 |
|------|-----------------------------------|
| メタ開発 | `.`（カレントディレクトリ = プロジェクトルート） |
| 通常利用（ghq） | ghq rootからの自動解決パス |
| 通常利用（手動） | ユーザーに確認した絶対パス（例: `/path/to/ai-dlc-starter-kit`） |

**非ghq環境の場合**:

- ghqを使用していない環境では、スターターキットの絶対パスを手動で指定してください
- 例: `/path/to/ai-dlc-starter-kit`

**メタ開発時の注意**:

- rsync元とrsync先が同一リポジトリ内になる
- `prompts/package/` → `docs/aidlc/` への同期
- 変更は `prompts/package/` で行い、rsyncで `docs/aidlc/` に反映する

### 8.2 パッケージファイルの同期【重要: 削除確認必須】

スターターキットの `prompts/package/` ディレクトリから `docs/aidlc/` に同期。

**注意**: 以下のコマンド例で使用する `[スターターキットパス]` は、セクション8.1.1で判定したパスに置き換えてください。メタ開発環境の場合は `.`（カレントディレクトリ）になります。

**移行モード・アップグレードモード共通**:
rsync実行前に**必ず**削除対象ファイルを確認し、ユーザーの承認を得てください。

**重要**:
- rsync で完全同期（差分のみ更新、不要ファイル削除）
- プロジェクト固有のファイルは別途処理

**同期スクリプト**:

各ディレクトリの同期には `sync-package.sh` を使用します。
- メタ開発モード: `prompts/package/bin/sync-package.sh`
- アップグレードモード（同期済み）: `docs/aidlc/bin/sync-package.sh`
- 初回セットアップ: `[スターターキットパス]/prompts/package/bin/sync-package.sh`

**同期対象ディレクトリ一覧**:

| # | ソース | 宛先 | 内容 |
|---|--------|------|------|
| 1 | `[スターターキットパス]/prompts/package/prompts/` | `docs/aidlc/prompts/` | フェーズプロンプト |
| 2 | `[スターターキットパス]/prompts/package/templates/` | `docs/aidlc/templates/` | ドキュメントテンプレート |
| 3 | `[スターターキットパス]/prompts/package/guides/` | `docs/aidlc/guides/` | ガイド |
| 4 | `[スターターキットパス]/prompts/package/bin/` | `docs/aidlc/bin/` | スクリプト |
| 5 | `[スターターキットパス]/prompts/package/skills/` | `docs/aidlc/skills/` | スキルファイル |
| 6 | `[スターターキットパス]/prompts/package/kiro/` | `docs/aidlc/kiro/` | KiroCLIエージェント設定 |

**各ディレクトリの同期手順**（全ディレクトリ共通）:

1. 宛先ディレクトリが存在しない場合は作成:
```bash
mkdir -p [宛先ディレクトリ]
```

2. ドライランで削除対象を確認:
```bash
sync-package.sh --source [ソース] --dest [宛先] --delete --dry-run
```

3. 出力を確認:

出力例:
```text
sync:dry-run
source:[ソース]/
destination:[宛先]/
sync_deleted:old-file.md
sync_updated:construction.md
sync_added:new-feature.md
```

| プレフィックス | 意味 |
|-------------|------|
| `sync_deleted:<file>` | 削除されるファイル |
| `sync_updated:<file>` | 更新されるファイル |
| `sync_added:<file>` | 新規追加されるファイル |

4. `sync_deleted:` 行がある場合、削除対象をユーザーに表示し確認:

```text
警告: 以下のファイルが削除されます：

[sync_deleted: のファイル一覧]

これらはスターターキットに存在しないファイルです。
プロジェクト固有のカスタマイズが含まれている可能性があります。

選択してください:
1. 削除して同期する（スターターキットと完全同期）
2. 削除せずに同期する（--deleteオプションなし）
3. 同期をキャンセルする

どれを選択しますか？
```

5. 選択に応じた実行:
- 1: `sync-package.sh --source [ソース] --dest [宛先] --delete`
- 2: `sync-package.sh --source [ソース] --dest [宛先]`
- 3: 同期をスキップし、手動対応を案内

6. `sync_deleted:` 行がない場合は削除なしで直接実行:
```bash
sync-package.sh --source [ソース] --dest [宛先] --delete
```

**変更要約の表示【アップグレードモードのみ】**:

同期実行後、出力の `sync_updated:` と `sync_added:` 行をまとめて要約表示する。

表示例:
```text
[prompts] 更新されたファイル:
  - construction.md（更新）
  - lite/operations.md（更新）
  - new-prompt.md（新規）
```

#### 8.2.3 プロジェクト固有ファイル（初回のみコピー / 参照行追記）

以下のファイルはプロジェクト固有の設定を含むため、**既に存在する場合はコピーしない**:

| ファイル | 説明 |
|--------|------|
| `docs/cycles/rules.md` | プロジェクト固有の追加ルール |
| `docs/cycles/operations.md` | サイクル横断の運用引き継ぎ情報 |
| `AGENTS.md` | AIツール共通設定（参照行を追記） |
| `CLAUDE.md` | Claude Code専用設定（参照行を追記） |

**存在確認後にコピー**:
```bash
# rules.md が存在しない場合のみコピー
if [ ! -f docs/cycles/rules.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/rules_template.md docs/cycles/rules.md
fi

# operations.md が存在しない場合のみコピー
if [ ! -f docs/cycles/operations.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/operations_handover_template.md docs/cycles/operations.md
fi
```

**AGENTS.md / CLAUDE.md の処理（参照行追記）**:

AGENTS.mdとCLAUDE.mdは、AI-DLC設定ファイルへの参照を追記します。
参照先ファイル（`docs/aidlc/prompts/AGENTS.md`, `docs/aidlc/prompts/CLAUDE.md`）はrsyncで同期されるため、常に最新の設定が適用されます。

**AGENTS.md の処理（全AIツール共通）**:

AGENTS.mdが存在しない場合は新規作成する:

```bash
if [ ! -f AGENTS.md ]; then
  cat > AGENTS.md << 'EOF'
# AGENTS.md

@docs/aidlc/prompts/AGENTS.md を参照してください。
EOF
  echo "Created: AGENTS.md"
fi
```

AGENTS.mdが既に存在し、参照行がない場合は先頭に追記する:

1. Bashツールで追記が必要か確認する: `grep -q "@docs/aidlc/prompts/AGENTS.md" AGENTS.md || echo "NEEDS_UPDATE"`
2. 追記が必要な場合、Bashツールで `mktemp` を実行してパスを取得する
3. 以下のコマンドで先頭に追記する（`<パス>` は取得したパスに置換）:

```bash
echo "@docs/aidlc/prompts/AGENTS.md を参照してください。" > "<パス>" && echo "" >> "<パス>" && cat AGENTS.md >> "<パス>" && \mv "<パス>" AGENTS.md && echo "Added reference to AGENTS.md"
```

**CLAUDE.md の処理（Claude Code専用）**:

CLAUDE.mdが存在しない場合は新規作成する:

```bash
if [ ! -f CLAUDE.md ]; then
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

@AGENTS.md を参照してください。
@docs/aidlc/prompts/CLAUDE.md を参照してください。
EOF
  echo "Created: CLAUDE.md"
fi
```

CLAUDE.mdが既に存在する場合、以下の参照行を逆順で先頭に追記する（最終的に `@AGENTS.md` → `@CLAUDE.md` の順になる）:

1. `@docs/aidlc/prompts/CLAUDE.md` 参照の追記:
   - Bashツールで追記が必要か確認する: `grep -q "@docs/aidlc/prompts/CLAUDE.md" CLAUDE.md || echo "NEEDS_UPDATE"`
   - 追記が必要な場合、Bashツールで `mktemp` を実行してパスを取得する
   - 以下のコマンドで先頭に追記する（`<パス>` は取得したパスに置換）:

   ```bash
   echo "@docs/aidlc/prompts/CLAUDE.md を参照してください。" > "<パス>" && echo "" >> "<パス>" && cat CLAUDE.md >> "<パス>" && \mv "<パス>" CLAUDE.md && echo "Added reference to CLAUDE.md: @docs/aidlc/prompts/CLAUDE.md"
   ```

2. `@AGENTS.md` 参照の追記（これが最上段になる）:
   - Bashツールで追記が必要か確認する: `grep -q "@AGENTS.md" CLAUDE.md || echo "NEEDS_UPDATE"`
   - 追記が必要な場合、Bashツールで `mktemp` を実行してパスを取得する
   - 以下のコマンドで先頭に追記する（`<パス>` は取得したパスに置換）:

   ```bash
   echo "@AGENTS.md を参照してください。" > "<パス>" && echo "" >> "<パス>" && cat CLAUDE.md >> "<パス>" && \mv "<パス>" CLAUDE.md && echo "Added reference to CLAUDE.md: @AGENTS.md"
   ```

#### 8.2.4 rsync出力例

```text
sending incremental file list
>fcst....... construction.md   # 内容が異なる → 更新
.f..t....... inception.md      # タイムスタンプのみ → スキップ（--checksumにより）

sent 1,234 bytes  received 56 bytes
```

**互換性**: rsync は macOS/Linux 共通でプリインストール済み

#### 8.2.5 GitHub Issueテンプレートのコピー

GitHub Issueテンプレートをプロジェクトにコピーします。

**ケース1: ディレクトリが存在しない場合**:

```bash
if [ ! -d ".github/ISSUE_TEMPLATE" ]; then
    mkdir -p .github/ISSUE_TEMPLATE
    cp [スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/
    echo "Created: .github/ISSUE_TEMPLATE/ with backlog.yml, bug.yml, feature.yml, feedback.yml"
fi
```

**ケース2: ディレクトリが存在する場合（差分確認）**:

差分を確認し、変更がある場合のみユーザーに確認を求める:

```bash
# 差分確認
DIFF_FILES=""
NEW_FILES=""
for file in backlog.yml bug.yml feature.yml feedback.yml; do
    SOURCE="[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file"
    TARGET=".github/ISSUE_TEMPLATE/$file"
    if [ -f "$SOURCE" ]; then
        if [ -f "$TARGET" ]; then
            # 既存ファイル: 差分確認
            if ! diff -q "$SOURCE" "$TARGET" >/dev/null 2>&1; then
                DIFF_FILES="${DIFF_FILES}${file} "
            fi
        else
            # 新規ファイル
            NEW_FILES="${NEW_FILES}${file} "
        fi
    fi
done

echo "Diff files: ${DIFF_FILES:-none}"
echo "New files: ${NEW_FILES:-none}"
```

**差分も新規ファイルもない場合**:

```text
Issueテンプレートに差分はありません。スキップします。
```

**差分または新規ファイルがある場合**:

以下のメッセージを表示しユーザーに選択を求める:

**差分のあるファイルがある場合**:

```text
以下のIssueテンプレートに変更があります：

差分のあるファイル: [DIFF_FILES]
新規ファイル: [NEW_FILES]（なければ省略）

選択してください:
1. 上書きする（推奨）
2. スキップする
3. 差分を確認してから決める

どれを選択しますか？
```

**新規ファイルのみの場合（DIFF_FILESが空）**:

```text
以下のIssueテンプレートを追加します：

新規ファイル: [NEW_FILES]

選択してください:
1. 追加する（推奨）
2. スキップする

どれを選択しますか？
```

- **選択1（上書き/追加）**: 差分のあるファイルと新規ファイルをコピー

  ```bash
  for file in $DIFF_FILES $NEW_FILES; do
      cp "[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file" ".github/ISSUE_TEMPLATE/"
      echo "Copied: $file"
  done
  ```

- **選択2（スキップ）**: 何もせず終了

- **選択3（差分確認）**【差分のあるファイルがある場合のみ表示】: 差分のあるファイルの詳細を表示

  ```bash
  for file in $DIFF_FILES; do
      echo "=== $file ==="
      diff "[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file" ".github/ISSUE_TEMPLATE/$file"
      echo ""
  done
  ```

  表示後、再度選択肢1または2を選択させる。

**結果報告**:

```text
GitHub Issueテンプレートの配置が完了しました：

| ファイル | 状態 |
|----------|------|
| backlog.yml | [新規作成 / 更新 / スキップ / 差分なし] |
| bug.yml | [新規作成 / 更新 / スキップ / 差分なし] |
| feature.yml | [新規作成 / 更新 / スキップ / 差分なし] |
| feedback.yml | [新規作成 / 更新 / スキップ / 差分なし] |
```

**注意**: Issue Formsはパブリック・プライベート両方のリポジトリで利用可能です。

#### 8.2.6 Issue用基本ラベルの作成【mode=issueまたはissue-onlyの場合のみ】

GitHub CLIが利用可能で、バックログモードがIssue駆動の場合、バックログ管理用の共通ラベルを作成します。

**前提条件**:
- `gh:available` であること
- `docs/aidlc.toml` の `[rules.backlog].mode` が `issue` または `issue-only` であること

**前提条件を満たさない場合**: このステップをスキップ。

**ラベル作成**:

```bash
[スターターキットパス]/prompts/setup/bin/init-labels.sh
```

**出力例**:

```text
label:backlog:created
label:type:feature:created
label:type:bugfix:exists
...
```

**注意**: 既存のラベルはスキップされます（冪等性あり）。

#### 8.2.7 AIツール設定のセットアップ【初回・アップグレード共通】

Claude CodeとKiroCLIの設定ファイルをセットアップします。

```bash
# スクリプトで実行
docs/aidlc/bin/setup-ai-tools.sh
```

このスクリプトは以下を行います:

1. **Claude Code スキル**: `.claude/skills/` に各スキルへのシンボリックリンクを配置
2. **KiroCLI スキル**: `.kiro/skills/` に各スキルへのシンボリックリンクを配置（Kiro標準スキル発見方式）
3. **KiroCLI エージェント**: `.kiro/agents/aidlc.json` へのシンボリックリンクを配置
4. **壊れたリンクの削除**: リンク先が存在しないシンボリックリンクを自動削除
5. **不正リンクの修復**: リンク先が異なるシンボリックリンクを自動修復

**ディレクトリ構成**:

```text
.claude/skills/                       ← 実ディレクトリ
├── reviewing-code/          → symlink → ../../docs/aidlc/skills/reviewing-code/
├── reviewing-architecture/  → symlink → ../../docs/aidlc/skills/reviewing-architecture/
├── reviewing-security/      → symlink → ../../docs/aidlc/skills/reviewing-security/
├── upgrading-aidlc/         → symlink → ../../docs/aidlc/skills/upgrading-aidlc/
├── versioning-with-jj/      → symlink → ../../docs/aidlc/skills/versioning-with-jj/
└── my-custom/  ← プロジェクト独自スキル（実ディレクトリ）

.kiro/skills/                         ← 実ディレクトリ
├── reviewing-code/          → symlink → ../../docs/aidlc/skills/reviewing-code/
├── reviewing-architecture/  → symlink → ../../docs/aidlc/skills/reviewing-architecture/
├── reviewing-security/      → symlink → ../../docs/aidlc/skills/reviewing-security/
├── upgrading-aidlc/         → symlink → ../../docs/aidlc/skills/upgrading-aidlc/
└── versioning-with-jj/      → symlink → ../../docs/aidlc/skills/versioning-with-jj/

.kiro/agents/
└── aidlc.json → symlink → ../../docs/aidlc/kiro/agents/aidlc.json
```

**注意**:

- `.claude/skills/` 内にプロジェクト独自スキルを追加できます。詳細は `docs/aidlc/guides/skill-usage-guide.md` を参照してください。
- `.kiro/skills/` にはKiroネイティブのスキル発見機能でスキルが自動認識されます。
- KiroCLI設定は `docs/aidlc/kiro/agents/aidlc.json` で管理され、アップグレード時に自動更新されます。
- スキル名が変更された場合、古いシンボリックリンクは自動的に削除されます。

**KiroCLI利用方法**:

```bash
# aidlcエージェントでKiroCLIを起動
kiro-cli --agent aidlc

# または起動後に切り替え
> /agent swap aidlc
```

### 8.3 同期対象のファイル一覧

rsync により以下のファイルが `docs/aidlc/` に同期されます:

**prompts/** → `docs/aidlc/prompts/`:
- inception.md, construction.md, operations.md, setup.md
- AGENTS.md, CLAUDE.md（AIツール設定）
- lite/inception.md, lite/construction.md, lite/operations.md

**templates/** → `docs/aidlc/templates/`:
- 各種テンプレートファイル（index.md含む）

**guides/** → `docs/aidlc/guides/`:
- ai-agent-allowlist.md（AIエージェント許可リストガイド）
- backlog-management.md（バックログ管理ガイド）

**skills/** → `docs/aidlc/skills/`:
- reviewing-code/SKILL.md, reviewing-architecture/SKILL.md, reviewing-security/SKILL.md（レビュースキル）
- upgrading-aidlc/SKILL.md（アップグレードスキル）、versioning-with-jj/SKILL.md（jjスキル）

**注意**: バージョン情報は `docs/aidlc.toml` の `starter_kit_version` フィールドで管理します。`version.txt` は作成しません。

---

## 9. Git コミット

セットアップで作成・更新したすべてのファイルをコミット:

```bash
git add docs/aidlc.toml docs/aidlc/ docs/cycles/rules.md docs/cycles/operations.md AGENTS.md CLAUDE.md .github/
# .claude/skills ディレクトリが作成されている場合のみ追加
[ -d ".claude/skills" ] && git add .claude/
# .kiro/agents/aidlc.json が作成されている場合のみ追加
[ -f ".kiro/agents/aidlc.json" ] && git add .kiro/
```

**コミットメッセージ**（モードに応じて選択）:
- **初回**: `git commit -m "feat: AI-DLC初回セットアップ完了"`
- **アップグレード**: `git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"`
- **移行**: `git commit -m "chore: AI-DLC新ファイル構成に移行"`

---

## 10. 完了メッセージと次のステップ

### 初回セットアップの場合

```text
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

プロジェクト設定:
- docs/aidlc.toml - プロジェクト設定

共通ファイル（docs/aidlc/）:
- prompts/inception.md - Inception Phase プロンプト
- prompts/construction.md - Construction Phase プロンプト
- prompts/operations.md - Operations Phase プロンプト
- prompts/setup.md - サイクルセットアップ プロンプト
- templates/ - ドキュメントテンプレート
- skills/ - AIスキルファイル（reviewing-code, reviewing-architecture, reviewing-security, upgrading-aidlc, versioning-with-jj）
- kiro/agents/ - KiroCLIエージェント設定

プロジェクト固有ファイル（docs/cycles/）:
- rules.md - プロジェクト固有ルール
- operations.md - 運用引き継ぎ情報

AIツール設定ファイル（プロジェクトルート）:
- AGENTS.md - 全AIツール共通（AI-DLC設定を参照）
- CLAUDE.md - Claude Code専用（AI-DLC設定を参照）
- .claude/skills/ - スキルディレクトリ（各スキルへのシンボリックリンク + 独自スキル用）
- .kiro/skills/ - KiroCLIスキルディレクトリ（各スキルへのシンボリックリンク）
- .kiro/agents/aidlc.json - KiroCLIエージェント設定（シンボリックリンク）

GitHub Issueテンプレート（.github/ISSUE_TEMPLATE/）:
- backlog.yml - バックログ用テンプレート
- bug.yml - バグ報告用テンプレート
- feature.yml - 機能要望用テンプレート
- feedback.yml - フィードバック用テンプレート

### AIエージェント許可リストの設定（オプション）

AI-DLCではファイル操作やGitコマンドを多用します。
毎回の確認を減らすため、許可リストまたはsandbox環境の設定を推奨します。

詳細は docs/aidlc/guides/ai-agent-allowlist.md を参照してください。

### ユーザー共通設定（オプション）

複数のAI-DLCプロジェクトで共通設定を使用したい場合:
1. ディレクトリ作成: mkdir -p ~/.aidlc
2. 設定ファイル作成: touch ~/.aidlc/config.toml
3. 共通設定を記述

詳細は docs/aidlc/guides/config-merge.md を参照してください。
```

### アップグレードの場合

```text
AI-DLCのアップグレードが完了しました！

更新されたファイル:
- docs/aidlc/prompts/ - フェーズプロンプト
- docs/aidlc/templates/ - ドキュメントテンプレート

※ docs/aidlc.toml は保持されています（変更なし）

---
**セットアップは完了です。このセッションはここで終了してください。**

新しいセッションで「start inception」と指示し、サイクルを開始してください。
```

**重要**: アップグレード完了後は、自動で `inception.md` を読み込まないでください。ユーザーが新しいセッションで明示的に開始するまで待機してください。

### 移行の場合

```text
AI-DLCの新ファイル構成への移行が完了しました！

移行されたファイル:
| 移行元 | 移行先 |
|--------|--------|
| docs/aidlc/project.toml | docs/aidlc.toml |
| docs/aidlc/prompts/additional-rules.md | docs/cycles/rules.md |
| docs/aidlc/version.txt | （削除: aidlc.toml に統合） |

これにより、docs/aidlc/ ディレクトリはスターターキットと完全同期可能になりました。
```

---

## 次のステップ: サイクル開始

**注意**: このセクションは初回セットアップ・移行の場合のみ表示してください。
- **ケースB（バージョン同じ）**: このセクションは表示せず、自動で `inception.md` を読み込む
- **ケースC（アップグレード完了後）**: 上記「アップグレードの場合」のメッセージを表示し、セッションを終了する

### 初回セットアップ・移行の場合

セットアップが完了しました。新しいセッションで「start inception」と指示し、サイクルを開始してください。

---

## AI-DLC 概要

AI-DLC（AI-Driven Development Lifecycle）は、AIを開発の中心に据えた新しい開発手法です。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **短サイクル反復**: 各フェーズを短いサイクルで反復

**3つのフェーズ**:
1. **Inception**: 要件定義、ユーザーストーリー作成、Unit分解
2. **Construction**: 設計、実装、テスト
3. **Operations**: デプロイ、監視、運用
