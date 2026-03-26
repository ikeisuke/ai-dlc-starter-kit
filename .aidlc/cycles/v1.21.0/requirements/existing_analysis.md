# 既存コードベース分析

## ディレクトリ構造・ファイル構成

### スキル管理の3段階構造

```
prompts/package/skills/          → docs/aidlc/skills/          → .claude/skills/
(スターターキットソース)           (プロジェクトコピー)            (Claude Code用シンボリックリンク)
                                                                  .kiro/skills/
                                                                  (KiroCLI用シンボリックリンク)
```

### 現在のスキル一覧（8スキル）

| スキル | 種別 | 状態 | ファイル構成 |
|--------|------|------|------------|
| `reviewing-architecture` | AI-DLC固有 | 有効 | SKILL.md, references/session-management.md |
| `reviewing-code` | AI-DLC固有 | 有効 | SKILL.md, references/session-management.md |
| `reviewing-inception` | AI-DLC固有 | 有効 | SKILL.md, references/session-management.md |
| `reviewing-security` | AI-DLC固有 | 有効 | SKILL.md, references/session-management.md |
| `session-title` | 汎用ツール | 有効 | SKILL.md, bin/aidlc-session-title.sh |
| `squash-unit` | AI-DLC固有 | 有効 | SKILL.md |
| `upgrading-aidlc` | AI-DLC固有 | 有効（リネーム対象） | SKILL.md, bin/upgrade-aidlc.sh |
| `versioning-with-jj` | 汎用ツール | 非推奨（v1.19.0） | SKILL.md, references/jj-support.md |

## アーキテクチャ・パターン

### スキルデプロイメントパイプライン

1. **パッケージ同期**（`prompts/package/bin/sync-package.sh`）: `prompts/package/skills/` → `docs/aidlc/skills/` にrsyncコピー
2. **AIツールセットアップ**（`docs/aidlc/bin/setup-ai-tools.sh`）: `docs/aidlc/skills/*/` を走査し、SKILL.mdがあるディレクトリに対して `.claude/skills/` と `.kiro/skills/` にシンボリックリンクを作成
3. 根拠: `upgrade-aidlc.sh` のステップ6-7で上記パイプラインを実行

### マーケットプレイス方式

- 現在のリポジトリに `.claude-plugin/marketplace.json` は**存在しない**
- `claude-skills` リポジトリへの参照もコードベース内になし
- マーケットプレイス方式は完全に新規実装が必要

### スキル参照箇所

| ファイル | 参照内容 |
|---------|---------|
| `docs/aidlc/prompts/common/ai-tools.md` | スキル一覧テーブル（正式なカタログ） |
| `docs/aidlc/prompts/common/review-flow.md` | `skill="reviewing-*"` 呼び出し |
| `docs/aidlc/prompts/operations.md` | `/upgrading-aidlc` スキル呼び出し |
| `docs/aidlc/prompts/inception.md` | `session-title` スキル呼び出し |
| `docs/aidlc/prompts/construction.md` | `session-title` スキル呼び出し |
| `docs/aidlc/prompts/common/commit-flow.md` | `/squash-unit` スキル推奨 |
| `docs/aidlc/prompts/common/rules.md` | `versioning-with-jj` 参照 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown, Bash | prompts/package/skills/*/SKILL.md, docs/aidlc/bin/*.sh |
| フレームワーク | AI-DLC（独自方法論） | docs/aidlc/prompts/ |
| 主要ツール | Claude Code, GitHub CLI, dasel | docs/aidlc.toml |
| VCS | Git（jjは非推奨） | docs/aidlc.toml [rules.jj] |
| 対応AIエージェント | Claude Code, KiroCLI, Codex CLI, Gemini CLI, Cursor, Cline, Windsurf | docs/aidlc/prompts/common/commit-flow.md |

## 依存関係

### jj関連コードの分布（削除対象）

| ファイル | jj関連コード |
|---------|-------------|
| `docs/aidlc/bin/aidlc-git-info.sh` | `.jj`ディレクトリ検出、`jj log`/`jj diff --stat`呼び出し、`warn:jj-deprecated`出力 |
| `docs/aidlc/bin/aidlc-cycle-info.sh` | `.jj`検出、`jj log -r @ -T 'bookmarks'`でブランチ取得 |
| `docs/aidlc/bin/squash-unit.sh` | `find_base_commit_jj()`, `squash_jj()`, `--vcs jj`オプション処理 |
| `docs/aidlc/bin/aidlc-env-check.sh` | `jj`コマンド可用性チェック |
| `docs/aidlc/prompts/common/rules.md` | `rules.jj.enabled`読み取り、`jj-support.md`参照 |
| `docs/aidlc/prompts/common/commit-flow.md` | jj用コミットブロック（`jj describe`, `jj new`, `jj status`） |
| `docs/aidlc/prompts/inception.md` | `jj status`参照、env-info表のjj行 |
| `docs/aidlc/prompts/construction.md` | `jj diff --stat`参照 |
| `docs/aidlc/prompts/operations.md` | gitタグはjj環境でもgitを使用する注記 |
| `docs/aidlc.toml` | `[rules.jj]`セクション |

### マルチプラットフォーム対応の現状

| エージェント | 設定ファイル | スキル連携 | コミット属性 | 備考 |
|------------|-----------|---------|-----------|------|
| Claude Code | CLAUDE.md, .claude/skills/ | シンボリックリンク | 自動検出 | 最も充実 |
| KiroCLI | .kiro/agents/aidlc.json, .kiro/skills/ | シンボリックリンク | 自動検出 | 2番目に充実 |
| Codex CLI | なし | 外部レビューツールとして使用 | 自動検出 | エージェントホストとしても対応 |
| Gemini CLI | なし | 外部レビューツールとして使用 | 未対応 | エージェント設定なし |
| Cursor | なし（.cursorrules不在） | なし | 環境変数検出 | 設定ファイル未整備 |
| Cline | なし（.clinerules不在） | なし | 環境変数検出 | 設定ファイル未整備 |
| Windsurf | なし | なし | 環境変数検出 | commit-flowのみ |

### 互換性ギャップ

1. **共有プロンプト内のClaude Code固有ツール名**: `commit-flow.md`/`review-flow.md`が`Writeツール`/`Readツール`を参照（他エージェントでは解釈が必要）
2. **`AskUserQuestion`はClaude Code専用**: `inception.md`等で使用。他エージェントではプレーンテキストにフォールバック
3. **`$()`禁止ルール**: Claude Codeのセミオートモード固有の制約（他エージェントでは無関係だが無害）
4. **サブエージェント（Task Tool）/ Plan Mode**: Claude Code専用機能（他エージェントに同等機能なし）
5. **`.cursorrules`/`.windsurfrules`/`.clinerules`未作成**: Cursor/Windsurf/Clineには専用コンテキスト注入機構がない

## 特記事項

- `prompts/package/`（ソース）と`docs/aidlc/`（コピー）は同一内容。編集は必ず`prompts/package/`側で行う
- `upgrading-aidlc`の`upgrade-aidlc.sh`はシンボリックリンク追跡に対応（`.claude/skills/`から実行しても正しくパス解決）
- レビュースキルは3つの外部CLIツール（codex/claude/gemini）とセルフレビューモードの4方式に対応
- Kiroは`.kiro/agents/aidlc.json`による専用エージェント設定が既にある
