# 既存コード分析 - v1.13.4

## 分析対象
- Codex skills関連の実装
- claude-reviewスキルの実装
- セットアップスクリプト

## 現状の構造

### スキル配置の二層構造
1. **ソース**: `prompts/package/skills/` → rsyncで `docs/aidlc/skills/` にコピー
2. **配置**: `docs/aidlc/skills/` → `.claude/skills/` にシンボリックリンク

### セットアップスクリプト
- **本体**: `docs/aidlc/bin/setup-ai-tools.sh`（130行）
- **簡略版**: `prompts/package/bin/setup-ai-tools.sh`（44行）
- `.claude/skills/<skill-name>/` にシンボリックリンクを作成
- `~/.codex/skills/` への配置は**未対応**

### 各スキルのメタデータ（共通フィールド）
- `name`, `description`, `argument-hint`, `allowed-tools`
- **compatibilityフィールドは存在しない**

## Issue別の影響分析

### #177: Codex skillsシンボリックリンク調整
- **現状**: `.claude/skills/` のみ配置。Codex CLIの `~/.codex/skills/` は未対応
- **変更箇所**: `prompts/package/bin/setup-ai-tools.sh` にCodex skills配置処理を追加
- **注意**: メタ開発のため `docs/aidlc/bin/setup-ai-tools.sh` は直接編集せず、`prompts/package/bin/` を編集

### #178: compatibilityフィールド追加
- **現状**: SKILL.mdにcompatibilityフィールドなし
- **変更箇所**: `prompts/package/skills/codex-review/SKILL.md` にフィールド追加
- **参考**: Agent Skills Specification のcompatibilityフィールド仕様

### #179: claude-reviewスキル不安定動作
- **現状のコマンド**: `claude -p "<レビュー指示>"`
- **セッション継続**: `claude --session-id <uuid> -p "<追加指示>"`
- **不安定動作の可能性**:
  - レスポンス未返却: `-p` モードのタイムアウトや出力バッファリングの問題
  - 指摘の二転三転: セッション継続が正しく機能していない、またはモデルの非決定性

## 関連ファイル一覧

| ファイル | 役割 |
|----------|------|
| `prompts/package/skills/codex-review/SKILL.md` | Codex reviewスキル定義（ソース） |
| `prompts/package/skills/claude-review/SKILL.md` | Claude reviewスキル定義（ソース） |
| `prompts/package/bin/setup-ai-tools.sh` | AIツールセットアップ（ソース） |
| `docs/aidlc/skills/codex-review/SKILL.md` | Codex reviewスキル定義（デプロイ先） |
| `docs/aidlc/skills/claude-review/SKILL.md` | Claude reviewスキル定義（デプロイ先） |
| `docs/aidlc/bin/setup-ai-tools.sh` | AIツールセットアップ（デプロイ先） |
