# 既存コードベース分析

## ディレクトリ構造・ファイル構成

rsync関連のファイル配置:

```text
prompts/
├── bin/
│   └── sync-package.sh          # rsync同期スクリプト（正本）
├── package/
│   ├── guides/
│   │   └── ai-agent-allowlist.md # AIエージェント許可ルールガイド
│   └── skills/
│       └── aidlc-setup/
│           └── bin/
│               └── aidlc-setup.sh # アップグレードスクリプト（rsync dry-run使用）
└── setup-prompt.md               # セットアッププロンプト（sync-package.sh経由で同期）
```

## アーキテクチャ・パターン

### rsync実行の現状

| 呼び出し元 | rsync使用方法 | スクリプト内か |
|-----------|-------------|------------|
| `sync-package.sh` | rsync同期実行 | Yes（スクリプト内） |
| `aidlc-setup.sh` `_has_file_diff()` | rsync -ani dry-run | Yes（スクリプト内） |
| `aidlc-setup.sh` 同期ループ | sync-package.sh経由 | Yes（スクリプト経由） |

根拠: `prompts/bin/sync-package.sh:105`、`prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh:135`

### 許可ルールの現状

`ai-agent-allowlist.md` に `Bash(rsync * docs/aidlc/prompts/)` 等のrsync個別許可パターンが記載されている。

根拠: `prompts/package/guides/ai-agent-allowlist.md:205-207`

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash | sync-package.sh, aidlc-setup.sh |
| ツール | rsync | sync-package.sh内で使用 |
| 設定 | TOML (aidlc.toml) | docs/aidlc.toml |

## 依存関係

- `aidlc-setup.sh` → `sync-package.sh`（同期実行時）
- `aidlc-setup.sh` → rsync（`_has_file_diff()`内で直接呼び出し）
- `setup-prompt.md` → `sync-package.sh`（セットアップ時）

## 特記事項

- `_has_file_diff()`内のrsync dry-runは既にスクリプト内に閉じ込められている
- 問題は`ai-agent-allowlist.md`にrsync個別許可ルールが文書化されていること
- rsyncはスクリプト（aidlc-setup.sh、sync-package.sh）経由でのみ実行されるため、個別許可は不要
