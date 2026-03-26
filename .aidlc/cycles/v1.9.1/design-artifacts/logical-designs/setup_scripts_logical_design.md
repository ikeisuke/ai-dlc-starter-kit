# 論理設計: 確認系処理のスクリプト化

## 概要

setup-prompt.md 内の確認系処理をスクリプト化し、プロンプトを簡素化する。シェルスクリプトの構成と入出力インターフェースを設計する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

単純なシェルスクリプト形式を採用。既存スクリプト（check-gh-status.sh, check-backlog-mode.sh）と同様のパターンを踏襲し、一貫性を維持する。

## コンポーネント構成

### ファイル構成

```text
prompts/package/bin/
├── check-version.sh       # バージョン比較スクリプト（新規）
├── check-setup-type.sh    # セットアップ種類判定スクリプト（新規）
├── check-gh-status.sh     # 既存: GitHub CLI状態確認
├── check-backlog-mode.sh  # 既存: バックログモード確認
└── ...
```

### コンポーネント詳細

#### check-version.sh

- **責務**: プロジェクトとスターターキットのバージョンを比較
- **依存**: dasel（オプション）
- **入力**: なし（ファイルシステムから読み取り）
- **出力**: `version_status:{状態}` 形式の文字列

#### check-setup-type.sh

- **責務**: 設定ファイル状態とバージョン情報からセットアップ種類を判定
- **依存**: check-version.sh（内部呼び出し）
- **入力**: なし（ファイルシステムから読み取り）
- **出力**: `setup_type:{種類}` 形式の文字列

## インターフェース設計

### コマンド: check-version.sh

#### 使用方法

```bash
./check-version.sh
```

#### パラメータ

なし

#### 出力形式

| 出力 | 条件 |
|------|------|
| `version_status:current` | バージョンが同じ |
| `version_status:upgrade_available:{project}:{kit}` | アップグレード可能 |
| `version_status:project_newer:{project}:{kit}` | プロジェクトが新しい |
| `version_status:not_found` | バージョン情報取得不可 |
| `version_status:` | dasel未インストール（AIに委ねる） |

#### 終了コード

- `0`: 正常終了（すべてのケース）

### コマンド: check-setup-type.sh

#### 使用方法

```bash
./check-setup-type.sh
```

#### パラメータ

なし

#### 出力形式

| 出力 | 条件 |
|------|------|
| `setup_type:initial` | 設定ファイルなし |
| `setup_type:cycle_start` | aidlc.toml存在 & バージョン同じ |
| `setup_type:upgrade:{project}:{kit}` | アップグレード可能 |
| `setup_type:warning_newer:{project}:{kit}` | プロジェクトが新しい |
| `setup_type:migration` | project.toml存在（旧形式） |
| `setup_type:` | dasel未インストール（AIに委ねる） |

#### 終了コード

- `0`: 正常終了（すべてのケース）

## 処理フロー概要

### check-version.sh の処理フロー

1. daselコマンドの存在確認
   - 存在しない場合: `version_status:` を出力して終了（AIに委ねる）
2. スクリプトの配置パスから version.txt のパスを解決
   - `$SCRIPT_DIR/../../../version.txt`（prompts/package/bin/ からリポジトリルートへ）
3. version.txt からスターターキットのバージョンを取得
   - 取得失敗時または空文字: `version_status:not_found` を出力
4. docs/aidlc.toml から starter_kit_version を取得
   - ファイルが存在しない場合: `version_status:not_found` を出力
   - キーが存在しない場合または空文字: `version_status:not_found` を出力
5. バージョンを比較（両方とも有効な値の場合のみ）
   - 同じ: `version_status:current`
   - プロジェクト < キット: `version_status:upgrade_available:{project}:{kit}`
   - プロジェクト > キット: `version_status:project_newer:{project}:{kit}`

### check-setup-type.sh の処理フロー

1. daselコマンドの存在確認
   - 存在しない場合: `setup_type:` を出力して終了（AIに委ねる）
2. 設定ファイルの存在確認（aidlc.toml 優先）
   - `docs/aidlc.toml` が存在 → 3へ（project.toml は無視）
   - `docs/aidlc.toml` なし & `docs/aidlc/project.toml` が存在 → `setup_type:migration` を出力
   - どちらもなし → `setup_type:initial` を出力
3. check-version.sh を呼び出してバージョン状態を取得
4. バージョン状態に基づいて出力
   - 空値（unknown）→ `setup_type:` を出力（AIに委ねる）
   - `current` → `setup_type:cycle_start`
   - `upgrade_available` → `setup_type:upgrade:{project}:{kit}`
   - `project_newer` → `setup_type:warning_newer:{project}:{kit}`
   - `not_found` → `setup_type:initial`（バージョン情報がない = 初回扱い）

## 技術選定

- **言語**: Bash (POSIX互換)
- **オプション依存**: dasel（TOML解析）
- **フォールバック**: dasel未インストール時は空値を返し、AIに直接ファイル読み取りを委ねる

## 実装上の注意事項

- `set -euo pipefail` を使用して堅牢なスクリプトにする
- dasel未インストール時はエラーではなく、空値を返す（AIがフォールバック処理を行う）
- version.txt のパスはスクリプトの配置ディレクトリ基準で解決（`../../../version.txt`）
- セマンティックバージョン比較はシェルで実装（外部ツール不要）
- バージョン正規化: 比較前に `1.9` → `1.9.0` のように正規化する

## setup-prompt.md への変更

### 現在のセクション2の構造

1. aidlc.toml/project.toml の存在確認（インラインbash）
2. バージョン取得（インラインbash + daselオプション）
3. ケース判定（A〜D + 後方互換性）

### 変更後

1. `check-setup-type.sh` を呼び出し
2. 出力をもとにケース判定

### 削減される記述

- 約40行のインラインbashコード
- daselの存在確認とフォールバック処理の説明

## 不明点と質問

（なし - 既存スクリプトパターンに従い、setup-prompt.mdの要件は明確）
