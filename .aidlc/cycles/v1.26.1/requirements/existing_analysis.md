# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
prompts/package/          # 正本（編集対象）
├── bin/                  # ユーティリティスクリプト
│   ├── read-config.sh   # 4層設定読み込み（defaults→user→project→local）
│   ├── check-bash-substitution.sh  # $()検出スクリプト
│   └── ...
├── config/
│   └── defaults.toml    # デフォルト設定値（レイヤー0）
├── prompts/
│   ├── inception.md      # --default使用: 3箇所
│   ├── operations-release.md  # 7.6にBash Substitution Check
│   └── common/
│       ├── preflight.md  # --default使用: 11箇所（バッチモード化対象）
│       ├── commit-flow.md # --default使用: 1箇所
│       ├── feedback.md   # --default使用: 1箇所
│       ├── compaction.md # --default使用: 1箇所
│       └── rules.md      # --default使用: 10箇所以上
└── skills/aidlc-setup/   # --default使用: 1箇所

docs/aidlc/               # デプロイ先（rsyncコピー、直接編集禁止）
docs/cycles/rules.md      # プロジェクト固有カスタムワークフロー
```

## アーキテクチャ・パターン

- **4層設定マージ**: defaults.toml → ~/.aidlc/config.toml → docs/aidlc.toml → docs/aidlc.local.toml
  - 根拠: `read-config.sh` の実装（4ファイルを順に読み込み）
- **ソース→デプロイ分離**: prompts/package/ が正本、docs/aidlc/ がデプロイ先
  - 根拠: rules.md「docs/aidlc/ は直接編集禁止」、aidlc-setupスキル
- **終了コードベースのエラーハンドリング**: 0=成功, 1=キー不在, 2=スクリプトエラー
  - 根拠: read-config.sh の実装

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash, Markdown | bin/*.sh, prompts/*.md |
| ツール | dasel (v2/v3互換), gh CLI | read-config.sh, env-info.sh |
| 設定形式 | TOML | defaults.toml, aidlc.toml |

## 依存関係

- **read-config.sh** → dasel（TOML解析）, defaults.toml（レイヤー0）
- **preflight.md** → read-config.sh（11回の個別呼び出し）
- **operations-release.md** → check-bash-substitution.sh（ステップ7.6）
- **rules.md** → operations-release.md（カスタムワークフローが7.xステップを参照）
- 循環依存: なし

## 特記事項

- **--default使用箇所**: 合計20箇所以上（preflight.md:11, rules.md:10+, inception.md:3, その他）
- **defaults.toml未登録キー**: `rules.depth_level.level`, `rules.automation.mode`, `rules.construction.max_retry`, `rules.preflight.enabled`, `rules.preflight.checks`（#376で追加予定）
- **operations-release.mdのステップ番号**: 7.6削除後、7.7〜7.14を7.6〜7.13に繰り上げ必要。rules.mdのカスタムワークフロー（7.8後、7.9前）の参照も更新要
- **dasel v2/v3互換**: read-config.shが自動検出で対応（変更不要）
