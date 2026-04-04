# Unit 003 計画: config.toml欠落キー検出・追記候補提示

## 概要
defaults.tomlをスキーマとしてconfig.tomlに欠落しているキーを検出し、追記候補として提示する機能を`/aidlc setup`のアップグレードフローに追加する。

## 対応方針

### サブ責務A: 差分検出スクリプト
- `skills/aidlc-setup/scripts/detect-missing-keys.sh` を新規作成
- defaults.tomlの全リーフキーを列挙し、config.tomlに存在しないキーを検出
- 欠落キーをkey:default_value形式で標準出力

### サブ責務B: aidlc-setupフロー統合
- `skills/aidlc-setup/steps/02-generate-config.md` のアップグレードフローに欠落キー検出ステップを追加
- 既存の確認UIパターンを流用してユーザーに追記候補を提示
- ユーザー確認後にdaselでconfig.tomlに追記

## 完了条件チェックリスト
- [ ] defaults.tomlとconfig.tomlの差分が正しく検出されること
- [ ] 欠落キーが追記候補として提示されること
- [ ] ユーザー確認後にのみ追記されること
- [ ] 既存設定値が上書きされないこと
- [ ] 欠落キー0件時に「欠落キーなし」と表示されること
- [ ] defaults.toml不在時にスキップされること
- [ ] dasel未インストール時にエラーにならないこと

## 変更対象ファイル
- `skills/aidlc-setup/scripts/detect-missing-keys.sh`（新規）
- `skills/aidlc-setup/steps/02-generate-config.md`（修正）
