# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/aidlc/
├── SKILL.md                    # エントリポイント
├── AGENTS.md                   # プラグインルート（全スキル共通自動ロード）
├── CLAUDE.md                   # プラグインルート
├── version.txt                 # スキルバージョン
├── config/
│   └── defaults.toml           # デフォルト設定値
├── steps/
│   ├── common/                 # 共通ステップ
│   │   ├── rules-core.md       # コアルール（187行）
│   │   ├── rules-automation.md # 自動化ルール
│   │   ├── rules-reference.md  # リファレンス
│   │   ├── review-flow.md      # レビューフロー（215行）
│   │   ├── review-flow-reference.md # ツール別制約（100行）
│   │   ├── commit-flow.md      # コミットフロー
│   │   └── ...
│   ├── inception/              # Inception Phase
│   │   └── 01-setup.md         # セットアップ（バージョンチェック含む）
│   ├── construction/           # Construction Phase
│   │   └── 01-setup.md         # セットアップ（ステップ8バックログ確認含む）
│   └── operations/             # Operations Phase
│       └── operations-release.md # リリース処理（PRマージ含む）
├── guides/
│   └── version-check.md        # バージョン比較ロジック（65行）
├── templates/                  # テンプレート群
└── scripts/                    # シェルスクリプト群
```

## アーキテクチャ・パターン

- **スキルプラグインモデル**: `skills/aidlc/` がプラグインとして動作。`AGENTS.md`/`CLAUDE.md` は全スキル共通で自動注入
- **ステップファイル分離**: フェーズごとにステップファイルを分離し、SKILL.mdから順次読み込み
- **設定管理**: `config.toml` + `defaults.toml` + `read-config.sh` による階層的設定管理
- **レビュースキル分離**: 9つのreviewingスキルが独立スキルとして存在（共通基盤は`reviewing-common-base.md`に抽出済み）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown, Bash | steps/, scripts/ |
| フレームワーク | Claude Code Skills | SKILL.md |
| 主要ライブラリ | dasel (TOML操作), gh CLI | scripts/read-config.sh |

## 依存関係

- **SKILL.md** → `steps/common/rules-core.md` → `steps/common/preflight.md` → フェーズステップ
- **rules-core.md**: 全フェーズから参照される中核ルール
- **review-flow.md**: レビュー実施時に参照、reviewing-*スキルを呼び出す
- **defaults.toml**: `read-config.sh` のフォールバック値として使用

## 特記事項

- `agents-rules.md` は既に v2.2.0 で rules-core.md に統合済み（S3完了）。ファイル自体は存在しない
- `review-flow-reference.md` はツール別制約（Codex/Claude/Gemini）を記載。review-flow.mdから参照される
- Construction Phase 01-setup.md のステップ8（バックログ確認）は既に最小限（3行程度）
- Operations Phase の PRマージ箇所は `operations-release.md` のステップ7.8付近（74-109行）
- STARTER_KIT_DEV特別扱いは `guides/version-check.md` 内に存在する可能性あり（要確認）
