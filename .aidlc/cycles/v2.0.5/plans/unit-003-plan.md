# Unit 003 計画: v1インフラ廃止・スクリプトv2対応・ルール追加

## 概要

v1セットアップインフラの廃止、スクリプトのv2対応、バックログルール追加、旧エントリポイント誘導設置を行う。

## 変更対象ファイル

### 1. rsync同期インフラの完全廃止（#449）

| ファイル | 変更内容 |
|---------|---------|
| `prompts/bin/sync-package.sh` | ファイル削除（rsync同期はv2で不要） |
| `skills/aidlc/scripts/sync-package.sh` | 後方互換ラッパーも削除（実体の `prompts/bin/sync-package.sh` を削除するため、ラッパーも不要） |

**注**: sync-package の公開APIを完全廃止する。ラッパーだけ残して実体を消すアンチパターンを避ける。

### 2. prompts/setup/ 配下のv1パスハードコード更新（#448）

**正本の一本化方針（Codexレビュー #1 対応）**: `skills/aidlc/scripts/check-setup-type.sh` と `skills/aidlc/scripts/check-version.sh` が唯一の正本。`prompts/setup/bin/` 配下の同名スクリプトは正本へのラッパー（`exec` 委譲）に変更する。個別ロジック修正はスコープ外（正本側のみ修正）。

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup/bin/check-setup-type.sh` | 正本 `skills/aidlc/scripts/check-setup-type.sh` への `exec` ラッパーに変更 |
| `prompts/setup/bin/check-version.sh` | 正本 `skills/aidlc/scripts/check-version.sh` への `exec` ラッパーに変更 |
| `prompts/setup/templates/aidlc.toml.template` | `aidlc_dir = "docs/aidlc"` 行を削除（aidlc_dir廃止） |
| `skills/aidlc/scripts/tests/test_check_setup_type.sh` | テスト対象パスを正本 `skills/aidlc/scripts/` に更新 |
| `skills/aidlc/scripts/tests/test_check_version.sh` | テスト対象パスを正本 `skills/aidlc/scripts/` に更新 |

### 3. aidlc-setup.sh パス解決修正（#447）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-setup/bin/aidlc-setup.sh` | `resolve_starter_kit_root()` でシンボリックリンク解決対応。現在 `resolve_script_dir()` でsymlink解決済みだが、外部プロジェクトからsymlink経由で実行される場合の `SCRIPT_DIR` パターンマッチ（`*/skills/aidlc-setup/bin`）が実体パスではなくsymlinkの親ディレクトリを返す問題を修正 |

### 4. update-version.sh v2対応（#444）

| ファイル | 変更内容 |
|---------|---------|
| `bin/update-version.sh` | `docs/aidlc.toml` のハードコード参照を `.aidlc/config.toml` に変更。v2では `starter_kit_version` は `.aidlc/config.toml` に格納 |

### 5. バックログ即時実装ルール追加（#439）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/common/agents-rules.md` | 「バックログ管理」セクションに即時実装優先ルールを追加 |

### 6. 旧エントリポイント誘導（#450）

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-prompt.md` | 大幅簡略化。`/aidlc setup` への誘導メッセージのみに変更 |

### 7. bootstrap.sh の AIDLC_DOCS_DIR 変数再設計（Unit 002 からの引き継ぎ）

**変数設計方針（Codexレビュー #1 対応）**: `AIDLC_DOCS_DIR` の意味を変えるのではなく、v2では不要となった `AIDLC_DOCS_DIR` 自体を廃止する。

- `AIDLC_DOCS_DIR` は「プロジェクト側の docs/aidlc/ ディレクトリ」を指す変数だった
- v2ではドキュメントは `skills/aidlc/` に移動済みで、`AIDLC_PLUGIN_ROOT` が既にその役割を担う
- `AIDLC_DOCS_DIR` を参照しているスクリプト（`check-setup-type.sh`, `migrate-config.sh`）は個別に対応

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/scripts/lib/bootstrap.sh` | `AIDLC_DOCS_DIR` の算出ロジックと export を削除。`paths.aidlc_dir` の読み取りも削除 |
| `skills/aidlc/scripts/check-setup-type.sh` | `AIDLC_DOCS_DIR` 参照を除去。`project.toml` 存在チェック自体がv2では不要（v1移行判定用）なので分岐を簡素化 |
| `.aidlc/config.toml` | `[paths]` セクションの `aidlc_dir` キーを削除 |
| `skills/aidlc/config/defaults.toml` | `[paths]` セクションの `aidlc_dir` デフォルト値を削除 |

**スコープ外（AIDLC_DOCS_DIR 参照を変更しない）**:

| ファイル | 理由 |
|---------|------|
| `skills/aidlc/scripts/migrate-config.sh` | v1→v2移行スクリプト。`AIDLC_DOCS_DIR` はv1からの移行パス解決に必要。bootstrap.sh から `AIDLC_DOCS_DIR` を削除した場合、migrate-config.sh 内で独自にフォールバックを定義する（空時は `docs/aidlc` をデフォルト使用） |

### 8. スコープ外（変更しない）

| ファイル | 理由 |
|---------|------|
| `skills/aidlc/steps/` 配下 | Unit 002で完了済み |
| `skills/aidlc/scripts/migrate-*.sh`（migrate-config.sh以外） | v1→v2移行スクリプト。移行元の前提を維持する必要がある |

## 実装計画

1. **Phase 1: 設計** — depth_level=standard のため実施
   - ドメインモデル設計（スクリプト修正・パス解決が主のため簡潔に）
   - 論理設計（各スクリプトの修正方針・変数設計・正本一本化の定義）
2. **Phase 2: 実装**
   - bootstrap.sh の AIDLC_DOCS_DIR 廃止・paths.aidlc_dir 読み取り削除
   - check-setup-type.sh の AIDLC_DOCS_DIR 参照除去
   - migrate-config.sh の AIDLC_DOCS_DIR フォールバック追加
   - config.toml / defaults.toml から paths.aidlc_dir 削除
   - sync-package.sh 完全廃止（実体 + ラッパー）
   - prompts/setup/bin/ 配下のハードコード更新
   - テストの正本パス更新
   - aidlc-setup.sh のsymlink解決修正
   - update-version.sh のv2対応
   - agents-rules.md にルール追加
   - setup-prompt.md の簡略化
   - テスト実行
   - AIレビュー

## 完了条件チェックリスト

- [ ] `prompts/bin/sync-package.sh` が削除されている
- [ ] `skills/aidlc/scripts/sync-package.sh` （ラッパー）も削除されている
- [ ] `prompts/setup/bin/check-setup-type.sh` が正本へのラッパー（exec委譲）に変更されている
- [ ] `prompts/setup/bin/check-version.sh` が正本へのラッパー（exec委譲）に変更されている
- [ ] テスト（`test_check_setup_type.sh`, `test_check_version.sh`）が正本 `skills/aidlc/scripts/` を参照している
- [ ] `prompts/setup/templates/aidlc.toml.template` から `aidlc_dir` 行が削除されている
- [ ] `aidlc-setup.sh` の `resolve_starter_kit_root()` がシンボリックリンク経由で正しくパス解決する
- [ ] `bin/update-version.sh` が `.aidlc/config.toml` を参照している（`docs/aidlc.toml` 参照なし）
- [ ] `skills/aidlc/steps/common/agents-rules.md` に即時実装優先ルールが追加されている
- [ ] `prompts/setup-prompt.md` が誘導メッセージのみに簡略化されている
- [ ] `bootstrap.sh` から `AIDLC_DOCS_DIR` と `paths.aidlc_dir` 読み取りが除去されている
- [ ] `skills/aidlc/scripts/check-setup-type.sh` から `AIDLC_DOCS_DIR` 参照が除去されている
- [ ] `.aidlc/config.toml` と `defaults.toml` から `paths.aidlc_dir` が削除されている
- [ ] `skills/aidlc/scripts/migrate-config.sh` が `AIDLC_DOCS_DIR` 未設定時にフォールバックする
- [ ] 関連スクリプトのテスト実行がエラーなし
