# Unit 001 計画: パス参照問題の調査・修正

## 概要

プラグイン環境で破綻する `../../` 等の相対パス参照を修正し、スキル間の内部依存を除去する。

## 設計方針

### パス解決ポリシー

migrateスクリプト群のパス解決は以下の統一方式に従う:

- **プロジェクトルート**: `AIDLC_PROJECT_ROOT` 環境変数を直接使用（全スクリプト共通）
- **プラグインルート**: `AIDLC_PLUGIN_ROOT` は `AIDLC_PROJECT_ROOT` からの算出を維持（既存のbootstrap.shと同一方式）
- `/../..` による逆方向算出を廃止し、`AIDLC_PROJECT_ROOT` の直接参照に置き換える

### 依存境界ルール（既存制約の参照）

`.aidlc/rules.md` に既に「ファイル参照境界ルール」と「スキル間依存ルール」が定義済み。本Unitは既存ルールに基づいて違反箇所を修正する。

### Markdownリンク修正方針

`steps/` 配下のMarkdownファイルはAIエージェントが読み込むプロンプトであり、`../../` 相対リンクはプラグイン環境で破綻する。スキルベース相対パスのテキスト参照（`guides/skill-usage-guide.md` 形式）に変更する。これはプラグイン環境のパス解決ルール（SKILL.mdの「パス解決」）に準拠した正規化である。

## 調査結果

### 修正が必要な箇所

| # | ファイル | 問題 | 修正方針 |
|---|---------|------|---------|
| 1 | `skills/aidlc/steps/common/ai-tools.md:5` | `../../guides/skill-usage-guide.md` Markdownリンク | スキルベース相対パス `guides/skill-usage-guide.md` のテキスト参照に変更 |
| 2 | `skills/aidlc/steps/common/intro.md:26` | `../../guides/error-handling.md` Markdownリンク | スキルベース相対パス `guides/error-handling.md` のテキスト参照に変更 |
| 3 | `skills/aidlc/guides/skill-usage-guide.md:209-214` | `../../skills/reviewing-*` シンボリックリンク記述 | プラグイン環境向けのパス表記に更新（旧スキル名はUnit 002で対応するため、パス形式のみ修正） |
| 4 | `skills/aidlc-migrate/scripts/migrate-detect.sh:29,130` | `AIDLC_PLUGIN_ROOT` ハードコード + `/../..` でプロジェクトルート算出 | `AIDLC_PROJECT_ROOT` を直接使用（`_starter_kit_root="$AIDLC_PROJECT_ROOT"`） |
| 5 | `skills/aidlc-migrate/scripts/migrate-cleanup.sh:26,108` | `AIDLC_PLUGIN_ROOT` ハードコード（`${AIDLC_PROJECT_ROOT}/skills/aidlc`） | プラグイン環境のルート検出に変更（`AIDLC_PROJECT_ROOT` を直接使用） |
| 6 | `skills/aidlc-migrate/scripts/migrate-apply-config.sh:143,145` | `@skills/aidlc/` ハードコードの grep パターン | プラグイン環境でも動作するパターンに修正 |

### 修正対象外（scripts/tests/ はメタ開発例外）

- `skills/aidlc/scripts/tests/test_detect_phase.sh:22` — `../../..`
- `skills/aidlc/scripts/tests/test_bootstrap_utils.sh:23` — `../../../..`

**例外の根拠**: テストスクリプトはメタ開発リポジトリ内でのみ実行され、プラグインとして外部配布されない。`PROJECT_ROOT` の算出にはリポジトリルートからの相対パスが正当な方法である。

### 修正不要（正当な参照）

- `skills/aidlc/scripts/lib/bootstrap.sh:30` — 同スキル内の `/../..` でプラグインルート算出（正当）
- `skills/aidlc/scripts/*.sh` — `${SCRIPT_DIR}/lib/` は同スキル内参照（正当）
- `skills/aidlc-setup/scripts/*.sh` — `${SCRIPT_DIR}/../` は同スキル内参照（正当）

## 変更対象ファイル

1. `skills/aidlc/steps/common/ai-tools.md`
2. `skills/aidlc/steps/common/intro.md`
3. `skills/aidlc/guides/skill-usage-guide.md`
4. `skills/aidlc-migrate/scripts/migrate-detect.sh`
5. `skills/aidlc-migrate/scripts/migrate-cleanup.sh`
6. `skills/aidlc-migrate/scripts/migrate-apply-config.sh`

## 実装計画

### Phase 1: Markdownファイルのパス参照修正

1. `ai-tools.md` の `../../guides/` リンクをスキルベース相対パスのテキスト参照に変更
2. `intro.md` の `../../guides/` リンクをスキルベース相対パスのテキスト参照に変更
3. `skill-usage-guide.md` のシンボリックリンク記述のパス形式を更新

### Phase 2: migrate スクリプトのプラグイン環境対応

1. `migrate-detect.sh`: 130行目の `AIDLC_PLUGIN_ROOT/../..` を `AIDLC_PROJECT_ROOT` 直接使用に修正
2. `migrate-cleanup.sh`: `AIDLC_PLUGIN_ROOT` のハードコードを `AIDLC_PROJECT_ROOT` ベースに修正
3. `migrate-apply-config.sh`: grep パターンをプラグイン環境非依存に修正

### Phase 3: 検証

1. `skills/` 配下に `../../` 参照が残っていないことを grep で確認（`scripts/tests/` 除く）
2. 修正したスクリプトのシンタックスチェック（`bash -n`）
3. `AIDLC_PROJECT_ROOT` 未設定時のエラーハンドリング確認（bootstrap.shの既存チェックとの整合性）

## 完了条件チェックリスト

- [ ] `skills/` 配下のスクリプト・Markdownファイルの `../../` 参照を修正（`scripts/tests/` 配下は除外）
- [ ] aidlc-migrate の `migrate-detect.sh` のプラグイン環境対応
- [ ] aidlc-setup のスクリプトのパス参照修正（調査の結果、修正不要であることを確認済み）
- [ ] aidlc guides 内のMarkdownリンク修正
- [ ] スキル間の内部ファイル直接参照の除去
