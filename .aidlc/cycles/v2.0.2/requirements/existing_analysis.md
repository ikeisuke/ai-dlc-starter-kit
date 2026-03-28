# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
.
├── .aidlc/                    # AI-DLC設定・サイクルデータ
│   ├── config.toml            # プロジェクト設定
│   └── cycles/                # サイクル履歴（v1.0.1〜v2.0.2）
├── .agents/                   # Codex CLI スキル登録（シンボリックリンク）
│   └── skills/                # → docs/aidlc/skills/* へのリンク（v1パス）
├── .claude/                   # Claude Code設定
│   ├── settings.json          # パーミッション設定
│   └── skills/                # → skills/* へのリンク（v2パス）
├── .github/ISSUE_TEMPLATE/    # Issueテンプレート（スターターキットから導入）
│   ├── backlog.yml
│   ├── bug.yml
│   ├── feature.yml
│   └── feedback.yml
├── .kiro/                     # Kiro CLI設定
│   ├── agents/                # aidlc.json（→ docs/aidlc/kiro/、v1パス）+ aidlc-poc.json（実体）
│   └── skills/                # → docs/aidlc/skills/* へのリンク（v1パス）
├── bin/                       # メタ開発用スクリプト
├── docs/aidlc/                # v1配布パッケージ（rsync先、v2では参照先としては廃止予定）
│   ├── skills/                # スキル定義（v1配置先、.agents/.kiroのリンク先）
│   ├── kiro/agents/           # Kiroエージェント設定（v1配置先）
│   ├── lib/                   # 共通ライブラリ
│   └── ...
├── prompts/                   # スターターキット開発用ソース（スコープ外）
│   └── package/               # rsync元
├── skills/                    # v2スキル実体（.claude/skills/のリンク先）
│   ├── aidlc/                 # メインスキル（SKILL.md, steps/, scripts/, templates/）
│   ├── aidlc-setup/           # セットアップスキル
│   ├── reviewing-*/           # レビュースキル群
│   └── squash-unit/           # スカッシュスキル
├── AGENTS.md                  # エージェント設定
├── CLAUDE.md                  # Claude Code設定
└── version.txt                # バージョン（2.0.1）
```

## アーキテクチャ・パターン

### シンボリックリンクによるマルチツール対応

3つのAIツール（Claude Code / Codex CLI / Kiro CLI）に対応するため、各ツールのスキル登録ディレクトリからシンボリックリンクで参照する構成。

| ツール | 登録先 | リンク先（v1） | リンク先（v2） |
|--------|--------|---------------|---------------|
| Claude Code | `.claude/skills/` | `skills/*`（v2済み） | — |
| Codex CLI | `.agents/skills/` | `docs/aidlc/skills/*`（v1パス） | 未移行 |
| Kiro CLI | `.kiro/skills/` | `docs/aidlc/skills/*`（v1パス） | 未移行 |
| Kiro agents | `.kiro/agents/` | `docs/aidlc/kiro/agents/*`（v1パス） | 未移行 |

**根拠**: `.claude/skills/` は v2.0.1 で `skills/` への直接リンクに更新済み。`.agents/` と `.kiro/` は `docs/aidlc/` への旧パスのまま。

### スキル構成

- メインスキル `skills/aidlc/` がオーケストレーター
- ステップファイル方式（`steps/{phase}/{NN}-{name}.md`）で手順を分離
- 共通処理は `steps/common/` に集約
- テンプレートは `skills/aidlc/templates/` に配置
- スクリプトは `skills/aidlc/scripts/` に配置

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown, Bash | skills/aidlc/SKILL.md, skills/aidlc/scripts/*.sh |
| フレームワーク | なし（AI-DLCスキルフレームワーク） | — |
| 主要ツール | Claude Code, Codex CLI, Kiro CLI | .claude/, .agents/, .kiro/ |
| 設定形式 | TOML | .aidlc/config.toml |

## 依存関係

### 内部モジュール間（スキル単位）

```
aidlc (オーケストレーター)
├── aidlc-setup (セットアップ)
├── reviewing-inception (Inceptionレビュー)
├── reviewing-code (コードレビュー)
├── reviewing-architecture (アーキテクチャレビュー)
├── reviewing-security (セキュリティレビュー)
└── squash-unit (スカッシュ)
```

- 依存方向: aidlc → 他スキル（一方向）
- 循環依存: なし

### v1→v2パス参照の残存箇所

- `.agents/skills/*` → `docs/aidlc/skills/*`（6件）
- `.kiro/skills/*` → `docs/aidlc/skills/*`（6件）
- `.kiro/agents/aidlc.json` → `docs/aidlc/kiro/agents/aidlc.json`（1件）
- ステップファイル内の `docs/aidlc/` 直接参照（#420の対象）

## 特記事項

- `.kiro/agents/aidlc-poc.json` は実体ファイル（シンボリックリンクではない）。POC用なので削除候補
- `.github/ISSUE_TEMPLATE/` の4ファイルはスターターキットのセットアップで導入されたもの。v2では削除対象
- Codexレビュー実行時に `.agents/skills/` のリンク切れエラーが毎回出力される（`docs/aidlc/skills/` の実体がworktreeに存在しないため）
- `docs/aidlc/` は `prompts/package/` からのrsync先だが、v2ではスキル実体が `skills/` に移動しているため、`docs/aidlc/skills/` は参照先として不整合
