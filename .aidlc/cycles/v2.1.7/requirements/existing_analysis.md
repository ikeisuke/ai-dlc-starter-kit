# 既存コードベース分析

## ディレクトリ構造・ファイル構成

### skills/aidlc-setup/（修正対象スキル）

```
skills/aidlc-setup/
├── SKILL.md
├── scripts/
│   ├── detect-missing-keys.sh  ← 欠落キー検出スクリプト（--defaults引数で参照先を受け取る）
│   ├── init-labels.sh
│   ├── migrate-backlog.sh
│   ├── migrate-config.sh
│   ├── read-version.sh
│   └── setup-ai-tools.sh
├── steps/
│   ├── 01-detect.md
│   ├── 02-generate-config.md   ← defaults.tomlパス解決ロジックを含む（L379）
│   └── 03-migrate.md
├── templates/
│   ├── config.toml.template
│   ├── operations_handover_template.md
│   └── rules_template.md
└── version.txt
```

**注**: `config/` ディレクトリは存在しない（新規作成が必要）

### skills/aidlc/config/（参照元）

```
skills/aidlc/config/
└── defaults.toml  ← 現在aidlc-setupが直接参照している対象
```

## アーキテクチャ・パターン

- **スキルプラグイン構成**: 各スキルは独立したディレクトリ（`scripts/`, `steps/`, `templates/`）で構成
- **スキル間依存ルール**: 他スキルの内部実装（`scripts/`, `steps/`, `templates/` 等）への直接依存は禁止。スキルの呼び出し名と公開引数のみ依存可
- **違反箇所**: `02-generate-config.md` L379 が `aidlc` スキルの `config/defaults.toml` のパスを解決して参照

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| スクリプト言語 | Bash (POSIX sh互換) | `scripts/detect-missing-keys.sh` |
| TOML解析 | dasel (v2/v3互換) | `detect-missing-keys.sh` L73-90 |
| ステップ定義 | Markdown | `steps/02-generate-config.md` |

## 依存関係

### detect-missing-keys.sh の依存

- **入力**: `--defaults <path>` でdefaults.tomlパスを受け取る（呼び出し元が解決）
- **入力**: `--config <path>` でconfig.tomlパスを受け取る
- **外部依存**: dasel コマンド（v2/v3互換）
- **出力**: タブ区切り形式（missing/summary/error）
- **終了コード**: 0=成功、1=ファイル不在、2=dasel未インストール

### 02-generate-config.md の依存（違反箇所）

- `aidlc` スキルのベースディレクトリ配下の `config/defaults.toml` をReadツールで存在確認・パス解決
- 解決したパスを `detect-missing-keys.sh` の `--defaults` 引数に渡す

## 特記事項

- `detect-missing-keys.sh` 自体はパス解決を行わない。`--defaults` 引数で外部から渡されるため、スクリプトのロジック変更は不要
- 修正対象は `02-generate-config.md` のパス解決ロジックのみ（自スキル内の `config/defaults.toml` を参照するよう変更）
- `skills/aidlc-setup/config/` ディレクトリは新規作成が必要
