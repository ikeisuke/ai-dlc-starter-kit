# 既存コードベース分析

## ディレクトリ構造・ファイル構成

対象: `prompts/package/guides/`（デプロイ後: `docs/aidlc/guides/`）

```text
docs/aidlc/guides/
├── ai-agent-allowlist.md    # AIエージェント許可リスト設定ガイド
├── backlog-management.md    # バックログ管理フロー定義
├── backlog-registration.md  # バックログ登録確認フロー
├── config-merge.md          # 設定ファイルマージルール
├── error-handling.md        # エラーハンドリング方針
├── glossary.md              # AI-DLC用語集
├── ios-version-update.md    # iOSバージョン更新手順
├── issue-management.md      # Issueライフサイクル管理
├── plan-mode.md             # Claude Codeプランモード活用
├── sandbox-environment.md   # サンドボックス環境設定
├── skill-usage-guide.md     # スキル利用方法
├── subagent-usage.md        # サブエージェント活用
└── worktree-usage.md        # git worktree利用方法
```

## アーキテクチャ・パターン

- ガイドは独立したMarkdownファイルとして構成
- 正本は `prompts/package/guides/` に配置し、`docs/aidlc/guides/` はrsyncコピー
- 各ガイドは特定のツール（Claude Code専用等）またはフェーズ横断で利用される

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown | 全ガイドファイル |
| ツール | Claude Code, Kiro CLI | ai-agent-allowlist.md |
| 設定形式 | TOML | docs/aidlc.toml |

## 依存関係

- ガイドからスクリプト参照: `docs/aidlc/bin/` 配下のスクリプト群
- ガイドからプロンプト参照: `docs/aidlc/prompts/common/` 配下
- 設定ファイル参照: `docs/aidlc.toml`

## 特記事項

### 精査で対応すべき問題の分類

| カテゴリ | 該当ファイル | 内容 |
|---------|-----------|------|
| 不要なツール記述（Codex CLI/Cline/Cursor/Gemini CLI） | ai-agent-allowlist.md, sandbox-environment.md, skill-usage-guide.md | 削除対象 |
| jj関連記述（非推奨） | ai-agent-allowlist.md | 許可リスト・設定例からjjコマンドを削除 |
| スクリプト参照の整合性 | backlog-management.md, issue-management.md, worktree-usage.md | 実在スクリプトとの照合が必要 |
| 参考リンクの正確性 | ai-agent-allowlist.md, sandbox-environment.md | リンク先の存在確認 |

### 精査不要（問題なし）と判定したファイル

- backlog-registration.md: シンプルで正確
- config-merge.md: マージルールが明確
- ios-version-update.md: iOS固有の手順で正確
- plan-mode.md: Claude Code専用、正確
- subagent-usage.md: Claude Code専用、正確
