# ドメインモデル: v1残存コード削除

## 概要

v1のrsyncコピー・ghqパス解決・旧設定パスの残存コードを削除し、v2プラグインモデルに整合させる。新規エンティティの導入はなく、既存コンポーネントの責務縮退と参照契約の整理が中心。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## コンポーネント構造

### aidlc-setup.sh（変更後の責務）

- **現在の責務**:
  1. スターターキットパス解決（`resolve_starter_kit_root()`）
  2. バージョン比較・アップグレード判定
  3. 設定マイグレーション（`migrate-config.sh` 委譲）
  4. rsync同期（SYNC_DIRS/SYNC_FILES）
- **変更後の責務**:
  1. スターターキットパス解決（SCRIPT_DIR相対のみ）
  2. バージョン比較・アップグレード判定
  3. 設定マイグレーション（`migrate-config.sh` 委譲）
  4. ~~rsync同期~~ **削除**
- **削除されるインターフェース**:
  - `--no-sync` CLIオプション
  - `sync_added:` / `sync_updated:` / `sync_deleted:` 出力キー
  - `_has_file_diff()` 内部関数
  - `SYNC_DIRS` / `SYNC_FILES` 配列

### resolve_starter_kit_root()（変更後のモード）

- **維持**:
  - 環境変数 `AIDLC_STARTER_KIT_PATH` による明示指定
  - `SCRIPT_DIR` ベースの相対パス解決（`bin/` → `aidlc-setup/` → `skills/` → ルート）
  - メタ開発環境検出（`version.txt` + `prompts/package/`）
- **削除**:
  - `read-config.sh` → `project.starter_kit_repo` → ghqパス解決
  - ghqコマンド可用性チェック
  - `ghq:` プレフィックス処理

### config.toml [paths] セクション（変更後のスキーマ）

- **維持**: `aidlc_dir`（ガイド等の参照パス）、`cycles_dir`
- **削除**: `setup_prompt`（プラグインモデルでは `/aidlc setup` が直接エントリポイント）

## 参照契約の整理

### setup_prompt 参照チェーン（全箇所を一括更新）

| 参照元 | 現在の動作 | 変更後 |
|--------|-----------|--------|
| `config.toml` [paths].setup_prompt | パスを保持 | キー削除 |
| `setup/02-generate-config.md` (7.2.1) | setup_prompt を生成 | セクション削除 |
| `operations/04-completion.md` (L168) | setup_prompt を読み取り | `/aidlc setup` 直参照に変更 |
| `aidlc-setup/SKILL.md` (L27-38) | ghq:パスでsetup-prompt.mdを解決 | 不要（スキルが直接呼び出される） |

### sync関連出力チェーン（全箇所を一括削除）

| 参照元 | 現在の動作 | 変更後 |
|--------|-----------|--------|
| `aidlc-setup.sh` | sync_added/updated/deleted 出力 | 出力行削除 |
| `aidlc-setup/SKILL.md` (L58-60) | 出力フォーマット表にsync行 | 行削除 |

## ユビキタス言語

- **プラグインモデル**: `claude install` でインストールし、`.claude/plugins/` 配下からスキルを直接参照する方式
- **rsync同期**: v1方式。スターターキットからプロジェクトにファイルをコピーする仕組み（廃止対象）
- **メタ開発**: スターターキット自身がスターターキットを使って開発されている構造
- **SCRIPT_DIR解決**: シェルスクリプトが自身の配置パスから相対的にルートを算出する方式
