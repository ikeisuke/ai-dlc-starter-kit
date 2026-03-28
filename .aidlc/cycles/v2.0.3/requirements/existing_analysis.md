# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/aidlc/
├── SKILL.md, CLAUDE.md, AGENTS.md  # Lite版ルーティングテーブルあり
├── scripts/
│   ├── migrate-detect.sh            # v1→v2検出スクリプト
│   ├── migrate-verify.sh            # v1→v2検証スクリプト
│   ├── migrate-apply-config.sh      # 設定移行
│   ├── migrate-apply-data.sh        # データ移行
│   ├── migrate-cleanup.sh           # クリーンアップ
│   ├── check-backlog-mode.sh        # バックログモード確認
│   └── setup-ai-tools.sh            # AIツール自動セットアップ（Kiro含む）
├── steps/
│   ├── inception/                    # Lite版ファイル要確認
│   ├── construction/01-setup.md      # ステップ8バックログチェック
│   └── operations/
├── config/defaults.toml              # デフォルト設定（backlog_mode含む）
└── templates/

examples/kiro/README.md               # Kiro設定ドキュメント（矛盾あり）
```

## アーキテクチャ・パターン

- **プロンプト駆動アーキテクチャ**: ステップファイル（.md）がワークフローを定義し、シェルスクリプトが実行を担当
- **設定駆動**: `.aidlc/config.toml` + `defaults.toml` でフォールバック付き設定管理
- 根拠: `read-config.sh` がdaselで設定読み取り、defaults.tomlでデフォルト提供

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト), Markdown (プロンプト) | scripts/*.sh, steps/**/*.md |
| ツール | dasel (TOML操作), jq (JSON操作), gh (GitHub CLI) | read-config.sh, setup-ai-tools.sh |
| テスト | bats-core (シェルスクリプトテスト) | tests/ ディレクトリ |

## 依存関係

- migrate-detect.sh → check-backlog-mode.sh（バックログモード判定に依存）
- setup-ai-tools.sh → examples/kiro/（テンプレート参照）
- construction/01-setup.md → check-backlog-mode.sh, gh CLI（バックログ確認）

## 特記事項

### Issue #425 (Lite版廃止)
- SKILL.md lines 39-41: Lite版ルーティング定義
- SKILL.md line 80: Liteプロンプト読み込み条件分岐
- CLAUDE.md lines 78-84: Lite版ユーザー向け説明

### Issue #423 (ローカルバックログ廃止)
- migrate-detect.sh lines 127-150: `.aidlc/cycles/backlog/` 検出ロジック
- backlog_modeの`git`/`git-only`オプションが複数ファイルで参照

### Issue #424 (バックログチェック改善)
- construction/01-setup.md lines 257-281: ステップ8の現在実装
- 全バックログ一覧表示→関連Issue詳細確認に変更が必要

### Issue #426 (Kiroドキュメント矛盾)
- examples/kiro/README.md: 「手動コピーが必要」と記載
- setup-ai-tools.sh lines 115-201: シンボリックリンク自動管理を実装済み
- 矛盾: ドキュメントは手動、実装は自動

### Issue #427 (E2Eテスト)
- migrate-detect.sh: 8リソースタイプの検出（symlink, file, dir, config, data）
- migrate-verify.sh: 3検証チェック（config_paths, v1_artifacts_removed, data_migrated）
- 出力: JSON形式のマニフェスト/検証結果
