# PRFAQ: AI-DLC Starter Kit v2.1.3

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.1.3 — 設定整合性の改善とバージョン確認機能の追加

**副見出し**: 未使用設定キーの除去、名前付きサイクル機能のopt-in制御、AskUserQuestionルール明文化、versionアクションを追加

**発表日**: 2026-04-02

**本文**:

AI-DLC Starter Kit v2.1.3では、v2.1.2のOperations Phaseで検出された4件の改善課題に対応しました。

設定ファイルから未使用の `cycles_dir` キーを除去し、名前付きサイクル機能に `named_enabled` 設定キーを追加してopt-in制御を可能にしました。また、semi_autoモードでのAskUserQuestionツールの適切な使用ルールを明文化し、`/aidlc version` コマンドでスキルバージョンを即座に確認できるようになりました。

## FAQ（よくある質問）

### Q1: `cycles_dir` を削除しても既存の設定ファイルに影響はありますか？
A: ありません。daselは未知のキーを無視するため、既存の `config.toml` に `cycles_dir` が残っていてもエラーは発生しません。

### Q2: 名前付きサイクル機能を使いたい場合はどうすればいいですか？
A: `config.toml` に `[rules.cycle]` セクションで `named_enabled = true` を追加してください。デフォルトは `false`（無効）です。

### Q3: `/aidlc version` はどのような出力をしますか？
A: `starter_kit_version` の値を1行で表示します。短縮形 `/aidlc v` も使用できます。
