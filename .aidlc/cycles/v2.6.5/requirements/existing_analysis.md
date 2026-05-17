# 既存コードベース分析

本サイクルは AI-DLC スターターキット自身のメタ開発であり、各 Unit が触る対象ファイルが Issue ごとに明確に分離されている。Construction Phase Unit 別の詳細 Read は #679 の改修方針に従い各 Unit Phase 1 で実施する前提で、本ファイルでは Inception 段階で必要な「対象ディレクトリ・対象スキル・関連 SoT」マップに留める。

## ディレクトリ構造・ファイル構成

メタ開発リポジトリ `ai-dlc-starter-kit` 本サイクル関連抜粋（深さ 3 程度）:

```text
.
├── .claude-plugin/marketplace.json        # version SoT（v2.6.0+）
├── skills/
│   ├── aidlc/
│   │   ├── SKILL.md                       # 親オーケストレーター（#717 対象 L160-191 委譲フロー）
│   │   ├── config/defaults.toml           # 本体 defaults（#714 正本側）
│   │   ├── steps/
│   │   │   ├── common/                    # 共通フロー（commit-flow / review-flow 等）
│   │   │   ├── inception/                 # #712 対象（重複検出フロー追記先）
│   │   │   ├── construction/              # #679 対象（Phase 1 設計起草前 Read 工程追加先）
│   │   │   └── operations/                # #641 対象（§7.13 直前プロンプト追加先）
│   │   └── templates/                     # Intent / Plan / progress 等のテンプレ群
│   └── aidlc-setup/
│       └── config/defaults.toml           # consumer 配布用 defaults（#714 コピー側 / 同期対象）
├── bin/                                   # メタ開発用スクリプト（update-version.sh / check-bash-substitution.sh 等）
├── .github/workflows/                     # CI ワークフロー（Defaults TOML Sync チェック等の追加候補）
└── .aidlc/                                # メタ開発のサイクル成果物（dogfooding）
```

## アーキテクチャ・パターン

- **プラグイン構成**: v2.0.5 以降スキルプラグイン形式。各スキルは `SKILL.md` を入口に `steps/` / `scripts/` / `templates/` / `config/` で構成（根拠: `.aidlc/rules.md` メタ開発セクション）
- **フェーズインデックス + 詳細ステップ**: Inception / Construction / Operations が `index.md` で materialized binding を保持し、詳細ステップは `steps/<phase>/NN-*.md` に分離（根拠: `steps/inception/index.md` 冒頭の `phase-index-schema: v1` 宣言）
- **委譲スキル分離**: setup / migrate / feedback / retrospective は独立スキルとして分離（v2.6.0+、根拠: `skills/aidlc/SKILL.md` L160-191）
- **公開 API スクリプト層**: `skills/aidlc/scripts/read-config.sh` は他スキルからも参照可能な公開 API（根拠: `.aidlc/rules.md` スキル間依存ルール）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（スクリプト） / Markdown（プロンプト） | `bin/*.sh`, `skills/aidlc/scripts/*.sh`, `skills/aidlc/steps/**/*.md` |
| TOML 操作 | dasel v3（CLI） | `skills/aidlc/scripts/read-config.sh`, `steps/common/rules-core.md` dasel 規約 |
| GitHub 連携 | gh CLI / GraphQL fallback | `bin/lib/gh-scope-check.sh`, `tools:gh-api-fallback` スキル |
| CI | GitHub Actions | `.github/workflows/*.yml` |
| Lint | markdownlint-cli2 / shellcheck | `package.json`, `.github/workflows/` |

## 依存関係

- **内部モジュール間**: 本サイクル対象スキル `skills/aidlc/` ↔ 配布対象 `skills/aidlc-setup/` の defaults.toml 同期関係（#714 が解消対象）
- **委譲先スキル**: `skills/aidlc-setup/`, `skills/aidlc-migrate/`, `skills/aidlc-feedback/`, `skills/aidlc-retrospective/`（#717 が委譲フロー改修対象）
- **レビュースキル**: `skills/reviewing-*/`（#679 が `reviewing-construction-design` 観点追加対象）
- **エントリポイント**: `/aidlc` slash command → `skills/aidlc/SKILL.md` → フェーズインデックス → 詳細ステップ
- **循環依存**: 検出なし（スキル間依存ルール「内部実装パス非依存」原則で防止）

## 特記事項

- 本サイクルは 5 Issue 集約サイクル。各 Unit の Phase 1 詳細解析は #679 の改修方針（事前コード Read 必須化）に従い、Construction Phase で実施する
- `skills/aidlc-setup/config/defaults.toml` の構造は本 Inception 段階では未確認（U4 設計段階で `skills/aidlc/config/defaults.toml` との差分構造を確定）
- U5 (#717) は AI エージェント側の Skill 連鎖呼び出し挙動依存のため、Construction Phase で Claude Code 実機での挙動を Construction 検証 + Operations で Codex CLI 実機検証する想定
- v2.6.4 の Defaults TOML Sync 修復コミット 421c5ac1 を U4 設計時の参照履歴として扱う
