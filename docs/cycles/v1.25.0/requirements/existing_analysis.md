# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
prompts/
├── package/
│   ├── prompts/           # フェーズプロンプト正本
│   │   ├── inception.md
│   │   ├── construction.md
│   │   ├── operations.md
│   │   ├── operations-release.md
│   │   ├── AGENTS.md      # フェーズ簡略指示テーブル
│   │   ├── CLAUDE.md
│   │   └── common/        # 共通プロンプト
│   ├── bin/               # スクリプト正本
│   ├── skills/            # スキル定義正本
│   └── templates/         # テンプレート正本
docs/
├── aidlc/                 # prompts/package/ のrsyncコピー（直接編集禁止）
│   ├── prompts/
│   ├── bin/
│   ├── skills/
│   ├── templates/
│   └── kiro/agents/       # KiroCLIエージェント定義
├── aidlc.toml             # プロジェクト共有設定
├── aidlc.local.toml       # 個人設定（.gitignore）
└── cycles/                # サイクル成果物
.kiro/
├── skills/                # docs/aidlc/skills/ へのシンボリックリンク群
└── agents/                # KiroCLIエージェント定義へのシンボリックリンク
.claude/
└── skills/                # Claude Code用スキルシンボリックリンク
```

## アーキテクチャ・パターン

### プロンプト駆動アーキテクチャ
- **正本**: `prompts/package/` にプロンプト・スクリプト・テンプレートの正本を配置
- **配布コピー**: `docs/aidlc/` は rsync によるコピー。Operations Phase で同期
- 根拠: `docs/cycles/rules.md` のメタ開発ルール、`setup-prompt.md` のセクション8.2.3

### 設定マージパターン
- 4層の階層マージ（優先度: 低→高）: defaults.toml → ~/.aidlc/config.toml → aidlc.toml → aidlc.local.toml
- `read-config.sh` が dasel を使用してTOMLを解析。dasel v2/v3互換対応あり
- 根拠: `docs/aidlc/bin/read-config.sh`

### スキル配布パターン
- `setup-ai-tools.sh` が各AI環境（.claude/skills/, .kiro/skills/）にシンボリックリンクを作成
- 相対パス形式（`../../docs/aidlc/skills/skill-name`）でポータビリティを確保
- 自己修復機能（壊れたシンボリックリンクの検出・修復）あり
- 根拠: `docs/aidlc/bin/setup-ai-tools.sh` L22-92

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト), Markdown (プロンプト・ドキュメント) | `docs/aidlc/bin/*.sh` |
| 設定管理 | TOML (dasel でパース) | `docs/aidlc.toml` |
| VCS | Git + GitHub CLI (gh) | `docs/aidlc/bin/env-info.sh` |
| AI統合 | Claude Code, KiroCLI, Codex | `docs/aidlc/bin/setup-ai-tools.sh` |
| 外部レビュー | Codex CLI, Claude CLI, Gemini CLI | `docs/aidlc/prompts/common/review-flow.md` |

## 依存関係

### 変更対象ファイルと影響範囲

#### #364 エクスプレスモードインスタント起動
- **直接変更**: `prompts/package/prompts/AGENTS.md` (フェーズ簡略指示テーブル), `prompts/package/prompts/CLAUDE.md` (同上)
- **直接変更**: `prompts/package/prompts/inception.md` (ステップ4b拡張、depth_levelオーバーライドロジック)
- **直接変更**: `prompts/package/prompts/common/rules.md` (エクスプレスモード仕様セクション)
- **依存**: `docs/aidlc.toml` の `rules.depth_level.level` 設定（読み取りのみ、変更なし）
- **現行トリガー**: `depth_level=minimal` のみ。`aidlc.toml` の事前設定が必要

#### #350/#320 プリフライトチェック・設定値一括取得
- **新規作成**: `prompts/package/prompts/common/preflight.md`
- **直接変更**: `prompts/package/prompts/inception.md`, `construction.md`, `operations.md` (初期化ステップにプリフライト呼び出しを追加)
- **依存**: `docs/aidlc/bin/read-config.sh` (--keysバッチモードが既存)
- **依存**: `docs/aidlc/bin/env-info.sh` (ツール可用性チェックが既存)
- **依存**: `docs/aidlc/bin/check-gh-status.sh`, `check-backlog-mode.sh`
- **現行状況**: 各フェーズで個別に設定値を読み取り。一括取得の仕組みなし

#### #336 Codex PRレビュー絵文字リアクション検出
- **直接変更**: `docs/cycles/rules.md` (PRマージ前レビューコメント確認セクション拡張)
- **直接変更**: `prompts/package/prompts/operations-release.md` (ステップ7.13拡張)
- **依存**: GitHub REST API (`gh api repos/{owner}/{repo}/pulls/{PR}/comments` のリアクション取得)
- **現行状況**: REST APIでレビュー状態とコメント未返信を判定。リアクション検出なし

#### #347 .kiro/skills → .agents/skills 移行
- **直接変更**: `prompts/package/bin/setup-ai-tools.sh` (`.kiro/skills` → `.agents/skills`)
- **直接変更**: `prompts/setup-prompt.md` (ドキュメント内の参照更新)
- **直接変更**: `.kiro/skills/` → `.agents/skills/` (ディレクトリ移動)
- **影響**: `.kiro/agents/aidlc.json` のシンボリックリンクも移行対象か要確認
- **現行状況**: 6スキルのシンボリックリンクが `.kiro/skills/` に存在。`setup-ai-tools.sh` L106で作成

## 特記事項

- `docs/aidlc/` は直接編集禁止。すべての変更は `prompts/package/` で行い、Operations Phase の aidlc-setup 同期で反映
- `read-config.sh` の `--keys` バッチモードは既存機能として利用可能（プリフライトチェックで活用可）
- `.kiro/agents/aidlc-poc.json` が直接ファイル（非シンボリックリンク）として存在。移行時の扱いを要確認
- `env-info.sh --setup` が既にツール可用性チェックを実装しており、プリフライトチェックの基盤として再利用可能
