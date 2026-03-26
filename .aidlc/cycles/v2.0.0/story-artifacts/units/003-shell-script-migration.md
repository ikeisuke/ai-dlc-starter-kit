# Unit: シェルスクリプト移行

## 概要
全シェルスクリプトを `skills/aidlc/scripts/` に移動し、パス解決メカニズム（AIDLC_PROJECT_ROOT / AIDLC_PLUGIN_ROOT）を導入。`.aidlc/config.toml` と `.aidlc/cycles/` への参照に変更する。

## 含まれるユーザーストーリー
- ストーリー 3: シェルスクリプトのパス移行

## 責務
- 全スクリプトを `skills/aidlc/scripts/` に移動
- `AIDLC_PROJECT_ROOT`（git rev-parse --show-toplevel）と `AIDLC_PLUGIN_ROOT`（dirname $0）の解決ロジックを全スクリプトに追加
- 設定パス変更: `docs/aidlc.toml` → `.aidlc/config.toml`
- サイクルパス変更: `docs/cycles/` → `.aidlc/cycles/`
- デフォルト設定パス変更: → `skills/aidlc/config/defaults.toml`（プラグイン相対）
- 不要スクリプトの削除: `resolve-starter-kit-path.sh`, `sync-package.sh`, `setup-ai-tools.sh`, `aidlc-setup.sh`

## 境界
- スクリプトの機能変更は最小限（パス変更のみ）
- 新規スクリプトの追加は行わない

## 依存関係

### 依存する Unit
- Unit 002: リポジトリ構造基盤（依存理由: `skills/aidlc/scripts/` ディレクトリが存在する必要がある）

### 外部依存
- dasel（TOML解析）
- gh（GitHub CLI）

## 非機能要件（NFR）
- **パフォーマンス**: 特になし
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- 既存テストの移行・更新が必要
- `defaults.toml` のパスはプラグインインストール先に依存

## 実装優先度
High

## 見積もり
中（28スクリプトのパス変更）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-26
- **完了日**: 2026-03-27
- **担当**: @ai
- **エクスプレス適格性**: -
- **適格性理由**: -
