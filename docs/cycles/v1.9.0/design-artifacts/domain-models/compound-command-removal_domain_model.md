# ドメインモデル: 複合コマンド廃止

## 概要

プロンプト内の複合コマンドを単純コマンドに変換するパターンを定義する。AIがReadツールで設定を直接読み取り、出力を解釈する方式へ移行する。

**重要**: このドメインモデル設計では**コードは書かず**、変換パターンの構造と責務の定義のみを行います。

## 変換パターン（Entity相当）

### Pattern1: ファイル/ディレクトリ存在チェック

- **ID**: file-existence-check
- **現状パターン**:
  - `[ -f file ] && echo "EXISTS" || echo "NOT_EXISTS"`
  - `ls dir/ 2>/dev/null && echo "EXISTS" || echo "NOT_EXISTS"`
- **変換後**:
  - ファイル: `ls path 2>/dev/null`
  - ディレクトリ: `ls -d path 2>/dev/null`（空ディレクトリでもパス名を出力）
- **AIの責務**: 出力の有無で存在を判定
- **判定基準**: 出力があれば存在、stderrにエラーまたは出力なしなら不存在

### Pattern2: ブランチ/参照存在チェック

- **ID**: branch-existence-check
- **現状パターン**:
  - `git show-ref --verify --quiet "refs/heads/branch" && echo "EXISTS" || echo "NOT_EXISTS"`
- **変換後**:
  - `git show-ref --verify "refs/heads/branch" 2>/dev/null`
- **AIの責務**: 出力の有無で存在を判定
- **DEFAULT_BRANCH判定時**: `git remote show origin` でHEADブランチを取得後、`git show-ref --verify "refs/remotes/origin/{branch}"` で存在確認。main不存在時はmasterを試行

### Pattern3: 設定値読み取り（変数代入）

- **ID**: config-value-read
- **現状パターン**:
  - `VAR=$(cat file | dasel ... | tr ... || echo "default")`
  - `[ -z "$VAR" ] && VAR="default"`
- **変換後**:
  - AIがReadツールで `docs/aidlc.toml` を直接読み取り
  - TOML構造を解析して値を取得
  - 未設定時はデフォルト値を使用
- **AIの責務**: ファイル読み取り、TOML解析、デフォルト値適用
- **フォールバック規則**:
  - ファイル未存在: デフォルト値を使用
  - ファイル読み取りエラー: デフォルト値を使用
  - TOML構文エラー: ユーザーに警告し、デフォルト値を使用
  - 値未設定: デフォルト値を使用

### Pattern4: コマンド出力処理（パイプチェーン）

- **ID**: command-output-processing
- **現状パターン**:
  - `cmd1 | cmd2 | cmd3`
  - `$(cmd1) | grep ...`
- **変換後**:
  - 単純コマンド実行
  - AIが出力を解釈・処理
  - ファイル検索は Claude Code の Glob ツールを使用（`find` コマンドの代替）
- **AIの責務**: コマンド出力の解釈、必要な情報の抽出
- **バージョンソート**: `ls -d docs/cycles/*/` の出力をAIがセマンティックバージョン順（v1.9 < v1.10）で判定

### Pattern5: 条件付きgitコミット

- **ID**: conditional-git-commit
- **現状パターン**:
  - `[ -n "$(git status --porcelain)" ] && git add -A && git commit -m "..."`
- **変換後**:
  - `git status --porcelain`
  - AIが出力を確認
  - 変更がある場合: `git add -A` → `git commit -m "..."`
- **AIの責務**: git status出力の解釈、条件に応じた後続コマンド実行

### Pattern6: フォールバック付きバージョン取得

- **ID**: version-fetch-with-fallback
- **現状パターン**:
  - `$(curl ... || echo "")`
- **変換後**:
  - `curl -s --max-time 5 URL 2>/dev/null`
  - AIがエラー時は空として扱う
- **AIの責務**: curlの成功/失敗判定、エラー時のフォールバック処理

## 変換ルール（Value Object相当）

### DefaultValue

- **属性**:
  - setting_path: String - 設定のパス（例: `project.type`）
  - default_value: String - デフォルト値（例: `"general"`）
- **適用条件**: 設定値が未設定または取得失敗時

### CommandReplacement

- **属性**:
  - original: String - 変換前のコマンドパターン
  - simplified: String - 変換後の単純コマンド
  - ai_responsibility: String - AIが担う解釈責務

## 対象ファイルと変換箇所（Aggregate相当）

### PromptFileGroup

- **集約ルート**: ファイルパス
- **含まれる要素**: 各パターンの出現箇所
- **境界**: 1ファイル単位で変換を完結させる

| ファイル | Pattern1 | Pattern2 | Pattern3 | Pattern4 | Pattern5 | Pattern6 |
|----------|----------|----------|----------|----------|----------|----------|
| operations.md | 2 | 1 | 4 | 3 | - | - |
| setup.md | 4 | 2 | 2 | 2 | - | 1 |
| inception.md | 2 | - | 2 | 1 | - | - |
| construction.md | 1 | - | - | - | - | - |
| review-flow.md | - | - | - | - | 4 | - |
| backlog-management.md | - | - | 1 | - | - | - |

## ドメインサービス

### CommandSimplificationService

- **責務**: 複合コマンドを単純コマンドに変換
- **操作**:
  - identifyPattern(command) - コマンドパターンの特定
  - transform(command, pattern) - パターンに基づく変換
  - updateDescription(context) - 周辺の説明文の調整

## ユビキタス言語

- **複合コマンド**: `&&`, `||`, `|`, `$(...)` を含むシェルコマンド
- **単純コマンド**: 上記を含まない、単一の実行可能コマンド（リダイレクト `2>/dev/null` は許容）
- **AIの解釈責務**: コマンド出力を元に、AIが判断・処理を行う役割
- **フォールバック**: エラー時に使用するデフォルト値または代替処理

## 終了コード/stderrの扱いルール

AIがコマンド実行結果を判定する際の規則:

| 状況 | stdout | stderr/exit | AIの判断 |
|------|--------|-------------|----------|
| 成功・存在 | あり | なし/0 | 存在・成功 |
| 失敗・不存在 | なし | あり/非0 | 不存在・失敗 |
| 成功・空結果 | なし | なし/0 | 成功だが結果なし（空ディレクトリ等） |

**注意**: `2>/dev/null` でstderrを抑制している場合、Bashツールの終了コードで失敗を判定

## 不明点と質問

なし（Unit定義と計画で方針確定済み）
