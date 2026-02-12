# 既存コード分析 - v1.14.0

## 現在のスキル構成

### スキル一覧（6スキル）

| スキル名 | 行数 | 種別 | agentskills.io準拠状況 |
|----------|------|------|----------------------|
| codex-review | 88行 | レビュー | description: 日本語（三人称でない）、compatibility: あり |
| claude-review | 111行 | レビュー | description: 日本語（三人称でない）、compatibility: なし |
| gemini-review | 94行 | レビュー | description: 日本語（三人称でない）、compatibility: なし |
| gh | 222行 | ユーティリティ | description: 日本語（三人称でない） |
| jj | 267行 | ユーティリティ | description: 日本語（三人称でない） |
| aidlc-upgrade | 43行 | ワークフロー | description: 日本語（三人称でない） |

### agentskills.io準拠の課題

1. **description が三人称でない**: 全スキル共通。ベストプラクティスでは三人称推奨（"Executes..." ではなく "I can help..." でもない）
2. **name が gerund form でない**: codex-review, claude-review, gemini-review は gerund form 推奨に対して noun-phrase
3. **compatibility フィールド**: codex-review のみ設定、他は未設定
4. **Progressive Disclosure 未適用**: 全スキルがフラットな SKILL.md のみ、references/ を活用していない

## レビュースキルの詳細分析

### 共通パターン（3スキル共通）

```
1. 実行コマンド
2. セッション継続方法
3. 反復レビュー時のルール
4. セッション継続を使うべき場面（テーブル）
5. 反復レビューの流れ（例）
6. パラメータ一覧
7. 使用例（設計/実装レビュー）
8. 実行手順
```

### ツール固有の差分

| 項目 | Codex | Claude | Gemini |
|------|-------|--------|--------|
| 実行コマンド | `codex exec -s read-only -C <dir> "<指示>"` | `claude -p --output-format stream-json "<指示>"` | `gemini -p "<指示>" --sandbox` |
| セッション継続 | `codex exec resume <session-id> "<指示>"` | `claude --session-id <uuid> -p --output-format stream-json "<指示>"` | `gemini --resume <index> -p "<指示>"` |
| セッション確認 | 出力末尾の session id | session id確認 | `gemini --list-sessions` |
| 固有の注意事項 | なし | stream-json必須、非決定性の対処 | インデックスベースのセッション管理 |

### 統合時のポイント

- **共通部分**: 反復レビューフロー、セッション使用場面テーブル、使用例パターンはほぼ同一
- **ツール固有部分**: コマンド構文、セッション管理方法、既知の制限事項が異なる
- **新規追加**: レビュー種別（lens）に応じた観点・チェックリストが必要

## ghスキルの分析

### 内容
- GitHub CLIの基本操作一覧（Issue、PR、リリース、API）
- 222行の包括的なコマンドリファレンス

### 削除理由
- Claude/Codex/Gemini は gh コマンドを既知
- AI-DLCプロンプト自体にも gh の使い方が埋め込まれている
- スキルとしての付加価値が低い

### 削除時の影響箇所

| ファイル（prompts/package/配下） | 参照内容 |
|--------------------------------|---------|
| `prompts/AGENTS.md` | スキル一覧テーブルからの削除 |
| `guides/skill-usage-guide.md` | gh関連の記述削除 |
| `.claude/skills/gh` | シンボリックリンク削除 |

### プロンプト調整（gh未使用時の対応）

以下のプロンプトでgh関連コマンドが直接使用されている:
- `prompts/inception.md`: ステップ12（Issue確認）、ステップ13（バックログ確認）、完了時（ラベル作成、ドラフトPR）
- `prompts/construction.md`: Unit完了時のコミット・プッシュ
- `prompts/operations.md`: リリース作成、PR操作

→ 既に `gh:available` の判定フローがあるため、**ghスキル削除はプロンプト側の変更は不要**（判定ロジックはスキルに依存していない）

## jjスキルの分析

### 内容
- 267行のjjコマンドリファレンス + Git対照表
- bookmark手動管理の重要な注意事項

### 改善点
1. **description**: 三人称化、英語での記述を検討
2. **Progressive Disclosure**: Git対照表（約40行）をreferencesに分離可能
3. **frontmatter**: name は gerund form を検討（ただし `jj` はツール名なので例外的にそのままでも可）

## aidlc-upgradeスキルの分析

### 内容
- 43行のシンプルなスキル
- setup-prompt.md を読み込む手順を案内

### 改善点
1. **#181対応**: 外部プロジェクトでの検索効率化
   - 現状: `prompts/setup-prompt.md` → Glob検索 → `docs/aidlc.toml` + ghq
   - 改善: まず `prompts/setup-prompt.md` 存在確認 → 不在なら即 `docs/aidlc.toml` 経由
2. **description**: 三人称化
3. **frontmatter**: name は gerund form を検討（`upgrading-aidlc` ?）

## 関連ファイルの参照マップ

### review-flow.md（最重要）
- `skill="codex"` / `skill="claude"` / `skill="gemini"` でスキルを呼び出し
- ai_tools設定（`docs/aidlc.toml`）から優先順位リストで選択
- **変更必要**: スキル名の更新、レビュー種別選択ロジックの追加

### AGENTS.md
- スキル一覧テーブル（Codex CLI / Claude Code / Gemini CLI）
- **変更必要**: テーブルの更新

### skill-usage-guide.md
- 各AIツールでのスキル設定手順
- `.claude/skills/` のシンボリックリンク構成説明
- **変更必要**: スキル名・構成の全面更新

### setup-prompt.md
- スキルディレクトリのrsync処理
- `.claude/skills/` シンボリックリンク作成処理
- **変更必要**: シンボリックリンク作成対象の更新

### docs/cycles/rules.md
- `Skill tool: skill="codex"` の記述
- **変更必要**: 新スキル名への更新

### docs/aidlc.toml
- `[rules.mcp_review]` の `ai_tools` 設定（`["codex"]`）
- **変更検討**: レビュー種別の設定追加の可能性
