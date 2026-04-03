# Unit 004: バージョンチェック改善・setup早期判定改修 - 計画

## 概要

`/aidlc`起動時のバージョンチェック（Inception Phase ステップ6）の設定キーをリネームし、デフォルト有効化する。メタ開発スキップ条件（STARTER_KIT_DEV）を廃止する。また、setupスキルの早期判定でconfig.toml存在時にバージョン比較を追加し、不一致時にアップグレードモードに遷移できるようにする。

## 変更対象ファイル

- `skills/aidlc/steps/inception/01-setup.md` - ステップ6のバージョンチェックロジック改修（設定キー変更、STARTER_KIT_DEV条件削除）
- `skills/aidlc/config/defaults.toml` - `[rules.upgrade_check]` → `[rules.version_check]`、`enabled = false` → `enabled = true`
- `skills/aidlc-setup/steps/01-detect.md` - config.toml存在時のバージョン比較ロジック追加
- `skills/aidlc-setup/scripts/migrate-config.sh` - `rules.upgrade_check` → `rules.version_check` のマイグレーション処理更新
- `.aidlc/config.toml` - `[rules.upgrade_check]` セクションを `[rules.version_check]` にリネーム

## 設定解決順（互換インターフェース）

実行時の設定読み取りは以下の優先順で解決する。マイグレーション（永続化）と実行時フォールバック（互換性維持）は別の責務として分離する。

1. `rules.version_check.enabled`（新キー）→ 値があればその値を使用
2. `rules.upgrade_check.enabled`（旧キー）→ 新キー不在時のフォールバック
3. デフォルト値（`true`）→ 両キー不在時

**マイグレーション層の責務**: `migrate-config.sh`が旧キーを新キーにリネームし永続化する
**実行時フォールバックの責務**: `01-setup.md`のステップ6が上記優先順で設定を解決する

## バージョン比較の共通契約

`01-detect.md`（setup早期判定）と`01-setup.md`（バージョンチェック）はそれぞれ異なる目的でバージョン比較を行うが、以下の共通契約に従う:

- **バージョン取得元**: `config.toml`の`starter_kit_version`（ローカル）、スキルの`version.txt`（スキル側）
- **正規化**: 先頭`v`プレフィックスを除去し、前後空白をトリム
- **比較条件**: 文字列完全一致（semver比較ではない）
- **失敗時フォールバック**: どちらか一方でも取得失敗・パース不能の場合は比較をスキップし、従来の動作を維持（警告のみ表示）
- **責務分離**: `01-detect.md`は「アップグレードモード遷移判定」、`01-setup.md`は「バージョン不整合の表示・案内」

## 実装計画

### 1. 設定キーリネーム（defaults.toml）

- `[rules.upgrade_check]` → `[rules.version_check]` にセクション名変更
- `enabled = false` → `enabled = true` にデフォルト値変更
- コメントを「バージョンチェック設定」に更新

### 2. バージョンチェックロジック改修（01-setup.md）

- ステップ6の設定キー参照を `rules.version_check.enabled` に変更（設定解決順に従い旧キーフォールバックを明記）
- `STARTER_KIT_DEV` によるスキップ条件を削除
- デフォルト有効化に合わせて、`enabled = false` の場合にスキップするロジックに変更（従来は `enabled = true` の場合のみ実行）
- 3ソース比較（ComparisonMode）の大枠は維持

### 3. setupスキル早期判定改修（01-detect.md）

- config.toml存在時の処理フローにバージョン比較を追加
- `starter_kit_version`（config.toml）とスキルの`version.txt`を比較（共通契約に従う）
- **正常系**: 両方取得成功かつ不一致 → アップグレードモードに遷移
- **正常系**: 両方取得成功かつ一致 → 従来通りInception Phaseへの遷移を案内
- **異常系フェイルセーフ**: `version.txt`読取失敗、`starter_kit_version`未設定、パース不能の場合 → 従来のInception遷移を維持し警告のみ表示（アップグレード判定をスキップ）

### 4. マイグレーション処理更新（migrate-config.sh）

- `_add_section` のパターンを `rules\\.version_check` に変更
- セクション内容を `[rules.version_check]` に更新
- 旧キー `rules.upgrade_check` が存在する場合のリネーム処理を追加

### 5. 開発環境設定更新（.aidlc/config.toml）

- `[rules.upgrade_check]` → `[rules.version_check]` にセクション名変更

## 完了条件チェックリスト

- [x] バージョンチェックの設定キーリネーム（`rules.upgrade_check.enabled` → `rules.version_check.enabled`）が完了している
- [x] デフォルト有効化（`config/defaults.toml` で `enabled = true`）が設定されている
- [x] メタ開発スキップ（STARTER_KIT_DEV）条件が01-setup.mdから削除されている
- [x] setupスキルのconfig.toml存在時にバージョン比較が追加されている
- [x] `config/defaults.toml` のデフォルト値が更新されている
