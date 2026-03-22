# 既存コードベース分析

## ディレクトリ構造・ファイル構成

対象ファイルのみ抜粋:

```
prompts/package/bin/
├── post-merge-cleanup.sh    # 正本（#390, #389）
├── setup-ai-tools.sh        # 正本（#388）
└── ...
prompts/package/
├── config/defaults.toml     # 正本（defaults.tomlパス問題）
├── prompts/common/
│   ├── rules.md             # defaults.toml参照あり（ファイル名のみ）
│   ├── preflight.md         # defaults.toml参照あり（ファイル名のみ）
│   └── compaction.md        # defaults.toml参照あり（ファイル名のみ）
└── guides/
    └── config-merge.md      # defaults.toml参照あり（「スクリプト内蔵」表記）
docs/aidlc/
├── bin/post-merge-cleanup.sh  # rsyncコピー
├── bin/setup-ai-tools.sh      # rsyncコピー
├── config/defaults.toml       # rsyncコピー
└── ...
```

## アーキテクチャ・パターン

### post-merge-cleanup.sh のリモート解決

- **resolve_remote()** (L109-131): ブランチ名からリモートを解決
  1. `branch_name` が空でない場合: `git config branch.<name>.remote` を参照
  2. 取得できない場合: `origin` が存在すればフォールバック
  3. `origin` もなければ: `git remote | head -1`
- **問題箇所** (L234-240): ローカルブランチ不在時に `resolve_remote ""` を呼ぶため、ブランチ設定を参照できず直接originフォールバックする
  - マルチリモート環境で、リモートブランチが origin 以外に存在する場合に誤動作

### setup_kiro_agent() のファイル管理

- **setup_kiro_agent()** (L113-149): symlink管理のみ
  - ファイル不在 → symlink作成
  - symlink → ターゲット確認・修復
  - **実ファイル → Warningのみ、マージなし** (L144-145)
- **setup_claude_permissions()** (L444-): 対比用の完全版マージロジック
  - `_merge_permissions_jq()` (L293-): jqによるset-differenceマージ
  - `_merge_permissions_python()` (L367-): Python3フォールバック
  - ワイルドカード包含チェック付き

### defaults.toml パス参照

- `read-config.sh` (L41): `DEFAULTS_CONFIG_FILE="${SCRIPT_DIR}/../config/defaults.toml"` で相対解決（正しい）
- プロンプト・ガイドではファイル名「defaults.toml」のみ記載、フルパス未記載
- AIがパス推測時に `docs/aidlc/defaults.toml`（configサブディレクトリなし）と誤案内するリスク

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (シェルスクリプト) | post-merge-cleanup.sh, setup-ai-tools.sh |
| JSON操作 | jq / Python3 (フォールバック) | setup-ai-tools.sh L293, L367 |
| 設定管理 | TOML (dasel) | read-config.sh |

## 依存関係

- post-merge-cleanup.sh → git, validate.sh (共通ライブラリ)
- setup-ai-tools.sh → jq or python3, _generate_template() (テンプレート生成)
- read-config.sh → dasel, defaults.toml, aidlc.toml

## 特記事項

- `prompts/package/` が正本、`docs/aidlc/` はrsyncコピー。Construction Phaseでは正本のみ編集する
- #390と#389は同一箇所（resolve_remote + step_0a）の修正で対応可能
- #388はsetup_claude_permissions()のマージロジックをsetup_kiro_agentに移植する方針。ただしKiro側はallowedCommands配列のマージが対象（permissions.allow/askではない）
