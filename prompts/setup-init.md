# AI-DLC 初回セットアップ / アップグレード

このファイルはプロジェクトへの AI-DLC 初回導入、またはアップグレードを行います。

**前提**: setup-prompt.md から誘導されてこのファイルを読み込んでいること

---

## 1. モード判定

以下のコマンドで現在の状態を確認してください:

```bash
ls docs/aidlc/project.toml 2>/dev/null && echo "UPGRADE_MODE" || echo "INITIAL_MODE"
```

| 結果 | モード | 説明 |
|------|--------|------|
| INITIAL_MODE | 初回セットアップ | project.toml を新規作成 |
| UPGRADE_MODE | アップグレード | project.toml を保持、プロンプト・テンプレートのみ更新 |

**アップグレードモードの場合**: セクション 3（プロジェクト情報の収集）と 4（project.toml の生成）をスキップしてください。

---

## 2. スターターキットのバージョン確認

このファイル（setup-init.md）のディレクトリから `../version.txt` を読み込み、スターターキットのバージョンを確認してください。

---

## 3. Git環境の確認

### 3.1 Gitリポジトリの確認

```bash
git rev-parse --git-dir 2>/dev/null && echo "GIT_REPO" || echo "NOT_GIT_REPO"
```

**Gitリポジトリでない場合**:
- 警告を表示: 「このディレクトリはGitリポジトリではありません」
- `git init` での初期化を提案
- ユーザーに「初期化する / バージョン管理なしで続行」を選択させる

### 3.2 現在のブランチ確認

Gitリポジトリの場合:

```bash
git branch --show-current
```

---

## 4. プロジェクト情報の収集【初回のみ】

ユーザーとの対話で以下の情報を収集してください。**一問一答形式**で質問します。

**重要**: デフォルト値がある場合、ユーザーが「OK」「はい」「デフォルトで」などと答えた場合は、デフォルト値を採用して次に進んでください。すべての質問に対して「全部デフォルトで」と言われた場合は、残りの質問をスキップしてデフォルト値を採用してください。

### 4.1 基本情報

#### 質問 1: プロジェクト名
```
プロジェクト名: [リポジトリ名 or ディレクトリ名]

このプロジェクト名でよろしいですか？（変更する場合は新しい名前を入力）
```

#### 質問 2: プロジェクト概要
```
プロジェクトの概要を1-2文で入力してください（スキップする場合は「スキップ」）:
```

### 4.2 技術スタック（任意）

#### 質問 3: 使用言語
```
使用する言語を入力してください（カンマ区切り、例: TypeScript, Python）
スキップする場合は Enter:
```

#### 質問 4: フレームワーク
```
使用するフレームワークを入力してください（カンマ区切り、例: React, FastAPI）
スキップする場合は Enter:
```

### 4.3 開発ルール（任意）

#### 質問 5: 命名規則
```
命名規則を選択してください:
1. lowerCamelCase（デフォルト）
2. snake_case
3. その他（入力）
```

---

## 5. project.toml の生成【初回のみ】

収集した情報を元に `docs/aidlc/project.toml` を生成します。

### 5.1 ディレクトリ作成

```bash
mkdir -p docs/aidlc
```

### 5.2 project.toml の内容

以下のテンプレートを使用し、収集した情報で置換してください:

```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]
# スターターキットバージョン: [version.txt の内容]

[project]
name = "[プロジェクト名]"
description = "[プロジェクト概要]"

[project.tech_stack]
languages = [[言語リスト]]
frameworks = [[フレームワークリスト]]
tools = ["Claude Code"]

[paths]
setup_prompt = "prompts/setup-prompt.md"
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

[rules.documentation]
language = "日本語"

[rules.custom]
# プロジェクト固有のカスタムルール
# 必要に応じて追記してください
```

---

## 6. 共通ファイルの配置

### 6.1 ディレクトリ構造の作成

```bash
mkdir -p docs/aidlc/prompts
mkdir -p docs/aidlc/templates
mkdir -p docs/aidlc/operations
```

### 6.2 パッケージファイルのコピー

スターターキットの `prompts/package/` ディレクトリから `docs/aidlc/` にコピー。

**重要**:
- プロジェクト固有のファイルは上書きしないこと
- **cp コマンドは `\cp -f` を使用**（macOS の alias をバイパスし、上書き確認プロンプトを回避）

#### 6.2.1 フェーズプロンプト（上書きOK）

| ソース | 出力先 |
|--------|--------|
| prompts/package/prompts/inception.md | docs/aidlc/prompts/inception.md |
| prompts/package/prompts/construction.md | docs/aidlc/prompts/construction.md |
| prompts/package/prompts/operations.md | docs/aidlc/prompts/operations.md |
| prompts/package/prompts/lite/ | docs/aidlc/prompts/lite/ |

これらのファイルは上書きして最新版に更新します。

**注意**: `lite/` ディレクトリはライト版プロンプト（簡易版）です。

#### 6.2.2 ドキュメントテンプレート（上書きOK）

| ソース | 出力先 |
|--------|--------|
| prompts/package/templates/ | docs/aidlc/templates/ |

テンプレートは上書きして最新版に更新します。

#### 6.2.3 プロジェクト固有ファイル（存在する場合はスキップ）

以下のファイルはプロジェクト固有の設定を含むため、**既に存在する場合はコピーしない**:

| ファイル | 説明 |
|--------|------|
| `docs/aidlc/prompts/additional-rules.md` | プロジェクト固有の追加ルール |

**コピー前に存在確認**:
```bash
# additional-rules.md が存在しない場合のみコピー
if [ ! -f docs/aidlc/prompts/additional-rules.md ]; then
  \cp -f [スターターキットパス]/prompts/package/prompts/additional-rules.md docs/aidlc/prompts/
fi
```

### 6.3 バージョンファイルの配置

```bash
\cp -f [スターターキットパス]/version.txt docs/aidlc/version.txt
```

### 6.4 その他の共通ファイル

以下のファイルもコピー:
- `docs/aidlc/templates/index.md` - テンプレート一覧

---

## 7. サイクル開始処理

初回セットアップ完了後、続けてサイクル開始処理を実行します。

### 7.1 サイクルバージョンの確認

```
最初のサイクルバージョンを入力してください（例: v1.0.0）:
```

### 7.2 ブランチの確認と整合性チェック

現在のブランチを確認し、サイクルバージョンとの整合性をチェック:

```bash
git branch --show-current
```

**整合性チェック**:
- 現在のブランチが `cycle/[バージョン]` または `feature/[バージョン]` パターンの場合、ブランチ名からバージョンを抽出
- 入力されたサイクルバージョンとブランチ名が異なる場合、警告を表示:

```
警告: サイクルバージョンとブランチ名が一致しません。

入力されたサイクル: [入力バージョン]
現在のブランチ: [ブランチ名]

どうしますか？
1. サイクルバージョンをブランチ名に合わせる（推奨）
2. 新しいブランチ cycle/[入力バージョン] を作成
3. 不一致のまま続行（非推奨）
```

**ブランチ操作**:
```
現在のブランチ: [ブランチ名]

サイクル用ブランチ cycle/[バージョン] を作成しますか？
1. 新しいブランチを作成して切り替える
2. 現在のブランチで続行する
```

### 7.3 サイクルディレクトリの作成

```bash
mkdir -p docs/cycles/[バージョン]/plans
mkdir -p docs/cycles/[バージョン]/requirements
mkdir -p docs/cycles/[バージョン]/story-artifacts/units
mkdir -p docs/cycles/[バージョン]/design-artifacts/domain-models
mkdir -p docs/cycles/[バージョン]/design-artifacts/logical-designs
mkdir -p docs/cycles/[バージョン]/design-artifacts/architecture
mkdir -p docs/cycles/[バージョン]/inception
mkdir -p docs/cycles/[バージョン]/construction/units
mkdir -p docs/cycles/[バージョン]/operations
```

各ディレクトリに `.gitkeep` を配置。

### 7.4 history.md の初期化

`docs/cycles/[バージョン]/history.md` を作成:

```markdown
# プロンプト実行履歴

## サイクル
[バージョン]

---

## [現在日時]

**フェーズ**: 準備
**実行内容**: AI-DLC環境セットアップ（初回）
**成果物**:
- docs/aidlc/project.toml
- docs/aidlc/prompts/（フェーズプロンプト）
- docs/aidlc/templates/（テンプレート）
- docs/cycles/[バージョン]/（サイクルディレクトリ）

---
```

---

## 8. Git コミット

セットアップで作成・更新したすべてのファイルをコミット:

```bash
git add docs/aidlc/ docs/cycles/
```

**コミットメッセージ**（モードに応じて選択）:
- **初回**: `git commit -m "feat: AI-DLC初回セットアップ完了"`
- **アップグレード**: `git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"`

---

## 9. 完了メッセージ

### 初回セットアップの場合

```
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

共通ファイル（docs/aidlc/）:
- project.toml - プロジェクト設定
- prompts/inception.md - Inception Phase プロンプト
- prompts/construction.md - Construction Phase プロンプト
- prompts/operations.md - Operations Phase プロンプト
- templates/ - ドキュメントテンプレート
- version.txt - スターターキットバージョン

サイクル固有ファイル（docs/cycles/[バージョン]/）:
- history.md - 実行履歴
- 各種ディレクトリ
```

### アップグレードの場合

```
AI-DLCのアップグレードが完了しました！

更新されたファイル:
- prompts/ - フェーズプロンプト
- templates/ - ドキュメントテンプレート
- version.txt - スターターキットバージョン

※ project.toml は保持されています（変更なし）

サイクル固有ファイル（docs/cycles/[バージョン]/）:
- history.md - 実行履歴
- 各種ディレクトリ
```

---

## 次のステップ: Inception Phase の開始

新しいセッションで以下を実行してください：

```
以下のファイルを読み込んで、サイクル [バージョン] の Inception Phase を開始してください：
docs/aidlc/prompts/inception.md
```
