# AI-DLC セットアップ

このファイルは AI-DLC セットアップのエントリーポイントです。
プロジェクトの状態を判定し、初回セットアップ、アップグレード、または移行を実行します。

---

## 共通ルール

- **予想禁止・一問一答質問ルール【重要】**: 不明点や判断に迷う点がある場合、予想や仮定で進めてはいけない。必ずユーザーに質問する。

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

# 通常利用の場合（ghq使用時）
$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup/bin/check-setup-type.sh
```

**出力例**:

```text
setup_type:cycle_start
```

**dasel未インストールの場合**（`setup_type:` と空値が返る場合）: AIは `docs/aidlc.toml` を読み込み、`starter_kit_version` の値を取得してください。また、このファイル（setup-prompt.md）のディレクトリから `../version.txt` を読み込み、スターターキットのバージョンと比較してください。

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
1. `docs/aidlc/prompts/setup.md` の存在を確認
2. 存在する場合: プロジェクト内の `docs/aidlc/prompts/setup.md` を読み込む
3. 存在しない場合: このファイル（setup-prompt.md）と同じディレクトリにある `package/prompts/setup.md` を読み込む

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
  1. `docs/aidlc/prompts/setup.md` の存在を確認
  2. 存在する場合: プロジェクト内の `docs/aidlc/prompts/setup.md` を読み込む
  3. 存在しない場合: このファイル（setup-prompt.md）と同じディレクトリにある `package/prompts/setup.md` を読み込む

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
1. `docs/aidlc/prompts/setup.md` の存在を確認
2. 存在する場合: プロジェクト内の `docs/aidlc/prompts/setup.md` を読み込む
3. 存在しない場合: このファイル（setup-prompt.md）と同じディレクトリにある `package/prompts/setup.md` を読み込む

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

### 7.2 aidlc.toml の内容

以下のテンプレートを使用し、収集した情報で置換してください:

```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]

starter_kit_version = "[version.txt の内容]"

[project]
name = "[プロジェクト名]"
description = "[プロジェクト概要]"
type = "[プロジェクトタイプ]"

[project.tech_stack]
languages = [[言語リスト]]
frameworks = [[フレームワークリスト]]
tools = ["Claude Code"]

[paths]
# セットアッププロンプトのパス（詳細は 7.2.1 参照）
setup_prompt = "[setup_prompt パス]"
aidlc_dir = "docs/aidlc"
cycles_dir = "docs/cycles"

[rules]
# 開発ルール

[rules.coding]
naming_convention = "[命名規則]"
# 追加のコーディングルールはここに記載

[rules.security]
validate_user_input = true
use_env_for_secrets = true

[rules.git]
# Git運用ルール
commit_on_unit_complete = true
commit_on_phase_complete = true

[rules.commit]
# コミット設定（v1.9.1で追加）
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"（推奨）または任意の文字列
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"

[rules.documentation]
language = "日本語"

[rules.mcp_review]
# MCPレビュー設定
# mode: "recommend" | "required" | "disabled"
# - recommend: MCP利用可能時にレビューを推奨（デフォルト）
# - required: MCP利用可能時にレビュー必須
# - disabled: レビュー推奨を無効化
mode = "recommend"
# ai_tools: AIレビューに使用するサービスのリスト（優先順位順）（v1.8.2で追加）
# - デフォルト: ["codex"]
# - 例: ["codex", "claude", "gemini"]
# - リスト順に利用可否を確認し、最初に利用可能なサービスを使用
ai_tools = ["codex"]

[rules.worktree]
# git worktree設定
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false

[rules.history]
# 履歴記録設定
# level: "detailed" | "standard" | "minimal"
# - detailed: ステップ完了時に記録 + 修正差分も記録
# - standard: ステップ完了時に記録（デフォルト）
# - minimal: Unit完了時にまとめて記録
level = "standard"

[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false

[rules.custom]
# プロジェクト固有のカスタムルール
# 必要に応じて追記してください

[backlog]
# バックログ管理モード設定
# mode: "git" | "issue" | "git-only" | "issue-only"
# - git: ローカルファイルがデフォルト、状況に応じてIssueも許容（デフォルト）
# - issue: GitHub Issueがデフォルト、状況に応じてローカルも許容
# - git-only: ローカルファイルのみ（Issueへの記録を禁止）
# - issue-only: GitHub Issueのみ（ローカルファイルへの記録を禁止）
mode = "git"
```

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
- 外部リポジトリの場合、以下のコマンドでghq形式パスを構築可能:
  ```bash
  # ghq root を取得
  GHQ_ROOT=$(ghq root)
  # スターターキットの相対パスを取得（ghq root からの相対パス）
  STARTER_KIT_PATH="github.com/[owner]/[repo]"
  # 完成形: ghq:github.com/[owner]/[repo]/prompts/setup-prompt.md
  ```

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

新しいバージョンで追加された設定セクションを既存の `docs/aidlc.toml` に追加します。

**マイグレーション対象の確認と追加**:

```bash
# [rules.mcp_review] セクションが存在しない場合は追加
if ! grep -q "^\[rules.mcp_review\]" docs/aidlc.toml; then
  echo "Adding [rules.mcp_review] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.mcp_review]
# MCPレビュー設定（v1.4.0で追加）
# mode: "recommend" | "required" | "disabled"
# - recommend: MCP利用可能時にレビューを推奨（デフォルト）
# - required: MCP利用可能時にレビュー必須
# - disabled: レビュー推奨を無効化
mode = "recommend"
EOF
  echo "Added [rules.mcp_review] section"
else
  echo "[rules.mcp_review] section already exists"
fi

# [rules.worktree] セクションが存在しない場合は追加
if ! grep -q "^\[rules.worktree\]" docs/aidlc.toml; then
  echo "Adding [rules.worktree] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.worktree]
# git worktree設定（v1.4.0で追加）
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false
EOF
  echo "Added [rules.worktree] section"
else
  echo "[rules.worktree] section already exists"
fi

# [rules.history] セクションが存在しない場合は追加
if ! grep -q "^\[rules.history\]" docs/aidlc.toml; then
  echo "Adding [rules.history] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.history]
# 履歴記録設定（v1.5.1で追加）
# level: "detailed" | "standard" | "minimal"
# - detailed: ステップ完了時に記録 + 修正差分も記録
# - standard: ステップ完了時に記録（デフォルト）
# - minimal: Unit完了時にまとめて記録
level = "standard"
EOF
  echo "Added [rules.history] section"
else
  echo "[rules.history] section already exists"
fi

# [backlog] セクションが存在しない場合は追加
if ! grep -q "^\[backlog\]" docs/aidlc.toml; then
  echo "Adding [backlog] section..."
  cat >> docs/aidlc.toml << 'EOF'

[backlog]
# バックログ管理モード設定（v1.7.0で追加）
# mode: "git" | "issue"
# - git: ローカルファイルに保存（従来方式、デフォルト）
# - issue: GitHub Issueに保存
mode = "git"
EOF
  echo "Added [backlog] section"
else
  echo "[backlog] section already exists"
fi

# [rules.jj] セクションが存在しない場合は追加
if ! grep -q "^\[rules.jj\]" docs/aidlc.toml; then
  echo "Adding [rules.jj] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
EOF
  echo "Added [rules.jj] section"
else
  echo "[rules.jj] section already exists"
fi

# [rules.linting] セクションが存在しない場合は追加
if ! grep -q "^\[rules.linting\]" docs/aidlc.toml; then
  echo "Adding [rules.linting] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.linting]
# markdownlint設定（v1.8.0で追加）
# markdown_lint: true | false
# - true: markdownlint を実行する
# - false: markdownlint をスキップする（デフォルト）
markdown_lint = false
EOF
  echo "Added [rules.linting] section"
else
  echo "[rules.linting] section already exists"
fi

# [rules.mcp_review] に ai_tools が存在しない場合は追加（v1.8.2で追加）
# セクション内での存在チェック: [rules.mcp_review]から次のセクションまでの範囲でai_toolsを検索
if grep -q "^\[rules.mcp_review\]" docs/aidlc.toml; then
  AI_TOOLS_IN_SECTION=$(sed -n '/^\[rules.mcp_review\]/,/^\[/p' docs/aidlc.toml | grep -c "^ai_tools" || echo "0")
  if [ "$AI_TOOLS_IN_SECTION" = "0" ]; then
    echo "Adding ai_tools to [rules.mcp_review] section..."
    # [rules.mcp_review] セクション内の mode = 行の後に追加
    sed -i '' '/^\[rules.mcp_review\]/,/^\[/ {
      /^\[rules.mcp_review\]/!{
        /^\[/!{
          /^mode = /a\
# ai_tools: AIレビューに使用するサービスのリスト（優先順位順）（v1.8.2で追加）\
# - デフォルト: ["codex"]\
# - 例: ["codex", "claude", "gemini"]\
# - リスト順に利用可否を確認し、最初に利用可能なサービスを使用\
ai_tools = ["codex"]
        }
      }
    }' docs/aidlc.toml 2>/dev/null || echo "Manual addition may be required"
    echo "Added ai_tools to [rules.mcp_review] section"
  else
    echo "ai_tools already exists in [rules.mcp_review] section"
  fi
else
  echo "[rules.mcp_review] section not found"
fi

# [rules.commit] セクションが存在しない場合は追加
if ! grep -q "^\[rules.commit\]" docs/aidlc.toml; then
  echo "Adding [rules.commit] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.commit]
# コミット設定（v1.9.1で追加）
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"（推奨）または任意の文字列
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"
EOF
  echo "Added [rules.commit] section"
else
  echo "[rules.commit] section already exists"
fi
```

**マイグレーション結果の確認**:

```bash
grep -A 5 "^\[rules.mcp_review\]" docs/aidlc.toml
grep -A 5 "^\[rules.worktree\]" docs/aidlc.toml
grep -A 5 "^\[backlog\]" docs/aidlc.toml
grep -A 5 "^\[rules.jj\]" docs/aidlc.toml
grep -A 5 "^\[rules.linting\]" docs/aidlc.toml
grep -A 5 "^\[rules.commit\]" docs/aidlc.toml
```

**注意**: 今後のバージョンで新しい設定セクションが追加された場合、このセクションにマイグレーションコマンドを追加してください。

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
# メタ開発環境の判定（prompts/package/ が存在するか）
if [ -d "prompts/package" ]; then
    echo "META_DEV_MODE"
    STARTER_KIT_PATH="."  # 同一リポジトリ内
elif command -v ghq >/dev/null 2>&1; then
    # ghq形式でパスを構築
    STARTER_KIT_PATH="$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit"
    # パスの存在確認
    if [ -d "${STARTER_KIT_PATH}/prompts/package" ]; then
        echo "NORMAL_MODE (ghq)"
    else
        echo "NORMAL_MODE (ghq path not found, fallback to manual)"
        STARTER_KIT_PATH=""
    fi
else
    echo "NORMAL_MODE (manual)"
    STARTER_KIT_PATH=""
fi

# パスが未設定の場合は手動入力
if [ -z "$STARTER_KIT_PATH" ]; then
    echo "スターターキットの絶対パスを入力してください:"
    echo "例: /path/to/ai-dlc-starter-kit"
    # ユーザー入力を待つ
fi
```

**パス参照の読み替え**:

| 環境 | `[スターターキットパス]` の実際の値 |
|------|-----------------------------------|
| メタ開発 | `.`（カレントディレクトリ = プロジェクトルート） |
| 通常利用（ghq） | `$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit` |
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

**手順**:
1. ドライランで削除対象を確認
2. 削除対象があればユーザーに表示
3. ユーザー承認後に実際の同期を実行
4. 承認が得られない場合は `--delete` オプションなしで同期

**重要**:
- rsync で完全同期（差分のみ更新、不要ファイル削除）
- プロジェクト固有のファイルは別途処理

#### 8.2.1 フェーズプロンプトの同期（rsync）

**手順**:
1. まずドライランで削除対象を確認
2. 削除されるファイルがあればユーザーに確認
3. 承認後に実行

**削除対象の確認**:
```bash
# 削除対象を抽出
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/prompts/ \
  docs/aidlc/prompts/ 2>&1 | grep "^deleting"
```

**削除対象がある場合**:
```text
警告: 以下のファイルが削除されます：

[削除対象のファイル一覧]

これらはスターターキットに存在しないファイルです。
プロジェクト固有のカスタマイズが含まれている可能性があります。

選択してください:
1. 削除して同期する（スターターキットと完全同期）
2. 削除せずに同期する（--deleteオプションなし）
3. 同期をキャンセルする

どれを選択しますか？
```

**選択に応じた処理**:
- 1: `rsync -av --checksum --delete ...` を実行
- 2: `rsync -av --checksum ...` を実行（--deleteなし）
- 3: 同期をスキップし、手動対応を案内

**削除対象がない場合**:
```bash
# 2. 実際の同期を実行
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/prompts/ \
  docs/aidlc/prompts/
```

| オプション | 説明 |
|-----------|------|
| `-av` | アーカイブモード + 詳細出力 |
| `-n` | ドライラン（実際には実行しない） |
| `--checksum` | ハッシュで比較、同一内容ならスキップ |
| `--delete` | コピー元にないファイルを削除 |

**同期対象**:
- inception.md, construction.md, operations.md
- setup.md
- lite/ ディレクトリ（簡易版プロンプト）

#### 8.2.1.1 プロンプト変更要約の表示【アップグレードモードのみ】

rsync実行後、更新されたファイルを要約表示：

```bash
# rsync出力から更新されたファイルを抽出（>f で始まる行が更新対象）
UPDATED_PROMPTS=$(rsync -avn --checksum \
  [スターターキットパス]/prompts/package/prompts/ \
  docs/aidlc/prompts/ 2>&1 | grep "^>f" | awk '{print $2}')

if [ -n "$UPDATED_PROMPTS" ]; then
  echo "更新されたプロンプト:"
  echo "$UPDATED_PROMPTS" | while read f; do echo "  - $f"; done
fi
```

**表示例**:
```text
更新されたプロンプト:
  - construction.md
  - lite/operations.md
```

#### 8.2.2 ドキュメントテンプレートの同期（rsync）

同様にドライラン → 確認 → 実行の手順で同期：

```bash
# 1. ドライランで削除対象を確認
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/templates/ \
  docs/aidlc/templates/ 2>&1 | grep "^deleting"

# 2. 承認後に実行
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/templates/ \
  docs/aidlc/templates/
```

テンプレートも同様に完全同期します。

#### 8.2.2.1 テンプレート変更要約の表示【アップグレードモードのみ】

rsync実行後、更新されたテンプレートを要約表示：

```bash
# rsync出力から更新されたファイルを抽出
UPDATED_TEMPLATES=$(rsync -avn --checksum \
  [スターターキットパス]/prompts/package/templates/ \
  docs/aidlc/templates/ 2>&1 | grep "^>f" | awk '{print $2}')

if [ -n "$UPDATED_TEMPLATES" ]; then
  echo "更新されたテンプレート:"
  echo "$UPDATED_TEMPLATES" | while read f; do echo "  - $f"; done
fi
```

**表示例**:
```text
更新されたテンプレート:
  - unit_definition_template.md
  - implementation_record_template.md
```

#### 8.2.2.2 ガイドの同期（rsync）

同様にドライラン → 確認 → 実行の手順で同期：

```bash
# 1. ドライランで削除対象を確認
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/guides/ \
  docs/aidlc/guides/ 2>&1 | grep "^deleting"

# 2. 承認後に実行
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/guides/ \
  docs/aidlc/guides/
```

ガイドも同様に完全同期します。

#### 8.2.2.3 スクリプトの同期（rsync）

同様にドライラン → 確認 → 実行の手順で同期：

```bash
# 1. ドライランで削除対象を確認
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/bin/ \
  docs/aidlc/bin/ 2>&1 | grep "^deleting"

# 2. 承認後に実行
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/bin/ \
  docs/aidlc/bin/
```

スクリプトも同様に完全同期します。

#### 8.2.2.4 スキルファイルの同期（rsync）

同様にドライラン → 確認 → 実行の手順で同期：

```bash
# 1. 宛先ディレクトリ作成
mkdir -p docs/aidlc/skills

# 2. ドライランで削除対象を確認
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/skills/ \
  docs/aidlc/skills/ 2>&1 | grep "^deleting"

# 3. 承認後に実行
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/skills/ \
  docs/aidlc/skills/
```

スキルファイル（AIエージェント拡張機能）も同様に完全同期します。

#### 8.2.2.5 KiroCLIエージェント設定の同期（rsync）

同様にドライラン → 確認 → 実行の手順で同期：

```bash
# 1. 宛先ディレクトリ作成
mkdir -p docs/aidlc/kiro/agents

# 2. ドライランで削除対象を確認
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/kiro/ \
  docs/aidlc/kiro/ 2>&1 | grep "^deleting"

# 3. 承認後に実行
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/kiro/ \
  docs/aidlc/kiro/
```

KiroCLIエージェント設定も同様に完全同期します。

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

```bash
# AGENTS.md の処理（全AIツール共通）
if [ ! -f AGENTS.md ]; then
  # 新規作成
  cat > AGENTS.md << 'EOF'
# AGENTS.md

@docs/aidlc/prompts/AGENTS.md を参照してください。
EOF
  echo "Created: AGENTS.md"
else
  # 参照行がなければ先頭に追記
  if ! grep -q "@docs/aidlc/prompts/AGENTS.md" AGENTS.md; then
    TEMP_FILE=$(mktemp)
    echo "@docs/aidlc/prompts/AGENTS.md を参照してください。" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    cat AGENTS.md >> "$TEMP_FILE"
    mv "$TEMP_FILE" AGENTS.md
    echo "Added reference to AGENTS.md: @docs/aidlc/prompts/AGENTS.md"
  fi
fi

# CLAUDE.md の処理（Claude Code専用）
if [ ! -f CLAUDE.md ]; then
  # 新規作成（AGENTS.md参照も含む）
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

@AGENTS.md を参照してください。
@docs/aidlc/prompts/CLAUDE.md を参照してください。
EOF
  echo "Created: CLAUDE.md"
else
  # 参照行を追記（順序: @AGENTS.md → @CLAUDE.md となるように逆順で先頭挿入）
  # 1. CLAUDE.md参照がなければ先頭に追記
  if ! grep -q "@docs/aidlc/prompts/CLAUDE.md" CLAUDE.md; then
    TEMP_FILE=$(mktemp)
    echo "@docs/aidlc/prompts/CLAUDE.md を参照してください。" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    cat CLAUDE.md >> "$TEMP_FILE"
    mv "$TEMP_FILE" CLAUDE.md
    echo "Added reference to CLAUDE.md: @docs/aidlc/prompts/CLAUDE.md"
  fi
  # 2. AGENTS.md参照がなければ先頭に追記（これが最上段になる）
  if ! grep -q "@AGENTS.md" CLAUDE.md; then
    TEMP_FILE=$(mktemp)
    echo "@AGENTS.md を参照してください。" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    cat CLAUDE.md >> "$TEMP_FILE"
    mv "$TEMP_FILE" CLAUDE.md
    echo "Added reference to CLAUDE.md: @AGENTS.md"
  fi
fi
```

**AIツール設定のセットアップ**:

Claude CodeとKiroCLIの設定ファイルをセットアップします。

```bash
# スクリプトで実行
docs/aidlc/bin/setup-ai-tools.sh
```

このスクリプトは以下を行います:

1. **Claude Code スキル**: `.claude/skills/` に各スキルへのシンボリックリンクを配置
2. **KiroCLI エージェント**: `.kiro/agents/aidlc.json` へのシンボリックリンクを配置

**ディレクトリ構成**:
```
.claude/skills/              ← 実ディレクトリ
├── codex/   → symlink → ../../docs/aidlc/skills/codex/
├── claude/  → symlink → ../../docs/aidlc/skills/claude/
├── gemini/  → symlink → ../../docs/aidlc/skills/gemini/
└── my-custom/  ← プロジェクト独自スキル（実ディレクトリ）

.kiro/agents/
└── aidlc.json → symlink → ../../docs/aidlc/kiro/agents/aidlc.json
```

**注意**:
- `.claude/skills/` 内にプロジェクト独自スキルを追加できます。詳細は `docs/aidlc/guides/skill-usage-guide.md` を参照してください。
- KiroCLI設定は `docs/aidlc/kiro/agents/aidlc.json` で管理され、アップグレード時に自動更新されます。

**KiroCLI利用方法**:
```bash
# aidlcエージェントでKiroCLIを起動
kiro-cli --agent aidlc

# または起動後に切り替え
> /agent swap aidlc
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

**状態確認**:
```bash
# .github/ISSUE_TEMPLATE/ の存在と内容確認
if [ -d ".github/ISSUE_TEMPLATE" ]; then
    echo "Existing Issue templates:"
    ls .github/ISSUE_TEMPLATE/
    echo "ISSUE_TEMPLATE_EXISTS"
else
    echo "ISSUE_TEMPLATE_NOT_EXISTS"
fi
```

**ケース1: ディレクトリが存在しない場合**:
```bash
mkdir -p .github/ISSUE_TEMPLATE
cp [スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/
echo "Created: .github/ISSUE_TEMPLATE/ with backlog.yml, bug.yml, feature.yml"
```

**ケース2: 同名ファイルが存在する場合**:

まず競合を確認:
```bash
CONFLICT_FILES=""
for file in backlog.yml bug.yml feature.yml; do
    if [ -f ".github/ISSUE_TEMPLATE/$file" ]; then
        CONFLICT_FILES="${CONFLICT_FILES}${file} "
    fi
done
echo "Conflict files: ${CONFLICT_FILES:-none}"
```

競合がある場合、以下のメッセージを表示しユーザーに選択を求める:
```text
警告: 以下のIssueテンプレートが既に存在します：

[競合ファイル一覧]

選択してください:
1. 上書きする（すべて置き換え）
2. スキップする（既存を保持、新規のみ追加）
3. 個別に確認する

どれを選択しますか？
```

- **選択1（上書き）**: `cp -f [スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/`
- **選択2（スキップ）**: 存在しないファイルのみコピー
- **選択3（個別確認）**: 競合ファイルごとに上書き/スキップを選択

**ケース3: 同名ファイルが存在しない場合**:
```bash
mkdir -p .github/ISSUE_TEMPLATE
for file in backlog.yml bug.yml feature.yml; do
    if [ ! -f ".github/ISSUE_TEMPLATE/$file" ]; then
        cp "[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file" ".github/ISSUE_TEMPLATE/"
        echo "Copied: $file"
    fi
done
```

**結果報告**:
```text
GitHub Issueテンプレートの配置が完了しました：

| ファイル | 状態 |
|----------|------|
| backlog.yml | [新規作成 / スキップ / 上書き] |
| bug.yml | [新規作成 / スキップ / 上書き] |
| feature.yml | [新規作成 / スキップ / 上書き] |
```

**注意**: Issue Formsはパブリック・プライベート両方のリポジトリで利用可能です。

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
- codex/SKILL.md, claude/SKILL.md, gemini/SKILL.md（AIスキルファイル）

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
- skills/ - AIスキルファイル（codex, claude, gemini）
- kiro/agents/ - KiroCLIエージェント設定

プロジェクト固有ファイル（docs/cycles/）:
- rules.md - プロジェクト固有ルール
- operations.md - 運用引き継ぎ情報

AIツール設定ファイル（プロジェクトルート）:
- AGENTS.md - 全AIツール共通（AI-DLC設定を参照）
- CLAUDE.md - Claude Code専用（AI-DLC設定を参照）
- .claude/skills/ - スキルディレクトリ（各スキルへのシンボリックリンク + 独自スキル用）
- .kiro/agents/aidlc.json - KiroCLIエージェント設定（シンボリックリンク）

GitHub Issueテンプレート（.github/ISSUE_TEMPLATE/）:
- backlog.yml - バックログ用テンプレート
- bug.yml - バグ報告用テンプレート
- feature.yml - 機能要望用テンプレート

### AIエージェント許可リストの設定（オプション）

AI-DLCではファイル操作やGitコマンドを多用します。
毎回の確認を減らすため、許可リストまたはsandbox環境の設定を推奨します。

詳細は docs/aidlc/guides/ai-agent-allowlist.md を参照してください。
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

新しいセッションで「start setup」と指示し、サイクルを開始してください。
```

**重要**: アップグレード完了後は、自動で `setup.md` を読み込まないでください。ユーザーが新しいセッションで明示的に開始するまで待機してください。

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
- **ケースB（バージョン同じ）**: このセクションは表示せず、自動で `setup.md` を読み込む
- **ケースC（アップグレード完了後）**: 上記「アップグレードの場合」のメッセージを表示し、セッションを終了する

### 初回セットアップ・移行の場合

セットアップが完了しました。新しいセッションで「start setup」と指示し、サイクルを開始してください。

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
