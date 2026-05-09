# 既存コードベース分析 — v2.5.6

本サイクル v2.5.6 で対応する 4 項目（A: CI ガード / B: fixture 除外 / C: permissions audit / D: Inception 02-preparation Issue 選択）の影響範囲に絞った既存コード分析。

## ディレクトリ構造・ファイル構成

```
.
├── .aidlc/                  # AI-DLC ランタイム設定・サイクル成果物
│   ├── config.toml          # プロジェクト設定（scopeマージのベース）
│   ├── rules.md             # プロジェクト固有ルール（メタ開発意識・ブランチ運用 等）
│   └── cycles/{vX.X.X}/     # サイクル別成果物（requirements/story-artifacts/design-artifacts/inception/construction/operations/history）
├── .claude/                 # Claude Code 設定
│   └── settings.json        # 許可ルール・hooks（permissions audit 対象）
├── .github/workflows/       # CI ワークフロー（4 ファイル: pr-check / migration-tests / auto-tag / skill-reference-check）
├── bin/                     # メタ開発用ローカル実行スクリプト
│   ├── check-bash-substitution.sh
│   ├── check-defaults-sync.sh
│   ├── check-markdownlint.sh
│   ├── check-size.sh
│   ├── check-skill-references.sh
│   ├── check-utf8-corruption.sh
│   ├── post-merge-sync.sh
│   ├── update-version.sh
│   └── tests/               # bin/ スクリプトの bats テスト
├── skills/                  # スキルプラグイン群（aidlc / aidlc-setup / aidlc-migrate / reviewing-* / write-history / squash-unit / install-kiro-agent / aidlc-feedback）
│   └── aidlc/
│       ├── SKILL.md         # オーケストレーター
│       ├── steps/           # フェーズ別ステップファイル（common/inception/construction/operations）
│       ├── scripts/         # スキル内シェルスクリプト
│       ├── templates/       # 成果物テンプレート
│       ├── guides/          # サブガイド
│       ├── config/defaults.toml  # 設定デフォルト
│       └── version.txt
└── tests/                   # bats テスト（health-check / setup / migrate / retrospective / feedback / config 等）
```

## アーキテクチャ・パターン

| パターン | 適用箇所 | 根拠 |
|---------|---------|------|
| **Skill プラグインアーキテクチャ** | `skills/*/SKILL.md` | v2.0.5 以降の構成原則（rules.md「プラグイン前提の構成原則」） |
| **Materialized Binding** | `steps/{phase}/index.md` | フェーズインデックス + spec参照トークンで判定規則を分離（`<!-- phase-index-schema: v1 -->`） |
| **ステップファイル分割ディスパッチ** | `steps/inception/01-setup.md` 〜 `05-completion.md` | SKILL.md は契約テーブルのみ、詳細はオンデマンドロード |
| **設定階層マージ** | `read-config.sh` | defaults / user-global / project / project.local の 4 階層マージ |
| **5 ケース判定 + フォールバック** | `milestone-ops.sh`、`pr-ops.sh` 等 | open=N / closed=N の組み合わせで分岐 + REST PATCH fallback |
| **Health-check スクリプト** | `scripts/main-repo-health-check.sh` | check_* 関数群で multi-aspect 検証、`status:label:reason` 形式出力 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash 5+ (POSIX/zsh 互換配慮)、Markdown | `scripts/`, `bin/`, `*.md` |
| フレームワーク | Claude Code Skill plugin (`.claude-plugin/plugin.json`)、GitHub Actions | `.claude-plugin/`, `.github/workflows/` |
| 主要ライブラリ・CLI | `gh` (GitHub CLI)、`dasel` (TOML)、`jq` (JSON)、`codex` (review)、`bats` (test)、`markdownlint-cli2` | rules.md / pr-check.yml / setup スキル / tests/ |
| パッケージマネージャ | なし（純シェル）。Node.js 経由の補助ツールは npx 一過性 | （存在せず） |

## 依存関係

### A 関連（CI ガード）

- **影響範囲**: `.github/workflows/` に新規 workflow 追加、`bin/check-cycle-phase-completion.sh` 新規作成
- **既存 CI workflow との独立性**: pr-check.yml / migration-tests.yml / auto-tag.yml / skill-reference-check.yml と並列、コンフリクトなし
- **判定対象パス（既存仕様の再利用）**:
  - Inception: `.aidlc/cycles/{cycle}/inception/progress.md`
  - Construction: `.aidlc/cycles/{cycle}/story-artifacts/units/*.md` の「実装状態」
  - Operations: `.aidlc/cycles/{cycle}/operations/progress.md` の固定スロット (`release_gate_ready` / `completion_gate_ready` / `pr_number`)
- **依存ライブラリ**: `dasel` (TOML), `jq` (任意)、または直接 `awk` パース

### B 関連（main-repo-health-check fixture 除外）

- **対象関数**: `skills/aidlc/scripts/main-repo-health-check.sh:139` `check_conflict_marker()`
- **既存 git grep コマンド**: `git grep -I -n -E '^<<<<<<< |^>>>>>>> |^=======$'`
- **影響範囲**: 単一関数 + bats テスト追記。他 check 関数（lock-file / orphan-cycle 等）に影響なし

### C 関連（permissions audit）

- **対象ファイル**: `.claude/settings.json`（プロジェクト）/ `~/.claude/settings.json`（グローバル）の 2 階層
- **検出元**: `/tools:suggest-permissions --review all` の出力
- **既存設定**: 複数の `Bash(...)` allow ルールが文字列マッチで MED 検出される（`gh issue list *`, `gh pr view *` 等）
- **影響範囲**: settings.json の `permissions.ask` 配列追加 + `suggestPermissions.acknowledgedFindings` セクション新設

### D 関連（Inception Issue 選択）

- **対象ファイル**: `skills/aidlc/steps/inception/02-preparation.md` §16 (GitHub Issue 確認)
- **AI への暗黙的影響**: §16 のテキスト誘導により AskUserQuestion の単一選択フォーマットを生成しがち
- **依存**: `scripts/check-open-issues.sh`（出力フォーマット変更不要、表示テキストのみ調整）
- **波及**: 02-preparation §16 は inception phase の中央実行点で他フェーズへの影響なし

### 共通依存（4 項目すべて）

- `bin/check-bash-substitution.sh` ガード（コード置換禁止）に従う
- `bin/post-merge-sync.sh` のブランチ削除安全制約は `cycle/*` / `upgrade/*` プレフィックスのみ対象（A の Ruleset 設定は影響なし）
- 循環依存なし（4 項目は互いに独立、Construction Phase で並列処理可能）

## 特記事項

- 既存 `.claude-plugin/plugin.json` のスキル定義に変更は不要（4 項目はいずれも新規スキル追加なし）
- `tests/main-repo-health-check.bats` は本サイクル B で受け入れテスト追加対象
- C で操作する `~/.claude/settings.json`（user-global）への変更は、ユーザーの個人環境にも影響するため User Confirmation 必須（rules.md「設定ファイルのスコープ」: スコープ不明時は確認）
- A の Repository Ruleset 操作（`gh api` REST/GraphQL）は本リポジトリの公式 GitHub 設定に直接影響するため、Operations Phase で適用判断 + 適用は Construction 設計時に決定
