# ドメインモデル: Unit 002 update-version.sh 挙動変更

## 概要

`bin/update-version.sh` のドメイン責務「リリース時のバージョン番号一括更新」のスコープから、`.aidlc/config.toml.starter_kit_version` の書き込みを除外する。本 Unit は bash スクリプトの局所変更のため、エンティティ/集約等の DDD 構造は採用せず、**更新対象集合の縮小** と **`.aidlc/config.toml` の役割再定義** を中心にドメインモデルを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### `update-version.sh`（バージョン更新コマンド）

- **責務**: AI-DLC スターターキットのリリース時に、リリース対象ファイルのバージョン番号を一括更新する
- **入力**:
  - **CLI 入力**: 新バージョン番号（`--version`）、dry-run フラグ（`--dry-run`）
  - **リポジトリ入力（必須）**: `version.txt`、`.aidlc/config.toml`（妥当性検証専用、修正後は読み取りのみで書き込みなし）、`skills/aidlc/scripts/lib/version.sh`（共通ライブラリ、不在時 `error:version-lib-not-found` で即終了）
  - **リポジトリ入力（条件付き、存在時のみ）**: `skills/aidlc/version.txt`、`skills/aidlc-setup/version.txt`
- **副作用**: 更新対象ファイル（後述）への書き込み
- **冪等性**: 同じバージョン番号で複数回実行しても結果は同じ

## 更新対象集合の再定義

### 修正前（v2.3.x まで）

`update-version.sh` は以下 4 ファイルを更新対象としていた:

| ファイル | 役割 | 修正前の扱い |
|---------|------|------------|
| `version.txt` | プロジェクトのリリースバージョン | 書き込み対象 |
| `.aidlc/config.toml.starter_kit_version` | 最後に実行した `aidlc-setup` のバージョン | 書き込み対象（**v1 流儀の bug**） |
| `skills/aidlc/version.txt` | aidlc スキルのバージョン | 書き込み対象 |
| `skills/aidlc-setup/version.txt` | aidlc-setup スキルのバージョン | 書き込み対象 |

### 修正後（v2.4.0 以降）

更新対象集合は `.aidlc/config.toml` を除外し、最大 3 ファイルに縮小する。`.aidlc/config.toml` は **妥当性検証専用の読み取り対象** として位置付けを変更する。実際の更新ファイル数は `skills/*/version.txt` の存在有無により 1〜3 ファイルに変動する（本リポジトリ標準状態では 3 ファイル）:

| ファイル | 役割 | 修正後の扱い |
|---------|------|------------|
| `version.txt` | プロジェクトのリリースバージョン | 書き込み対象（変更なし、無条件） |
| `.aidlc/config.toml` | リポジトリ整合性 + starter_kit_version の妥当性 | **妥当性検証専用の読み取り対象**（書き込みなし、存在チェック + read_starter_kit_version の検証副作用維持） |
| `skills/aidlc/version.txt` | aidlc スキルのバージョン | 書き込み対象（変更なし、**存在時のみ**） |
| `skills/aidlc-setup/version.txt` | aidlc-setup スキルのバージョン | 書き込み対象（変更なし、**存在時のみ**） |

**実際の更新ファイル数**:

- 両 skill ファイル存在（本リポジトリ標準状態）: 3 ファイル更新
- skill ファイル片方のみ存在: 2 ファイル更新
- 両 skill ファイル不在: 1 ファイル（`version.txt` のみ）更新

## `.aidlc/config.toml` の役割再定義

### 修正後の責務

`.aidlc/config.toml` は **書き込み対象から外れる** が、以下の検証副作用を維持する。検証範囲は **`starter_kit_version` 行のみ**（TOML 全体の構文検証ではない、`skills/aidlc/scripts/lib/version.sh:47-90` の `read_starter_kit_version` 実装に準拠）:

1. **存在チェック**: ファイル不在時は `error:config-toml-not-found` を出力し exit 1（リポジトリ整合性検証）
2. **読み取り検証** (`read_starter_kit_version` 経由、`starter_kit_version` 行に限定):
   - **unreadable / file not found**: ファイル読み取り権限なし等で `error:config-toml-read-failed` を出力し exit 1（return code 2）
   - **starter_kit_version 行の異常**（return code 1）→ `error:invalid-config-toml-format` を出力し exit 1
     - キー欠落（`starter_kit_version` 行が存在しない）
     - キー重複（`starter_kit_version` 行が 2 件以上）
     - 値が空または引用符不一致（`starter_kit_version = ""` または `starter_kit_version = unquoted_value`）

これにより、`starter_kit_version` 行が壊れた `.aidlc/config.toml` を持つ repo でリリーススクリプトが silent に通ってしまうリスクを防ぐ（既存契約の維持）。なお、TOML の他のキーや構文エラーはこの検証では捕捉しない（既存実装の責務範囲外）。

### 修正後の意味論

「`update-version.sh` は、`.aidlc/config.toml` が **存在し、かつ正しく読める形式である** ことを前提とするが、**その値を変更しない**」

この再定義により、メタ開発リポジトリ（AI-DLC スターターキット自身を AI-DLC で開発するリポジトリ）でアップグレードモードの試験が可能になる。`.aidlc/config.toml.starter_kit_version` は `aidlc-setup` / `aidlc-migrate` 実行時の値を保持し続け、`version.txt` とは独立した「最後に実行した setup のバージョン」を表す値として機能する。

## ユビキタス言語

- **starter_kit_version**: `.aidlc/config.toml` 内の値。「最後に実行した `aidlc-setup` または `aidlc-migrate` のバージョン」を表す。リリース時に変更されるべきではない値
- **リリースバージョン**: `version.txt` の値。プロジェクトの公式リリースバージョン
- **バージョン三角検証**: `aidlc-setup` がアップグレード必要性を判定する 3 値の比較ロジック（`skills/aidlc-setup/steps/01-detect.md:101` 参照）:
  - **local**: `.aidlc/config.toml.starter_kit_version`（最後に実行した setup のバージョン）
  - **skill**: `skills/aidlc/version.txt`（インストール済み skill のバージョン）
  - **remote**: GitHub からダウンロード可能な最新の `version.txt`
  修正前の bug では、`update-version.sh` が **local（`starter_kit_version`）を上書きする** ため、local が常に skill と一致してしまい三角検証が常時一致化（アップグレード未検出）となっていた。本 Unit の修正後は local が `aidlc-setup` 実行時の値を保持し、メタ開発時にも三角検証が正しく機能する
- **メタ開発リポジトリ**: AI-DLC スターターキット自身を AI-DLC で開発するリポジトリ（本リポジトリ `ikeisuke/ai-dlc-starter-kit` が該当）

## 不明点と質問

なし（既存実装の挙動変更であり、ドメイン責務に新規不明点なし）。
