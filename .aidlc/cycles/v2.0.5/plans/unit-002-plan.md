# Unit 002 計画: パス参照一括更新・aidlc_dir設定廃止

## 概要

`{{aidlc_dir}}/guides/...` 形式のパス参照をスキル内相対パス `guides/...` に一括更新し、ステップファイルおよびプリフライトから `aidlc_dir` の参照を除去する。設定キー自体（`config.toml`/`defaults.toml` の `paths.aidlc_dir`）は `bootstrap.sh` が依存しているため本Unitでは残置し、Unit 003 で `bootstrap.sh` 修正と同時に削除する。

## 変更対象ファイル

### 1. ステップファイル内の `{{aidlc_dir}}` パス参照置換（21箇所）

| ファイル | 変更内容 |
|---------|---------|
| `steps/construction/01-setup.md` (3箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/construction/04-completion.md` (1箇所) | `{{aidlc_dir}}/bug-response-flow.md` → 参照を削除（ファイル未存在のため。代替としてバックトラックセクションの既存説明で対応） |
| `steps/operations/01-setup.md` (1箇所) | `{{aidlc_dir}}/bug-response-flow.md` → 参照を削除（同上） |
| `steps/operations/02-deploy.md` (1箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/operations/04-completion.md` (2箇所) | `{{aidlc_dir}}/bug-response-flow.md` → 参照を削除（同上）、`{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/inception/01-setup.md` (2箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/inception/02-preparation.md` (2箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/inception/05-completion.md` (1箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/inception/06-backtrack.md` (1箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/setup/02-generate-config.md` (1箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/setup/03-migrate.md` (2箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/common/rules.md` (2箇所) | `{{aidlc_dir}}/guides/...` → `guides/...` |
| `steps/common/project-info.md` (1箇所) | `{{aidlc_dir}}/` ディレクトリ参照を削除または更新 |

### 2. 設定ファイルの `paths.aidlc_dir`

**本Unitでは設定キー自体の削除は行わない**。`bootstrap.sh` が `paths.aidlc_dir` を読んで `AIDLC_DOCS_DIR` を算出しており、キーを削除するとスクリプトが壊れるため。設定キーの削除は Unit 003 で `bootstrap.sh` の修正と同時に実施する。

### 3. プリフライトチェックの更新

| ファイル | 変更内容 |
|---------|---------|
| `steps/common/preflight.md` | バッチモード呼び出しから `paths.aidlc_dir` を除去、コンテキスト変数テーブルから `aidlc_dir` 行を除去、結果提示から `aidlc_dir` 行を除去 |

### 4. スコープ外（変更しない）

以下のファイルには `aidlc_dir` 依存が残るが、本Unitでは変更しない。理由と後続対応を明記する。

| ファイル | 残存する依存 | 変更しない理由 | 後続対応 |
|---------|------------|--------------|---------|
| `skills/aidlc/scripts/lib/bootstrap.sh` | `paths.aidlc_dir` の4階層カスケード解決、`AIDLC_DOCS_DIR` の算出 | スクリプト層の `aidlc_dir` 廃止はUnit 003の責務範囲。設定キー（`config.toml`/`defaults.toml`）も `bootstrap.sh` が依存しているため本Unitでは残置する | Unit 003 で `bootstrap.sh` の `AIDLC_DOCS_DIR` 解決を `AIDLC_PLUGIN_ROOT` ベースに変更し、同時に設定キーを削除 |
| `skills/aidlc/scripts/migrate-*.sh` | `{{aidlc_dir}}` テンプレート変数の置換・検証ロジック | v1→v2移行スクリプトであり、移行元の `aidlc_dir` 前提を維持する必要がある | 移行機能が不要になった時点で廃止（バックログ検討） |

## 実装計画

1. **Phase 1: 設計** — depth_level=standard のため実施
   - ドメインモデル設計（テキスト置換が主のため簡潔に）
   - 論理設計（置換ルール・影響範囲の定義）
2. **Phase 2: 実装**
   - ステップファイル内の `{{aidlc_dir}}` 参照を一括置換
   - `preflight.md` を更新（`aidlc_dir` 参照除去）
   - `project-info.md` を更新
   - ビルド・テスト実行
   - AIレビュー

## 完了条件チェックリスト

- [ ] `skills/aidlc/steps/` 内の `{{aidlc_dir}}/guides/...` を `guides/...` に置換（検証: `grep -r '{{aidlc_dir}}' skills/aidlc/steps/` が0件）
- [ ] `{{aidlc_dir}}/bug-response-flow.md` への参照を削除（3箇所: construction/04-completion.md, operations/01-setup.md, operations/04-completion.md）
- [ ] `steps/common/project-info.md` の `{{aidlc_dir}}/` ディレクトリ参照を更新
- [ ] プリフライトチェック（`preflight.md`）から `aidlc_dir` 関連の結果表示行を除去
- [ ] `read-config.sh` のバッチモード呼び出しから `paths.aidlc_dir` を除去（preflight.md内）
- [ ] 設定キー（`.aidlc/config.toml`、`defaults.toml`）は `bootstrap.sh` 依存のため残置を確認
