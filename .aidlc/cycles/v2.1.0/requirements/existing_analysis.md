# 既存コードベース分析

## ディレクトリ構造・ファイル構成

### スキル構成
```text
skills/
├── aidlc/              # メインスキル
│   ├── config/         # デフォルト設定
│   ├── guides/         # ガイドドキュメント
│   ├── scripts/        # ユーティリティスクリプト
│   │   ├── lib/        # 共有ライブラリ
│   │   └── tests/      # テストスクリプト
│   ├── steps/          # フェーズ別ステップ
│   │   ├── common/     # フェーズ共通
│   │   ├── inception/  # Inception Phase
│   │   ├── construction/ # Construction Phase
│   │   └── operations/ # Operations Phase
│   └── templates/      # テンプレート
│       └── kiro/       # Kiro CLI用
├── aidlc-setup/        # セットアップスキル
├── aidlc-migrate/      # マイグレーションスキル
├── aidlc-feedback/     # フィードバックスキル
├── reviewing-architecture/ # レビュー（旧: アーキテクチャ）
├── reviewing-code/     # レビュー（旧: コード）
├── reviewing-inception/ # レビュー（旧: インセプション）
├── reviewing-security/ # レビュー（旧: セキュリティ）
└── squash-unit/        # コミットスカッシュ
```

### marketplace.json 登録スキル
- `./skills/aidlc`, `./skills/aidlc-setup`, `./skills/aidlc-migrate`, `./skills/aidlc-feedback`
- `./skills/reviewing-architecture`, `./skills/reviewing-code`, `./skills/reviewing-inception`, `./skills/reviewing-security`
- `./skills/squash-unit`

## アーキテクチャ・パターン

### 現在のレビュースキル構成（種別ベース）

| スキル | 行数 | 主な観点 |
|--------|------|---------|
| reviewing-architecture | 144 | レイヤー分離、デザインパターン、API設計 |
| reviewing-code | 190 | 可読性、保守性、パフォーマンス、テスト品質 |
| reviewing-inception | 159 | Intent品質、ストーリー品質（INVEST）、Unit定義 |
| reviewing-security | 203 | OWASP Top 10、認証・認可、依存脆弱性 |

### review-flow.md のレビュー完了条件（変更対象）
- 行61: 「全種別で指摘0件で完了」
- 行184-185: 「全種別で指摘がゼロになった時点で完了出力」
- 行278: セルフレビューも同様の条件
- 行330: セミオートゲート判定 `unresolved_count == 0`

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| スクリプト | Bash (POSIX互換) | scripts/*.sh |
| 設定管理 | TOML (dasel) | config/defaults.toml, .aidlc/config.toml |
| プロンプト | Markdown | steps/**/*.md, SKILL.md |
| CI/CD | GitHub Actions | .github/workflows/ |
| パッケージ管理 | Claude Code Plugin | .claude-plugin/marketplace.json |

## 依存関係

### パス参照問題（`../../` を含むファイル）

**aidlc-migrate 内（プラグイン環境で破綻）**:
- `scripts/migrate-detect.sh` — `_starter_kit_root="$(cd "$AIDLC_PLUGIN_ROOT/../.." && pwd)"`

**aidlc-setup 内**:
- `scripts/read-version.sh` — `VERSION_FILE="${SCRIPT_DIR}/../version.txt"`
- `scripts/setup-ai-tools.sh` — `AIDLC_TEMPLATES_DIR="${SCRIPT_DIR}/../templates"`, `template_file="${SCRIPT_DIR}/../config/settings-template.json"`
- `scripts/migrate-backlog.sh`

**aidlc 内（guides のリンク）**:
- `guides/intro.md`, `guides/ai-tools.md`, `guides/skill-usage-guide.md` — 他ガイドへの `../../` 相対リンク
- `steps/common/intro.md`, `steps/common/ai-tools.md` — ガイドへのリンク
- `templates/logical_design_template.md`, `templates/monitoring_strategy_template.md`

**aidlc 内（scripts）**: テストスクリプト含め15ファイル

### スキル間の内部依存
- aidlc-migrate の `migrate-apply-config.sh` が `@skills/aidlc/AGENTS`, `@skills/aidlc/CLAUDE` を参照
- テストスクリプトが `$PROJECT_ROOT/skills/aidlc/scripts/` を直接参照

### 400行超えMarkdownファイル（9ファイル）

| ファイル | 行数 |
|---------|------|
| steps/inception/01-setup.md | 692 |
| steps/operations/operations-release.md | 628 |
| guides/sandbox-environment.md | 583 |
| guides/ai-agent-allowlist.md | 573 |
| steps/common/rules.md | 546 |
| steps/construction/01-setup.md | 478 |
| steps/common/review-flow.md | 439 |
| steps/common/commit-flow.md | 438 |
| steps/construction/04-completion.md | 416 |

## 特記事項

- `../../` 参照は主にスキル内のスクリプトからスキルルートへの参照（`SCRIPT_DIR/../`）と、Markdownのリンクに存在
- aidlc-migrate の `migrate-detect.sh` はプラグインルートの2階層上をプロジェクトルートと仮定しており、Kiro CLI環境（`~/.kiro/skills/aidlc-migrate/`）では破綻する
- テストスクリプトのプロジェクトルート相対パスはメタ開発固有の例外として許容される可能性がある
