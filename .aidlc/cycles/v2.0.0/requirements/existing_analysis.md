# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
ai-dlc-starter-kit/
├── .claude/
│   └── skills/              # 6 symlinks → docs/aidlc/skills/
├── .claude-plugin/
│   └── marketplace.json     # プラグイン登録（v1.22.1）
├── bin/                     # ルートレベル自動化スクリプト（4ファイル）
├── docs/
│   ├── aidlc/               # prompts/package/ のrsyncコピー（デプロイ先）
│   │   ├── bin/             # 28シェルスクリプト
│   │   ├── config/          # defaults.toml
│   │   ├── prompts/         # フェーズプロンプト + common/ + lite/
│   │   ├── skills/          # 6スキル実装
│   │   ├── templates/       # 23テンプレート
│   │   └── tests/           # テストスイート
│   └── cycles/              # サイクル成果物（v1.0.1〜v1.28.1）
├── prompts/                 # ソース（正本）
│   ├── setup-prompt.md      # セットアップエントリポイント
│   ├── package/             # マスターコピー（docs/aidlc/にミラー）
│   │   ├── bin/             # 28スクリプト
│   │   ├── config/          # 設定テンプレート
│   │   ├── guides/          # 実装ガイド
│   │   ├── lib/             # 共有ライブラリ
│   │   ├── prompts/         # フェーズプロンプト
│   │   ├── skills/          # スキル実装
│   │   └── templates/       # テンプレート
│   └── setup/               # セットアップ固有テンプレート
├── AGENTS.md                # → docs/aidlc/prompts/AGENTS.md 参照
├── CLAUDE.md                # → docs/aidlc/prompts/CLAUDE.md 参照
├── CHANGELOG.md             # バージョン履歴
├── aidlc.toml               # プロジェクト設定（シンボリックリンク）
└── version.txt              # 現行: 1.28.1
```

### 主要ディレクトリの役割

| ディレクトリ | 役割 |
|-------------|------|
| `prompts/package/` | AI-DLCの正本（ソース）。全プロンプト・スクリプト・テンプレートの一次ソース |
| `docs/aidlc/` | `prompts/package/` のrsyncコピー。Operations Phaseで同期 |
| `.claude/skills/` | Claude Codeスキルへのシンボリックリンク（docs/aidlc/skills/を指す） |
| `docs/cycles/` | サイクル成果物（要件定義・設計・実装記録） |
| `bin/` | プロジェクトルートの管理スクリプト |

## アーキテクチャ・パターン

### テンプレート駆動の成果物生成
- フェーズプロンプトが23テンプレートを使って一貫した成果物を生成
- 根拠: `docs/aidlc/templates/` 配下の各テンプレートファイル

### 設定駆動の動作制御
- `aidlc.toml` の30+ルールカテゴリで動的に動作を制御
- 根拠: `read-config.sh` が全フェーズプロンプトから呼び出される

### 二重配置パターン（同期方式）
- 正本: `prompts/package/`
- デプロイ先: `docs/aidlc/`（rsync同期）
- スキルリンク: `.claude/skills/`（シンボリックリンク）
- 根拠: `sync-package.sh`, `.claude/skills/` のシンボリックリンク構造

### 巨大単一ファイルプロンプト
- Inception: 1,436行（66KB）、Construction: 1,233行（53KB）、Operations: 779行（34KB）
- 各フェーズプロンプトにcommon/コンポーネントを@参照で統合
- 根拠: `docs/aidlc/prompts/inception.md`, `construction.md`, `operations.md`

### シェルスクリプト自動化基盤
- 28スクリプトが検証・設定管理・Git操作・GitHub連携を担当
- 根拠: `docs/aidlc/bin/` 配下の全スクリプト

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown（プロンプト）、Bash（スクリプト） | `docs/aidlc/prompts/`, `docs/aidlc/bin/` |
| ツール | Claude Code | `marketplace.json`, `.claude/skills/` |
| 設定形式 | TOML | `aidlc.toml`, `defaults.toml` |
| VCS | Git（worktreeサポート付き） | `bin/post-merge-sync.sh` |
| CI/CD | GitHub Actions | `.github/workflows/` |
| 外部連携 | GitHub CLI (gh), dasel | `env-info.sh` |

## 依存関係

### 内部モジュール間（プロンプト階層）
```
setup-prompt.md → inception.md → construction.md → operations.md
                  ↑ common/ コンポーネント群を各フェーズが共有参照
                  ↑ templates/ を各フェーズが参照
```

### 同期依存
```
prompts/package/ (正本)
    ↓ sync-package.sh (rsync)
docs/aidlc/ (デプロイ先)
    ↓ シンボリックリンク
.claude/skills/ (Claude Code統合)
```

### 外部ライブラリ依存
- `gh` (GitHub CLI): Issue/PR操作
- `dasel`: TOML設定ファイル解析
- `codex`: コードレビュー

### エントリポイント
- 初回セットアップ: `prompts/setup-prompt.md`
- フェーズ開始: `docs/aidlc/prompts/{phase}.md`
- スキル呼び出し: `.claude/skills/` 経由

### 循環依存: なし

## 特記事項

- marketplace.jsonのバージョン（1.22.1）がメインバージョン（1.28.1）より古い
- `docs/aidlc/` は直接編集禁止（`prompts/package/` が正本）
- Lite版プロンプト（`docs/aidlc/prompts/lite/`）はv2.0.0で廃止予定
- 現行のスキルは `.claude/skills/` のシンボリックリンク経由で登録されている（v2.0.0でプラグイン方式に移行）
