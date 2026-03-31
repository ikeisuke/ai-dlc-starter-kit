# ドメインモデル: パス参照問題の修正

## 概要

プラグイン環境でのパス解決メカニズムを分析し、修正対象と修正方針を構造化する。本Unitはスクリプトとドキュメントの修正であり、新規エンティティの設計ではなく、既存のパス解決アーキテクチャの理解と修正方針の定義が目的。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## パス解決コンポーネント

### PathBootstrap（既存: `scripts/lib/bootstrap.sh`）

- **責務**: スキル実行時の環境変数（`AIDLC_PLUGIN_ROOT`, `AIDLC_PROJECT_ROOT`）を初期化
- **算出方式**: `BASH_SOURCE[0]` から `../../` で自身のスキルルートを算出
- **影響範囲**: `skills/aidlc/scripts/*.sh` の全スクリプトが依存
- **修正**: 不要（同スキル内の正当な相対パス参照）

### MigrateDetector（既存: `aidlc-migrate/scripts/migrate-detect.sh`）

- **責務**: v1→v2 移行対象リソースの検出
- **問題**: 29行目で `AIDLC_PLUGIN_ROOT="${AIDLC_PROJECT_ROOT}/skills/aidlc"` とハードコード、130行目で `AIDLC_PLUGIN_ROOT/../..` による逆方向算出
- **修正方針**: 29行目を環境変数注入方式に変更（`AIDLC_PLUGIN_ROOT="${AIDLC_PLUGIN_ROOT:-${AIDLC_PROJECT_ROOT}/skills/aidlc}"`）。130行目は `AIDLC_PROJECT_ROOT` を直接使用

### MigrateCleanup（既存: `aidlc-migrate/scripts/migrate-cleanup.sh`）

- **責務**: v1→v2 移行時の不要リソース削除
- **問題**: 26行目で `AIDLC_PLUGIN_ROOT="${AIDLC_PROJECT_ROOT}/skills/aidlc"` とハードコード、108行目でテンプレートパス算出に使用
- **修正方針**: 環境変数注入方式に変更（`AIDLC_PLUGIN_ROOT="${AIDLC_PLUGIN_ROOT:-${AIDLC_PROJECT_ROOT}/skills/aidlc}"`）。未設定時は従来互換パスにフォールバック

### MigrateApplyConfig（既存: `aidlc-migrate/scripts/migrate-apply-config.sh`）

- **責務**: v1→v2 移行時の設定ファイル変換
- **問題**: 143,145行目で `@skills/aidlc/` をハードコードした grep パターン
- **修正方針**: 修正不要。grepパターンはv1/旧v2時代の参照行（`@skills/aidlc/`, `@docs/aidlc/prompts/`等）を検出・除去するためのもの。パターン自体はv1互換の検出用であり、プラグイン環境でのパス参照とは無関係

## Markdownパス参照の分類

### 破綻するリンク（修正対象）

| パターン | 使用箇所 | 原因 |
|---------|---------|------|
| `../../guides/xxx.md` | `steps/common/*.md` | プラグイン環境では `steps/` と `guides/` の相対位置が保証されない |
| `../../skills/xxx/` | `guides/skill-usage-guide.md` | シンボリックリンクの説明文でプロジェクト相対パスを使用 |

### 正当な参照（修正不要）

| パターン | 使用箇所 | 理由 |
|---------|---------|------|
| `${SCRIPT_DIR}/lib/xxx.sh` | `scripts/*.sh` | 同スキル内の相対参照 |
| `${SCRIPT_DIR}/../xxx` | `aidlc-setup/scripts/*.sh` | 同スキル内の相対参照 |

## ユビキタス言語

- **スキルベース相対パス**: SKILL.md が存在するディレクトリからの相対パス。プラグイン環境での標準的なパス解決方式
- **プラグインルート**: `AIDLC_PLUGIN_ROOT` — aidlcスキルのルートディレクトリ
- **プロジェクトルート**: `AIDLC_PROJECT_ROOT` — ユーザーのプロジェクトルートディレクトリ
- **逆方向算出**: `/../..` パターンで子ディレクトリから親ディレクトリを算出する手法。プラグイン環境で破綻する
