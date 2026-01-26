# Unit 004: skills構成変更 計画

## 概要

skillsディレクトリ配下の各スキルをシンボリックリンクにし、プロジェクト独自スキルを追加できるようにする。

## 現状の問題

- `setup-prompt.md` のセクション8.2.2.4 で `rsync --delete` を使用している
- これにより、プロジェクト独自スキル（例: `docs/aidlc/skills/my-custom/`）が削除される
- Issue #119「skills自体をシンボリックリンクにしない」のフィードバック

## 変更後の構成

```
docs/aidlc/skills/
├── codex/   → [スターターキット]/prompts/package/skills/codex/   (シンボリックリンク)
├── claude/  → [スターターキット]/prompts/package/skills/claude/  (シンボリックリンク)
├── gemini/  → [スターターキット]/prompts/package/skills/gemini/  (シンボリックリンク)
└── my-custom/  (プロジェクト独自、実ディレクトリ)
```

## 変更対象ファイル

1. `prompts/setup-prompt.md` - rsync → シンボリックリンク方式に変更
2. `prompts/package/guides/skill-usage-guide.md` - プロジェクト独自スキル追加方法をドキュメント化

## 実装計画

### Phase 1: 設計

#### 1. setup-prompt.md の修正方針

セクション8.2.2.4「スキルファイルの同期（rsync）」を以下に変更:

- rsync ではなくシンボリックリンクを作成する方式に変更
- `docs/aidlc/skills/` ディレクトリを作成（実ディレクトリ）
- 各スキル（codex, claude, gemini）をシンボリックリンクとして作成
- 既存のシンボリックリンクは確認してスキップ
- 既存の実ディレクトリがある場合はユーザーに確認

#### 2. skill-usage-guide.md への追記

以下のセクションを追加:
- プロジェクト独自スキルの追加方法
- ディレクトリ構成の例
- 命名規則（スターターキットのスキル名との衝突回避）

### Phase 2: 実装

1. setup-prompt.md の修正
2. skill-usage-guide.md の修正

## 完了条件チェックリスト

- [ ] セットアップ時に skills 配下の各スキルをシンボリックリンクで作成
- [ ] プロジェクト独自スキル追加方法をドキュメント化
