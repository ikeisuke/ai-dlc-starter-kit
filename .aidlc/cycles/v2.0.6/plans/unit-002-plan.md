# Unit 002 計画: バージョン検証ロジック共通化

## 概要
バージョン検証の共通関数を作成し、各スクリプトから利用する。

## 変更対象ファイル
- `skills/aidlc/scripts/lib/version.sh` (新規作成)
- `bin/update-version.sh`
- `skills/aidlc-setup/bin/aidlc-setup.sh`

## 実装計画

### 1. 共通関数 `skills/aidlc/scripts/lib/version.sh`
- `validate_semver()`: SemVerフォーマット検証（X.Y.Z + optional prerelease）
- `strip_v_prefix()`: vプレフィックス除去
- `read_starter_kit_version()`: config.tomlからstarter_kit_version読取
- 正規表現: `^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[a-zA-Z0-9.]+)?$`

### 2. update-version.sh
- 独自の正規表現を共通関数に置換

### 3. aidlc-setup.sh
- 制限的な正規表現 `^[0-9]+(\.[0-9]+){0,2}$` を共通関数に置換
- prerelease版も受け入れるようになる

## 完了条件チェックリスト
- [ ] バージョン検証の共通関数が作成される
- [ ] aidlc-setup.sh、update-version.sh が共通関数を使用する
- [ ] prerelease形式が全スクリプトで統一的に扱われる
- [ ] starter_kit_versionの読取ロジックの重複が解消される
