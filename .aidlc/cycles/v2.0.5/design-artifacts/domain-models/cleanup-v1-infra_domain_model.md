# ドメインモデル: v1インフラ廃止・スクリプトv2対応

## エンティティ

### BootstrapLibrary
- **責務**: スクリプト共通初期化。環境変数の提供
- **変更**: `AIDLC_DOCS_DIR` と `paths.aidlc_dir` カスケード解決を削除
- **提供変数（v2）**: `AIDLC_PROJECT_ROOT`, `AIDLC_PLUGIN_ROOT`, `AIDLC_CONFIG`, `AIDLC_LOCAL_CONFIG`, `AIDLC_CYCLES`, `AIDLC_DEFAULTS`

### SetupTypeChecker
- **責務**: セットアップ種別判定（initial / migration / upgrade / cycle_start）
- **変更**: `AIDLC_DOCS_DIR` 依存除去。`PROJECT_TOML` のパスを `AIDLC_DOCS_DIR` ベースから固定パス `docs/aidlc/project.toml` に変更（v1移行判定のみで使用）
- **判定規則（排他的）**:
  1. `.aidlc/config.toml` あり → バージョン比較で `cycle_start` / `upgrade` / `warning_newer`
  2. `.aidlc/config.toml` なし & `docs/aidlc/project.toml` あり → `migration`（v1→v2移行対象）
  3. どちらもなし → `initial`（初回セットアップ）

### VersionChecker
- **責務**: スターターキットバージョン比較
- **変更**: `docs/aidlc.toml` → `.aidlc/config.toml` へ参照先変更

### VersionUpdater (bin/update-version.sh)
- **責務**: リリース時のバージョン番号更新
- **変更**: `docs/aidlc.toml` → `.aidlc/config.toml` へ参照先変更

### SetupEntryPoint (prompts/setup-prompt.md)
- **責務**: 旧エントリポイント。v2では `/aidlc setup` への誘導のみ
- **変更**: 大幅簡略化

## 値オブジェクト

### PathConfig
- v1: `paths.aidlc_dir` → `AIDLC_DOCS_DIR` → `docs/aidlc/`
- v2: 廃止。`AIDLC_PLUGIN_ROOT` が `skills/aidlc/` を直接提供

### VersionLocation
- v1: `docs/aidlc.toml` 内の `starter_kit_version`
- v2: `.aidlc/config.toml` 内の `starter_kit_version`

## 集約

### InfraCleanup
- BootstrapLibrary + SetupTypeChecker + VersionChecker が連動して変更
- `AIDLC_DOCS_DIR` 廃止が起点、下流スクリプトが参照先を変更

## ドメインサービス

### MigrationCompatibility
- `migrate-config.sh` は `AIDLC_DOCS_DIR` が bootstrap.sh から消えた後も動作する必要がある
- **責務分離**: 移行元設定の参照（`docs/aidlc/*`）と移行ガイド表示（`AIDLC_PLUGIN_ROOT/guides/*`）を分離
- 移行ガイド表示: `AIDLC_PLUGIN_ROOT` を使用（bootstrap.sh のv2正式API）
