# 既存コード分析

## 分析対象

- #86: AIスキル統合
- #82: AIレビュー設定強化
- #83: jjサポート強化

---

## #86: AIスキル統合

### 現状

- `prompts/package/skills/` ディレクトリは**存在しない**（新規作成必要）
- `.claude/skills/` ディレクトリは存在（`settings.local.json`のみ）
- スキルファイルは個人環境（`~/.claude/skills/`）に配置されている

### 関連ファイル

| ファイル | 用途 |
|---------|------|
| `prompts/setup-prompt.md` | rsync処理（prompts/package/ → docs/aidlc/） |
| `~/.claude/skills/codex/SKILL.md` | 個人環境のcodexスキル |
| `~/.claude/skills/claude/SKILL.md` | 個人環境のclaudeスキル |
| `~/.claude/skills/gemini/SKILL.md` | 個人環境のgeminiスキル |

### 必要な変更

1. `prompts/package/skills/` ディレクトリを作成
2. スキルファイル（codex/claude/gemini）を配置
3. セットアップスクリプトのrsync対象に `skills/` を追加
4. `.claude/skills/` にシンボリックリンクを作成

---

## #82: AIレビュー設定強化

### 現状

- `aidlc.toml` の `[rules.mcp_review]` セクションに `mode` 設定のみ存在
- AIレビューツールの優先順位はプロンプト内でハードコード
  - 優先: Skill `codex`
  - フォールバック: MCP `mcp__codex__codex`

### 関連ファイル

| ファイル | 用途 |
|---------|------|
| `docs/aidlc.toml` | 設定ファイル |
| `prompts/package/prompts/inception.md` | AIレビューフロー定義 |
| `prompts/package/prompts/construction.md` | AIレビューフロー定義 |
| `prompts/package/prompts/operations.md` | AIレビューフロー定義 |

### 現在の設定例

```toml
[rules.mcp_review]
mode = "required"
```

### 必要な変更

1. `mcp_tools` 設定を追加
2. プロンプト内のAIレビューフローを変更（設定を読み取り、優先順位に従ってツールを選択）

### 提案する設定形式

```toml
[rules.mcp_review]
mode = "required"
mcp_tools = ["mcp__codex__codex", "mcp__other__tool"]
```

---

## #83: jjサポート強化

### 現状

- `docs/aidlc/guides/jj-support.md` は既に充実（427行）
- 以下のセクションが存在:
  - 概要・前提条件
  - gitとjjの考え方の違い
  - Git/jjコマンド対照表
  - AI-DLCワークフローでの使用方法
  - 作業開始/終了チェックリスト
  - 注意事項と制限

### 関連ファイル

| ファイル | 用途 |
|---------|------|
| `docs/aidlc/guides/jj-support.md` | jjサポートガイド |
| `prompts/package/guides/jj-support.md` | ガイドのソース |
| `docs/aidlc.toml` | `[rules.jj]` 設定 |

### 不足している内容

1. よくあるミスと対処法のセクション
2. トラブルシューティングガイド
3. 具体的なエラーメッセージと解決策

### 必要な変更

1. 「よくあるミスと対処法」セクションを追加
2. 具体的なエラーケースと解決策を記載

---

## 依存関係

```
#86（AIスキル統合）
  └── セットアップスクリプト修正
  └── シンボリックリンク作成

#82（AIレビュー設定強化）
  └── aidlc.toml設定追加
  └── プロンプト修正（各フェーズ）

#83（jjサポート強化）
  └── jj-support.md更新
```

---

## 分析日

2026-01-20
