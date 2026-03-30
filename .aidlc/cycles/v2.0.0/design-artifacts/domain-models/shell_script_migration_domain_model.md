# ドメインモデル: シェルスクリプト移行

## 概要

全シェルスクリプトを `skills/aidlc/scripts/` に集約し、共通bootstrapライブラリによるパス解決メカニズムを導入する。

## エンティティ

### ScriptFile（スクリプトファイル）

- **ID**: スクリプト名（例: `read-config.sh`）
- **属性**:
  - name: string
  - oldPath: string（`prompts/package/bin/`）
  - newPath: string（`skills/aidlc/scripts/`）
  - referencesConfig: boolean（docs/aidlc.toml参照有無）
  - referencesCycles: boolean（docs/cycles/参照有無）
  - referencesDefaults: boolean（defaults.toml参照有無）

### BootstrapLibrary（共通初期化ライブラリ）

- **ID**: 単一インスタンス（`skills/aidlc/scripts/lib/bootstrap.sh`）
- **責務**: パス解決、環境変数設定、fail-fastエラー処理
- **提供する変数**: AIDLC_PROJECT_ROOT, AIDLC_PLUGIN_ROOT, AIDLC_CONFIG, AIDLC_CYCLES, AIDLC_DEFAULTS

### ProjectConfig（プロジェクト設定）

- **ID**: `.aidlc/config.toml`
- **旧パス**: `docs/aidlc.toml`

## 値オブジェクト

### PathContract（パス契約）

| 変数 | 外部指定 | 解決方法 | 失敗時 |
|------|---------|---------|-------|
| AIDLC_PROJECT_ROOT | 可（環境変数） | `git rev-parse --show-toplevel` | fail-fast (exit 1) |
| AIDLC_PLUGIN_ROOT | 不可（内部専用） | `dirname BASH_SOURCE/../` | fail-fast |
| AIDLC_CONFIG | 不可（派生） | `$ROOT/.aidlc/config.toml` | - |
| AIDLC_LOCAL_CONFIG | 不可（派生） | `$ROOT/.aidlc/config.local.toml` | - |
| AIDLC_LOCAL_CONFIG_LEGACY | 不可（派生） | `$ROOT/.aidlc/config.toml.local` | - |
| AIDLC_CYCLES | 不可（派生） | `$ROOT/.aidlc/cycles` | - |
| AIDLC_DEFAULTS | 不可（派生） | `$PLUGIN/config/defaults.toml` | - |

## 不変条件

1. 全スクリプトは `bootstrap.sh` をsourceしてからロジックを開始する
2. Git管理外での実行は即座に失敗する（fail-fast）
3. パス解決ロジックは `bootstrap.sh` にのみ存在する（DRY）
