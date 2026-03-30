# Unit 005 計画: アップグレード判定修正

## 概要

check-version.shとcheck-setup-type.shを修正し、既存プロジェクトのアップグレードを正しく検出する。

## 根本原因

vプレフィックス付きバージョン（例: `v1.22.0`）がsemver正規表現 `^[0-9]+(\.[0-9]+){0,2}$` に拒否され、`not_found` を返す。check-setup-type.shは `not_found` を `initial` にマッピングするため、docs/aidlc.tomlが存在する既存プロジェクトでも「初回セットアップ」と誤判定される。

## 変更対象ファイル

1. `prompts/setup/bin/check-version.sh` - vプレフィックス正規化関数の追加
2. `prompts/setup/bin/check-setup-type.sh` - フォールバック改善

## 実装計画

### check-version.sh の修正

1. `sanitize_version()` 関数を追加（vプレフィックス除去 + 空白トリムを共通化）
2. KIT_VERSION取得後（L43付近）とPROJECT_VERSION取得後（L61付近）の両方で `sanitize_version()` を適用
3. 既存の `normalize_version()` はメジャー.マイナー.パッチの正規化のみに留める（責務分離）

### check-setup-type.sh の修正

1. `not_found` ケース（L67-69）を変更: aidlc.tomlが存在するブロック内で `not_found` を受けた場合、`setup_type:upgrade` を返す（バージョン比較なし）
2. ワイルドカード `*` ケース（L71-73）は `setup_type:` （unknown）を返す（fail-open防止: 未知のステータスは警告扱いとしAIに委ねる）

## 完了条件チェックリスト

- [ ] check-version.shのvプレフィックス正規化（sanitize_version関数として共通化）
- [ ] check-setup-type.shのフォールバック改善（docs/aidlc.toml存在時はinitialではなくupgradeとして扱う）
- [ ] 既存の正当なバージョン（v1.22.0、1.22.0等）に影響しないこと
