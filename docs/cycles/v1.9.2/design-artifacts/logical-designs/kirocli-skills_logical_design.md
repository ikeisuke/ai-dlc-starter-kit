# 論理設計: KiroCLI Skills対応

## 概要

KiroCLIからCodex、Claude、Gemini CLIをSkillsとして呼び出すための設定をセットアップ時に自動生成する。

## コンポーネント構成

### 1. セットアッププロンプト（変更）

**ファイル**: `prompts/setup-prompt.md`

**変更内容**: KiroCLIエージェント設定ファイルの自動生成処理を追加

**生成されるファイル**: `.kiro/agents/aidlc.json`

```json
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント。Codex、Claude、Gemini CLIを呼び出してコードレビューや分析を実行できます。",
  "tools": ["read", "write", "shell"],
  "resources": [
    "skill://docs/aidlc/skills/codex/SKILL.md",
    "skill://docs/aidlc/skills/claude/SKILL.md",
    "skill://docs/aidlc/skills/gemini/SKILL.md"
  ]
}
```

### 2. 既存スキルファイル（変更なし）

| ファイル | 役割 |
|---------|------|
| `codex/SKILL.md` | Codex CLI呼び出し方法 |
| `claude/SKILL.md` | Claude Code CLI呼び出し方法 |
| `gemini/SKILL.md` | Gemini CLI呼び出し方法 |

これらはKiroCLI形式と互換性があるため、変更不要。

## インターフェース設計

### 生成されるエージェント設定ファイル

**パス**: `.kiro/agents/aidlc.json`

```json
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント。Codex、Claude、Gemini CLIを呼び出してコードレビューや分析を実行できます。",
  "tools": ["read", "write", "shell"],
  "resources": [
    "skill://docs/aidlc/skills/codex/SKILL.md",
    "skill://docs/aidlc/skills/claude/SKILL.md",
    "skill://docs/aidlc/skills/gemini/SKILL.md"
  ]
}
```

### 利用方法

```bash
# aidlcエージェントで起動
kiro-cli --agent aidlc

# または起動後に切り替え
> /agent swap aidlc
```

## 処理フロー

```
1. ユーザーがKiroCLIでエージェントを起動
   ↓
2. エージェント設定からスキル参照を読み込み
   ↓
3. スキルのメタデータ（name, description）のみ読み込み
   ↓
4. ユーザーが「Codexでレビューして」と指示
   ↓
5. エージェントがcodexスキルの全文を読み込み
   ↓
6. スキルの指示に従いshellツールでCodex CLIを実行
   ↓
7. 結果をユーザーに報告
```

## setup-prompt.md への変更詳細

### 追加するセクション

セクション8.2.3（プロジェクト固有ファイル）の後に、KiroCLIエージェント設定の生成処理を追加。

### 処理フロー

```bash
# .kiro/agents ディレクトリ作成
mkdir -p .kiro/agents

# aidlc.json が存在しない場合のみ作成
if [ ! -f ".kiro/agents/aidlc.json" ]; then
  cat > .kiro/agents/aidlc.json << 'EOF'
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント。Codex、Claude、Gemini CLIを呼び出してコードレビューや分析を実行できます。",
  "tools": ["read", "write", "shell"],
  "resources": [
    "skill://docs/aidlc/skills/codex/SKILL.md",
    "skill://docs/aidlc/skills/claude/SKILL.md",
    "skill://docs/aidlc/skills/gemini/SKILL.md"
  ]
}
EOF
  echo "Created: .kiro/agents/aidlc.json"
else
  echo "Skipped: .kiro/agents/aidlc.json already exists"
fi
```

## 調査レポートの詳細設計

### docs/cycles/v1.9.2/research/kirocli-skills.md

**本文構成**:

1. **調査概要**: KiroCLI Skills機能の調査目的
2. **調査結果**: 機能の特徴、フォーマット要件
3. **既存スキルとの互換性**: 互換性分析結果
4. **設計への反映**: 設計方針の根拠
5. **参考資料**: 参照したドキュメントURL

## 不明点と質問

（なし）
