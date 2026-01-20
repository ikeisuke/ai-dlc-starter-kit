# Unit 001 実行計画: スキルファイル配置

## 概要

AIスキル（codex/claude/gemini）のソースファイルを `prompts/package/skills/` に配置する。

## 変更対象ファイル

### 新規作成

- `prompts/package/skills/codex/SKILL.md`
- `prompts/package/skills/claude/SKILL.md`
- `prompts/package/skills/gemini/SKILL.md`

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - スキルファイルの構造定義（YAMLフロントマター + Markdownコンテンツ）
   - ディレクトリ構成の設計

2. **論理設計**
   - ファイル配置パターンの決定

### Phase 2: 実装

1. **ディレクトリ作成**
   - `prompts/package/skills/` ディレクトリを作成
   - 各スキル用サブディレクトリ（codex, claude, gemini）を作成

2. **スキルファイル配置**
   - `~/.claude/skills/` から内容をコピー
   - SKILL.md 形式を維持

## 完了条件チェックリスト

- [ ] 3つのスキルファイル（codex/claude/gemini）を `prompts/package/skills/` に配置
- [ ] スキルファイルの内容は既存の `~/.claude/skills/` からコピー
- [ ] SKILL.md 形式（YAMLフロントマター + Markdownコンテンツ）を維持

## 備考

- このUnitはファイルコピーのみの小規模作業
- セットアップスクリプトの修正は Unit 002 で対応
