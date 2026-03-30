# 既存コードベース分析

## ディレクトリ構造・ファイル構成

v1.19.1で変更が必要なファイルは主に `prompts/package/` 配下に集中。

```text
prompts/package/
├── prompts/common/
│   ├── rules.md           (#286, #289)
│   └── review-flow.md     (#285)
├── prompts/
│   └── operations.md      (#288)
├── skills/session-title/
│   ├── SKILL.md            (#287)
│   └── bin/aidlc-session-title.sh (#287)
├── guides/
│   └── glossary.md         (#283, 新規作成)
└── bin/
    └── post-merge-cleanup.sh (#288, 参照対象)

.claude/skills/
├── reviewing-code/SKILL.md       (#285)
├── reviewing-architecture/SKILL.md (#285)
└── reviewing-security/SKILL.md    (#285)
```

## アーキテクチャ・パターン

- **メタ開発パターン**: `prompts/package/` が正本、`docs/aidlc/` はrsyncコピー
- **スキルパターン**: SKILL.mdで外部CLI呼び出し定義、セルフレビューモードはフォールバック
- **プロンプト駆動**: AIエージェントの動作はプロンプトファイルで制御

根拠: `docs/cycles/rules.md` のメタ開発セクション、各SKILL.mdのcompatibility定義

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown, Bash | prompts/, bin/ |
| フレームワーク | AI-DLC | docs/aidlc.toml |
| 主要ツール | Claude Code, Codex, gh CLI | docs/aidlc.toml, SKILL.md |

## 依存関係

### #285: レビュースキルの外部ツール優先問題

**現状の問題**:
- `review-flow.md` ステップ3（行111-118）: スキルの存在確認のみで外部CLIの可用性を未確認
- スキルが存在する → ステップ4へ → ステップ5で外部CLI実行 → CLIが見つからない場合のフォールバック未定義
- 3つのレビュースキル（行5-6）: `compatibility` と `allowed-tools` は外部CLI前提だがセルフレビューモード（行79-134）も存在

**変更対象**:

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `prompts/package/prompts/common/review-flow.md` | 83-98, 111-118 | 外部CLIの可用性確認ロジック追加 |
| `prompts/package/prompts/common/review-flow.md` | 135-210 | スキル実行失敗時のフォールバック処理追加 |
| `.claude/skills/reviewing-code/SKILL.md` | 5 | セルフレビューモードでは外部CLI不要である旨を追記 |
| `.claude/skills/reviewing-architecture/SKILL.md` | 5 | 同上 |
| `.claude/skills/reviewing-security/SKILL.md` | 5 | 同上 |

### #286: `$()`・バッククォート禁止ルール

**現状**: `$()` 禁止は `rules.md` 行259-272に既に明文化済み。バッククォート（`` ` ``）コマンド置換の禁止は未明文化。

**変更対象**:

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `prompts/package/prompts/common/rules.md` | 259 | 見出しにバッククォートを追加 |
| `prompts/package/prompts/common/rules.md` | 261-263 | バッククォート禁止の説明・例を追加 |

### #287: session-titleタイトル表示順変更

**現状**: 表示順は「プロジェクト / フェーズ / バージョン」（行22: `TITLE="$PROJECT_NAME / $PHASE / $CYCLE"`）

**変更対象**:

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `prompts/package/skills/session-title/bin/aidlc-session-title.sh` | 6, 14-16, 22 | 引数順・タイトル組み立て変更、UNIT引数追加 |
| `prompts/package/skills/session-title/SKILL.md` | 4, 16-18, 24, 26 | 引数説明・呼び出し例の更新 |
| 各フェーズプロンプトの呼び出し箇所 | 各所 | 引数順の更新 |

### #288: post-merge-cleanup.sh組み込み

**現状**: `operations.md` 行615-680「PRマージ後の手順」に手動コマンドが記載。`post-merge-cleanup.sh` への参照なし。

**変更対象**:

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `prompts/package/prompts/operations.md` | 615-680 | worktree環境時に `post-merge-cleanup.sh` を呼び出すフローを追加 |

**注意**: `post-merge-cleanup.sh` はworktree環境専用。非worktree環境では従来手順を維持。バージョンタグ付けは別途残す必要あり。

### #289: 改善提案のバックログissue作成ルール

**現状**: `rules.md` に改善提案時のバックログissue作成ルールは未定義。関連するバックログフローは `construction.md` の気づき記録フロー（行55-86）と `review-flow.md` のOUT_OF_SCOPEバックログ登録（行468-623）のみ。

**変更対象**:

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `prompts/package/prompts/common/rules.md` | 346の後 | 新セクション「改善提案のバックログ登録ルール」を追加 |

### #282: Error Handling体系化

**現状**: エラーハンドリングの体系的な定義なし。各プロンプトに個別のエラー処理記述が散在。

**変更対象**:

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/guides/error-handling.md`（新規） | エラー重大度レベル定義、主要フェーズの基本復旧手順 |
| 各フェーズプロンプト | エラー発生時にガイド参照を追加（最小限の変更） |

### #283: Terminology/Glossary

**現状**: AI-DLC固有用語の体系的な定義なし。`intro.md` に概要説明があるのみ。

**変更対象**:

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/guides/glossary.md`（新規） | AI-DLC固有用語の定義一覧 |

## 特記事項

- `docs/aidlc/` 配下の同名ファイルは `prompts/package/` の rsync コピーのため、直接編集禁止
- `.claude/skills/` のSKILL.mdは `prompts/package/skills/` から deploy されたコピー
- #288の `post-merge-cleanup.sh` はworktree環境専用のため、非worktree環境との分岐が必要
