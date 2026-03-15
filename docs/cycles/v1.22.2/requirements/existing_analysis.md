# 既存コードベース分析

## ディレクトリ構造・ファイル構成

対象領域に絞った構造:

```
prompts/
├── package/
│   ├── bin/           # CLIスクリプト群（read-config.sh等）
│   ├── lib/           # 共有ライブラリ（validate.sh）
│   ├── skills/        # スキル定義
│   │   └── aidlc-setup/
│   │       └── bin/
│   │           └── aidlc-setup.sh  # セットアップオーケストレータ
│   ├── prompts/       # プロンプトファイル
│   ├── templates/     # テンプレート
│   └── config/        # デフォルト設定（defaults.toml）
├── setup/
│   └── bin/
│       └── check-setup-type.sh  # セットアップ種別判定
└── setup-prompt.md    # セットアッププロンプト

docs/aidlc/             # prompts/package/ のrsyncコピー（直接編集禁止）
├── bin/
├── lib/
├── skills/
├── prompts/
├── templates/
└── config/
```

## アーキテクチャ・パターン

### aidlc-setup.sh オーケストレーション（429行）

8ステップのパイプライン:
1. スターターキットパス解決（3層: 環境変数 → メタ開発検出 → 外部プロジェクト検出）
2. セットアップ種別判定（check-setup-type.sh呼び出し）
3. 設定マイグレーション（migrate-config.sh）
4. パッケージ同期（sync-package.sh） ← **#338の問題箇所**
5. AIツールセットアップ
6. バージョン更新

### SYNC_DIRS配列（aidlc-setup.sh 327-335行）

```
prompts, templates, guides, bin, skills, kiro, lib
```
→ `lib` は明示的に含まれている

### スクリプト依存チェーン

```
read-config.sh (行42) → source "${SCRIPT_DIR}/../lib/validate.sh"
```
`SCRIPT_DIR` = `docs/aidlc/bin/` → `../lib/` = `docs/aidlc/lib/validate.sh`

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash | bin/*.sh |
| 設定パーサ | dasel | read-config.sh |
| 同期ツール | rsync | sync-package.sh |
| CLI連携 | gh (GitHub CLI) | check-open-issues.sh等 |

## 依存関係

### #339 lib/デプロイ問題

- SYNC_DIRS には `lib` が含まれている → sync-package.sh 自体は正しく lib/ を同期するはず
- 問題は sync-package.sh が見つからない（#338）ため、同期自体が実行されない可能性
- または、ユーザープロジェクトが v1.22.1 より前のバージョンから直接アップグレードした場合、sync-package.sh が存在しない

### #338 スクリプト不在

- `check-setup-type.sh` は `prompts/setup/bin/` に存在（package/ ではない）
- `sync-package.sh` は `prompts/package/bin/` に存在するはず → 要確認
- aidlc-setup.sh のパス解決ロジックがユーザープロジェクトで正しく動作していない可能性

### #337 ブランチ命名

- setup-prompt.md で `upgrade/vX.X.X` を案内している箇所を特定・修正が必要
- aidlc-setupスキルのSKILL.mdでも分岐作成の案内がある可能性

### #335 許可パターン

- 現在 `.claude/settings.json` はリポジトリに存在しない
- セットアップ時にデフォルト許可パターンを生成する仕組みがない

### #314 CLAUDE.md

- 現在のCLAUDE.mdは質問ルール・コミットルール・TodoWrite使用法のみ
- フェーズ開始手順（簡略指示表）はAGENTS.mdにあるが、CLAUDE.mdには未記載

## 特記事項

- sync-package.sh の実体がどこにあるか要確認（prompts/package/bin/ に存在するか）
- check-setup-type.sh は prompts/setup/bin/ にあり、package/ 配下ではない → aidlc-setup.sh がユーザープロジェクト側で実行される際のパス解決が問題
