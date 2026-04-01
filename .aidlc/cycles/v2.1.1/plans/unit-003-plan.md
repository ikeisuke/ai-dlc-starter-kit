# Unit 003 計画: マイグレーションフロー修正

## 概要

aidlc-migrateスキルの2つのバグを修正する:
1. **#499**: マイグレーション後に `starter_kit_version` が更新されない問題
2. **#490**: Issueテンプレートの自動削除判定がハッシュ比較で機能しない問題

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-migrate/scripts/migrate-apply-config.sh` | starter_kit_version更新処理を追加 |
| `skills/aidlc-migrate/scripts/migrate-detect.sh` | セクション6をハッシュ比較方式に変更 |
| `skills/aidlc-migrate/scripts/migrate-verify.sh` | starter_kit_version検証チェックを追加 |
| `skills/aidlc-migrate/config/known-hashes.json` | 既知テンプレートハッシュの定義ファイル（新規） |

## 実装計画

### タスク1: starter_kit_version更新 (#499)

**場所**: `migrate-apply-config.sh` の `migrate-config.sh` 実行後

1. `skills/aidlc/scripts/lib/version.sh` の `read_starter_kit_version()` を使用して現在値を読み取り（共通ライブラリ利用、ロジック重複なし）
2. `env-info.sh` 出力の `starter_kit_version:` 行からcanonical versionを取得
3. `dasel` で `.aidlc/config.toml` の `starter_kit_version` を更新
4. 更新成功をジャーナルに記録

**安全策（migrate-config.sh失敗時の制御）**:
- `migrate-config.sh` の実行結果（終了コード）を確認
- 失敗時（`|| true` で握りつぶされている現行コードの後に判定追加）はversion更新をスキップし、journalに `status: "skipped"`, `detail: "config migration failed"` を記録
- version更新は設定移行成功を前提条件とする（同一トランザクション責務）

### タスク2: starter_kit_version検証 (#499)

**場所**: `migrate-verify.sh` に新規チェック `starter_kit_version_updated` を追加

1. `version.sh` の `read_starter_kit_version()` で `.aidlc/config.toml` から現在値を取得
2. `env-info.sh` 出力からcanonical version（期待値）を取得
3. **完全一致検証**: 取得した値がcanonical versionと完全一致することを検証（「旧値でない」ではなく「期待値との一致」）
4. 検証結果をcheckに追加（既存のconfig_paths, v1_artifacts_removed, data_migratedと並列）

### タスク3: Issueテンプレートハッシュ比較 (#490)

**場所**: `migrate-detect.sh` セクション6

**データ分離**: 既知ハッシュ値は `skills/aidlc-migrate/config/known-hashes.json` に定義ファイルとして分離。`migrate-detect.sh` はこのファイルをsourceして参照する。

1. `config/known-hashes.json` に連想配列 `KNOWN_V1_TEMPLATE_HASHES` を定義
2. `migrate-detect.sh` セクション6で定義ファイルをsource
3. 各テンプレートの実ハッシュ値を `sha256sum` で計算
4. ハッシュ一致 → `action: "delete"`（`is_owned: true`, `expected_hash`, `actual_hash` を設定）で自動削除対象
5. ハッシュ不一致 → `action: "confirm_delete"`（`is_owned: false`, `expected_hash`, `actual_hash` を設定）で確認対象
6. manifestの `ownership_evidence` フィールドを活用してevidenceを記録

## 完了条件チェックリスト

- [ ] migrate-apply-config.shにstarter_kit_versionの更新処理を追加（version.sh共通ライブラリ使用）
- [ ] migrate-config.sh失敗時にversion更新をスキップする安全策を実装
- [ ] migrate-detect.shのセクション6でv1テンプレートの既知ハッシュ値によるテンプレート判定を実装
- [ ] 既知ハッシュ値をconfig/known-hashes.jsonに分離
- [ ] migrate-verify.shにstarter_kit_versionのcanonical version完全一致検証を追加
