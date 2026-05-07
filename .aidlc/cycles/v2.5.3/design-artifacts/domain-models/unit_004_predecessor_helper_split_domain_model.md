# ドメインモデル: Unit 004 predecessor-issue.sh の retrospective-issue.sh 横依存解消

## 概要

`predecessor-issue.sh` が `retrospective-issue.sh` から関数を借用する横依存構造を、責務別の独立 helper 群に分離して解消する。関数名・引数・stderr 文言は不変（API 完全互換）。

**重要**: コードは書かず、構造と責務の定義のみ。

## エンティティ

### HelperModule（Helper モジュール）

- **ID**: ファイルパス（例: `aidlc-validate.sh`）
- **属性**:
  - `kind`: `validation` | `gh_status` | `spool_io` | `path_resolution` | `composite`
  - `multi_source_guard`: 環境変数名（例: `__AIDLC_VALIDATE_SH_LOADED`）
  - `provided_functions`: 提供関数集合
  - `dependencies`: 他 helper への依存集合（境界完全分離なら空）
- **振る舞い**:
  - `load()` - 多重 source ガード経由で 1 回のみ読み込まれる

## 値オブジェクト

### FunctionMigrationMapping（関数移管マッピング）

- **属性**: `source_file` / `target_file` / `function_name`
- **不変性**: 関数本体（実装内容）は移管前後で完全同一
- **等価性**: トリプル一致

### LoadOrder（読込順序）

- **属性**: `order`: List<HelperModule>
- **不変性**: 順序は固定（`aidlc-paths` → `aidlc-validate` → `aidlc-gh` → `aidlc-spool`）
- **等価性**: 順序の一致

## 集約

### IndependentHelperBoundary（独立 Helper 境界）集約

- **集約ルート**: HelperModule（aidlc-validate / aidlc-gh / aidlc-spool）
- **不変条件**:
  - 各 helper は他 helper を source しない（境界完全分離）
  - 多重 source ガードを必ず備える
  - 関数本体は元 retrospective-issue.sh と完全同一

## ドメインサービス

### FunctionMigrationService

- **責務**: 移管対象関数の本体コピー + 元定義削除を atomic に実施
- **操作**: `migrate(mapping)` - 元 source からの定義切り出しと target への配置

### CrossDependencyVerificationService

- **責務**: 新 helper が retrospective-issue.sh / predecessor-issue.sh を source していないことを検証
- **操作**: `verify_no_cross_source(helpers)` - grep ベースで 0 件確認

## ユビキタス言語

- **横依存（Cross-Dependency）**: A モジュールが B モジュールから関数を借用する形態（解消対象）
- **境界完全分離**: 各 helper が他 helper を一切 source せず独立して機能する状態
- **多重 source ガード**: `__AIDLC_*_SH_LOADED=1` パターンによる重複読込防止
- **API 互換性**: 関数名・引数・戻り値・exit code・stderr 文言の不変保証
- **同一コミット切替**: 旧依存撤去と新依存設定を 1 コミットで完結（中間状態を作らない）

## 不明点と質問

[Question] 移管対象 3 関数以外で retrospective-issue.sh 内に依存が発生しないか

[Answer] 計画ファイル「変更操作の境界」表で移管対象を 3 関数（`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries`）に限定。Unit 001 で追加された `retrospective_dialog_token_*` 関数群は retrospective-issue.sh に残置（AC-U004-RETRO-GUARD-IMMUTABLE-1〜2）。
