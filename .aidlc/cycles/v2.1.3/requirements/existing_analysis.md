# 既存コードベース分析

## 変更対象ファイルと現状

### #506: cycles_dir 関連

| ファイル | 現状 | 変更内容 |
|---------|------|---------|
| `.aidlc/config.toml` (行16-17) | `cycles_dir = ".aidlc/cycles"` | `[paths]` セクションごと削除 |
| `skills/aidlc/config/defaults.toml` | `[paths]` セクションなし | 変更不要 |
| `skills/aidlc-setup/templates/config.toml.template` (行21) | `cycles_dir = "docs/cycles"` | 削除 |
| `skills/aidlc-setup/steps/02-generate-config.md` | テンプレート例に `cycles_dir` あり | 例示から削除 |

### #507: named_enabled 関連

| ファイル | 現状 | 変更内容 |
|---------|------|---------|
| `skills/aidlc/config/defaults.toml` (行56-57) | `[rules.cycle]` に `mode = "default"` のみ | `named_enabled = false` を追加 |
| `skills/aidlc/steps/inception/01-setup.md` | ステップ7-8で常時名前付きサイクル分岐あり | `named_enabled` チェックを追加 |

### #505: AskUserQuestion ルール

| ファイル | 現状 | 変更内容 |
|---------|------|---------|
| `skills/aidlc/steps/common/rules.md` | AskUserQuestion関連記述なし | 使用ルールセクション追加 |
| `skills/aidlc/CLAUDE.md` (行7-24) | 「AskUserQuestion機能の活用」セクションあり | rules.mdへの統合後、参照に変更 |

### #508: version アクション

| ファイル | 現状 | 変更内容 |
|---------|------|---------|
| `skills/aidlc/SKILL.md` | 引数: i/c/o/e/h/setup/feedback/migrate | `version`（`v`）を追加 |
| `skills/aidlc/scripts/env-info.sh` | `starter_kit_version` を出力済み | 変更不要（version表示で参照） |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 設定形式 | TOML | `.aidlc/config.toml` |
| 設定パーサ | dasel | `scripts/read-config.sh` |
| スクリプト言語 | Bash | `scripts/*.sh` |
| プロンプト形式 | Markdown | `steps/**/*.md` |

## 特記事項

- daselは未知キーを無視するため、`cycles_dir` 削除後も既存設定での互換性は自動的に維持される
- `env-info.sh` には既に `starter_kit_version` 取得ロジックがあり、`/aidlc version` はこれを活用可能
- `CLAUDE.md` にAskUserQuestion記述があるが、`rules.md` に統合して一元化するのが適切
