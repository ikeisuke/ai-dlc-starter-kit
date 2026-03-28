# Unit 005 計画: v1→v2移行スクリプトE2Eテスト追加

## 概要

v1→v2移行スクリプト群（migrate-detect.sh, migrate-apply-config.sh, migrate-apply-data.sh, migrate-cleanup.sh, migrate-verify.sh）のE2Eテストをbats-coreで作成する。

## コマンド契約マトリクス

| スクリプト | 必須引数 | stdout JSON | stderr | 終了コード |
|-----------|---------|-------------|--------|-----------|
| migrate-detect.sh | なし | manifest JSON (`{version, status, detected_at, source_version, target_version, resources}`) | 検出プロセス診断 | 0: 成功, 2: エラー |
| migrate-apply-config.sh | `--manifest <path>` `--backup-dir <path>` | journal JSON (`{phase: "config", applied}`) | 適用処理診断 | 0: 成功, 2: エラー |
| migrate-apply-data.sh | `--manifest <path>` `--backup-dir <path>` | journal JSON (`{phase: "data", applied}`) | 移行処理診断 | 0: 成功, 2: エラー |
| migrate-cleanup.sh | `--manifest <path>` `--backup-dir <path>` | journal JSON (`{phase: "cleanup", applied}`) | 削除処理診断 | 0: 成功, 2: エラー |
| migrate-verify.sh | `--manifest <path>` | verify result JSON (`{checks, overall: "ok"/"fail"}`) | 検証処理診断 | 0: 成功, 2: エラー |

## 変更対象ファイル

### 新規作成

- `tests/migration/` - テストディレクトリ
- `tests/migration/helpers/setup.bash` - 共通セットアップ（fixture展開・manifest生成・ラッパー関数・クリーンアップ）
- `tests/migration/migrate-detect.bats` - detect スクリプトのテスト
- `tests/migration/migrate-apply-config.bats` - apply-config スクリプトのテスト
- `tests/migration/migrate-apply-data.bats` - apply-data スクリプトのテスト
- `tests/migration/migrate-cleanup.bats` - cleanup スクリプトのテスト
- `tests/migration/migrate-verify.bats` - verify スクリプトのテスト
- `tests/migration/e2e-full-flow.bats` - detect→apply-config→apply-data→cleanup→verify 一連フロー
- `tests/fixtures/v1-structure/` - v1構造fixtureディレクトリ（静的ファイル）
- `.github/workflows/migration-tests.yml` - 移行テスト専用ワークフロー

### 変更なし

- `skills/aidlc/scripts/migrate-*.sh` - 移行スクリプト本体（テスト追加のみ）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: テスト対象スクリプトの入出力・依存関係を整理
2. **論理設計**: テストケース一覧、fixtureの構成、ヘルパーの責務を定義

### Phase 2: 実装

1. **fixture作成**: v1構造を再現する最小限のファイル群
   - fixtureは「実装が検出すべき所有権条件を満たす最小構成」で作成
   - ハッシュ一致が必要なファイル（`.kiro/agents/aidlc-poc.json`, `.github/ISSUE_TEMPLATE/backlog.yml`）はスクリプト内の`KNOWN_HASHES`定義から実行時に期待値を取得し、fixture側にハッシュ定数を重複保持しない
   - シンボリックリンク（`.agents/skills/aidlc`, `.kiro/skills/aidlc`等）はセットアップヘルパーで動的生成
   - `.aidlc/config.toml`（`docs/aidlc` パス参照あり）
   - `.aidlc/cycles/v1.0.0/history/example.md`（`docs/aidlc` パス参照あり）
   - `.aidlc/cycles/backlog/` ディレクトリ

2. **共通ヘルパー作成**: テスト前後のfixture展開・クリーンアップ + コマンド契約差異の吸収
   - `AIDLC_PROJECT_ROOT` を一時ディレクトリに設定（依存注入）
   - fixtureからv1構造を一時ディレクトリにコピー
   - コマンド契約マトリクスの差異を吸収するラッパー関数（`run_detect`, `run_apply_config`, `run_apply_data`, `run_cleanup`, `run_verify`）
   - JSON出力の共通検証ヘルパー（jqベースの契約検証）
   - テスト後にクリーンアップ

3. **個別スクリプトテスト**（filesystem fixture + JSON contract の2層構造）:
   - migrate-detect.sh: 8リソースタイプ全ての検出テスト + already_v2判定 + manifest JSON schema検証
   - migrate-apply-config.sh: config.toml内パス置換テスト + journal JSON contract検証
   - migrate-apply-data.sh: Markdown内パス置換テスト + journal JSON contract検証
   - migrate-cleanup.sh: 削除対象リソースの除去確認 + パス安全性検証 + journal JSON contract検証
   - migrate-verify.sh: 3検証チェック（config_paths, v1_artifacts_removed, data_migrated）+ verify result JSON contract検証

4. **E2Eテスト**: detect→apply-config→apply-data→cleanup→verifyの一連フロー（JSON中間出力をパイプラインで検証）

5. **CI対応**: 移行テスト専用ワークフロー（`.github/workflows/migration-tests.yml`）を新規作成
   - トリガーパス: `skills/aidlc/scripts/migrate-*.sh`, `skills/aidlc/scripts/lib/**`, `tests/migration/**`, `tests/fixtures/**`
   - bats-core + jq のセットアップステップを含む
   - `pr-check.yml` は既存のMarkdown系チェック専用のまま維持

## 完了条件チェックリスト

- [x] v1構造fixtureディレクトリの作成（tests/fixtures/）
- [x] migrate-detect.shの8リソースタイプ全てのテスト
- [x] migrate-apply-config.shのテスト（config.toml内のdocs/aidlc→skills/aidlcパス置換）
- [x] migrate-apply-data.shのテスト（Markdownファイル内の参照パス置換）
- [x] migrate-cleanup.shのテスト（削除対象リソースの除去確認）
- [x] migrate-verify.shの3検証チェックのテスト
- [x] E2Eテスト（detect→apply-config→apply-data→cleanup→verifyの一連フロー）
- [x] CI自動実行の確認（移行テスト専用ワークフロー）
