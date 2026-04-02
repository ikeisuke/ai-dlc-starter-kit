# Unit 002 計画: named_enabled 設定キーの追加

## 概要

`rules.cycle.named_enabled` 設定キーを追加し、名前付きサイクル機能のon/offを制御できるようにする。デフォルト `false` で意図的にopt-in化する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/config/defaults.toml` | `[rules.cycle]` セクションに `named_enabled = false` を追加 |
| `skills/aidlc/steps/inception/01-setup.md` | ステップ7の先頭に `named_enabled` チェックを追加。`false` の場合 `mode=named` の分岐とステップ8をスキップ |
| `skills/aidlc/config/config.toml.example` | `[rules.cycle]` セクションに `named_enabled` の説明とデフォルト値を追加 |

## 依存関係確認

- `defaults.toml` の `[rules.cycle]` セクションには既に `mode = "default"` が存在。同セクションに追加する
- `inception/01-setup.md` のステップ7で `cycle_mode` を読み取る前に `named_enabled` をチェックする必要がある
- ステップ8（名前付きサイクル継続確認）は `named_enabled=false` の場合スキップ対象
- `config.toml.example` の `[rules.cycle]` セクションに `named_enabled` の説明を追加し、`mode=named`/`ask` を使うには `named_enabled=true` が必要であることを明記する

## 実装計画

1. `skills/aidlc/config/defaults.toml` の `[rules.cycle]` セクションに `named_enabled = false` を追加
2. `skills/aidlc/steps/inception/01-setup.md` のステップ7の先頭に `named_enabled` 読み取りと分岐を追加:
   - `read-config.sh rules.cycle.named_enabled` で値を取得
   - `false` の場合: `cycle_mode` を `"default"` に設定し、ステップ8をスキップしてステップ9へ進む
   - `true` の場合: 既存のステップ7のフローをそのまま実行
3. ステップ8のスキップ条件に `named_enabled=false` を追加
4. `skills/aidlc/config/config.toml.example` の `[rules.cycle]` セクションに `named_enabled` の説明を追加

## 完了条件チェックリスト

- [ ] `defaults.toml` に `rules.cycle.named_enabled = false` が追加されていること
- [ ] `inception/01-setup.md` のステップ7に `named_enabled` チェックが追加されていること
- [ ] `named_enabled=false` の場合、mode=namedの分岐とステップ8がスキップされること
- [ ] `named_enabled=true` の場合、ステップ7-8が従来通り動作すること
- [ ] `.aidlc/config.toml` に `rules.cycle.named_enabled` キーが未設定のとき、`read-config.sh rules.cycle.named_enabled` が `defaults.toml` の `false` を返すこと
- [ ] `config.toml.example` に `named_enabled` の説明が追加されていること
