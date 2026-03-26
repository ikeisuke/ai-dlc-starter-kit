# ドメインモデル: 名前付きサイクルスクリプト対応

## 概要

名前付きサイクル（`[name]/vX.X.X`）形式に対応するため、5つのスクリプトの入力バリデーション・パース・パス生成を拡張する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### CycleIdentifier

サイクルを一意に識別する文字列。名前付き形式と名前なし形式の2種類がある。

- **属性**: identifier: string - サイクル識別子
- **形式**:
  - 名前なし: `vX.X.X`（例: `v1.0.0`）
  - 名前付き: `[name]/vX.X.X`（例: `waf/v1.0.0`）
- **不変性**: 入力値から確定し変更されない
- **等価性**: 文字列の完全一致で判定
- **構文制約**: `([^/]+/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?`

### CycleName

名前付きサイクルの名前部分。

- **属性**: name: string - サイクル名（空文字許容: 名前なし時）
- **構文制約**: スクリプト側は `[^/]+`（非空・スラッシュ不含）のみ。厳格な文字制約はプロンプト側（Unit 003）

### CycleVersion

サイクルのSemVerバージョン部分。

- **属性**: version: string - `vX.X.X` または `vX.X.X-prerelease` 形式
- **構文制約**: `v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?`
- **prereleaseの許容はスクリプト別**: 下記バリデーションプロファイルを参照

### スクリプト別バリデーションプロファイル

| スクリプト | prerelease許可 | 理由 |
|-----------|---------------|------|
| `setup-branch.sh` | はい | ブランチ作成時にprerelease版を許容（既存動作） |
| `post-merge-cleanup.sh` | はい | prerelease版ブランチのクリーンアップ対応（既存動作） |
| `aidlc-cycle-info.sh` | いいえ | 情報取得は安定版のみ対象（既存動作） |
| `suggest-version.sh` | いいえ | バージョン提案は安定版のみ対象（既存動作） |
| `init-cycle-dir.sh` | はい | 任意形式受付（既存動作、SemVer制約なし） |

## ドメインサービス

### BranchNameParser

ブランチ名からCycleIdentifier/CycleName/CycleVersionを抽出する。

- **責務**: `cycle/[name]/vX.X.X` または `cycle/vX.X.X` のパース
- **操作**:
  - parse(branch) → { identifier, name, version }
- **パース規則**: スクリプトごとのバリデーションプロファイルに応じた正規表現を使用
  - prerelease不許可（`aidlc-cycle-info.sh`、`suggest-version.sh`）: `^cycle/(([^/]+/)?(v[0-9]+\.[0-9]+\.[0-9]+))$`
  - prerelease許可（`setup-branch.sh`、`post-merge-cleanup.sh`）: `^cycle/(([^/]+/)?(v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?))$`

### VersionValidator

入力バージョン文字列の構文バリデーション。

- **責務**: CycleIdentifierの構文チェック
- **操作**:
  - validate(version) → boolean
- **バリデーション規則**:
  - パストラバーサル（`..`）拒否
  - 2レベル以上のスラッシュ拒否
  - 先頭・末尾スラッシュ拒否
  - 空セグメント拒否

### スクリプト別セキュリティ責務

| スクリプト | パス安全性チェック | 補足 |
|-----------|-------------------|------|
| `init-cycle-dir.sh` | `..`拒否、スラッシュ制約、先頭/末尾/空セグメント拒否 | ファイルシステム操作を行うため直接チェック |
| `setup-branch.sh` | 正規表現によるフォーマット検証 | git refの妥当性はgitが担保。`..`等はgit ref名として不正なためgitが拒否 |
| `post-merge-cleanup.sh` | 正規表現によるフォーマット検証 | 同上 |
| `aidlc-cycle-info.sh` | 正規表現によるパース | 入力はgitブランチ名（既にgitが検証済み） |
| `suggest-version.sh` | 正規表現によるパース | 入力はgitブランチ名（既にgitが検証済み） |

### WorktreePathNormalizer

名前付きサイクルのworktreeパスを正規化する。

- **責務**: スラッシュを含むバージョン文字列を1階層のworktreeパスに変換
- **操作**:
  - normalize(version) → path
- **変換規則**: `cycle-${version//\//-}`（スラッシュをハイフンに置換）

## ユビキタス言語

- **サイクル識別子（CycleIdentifier）**: `vX.X.X` または `[name]/vX.X.X` 形式でサイクルを特定する文字列
- **サイクル名（CycleName）**: 名前付きサイクルの名前部分（例: `waf`、`auth`）
- **名前付きブランチ**: `cycle/[name]/vX.X.X` 形式のgitブランチ
- **構文チェック**: スクリプト側で行う最低限のバリデーション（文字種制約はUnit 003）

## 不明点と質問（設計中に記録）

なし
