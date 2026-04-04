# ユーザーストーリー

## Epic: aidlc-setupスキルのスキル間依存ルール準拠

### ストーリー 1: defaults.tomlの自スキル内配置
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to `aidlc-setup` スキルが自スキル内の `config/defaults.toml` を参照する
So that スキル間依存ルールに準拠し、`aidlc` スキルの内部構造変更に影響されない

**受け入れ基準**:
- [ ] `skills/aidlc-setup/config/defaults.toml` が存在し、`skills/aidlc/config/defaults.toml` とTOML設定値部分が一致すること（同期用コメントの差異は許容）
- [ ] `02-generate-config.md` 内の欠落キー検出ステップで、`--defaults` 引数に渡すパスが自スキルのベースディレクトリ配下の `config/defaults.toml` に解決されること（`aidlc` スキルのパスを含まないこと）
- [ ] `skills/aidlc-setup/steps/` および `skills/aidlc-setup/scripts/` 内に `aidlc` スキルの内部パスへの参照がないこと
- [ ] `/aidlc setup` のアップグレードモードで、`config.toml` から既知のキー（例: `rules.squash.enabled`）を除去した状態で実行すると、該当キーが追記候補として表示される
- [ ] 既存キーが誤検出されない（false positive なし）
- [ ] `aidlc` スキルの既存フロー（プリフライトチェック、設定読み込み等）が変更前と同一の結果になること（非回帰確認）
- [ ] `skills/aidlc-setup/config/defaults.toml` が欠落している場合、欠落キー検出ステップが「defaults.toml が見つかりません。欠落キー検出をスキップします。」と表示してスキップすること（既存の異常系動作を維持）

**技術的考慮事項**:
- `detect-missing-keys.sh` の `--defaults` 引数インターフェイスは変更しない
- パス解決のみ変更（自スキルのベースディレクトリ配下の `config/defaults.toml`）
- `aidlc` スキルへの変更は不要
