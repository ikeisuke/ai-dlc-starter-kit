# 既存コードベース分析

## ディレクトリ構造・ファイル構成

変更対象のファイル・ディレクトリのみ抜粋:

```text
ai-dlc-starter-kit/
├── README.md                              # #482: 更新対象
├── skills/aidlc/
│   ├── steps/
│   │   ├── common/
│   │   │   └── review-flow.md             # #468: バグ修正対象
│   │   └── inception/
│   │       └── 01-setup.md                # #470: ステップ番号修正対象
│   └── scripts/
│       └── suggest-version.sh             # #432: 初回提案ロジック修正対象
└── .aidlc/
    └── rules.md                           # #484: 不整合修正対象
```

## アーキテクチャ・パターン

- **スキルプラグイン構成**: `skills/aidlc/` にスキル定義（SKILL.md）、ステップファイル、スクリプト、テンプレートを配置
- **プロンプト駆動**: ステップファイル（.md）がAIエージェントの実行指示を定義
- **設定駆動**: `.aidlc/config.toml` + `config/defaults.toml` でプロジェクト設定を管理

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト), Markdown (プロンプト) | scripts/*.sh, steps/**/*.md |
| ツール | Claude Code, Codex CLI | CLAUDE.md, .aidlc/rules.md |
| 設定管理 | TOML (dasel) | .aidlc/config.toml |

## 依存関係

- `review-flow.md` → `reviewing-*` スキル（外部スキル呼び出し）
- `01-setup.md` → `suggest-version.sh`（バージョン提案）
- `rules.md` → 各ステップファイル（ルール参照）

## 特記事項

- メタ開発のため、変更対象はスターターキット自体のファイル
- `review-flow.md` の変更は review_mode=required 時のみ影響
- `suggest-version.sh` の変更は初回サイクル時のみ影響
