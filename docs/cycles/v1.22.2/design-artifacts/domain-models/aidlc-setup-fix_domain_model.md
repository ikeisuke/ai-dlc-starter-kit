# ドメインモデル: aidlc-setupスクリプト修正

## 概要

aidlc-setup.sh のパス解決メカニズムにおける関数責務と依存構造を定義する。

**重要**: このドキュメントでは**コードは書かず**、構造と責務の定義のみを行います。

## 関数責務表

### resolve_starter_kit_root()

| 項目 | 内容 |
|------|------|
| **入力** | SCRIPT_DIR（実行スクリプトの絶対パス）、AIDLC_STARTER_KIT_PATH（環境変数、任意） |
| **出力** | スターターキットの絶対パス（stdout）、エラー/詳細メッセージ（stderr） |
| **失敗条件** | 4段階フォールバック全て失敗時にreturn 1 |
| **変更内容** | 各フォールバックステージのエラーメッセージに `detail:` 行を追加 |

**フォールバック戦略**:

1. 環境変数（AIDLC_STARTER_KIT_PATH）→ ディレクトリ不在で失敗
2. メタ開発パターン（`*/prompts/package/skills/*/bin`）→ パターン不一致で次へ
3. ユーザープロジェクトパターン（`*/docs/aidlc/skills/*/bin`）→ メタ開発判定 or ghq解決
4. エラー（対処法を含むメッセージ出力）

### 各ステップの依存チェック

| ステップ | 関数/処理 | チェック対象 | 検証方法 | 失敗時 |
|---------|----------|------------|---------|--------|
| Step 3 | check-setup-type呼び出し | `$CHECK_SETUP_TYPE` | `-x`（実行権限） | warn、空値で続行 |
| Step 5 | migrate-config呼び出し | `$MIGRATE_CONFIG` | `-x`（実行権限） | warn、スキップ |
| Step 6 | sync-package呼び出し | `$SYNC_PACKAGE` | `-x`（実行権限） | error、exit 1 |
| Step 4 | version.txt読み取り | `$VERSION_FILE` | `-f`（存在確認） | "unknown"で続行 |

## 依存マップ

### 直接依存（スクリプト）

| 依存 | パス（STARTER_KIT_ROOT相対） | 分類 | 失敗時 |
|------|---------------------------|------|--------|
| check-setup-type.sh | `prompts/setup/bin/check-setup-type.sh` | 任意 | warn、続行 |
| migrate-config.sh | `prompts/package/bin/migrate-config.sh` | 任意 | warn、続行 |
| sync-package.sh | `prompts/package/bin/sync-package.sh` | **必須** | error、exit 1 |
| version.txt | `version.txt` | 任意 | "unknown"で続行 |

### 環境依存（外部コマンド）

| 依存 | 分類 | 使用箇所 | 失敗時 |
|------|------|---------|--------|
| dasel | **必須** | aidlc-setup.sh 冒頭チェック（line 82-89） | error:dasel-required、exit 1 |
| ghq | 条件付き必須 | resolve_starter_kit_root() ユーザーPJモード | error、exit 1（環境変数未設定時） |
| rsync | **必須** | sync-package.sh内 | sync失敗 |
| read-config.sh | 条件付き必須 | resolve_starter_kit_root() ghq解決時 | -x不成立: error、exit 1。設定値取得失敗: デフォルト値で続行 |

### 推移依存（sync-package.shの同期対象）

sync-package.sh正常動作時に同期される7ディレクトリ:
`prompts/`, `templates/`, `guides/`, `bin/`, `skills/`, `kiro/`, `lib/`

## ユビキタス言語

- **STARTER_KIT_ROOT**: スターターキットリポジトリの絶対パス
- **メタ開発モード**: スターターキット自身を開発している環境
- **ユーザープロジェクトモード**: 外部プロジェクトからスターターキットを利用している環境
- **ghq解決**: ghqコマンドのルートディレクトリからスターターキットパスを算出するフォールバック
