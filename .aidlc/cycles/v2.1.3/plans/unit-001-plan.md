# Unit 001 計画: 未使用設定キー cycles_dir の削除

## 概要

config.toml・セットアップテンプレートから未使用の `[paths].cycles_dir` 設定キーを削除する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `.aidlc/config.toml` | `cycles_dir` キーを削除し、結果として `[paths]` が空になるためセクションごと削除 |
| `skills/aidlc-setup/templates/config.toml.template` | `cycles_dir` キーを削除し、結果として `[paths]` が空になるためセクションごと削除 |

## 依存関係確認

`rg -n "cycles_dir"` で横断確認した結果、実コード・スクリプトからの参照は以下の通り:

| 参照箇所 | 区分 | 対応 |
|---------|------|------|
| `.aidlc/config.toml` (行17) | 削除対象 | 本Unitで削除 |
| `skills/aidlc-setup/templates/config.toml.template` (行21) | 削除対象 | 本Unitで削除 |
| `.aidlc/cycles/` 配下の過去サイクル成果物 | 歴史的記録 | 変更不要（過去の設計・計画ドキュメント） |
| `skills/aidlc/config/defaults.toml` | 確認済み | 存在しない（対応不要） |
| `skills/aidlc-setup/steps/02-generate-config.md` | 確認済み | `cycles_dir` の参照なし |

スクリプト（`read-config.sh`, `bootstrap.sh` 等）およびプロンプトファイルからの動的参照は存在しない。

## 実装計画

1. `.aidlc/config.toml` から `cycles_dir` キーおよび空の `[paths]` セクション（行16-17）を削除
2. `skills/aidlc-setup/templates/config.toml.template` から `cycles_dir` キーおよび空の `[paths]` セクション（行20-21）を削除
3. `defaults.toml` に `[paths].cycles_dir` が存在しないことを確認（確認済み: 存在しない）
4. 後方互換性確認: `cycles_dir` が残った既存 `config.toml` で `read-config.sh` が正常動作することを確認（daselが未知キーを無視することの検証）

## 完了条件チェックリスト

- [ ] `.aidlc/config.toml` から `cycles_dir` キーおよび `[paths]` セクションが削除されていること
- [ ] セットアップテンプレートから `cycles_dir` キーおよび `[paths]` セクションが削除されていること
- [ ] セットアップステップの設定例から `cycles_dir` 参照が削除されていること（確認済み: 参照なし）
- [ ] `defaults.toml` に `[paths].cycles_dir` が存在しないこと（確認済み: 存在しない）
- [ ] 既存 `config.toml` に `cycles_dir` が残った状態で `read-config.sh` が正常に動作すること（後方互換性）
