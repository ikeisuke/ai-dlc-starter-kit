# Unit 004 計画: gh (GitHub CLI) Skill追加

## 概要

GitHub CLI (gh) の操作をAIスキルとして追加し、AIとの協調作業でGitHub操作を効率化する。

## 変更対象ファイル

| ファイル | 操作 |
|---------|------|
| `prompts/package/skills/gh/SKILL.md` | 新規作成 |

## 実装計画

### Phase 1: 設計

ドキュメントのみのUnitのため、設計省略。直接SKILL.mdの構成を定義する。

### Phase 2: 実装

1. `prompts/package/skills/gh/` ディレクトリを作成
2. 既存Skills（codex, claude, gemini）の形式に従い `SKILL.md` を作成
3. 以下のセクションを含める:
   - frontmatter (name, description, triggers)
   - 概要
   - Issue操作（作成、一覧、表示、クローズ）
   - PR操作（作成、一覧、表示、マージ）
   - リリース操作（作成、一覧、ダウンロード）
   - 認証に関する注意事項
   - 使用例

---

## 完了条件チェックリスト

- [x] `prompts/package/skills/gh/SKILL.md` を作成
- [x] Issue操作（作成、一覧、表示、クローズ）をカバー
- [x] PR操作（作成、一覧、表示、マージ）をカバー
- [x] リリース操作の基本コマンドをカバー
- [x] 他のSkillsと同様の形式で記載
