# AI-DLC 初回セットアップ / アップグレード

このファイルはプロジェクトへの AI-DLC 初回導入、またはアップグレードを行います。

**前提**: setup-prompt.md から誘導されてこのファイルを読み込んでいること

---

## 1. モード判定

以下のコマンドで現在の状態を確認してください:

```bash
# 新形式（aidlc.toml）または旧形式（project.toml）の存在確認
ls docs/aidlc.toml 2>/dev/null && echo "UPGRADE_MODE" || \
  (ls docs/aidlc/project.toml 2>/dev/null && echo "MIGRATION_MODE" || echo "INITIAL_MODE")
```

| 結果 | モード | 説明 |
|------|--------|------|
| INITIAL_MODE | 初回セットアップ | aidlc.toml を新規作成 |
| UPGRADE_MODE | アップグレード | aidlc.toml を保持、プロンプト・テンプレートのみ更新 |
| MIGRATION_MODE | 移行 + アップグレード | 旧形式から新形式に移行後、アップグレード |

**アップグレードモードの場合**: セクション 4（プロジェクト情報の収集）と 5（aidlc.toml の生成）をスキップしてください。

**移行モードの場合**: セクション 3（ファイル移行）を実行後、アップグレードモードと同様に進めてください。

---

## 2. スターターキットのバージョン確認

このファイル（setup-init.md）のディレクトリから `../version.txt` を読み込み、スターターキットのバージョンを確認してください。

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

```
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

README.mdからプロジェクト情報を推測し、まとめて確認します。

### 5.1 README.mdの読み込み

README.mdが存在する場合、内容を読み込んで以下の情報を推測します：
- プロジェクト名（READMEのタイトル `# xxx` またはディレクトリ名）
- プロジェクト概要（READMEの冒頭部分）
- 使用言語（READMEに記載があれば）
- フレームワーク（READMEに記載があれば）

README.mdが存在しない場合は、ディレクトリ名をプロジェクト名として使用します。

### 5.2 推測結果の確認

推測した情報をテーブル形式で表示し、ユーザーに確認を求めます：

```
プロジェクト情報を推測しました：

| 項目 | 推測値 |
|------|--------|
| プロジェクト名 | [推測値] |
| プロジェクト概要 | [推測値 or 「-」] |
| 使用言語 | [推測値 or 「-」] |
| フレームワーク | [推測値 or 「-」] |
| 命名規則 | lowerCamelCase（デフォルト） |

上記の内容で問題ありませんか？変更したい項目があれば教えてください。
```

**応答パターン**:
- 「OK」「はい」「問題ない」→ 推測値を採用し、次のステップへ
- 変更がある場合 → 指定された項目のみ更新

### 5.3 推測できなかった項目の入力

推測値が「-」の項目について、必要に応じて個別に質問します：

```
[項目名]が推測できませんでした。入力してください（スキップする場合は「スキップ」）:
```

**注意**: すべての項目はスキップ可能です。後から `docs/aidlc.toml` を直接編集することもできます。

---

## 6. aidlc.toml の生成【初回のみ】

収集した情報を元に `docs/aidlc.toml` を生成します。

### 6.1 ディレクトリ作成

```bash
mkdir -p docs/aidlc
mkdir -p docs/cycles
```

### 6.2 aidlc.toml の内容

以下のテンプレートを使用し、収集した情報で置換してください:

```toml
# AI-DLC プロジェクト設定
# 生成日: [現在日時]

starter_kit_version = "[version.txt の内容]"

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

[rules.mcp_review]
# MCPレビュー設定
# mode: "recommend" | "required" | "disabled"
# - recommend: MCP利用可能時にレビューを推奨（デフォルト）
# - required: MCP利用可能時にレビュー必須
# - disabled: レビュー推奨を無効化
mode = "recommend"

[rules.worktree]
# git worktree設定
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false

[rules.custom]
# プロジェクト固有のカスタムルール
# 必要に応じて追記してください
```

### 6.3 starter_kit_versionの更新【アップグレードモードのみ】

`docs/aidlc.toml` の `starter_kit_version` フィールドを最新バージョンに更新:

```bash
# starter_kit_versionが存在するか確認
if grep -q "^starter_kit_version" docs/aidlc.toml; then
  # 存在する場合: 更新
  sed -i '' 's/^starter_kit_version = ".*"/starter_kit_version = "[新バージョン]"/' docs/aidlc.toml
else
  # 存在しない場合: ファイル先頭に追加
  sed -i '' '1i\
starter_kit_version = "[新バージョン]"\
' docs/aidlc.toml
fi
```

**更新確認**:

更新後、以下のコマンドで正しく反映されたことを確認してください:

```bash
grep "^starter_kit_version" docs/aidlc.toml
```

期待される出力: `starter_kit_version = "[新バージョン]"`

正しく更新されていない場合は、手動で `docs/aidlc.toml` を編集してください。

### 6.4 設定マイグレーション【アップグレードモードのみ】

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
```

**マイグレーション結果の確認**:

```bash
grep -A 5 "^\[rules.mcp_review\]" docs/aidlc.toml
grep -A 5 "^\[rules.worktree\]" docs/aidlc.toml
```

**注意**: 今後のバージョンで新しい設定セクションが追加された場合、このセクションにマイグレーションコマンドを追加してください。

---

## 7. 共通ファイルの配置

### 7.1 ディレクトリ構造の作成

```bash
mkdir -p docs/aidlc/prompts
mkdir -p docs/aidlc/templates
```

### 7.2 パッケージファイルの同期【重要: 削除確認必須】

スターターキットの `prompts/package/` ディレクトリから `docs/aidlc/` に同期。

**移行モード・アップグレードモード共通**:
rsync実行前に**必ず**削除対象ファイルを確認し、ユーザーの承認を得てください。

**手順**:
1. ドライランで削除対象を確認
2. `.gitkeep` 以外の削除対象があればユーザーに表示
3. ユーザー承認後に実際の同期を実行
4. 承認が得られない場合は `--delete` オプションなしで同期

**重要**:
- rsync で完全同期（差分のみ更新、不要ファイル削除）
- プロジェクト固有のファイルは別途処理

#### 7.2.1 フェーズプロンプトの同期（rsync）

**手順**:
1. まずドライランで削除対象を確認
2. 削除されるファイルがあればユーザーに確認
3. 承認後に実行

**削除対象の確認**:
```bash
# 削除対象を抽出（.gitkeep を除く）
rsync -avn --checksum --delete \
  [スターターキットパス]/prompts/package/prompts/ \
  docs/aidlc/prompts/ 2>&1 | grep "^deleting" | grep -v ".gitkeep"
```

**削除対象がある場合（.gitkeep以外）**:
```
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

**削除対象がない場合（または.gitkeepのみ）**:
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
- lite/ ディレクトリ（簡易版プロンプト）

#### 7.2.1.1 プロンプト変更要約の表示【アップグレードモードのみ】

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
```
更新されたプロンプト:
  - construction.md
  - lite/operations.md
```

#### 7.2.2 ドキュメントテンプレートの同期（rsync）

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

#### 7.2.2.1 テンプレート変更要約の表示【アップグレードモードのみ】

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
```
更新されたテンプレート:
  - unit_definition_template.md
  - implementation_record_template.md
```

#### 7.2.3 プロジェクト固有ファイル（初回のみコピー）

以下のファイルはプロジェクト固有の設定を含むため、**既に存在する場合はコピーしない**:

| ファイル | 説明 |
|--------|------|
| `docs/cycles/rules.md` | プロジェクト固有の追加ルール |
| `docs/cycles/operations.md` | サイクル横断の運用引き継ぎ情報 |

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

#### 7.2.4 rsync出力例

```
sending incremental file list
>fcst....... construction.md   # 内容が異なる → 更新
.f..t....... inception.md      # タイムスタンプのみ → スキップ（--checksumにより）

sent 1,234 bytes  received 56 bytes
```

**互換性**: rsync は macOS/Linux 共通でプリインストール済み

### 7.3 同期対象のファイル一覧

rsync により以下のファイルが同期されます:

**prompts/**:
- inception.md, construction.md, operations.md
- lite/inception.md, lite/construction.md, lite/operations.md

**templates/**:
- 各種テンプレートファイル（index.md含む）

**注意**: バージョン情報は `docs/aidlc.toml` の `starter_kit_version` フィールドで管理します。`version.txt` は作成しません。

---

## 8. Git コミット

セットアップで作成・更新したすべてのファイルをコミット:

```bash
git add docs/aidlc.toml docs/aidlc/ docs/cycles/rules.md docs/cycles/operations.md docs/cycles/backlog.md docs/cycles/backlog-completed.md
```

**コミットメッセージ**（モードに応じて選択）:
- **初回**: `git commit -m "feat: AI-DLC初回セットアップ完了"`
- **アップグレード**: `git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"`
- **移行**: `git commit -m "chore: AI-DLC新ファイル構成に移行"`

---

## 9. 完了メッセージ

### 初回セットアップの場合

```
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

プロジェクト設定:
- docs/aidlc.toml - プロジェクト設定

共通ファイル（docs/aidlc/）:
- prompts/inception.md - Inception Phase プロンプト
- prompts/construction.md - Construction Phase プロンプト
- prompts/operations.md - Operations Phase プロンプト
- templates/ - ドキュメントテンプレート

プロジェクト固有ファイル（docs/cycles/）:
- rules.md - プロジェクト固有ルール
- operations.md - 運用引き継ぎ情報
- backlog.md - 共通バックログ
- backlog-completed.md - 完了済みバックログ
```

### アップグレードの場合

```
AI-DLCのアップグレードが完了しました！

更新されたファイル:
- docs/aidlc/prompts/ - フェーズプロンプト
- docs/aidlc/templates/ - ドキュメントテンプレート

※ docs/aidlc.toml は保持されています（変更なし）
```

### 移行の場合

```
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

セットアップが完了しました。新しいセッションで以下を実行し、サイクルを開始してください：

```
以下のファイルを読み込んで、サイクルを開始してください：
[スターターキットのパス]/prompts/setup-cycle.md
```

**注意**: `[スターターキットのパス]` は AI-DLC Starter Kit のルートディレクトリに置き換えてください。
