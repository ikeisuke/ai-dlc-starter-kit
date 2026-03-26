# Unit 001 計画: defaults.toml デフォルト値の補完

## 概要
`prompts/package/config/defaults.toml` に `rules.cycle.mode` と `rules.upgrade_check.enabled` のデフォルト値を追加し、`read-config.sh` のキー不在エラーを解消する。

## 変更対象ファイル
- `prompts/package/config/defaults.toml` — デフォルト値追加（正本）
- `docs/aidlc/config/defaults.toml` — 同期反映

## 実装計画

### Phase 1: 設計
- ドメインモデル・論理設計は設定ファイルの行追加のみのため簡略化

### Phase 2: 実装
1. `prompts/package/config/defaults.toml` に以下を追加:
   - `[rules.cycle]` セクションに `mode = "default"`
   - `[rules.upgrade_check]` セクションに `enabled = false`
2. `docs/aidlc/config/defaults.toml` に同内容を反映
3. 動作確認: `read-config.sh rules.cycle.mode` と `read-config.sh rules.upgrade_check.enabled` の実行結果を確認

## 完了条件チェックリスト
- [ ] `prompts/package/config/defaults.toml` に欠落しているデフォルト値を追加
- [ ] `docs/aidlc/config/defaults.toml` への同期反映
