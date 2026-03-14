# 既存コードベース分析

## ディレクトリ構造・ファイル構成

今回のスコープに関連するディレクトリのみ記載。

```
bin/                          # プロジェクト固有スクリプト
├── check-bash-substitution.sh  # Bash置換チェック（CI用）
├── check-size.sh
├── post-merge-sync.sh
└── update-version.sh
docs/aidlc/bin/               # AI-DLC CLIスクリプト（デプロイ済み）
├── read-config.sh             # 設定読み込み（toml.local対応）
├── write-history.sh           # 履歴記録（validate_cycle含む）
├── setup-branch.sh            # ブランチ作成（バリデーション含む）
├── init-cycle-dir.sh
├── suggest-version.sh
└── ... (31スクリプト)
prompts/package/bin/           # スターターキット本体（編集対象）
├── read-config.sh
├── write-history.sh
├── setup-branch.sh
└── ... (docs/aidlc/bin/ のミラー)
```

**重要**: メタ開発のため `prompts/package/bin/` を編集し、`docs/aidlc/bin/` は rsync でコピーされる。

## アーキテクチャ・パターン

- **ミラー構成**: `prompts/package/` が正本、`docs/aidlc/` がデプロイコピー
- **共通ライブラリなし**: `lib/` ディレクトリは存在しない。バリデーション等は各スクリプトに個別実装
- **設定階層**: `defaults.toml` → `~/.aidlc/config.toml` → `aidlc.toml` → `aidlc.toml.local`（後勝ち）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (POSIX互換志向) | `bin/*.sh`, `docs/aidlc/bin/*.sh` |
| 設定解析 | dasel | `read-config.sh` |
| CI | GitHub Actions | `.github/` |

## 依存関係

### サイクル名バリデーション（重複箇所）

正規表現 `^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$` が以下4箇所に重複:

1. `prompts/package/bin/write-history.sh` L103 (`validate_cycle` 関数)
2. `prompts/package/bin/setup-branch.sh` L179 (インラインバリデーション)
3. `docs/aidlc/bin/write-history.sh` L103 (デプロイコピー)
4. `docs/aidlc/bin/setup-branch.sh` L179 (デプロイコピー)

### 設定ファイル参照（aidlc.toml.local）

`read-config.sh` L289-310 で `docs/aidlc.toml.local` を参照。新名 `aidlc.local.toml` 優先・旧名フォールバック対応が必要。

### エラー出力パターン

現状のエラー形式は概ね `error:<code>` または `error:<code>:<detail>` だが、一部スクリプトで形式が不統一。

### ローカルCIチェック

`bin/check-bash-substitution.sh` は存在するが、Operations Phaseのフロー（`operations-release.md`）には組み込まれていない。

## 特記事項

- 共通ライブラリ（`lib/validate.sh` 等）を新設する場合、`prompts/package/lib/` に作成し、各スクリプトから `source` する設計が必要
- `aidlc.toml.local` → `aidlc.local.toml` のリネームは、両方存在する場合の優先順位を明確にする必要がある（新名優先、旧名フォールバック＋警告）
