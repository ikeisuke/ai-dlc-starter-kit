# 論理設計: env-info-integration

## 概要

setup.mdの依存ツール確認セクションをenv-info.sh呼び出しに置き換えるための詳細設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（bash、Markdown等）はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

**パイプライン処理パターン**: スクリプト実行 → 出力解析 → 状態変換 → 結果表示

選定理由: bash処理の標準的なパターンであり、各ステップが独立しているため理解しやすい。

## コンポーネント構成

### プロンプト内のセクション構成

```text
setup.md
└── ステップ1: 依存コマンド確認
    ├── 1. スクリプト実行（env-info.sh呼び出し）
    ├── 2. 出力解析（grep + cut）
    ├── 3. 状態変換（case文）
    ├── 4. 結果表示（テーブル形式）
    └── 5. 警告表示（条件分岐）
```

### コンポーネント詳細

#### スクリプト実行

- **責務**: env-info.shを実行し、出力を取得
- **依存**: docs/aidlc/bin/env-info.sh
- **出力**: 4行のテキスト（tool:status形式）

#### 出力解析

- **責務**: env-info.shの出力から必要なツールの状態を抽出
- **入力**: env-info.shの出力（複数行テキスト）
- **出力**: GH_RAW, DASEL_RAW 変数（英語状態値）
- **処理**: grep + cut で行と値を抽出

#### 状態変換

- **責務**: Raw値（英語状態値）を表示値（日本語）に変換
- **入力**: Raw値（available, not-installed, not-authenticated, unknown/空/その他）
- **出力**: 表示値（利用可能, 未インストール, 未認証, 不明）
- **処理**: case文による変換（マッチしない場合は `unknown` → "不明"）

#### 結果表示

- **責務**: 状態をテーブル形式で表示
- **入力**: 日本語状態値
- **出力**: Markdownテーブル形式のテキスト

#### 警告表示

- **責務**: 必要に応じて警告メッセージを表示
- **判定条件**: GH_RAW != "available" OR DASEL_RAW != "available"（Raw値で判定）
- **出力**: 警告テキストブロック

## インターフェース設計

### env-info.sh 出力仕様（既存、参照のみ）

```text
gh:{status}
dasel:{status}
jj:{status}
git:{status}
```

statusの取りうる値:
- `available`: 利用可能
- `not-installed`: 未インストール
- `not-authenticated`: 未認証（ghのみ）

### 状態変換マッピング

| 入力（Raw値、英語） | 出力（表示値、日本語） | 警告対象 |
|---------------------|----------------------|---------|
| available | 利用可能 | No |
| not-installed | 未インストール | Yes |
| not-authenticated | 未認証 | Yes |
| unknown（空/欠落/その他） | 不明 | Yes |

**警告条件判定**: Raw値が `available` 以外の場合、警告対象とする。

### 結果表示フォーマット

```text
【依存コマンド確認】

以下のコマンドの状態を確認しました：

| コマンド | 状態 | 用途 |
|---------|------|------|
| gh | {GH_STATUS} | GitHub操作（PR作成、Issue管理） |
| dasel | {DASEL_STATUS} | 設定ファイル解析 |
```

### 警告表示フォーマット（条件付き）

表示条件: GH_RAW != "available" OR DASEL_RAW != "available"（Raw値で判定）

```text
⚠️ 一部のコマンドが利用できません。関連機能は制限されます：
- gh未使用時: ドラフトPR作成、Issue操作、ラベル作成がスキップされます
- dasel未使用時: AIが設定ファイルを直接読み取ります（機能上の影響なし）

インストール方法:
- gh: https://cli.github.com/
- dasel: https://github.com/TomWright/dasel
```

## 処理フロー概要

### 依存コマンド確認の処理フロー

**ステップ**:

1. env-info.sh を実行し、結果を ENV_INFO 変数に格納
2. ENV_INFO から gh の状態を抽出（grep "^gh:" | cut -d: -f2）
3. ENV_INFO から dasel の状態を抽出（grep "^dasel:" | cut -d: -f2）
4. 各状態値を日本語に変換（case文）
5. 結果テーブルを表示
6. 警告条件を判定し、必要なら警告を表示

**関与するコンポーネント**: スクリプト実行、出力解析、状態変換、結果表示、警告表示

## 非機能要件（NFR）への対応

Unit定義より、本Unitは非機能要件の対象外（セットアップ時の一回実行）。

## 技術選定

- **言語**: Bash（プロンプト内のコードブロック）
- **フレームワーク**: N/A
- **ライブラリ**: N/A（標準コマンドのみ使用: grep, cut, echo）
- **データベース**: N/A

## 実装上の注意事項

- env-info.shのパスは `docs/aidlc/bin/env-info.sh` を使用
- 出力解析でgrepの正規表現は `^tool:` 形式で行頭マッチ
- 状態変換のフォールバック値は「不明」（Raw値は `unknown`）
- 警告表示の条件判定はRaw値で行い、`available` 以外すべてを対象とする

### エラーハンドリング

env-info.sh実行失敗や出力欠落時の挙動：

1. **env-info.shが存在しない場合**: エラーメッセージを表示し、フォールバックとして旧ロジック（個別コマンド確認）を使用
2. **実行失敗（exit非0）の場合**: 同上、旧ロジックにフォールバック
3. **出力が空または期待形式でない場合**: 該当ツールの状態を `unknown` として扱い、警告対象とする

### 現行setup.mdの出力行について

現行setup.mdにある以下の行は削除する：

```bash
echo "gh: ${GH_STATUS}"
echo "dasel: ${DASEL_STATUS}"
```

理由: テーブル形式での結果表示に統一するため、個別のecho行は不要。

## 変更箇所の特定

### 変更前（現在のsetup.md ステップ1）

```bash
# ghの判定
if ! command -v gh >/dev/null 2>&1; then
  GH_STATUS="未インストール"
elif ! gh auth status >/dev/null 2>&1; then
  GH_STATUS="未認証"
else
  GH_STATUS="利用可能"
fi

# daselの判定
if command -v dasel >/dev/null 2>&1; then
  DASEL_STATUS="利用可能"
else
  DASEL_STATUS="未インストール"
fi

echo "gh: ${GH_STATUS}"
echo "dasel: ${DASEL_STATUS}"
```

### 変更後（概要）

```bash
# env-info.shを実行して結果を取得
ENV_INFO=$(docs/aidlc/bin/env-info.sh)

# 各ツールの状態を抽出
GH_RAW=$(echo "$ENV_INFO" | grep "^gh:" | cut -d: -f2)
DASEL_RAW=$(echo "$ENV_INFO" | grep "^dasel:" | cut -d: -f2)

# 状態値を日本語に変換（case文で変換）
# ...（詳細は実装時に記述）
```

## 不明点と質問（設計中に記録）

設計中に不明点が発生した場合、ここに記録する。

（現時点で不明点なし）
