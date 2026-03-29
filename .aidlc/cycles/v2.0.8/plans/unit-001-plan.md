# Unit 001 計画: バグ修正（スクリプト）

## 概要
3件のスクリプトバグを修正する（#463, #465, #466）。

## 変更対象ファイル

### #466: squash-unit.sh --dry-run修正
- `skills/aidlc/scripts/squash-unit.sh` — --message必須チェックをDRY_RUN=false時のみに変更

### #463: migrate-config.sh --dry-run修正
- `skills/aidlc-setup/scripts/migrate-config.sh` — cleanup trap内の_cleanup_files配列の空チェック追加

### #465: bootstrap.sh依存脱却
- `skills/aidlc-migrate/scripts/migrate-verify.sh`
- `skills/aidlc-migrate/scripts/migrate-apply-data.sh`
- `skills/aidlc-migrate/scripts/migrate-detect.sh`
- `skills/aidlc-migrate/scripts/migrate-apply-config.sh`
- `skills/aidlc-migrate/scripts/migrate-cleanup.sh`
- `skills/aidlc-setup/scripts/migrate-backlog.sh`

### テスト更新対象
- `tests/migration/migrate-detect.bats`
- `tests/migration/migrate-apply-config.bats`
- `tests/migration/migrate-apply-data.bats`
- `tests/migration/migrate-cleanup.bats`
- `tests/migration/migrate-verify.bats`

## 実装計画

1. **#466修正**: `--message`チェックの条件に`DRY_RUN != true`を追加
2. **#463修正**: cleanup関数で`_cleanup_files`配列を安全に展開（`${_cleanup_files[@]+"${_cleanup_files[@]}"}`パターン）
3. **#465修正**: 各スクリプトに最小限のパス解決ロジックを埋め込む（共有helper不使用）
   - `source bootstrap.sh` を除去
   - 各スクリプトが使用する変数（AIDLC_PROJECT_ROOT, AIDLC_PLUGIN_ROOT, AIDLC_CONFIG, AIDLC_CYCLES等）をスクリプト冒頭で直接定義
   - AIDLC_PROJECT_ROOT: `git rev-parse --show-toplevel` で解決
   - AIDLC_PLUGIN_ROOT: 不要な場合は削除、必要な場合はプロジェクトルートからの相対パスで解決
   - 既存テスト（tests/migration/*.bats）を更新し、bootstrap.sh依存を除去した状態でも正常動作することを確認

## 完了条件チェックリスト
- [ ] `squash-unit.sh --dry-run --cycle v2.0.8 --phase inception --vcs git` が --message なしで exit 0
- [ ] `squash-unit.sh --cycle v2.0.8 --phase inception --vcs git` が --message なしで exit 1（既存動作維持）
- [ ] `migrate-config.sh --config .aidlc/config.toml --dry-run` でunbound variableエラーが発生せずexit 0
- [ ] 対象6ファイルが `grep -r "source.*bootstrap" <file>` で0件
- [ ] 対象6スクリプトが `--help` または `--dry-run` で起動可能（exit 0 or 期待されるexit code）
- [ ] tests/migration/*.bats のうちbootstrap.sh依存テストが修正後も通過
