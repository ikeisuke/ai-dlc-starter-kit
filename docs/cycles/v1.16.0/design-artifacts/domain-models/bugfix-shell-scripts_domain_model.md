# ドメインモデル: シェルスクリプトバグ修正

## 概要

VCS検出とサイクルバージョン管理の2つのユーティリティ関数のバグ修正に関するドメイン定義。既存の関数内修正のため、新規エンティティは追加しない。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### VcsType

- **属性**: type: string - "git", "jj", "unknown" のいずれか
- **不変性**: 検出結果は一度決定したら変わらない
- **等価性**: type文字列の一致で判定

### SemVer

- **属性**: major: integer, minor: integer, patch: integer
- **不変性**: バージョン番号は不変
- **等価性**: major, minor, patchの全一致で判定
- **バリデーション**: major/minor/patchはそれぞれ0以上の整数。先頭ゼロ不可（0自体は許容）

## ドメインサービス

### VcsDetector（aidlc-git-info.sh - detect_vcs()）

- **責務**: 現在のディレクトリのVCS種類を判定する
- **操作**: detect_vcs() - `.jj` と `.git` の存在と対応コマンドの利用可能性を確認し、VcsTypeを返す
- **判定ロジック（修正後）**:
  1. `.jj`ディレクトリが存在 AND `jj`コマンドが利用可能 → "jj"
  2. `.git`が存在（ファイルまたはディレクトリ） AND `git`コマンドが利用可能 → "git"
  3. いずれにも該当しない → "unknown"
- **修正ポイント**: ステップ2で`-d`（ディレクトリのみ）を`-e`（ファイルまたはディレクトリ）に変更。`command -v git`チェック追加。

### CycleVersionResolver（suggest-version.sh - get_latest_cycle()）

- **責務**: docs/cycles/ から最新のサイクルバージョンを特定する
- **操作**: get_latest_cycle() - ディレクトリ一覧からSemVer準拠のもののみをフィルタし、最新を返す
- **判定ロジック（修正後）**:
  1. `docs/cycles/v*/` に一致するディレクトリを列挙
  2. SemVerパターン `v{MAJOR}.{MINOR}.{PATCH}` にマッチするもののみフィルタ
  3. バージョンソートで最新を取得
- **修正ポイント**: ステップ2のSemVerフィルタを追加

## ユビキタス言語

- **worktree**: Gitの`git worktree`機能で作成された作業ディレクトリ。`.git`がディレクトリではなくファイルになる
- **SemVer**: Semantic Versioning（`MAJOR.MINOR.PATCH`形式のバージョニング規約）
- **VCS**: Version Control System（バージョン管理システム、gitまたはjj）

## 不明点と質問

なし（修正内容が明確なバグ修正のため）
