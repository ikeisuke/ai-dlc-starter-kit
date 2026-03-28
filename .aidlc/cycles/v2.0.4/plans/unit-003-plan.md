# Unit 003 計画: v1残存コード削除

## 概要

v1のrsyncコピー処理、旧パス設定、スターターキットパス判定の残存コードを削除・修正し、v2プラグイン構造と整合させる。

## 変更対象ファイル

### 主要変更

| ファイル | 変更内容 | 関連Issue |
|---------|---------|----------|
| `skills/aidlc-setup/bin/aidlc-setup.sh` | rsync同期処理・SYNC_DIRS/SYNC_FILES削除、`resolve_starter_kit_root()` 簡略化、`--no-sync`オプション削除、ヘルプ・出力仕様更新 | #429, #431, #433 |
| `.aidlc/config.toml` | `[paths].setup_prompt` 削除 | #430 |
| `prompts/setup-prompt.md` | v1互換コード（L234-246）削除、ghqパス参照更新、rsync関連手順削除 | #429, #431 |

### 参照先更新（指摘#1対応: setup_prompt参照の一括整理）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/operations/04-completion.md` (L168) | `setup_prompt` 読み取りロジックを削除し、`/aidlc setup` 直参照に変更 |
| `skills/aidlc/steps/setup/02-generate-config.md` (L288) | `[paths].setup_prompt` 生成ロジックを削除 |
| `skills/aidlc-setup/SKILL.md` | `sync_*` 出力仕様・`ghq:` パス参照を削除、スキル説明をv2プラグインモデルに更新 |

### CLI契約変更（指摘#3対応: --no-sync廃止の明示化）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-setup/bin/aidlc-setup.sh` | `--no-sync` オプションを削除、ヘルプ文言更新、dry-run出力からsync関連キーを削除 |
| `skills/aidlc-setup/SKILL.md` | 出力フォーマット表からsync_added/sync_updated/sync_deleted行を削除 |

## 実装計画

### #429: スターターキットパス判定更新

- `aidlc-setup.sh` の `resolve_starter_kit_root()` を簡略化
  - v2プラグインモデルでは、スクリプトは常にプラグイン/スターターキット内に存在する
  - `SCRIPT_DIR` → 3階層上がプラグインルート = スターターキットルート
  - **維持するモード**:
    - `AIDLC_STARTER_KIT_PATH` 環境変数指定（明示指定）
    - `SCRIPT_DIR` ベースの相対パス解決（メタ開発・プラグインインストール共通）
  - **削除するモード**:
    - ghq経由のフォールバック解決（プラグインモデルでは不要）
    - `read-config.sh` を介した `project.starter_kit_repo` 参照
  - メタ開発環境検出（`version.txt` + `prompts/package/`）は維持

### #430: config.toml パス設定修正

- `config.toml` の `[paths].setup_prompt` を削除
  - **参照元の一括更新**（AIレビュー指摘#1対応）:
    - `operations/04-completion.md`: `setup_prompt` 読み取りを `/aidlc setup` 直参照に変更
    - `setup/02-generate-config.md`: `setup_prompt` 生成セクション（7.2.1）を削除
  - `defaults.toml` は現状で問題なし（`setup_prompt` は既に存在しない）
- `[paths].aidlc_dir` は `docs/aidlc` のまま維持（ガイド等の参照先として引き続き使用）

### #431: v1 rsyncコピー処理削除

- `aidlc-setup.sh` から以下を削除:
  - `SYNC_DIRS` / `SYNC_FILES` 配列定義
  - `_has_file_diff()` 関数
  - rsync同期ループ（実行部分）
  - `--no-sync` オプション（引数解析・ヘルプ含む）
- `prompts/setup-prompt.md` のv1互換コードブロック（L234-246）を削除
- `aidlc-setup/SKILL.md` の出力仕様表を更新

### #433: 同期マニフェスト整理

- rsync削除に伴い、同期マニフェスト（SYNC_DIRS/SYNC_FILES）自体を削除
- `aidlc-setup.sh` はバージョン更新 + 設定マイグレーション機能のみ残す

## 完了条件チェックリスト

- [ ] #429: `resolve_starter_kit_root()` がプラグイン構造に合わせて簡略化されている
- [ ] #430: `config.toml` から `setup_prompt` パスが削除されている
- [ ] #430: `setup_prompt` の参照元（operations/04-completion.md, setup/02-generate-config.md）が更新されている
- [ ] #431: `aidlc-setup.sh` からrsync同期処理が削除されている
- [ ] #433: SYNC_DIRS/SYNC_FILES マニフェストが削除されている
- [ ] `aidlc-setup.sh` がバージョン更新・設定マイグレーション機能で正常動作する
- [ ] `aidlc-setup/SKILL.md` の出力仕様がrsync削除を反映している
- [ ] `prompts/setup-prompt.md` のv1互換コードが削除されている

## AIレビュー反映履歴

- **指摘#1（高）**: `setup_prompt` 参照元の一括整理 → operations/04-completion.md, setup/02-generate-config.md を変更対象に追加
- **指摘#2（高）**: `resolve_starter_kit_root()` の2モード明示 → 維持/削除するモードを明示化。プラグインモデルでは SCRIPT_DIR ベースで十分なため ghq フォールバックを削除
- **指摘#3（中）**: `--no-sync` 廃止のCLI契約変更 → SKILL.md の出力仕様更新を必須変更に昇格
