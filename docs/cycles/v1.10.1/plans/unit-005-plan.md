# Unit 005 計画: jj (Jujutsu) Skill追加

## 概要

Jujutsu (jj) の操作をAIスキルとして追加し、AIとの協調作業でバージョン管理操作を効率化する。

## 変更対象ファイル

| ファイル | 変更種別 |
|---------|---------|
| `prompts/package/skills/jj/SKILL.md` | 新規作成 |

## 参照ファイル

- `docs/aidlc/guides/jj-support.md` - 既存のjjガイド（内容活用）
- `prompts/package/skills/gh/SKILL.md` - 既存Skillの形式参考

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: スキル構造の定義
   - コマンドカテゴリの整理
   - 対象範囲の明確化

2. **論理設計**: SKILL.mdの構成設計
   - frontmatter形式の決定
   - セクション構成の設計

### Phase 2: 実装

3. **コード生成**: `prompts/package/skills/jj/SKILL.md` 作成
   - Claude Code公式スキル仕様に準拠
   - 500行以下に収める
   - jj-support.mdから必要な情報を抽出・簡潔化

4. **テスト生成**: N/A（ドキュメントのみ）

5. **統合とレビュー**: 内容確認

## 完了条件チェックリスト

- [ ] `prompts/package/skills/jj/SKILL.md` が作成されている
- [ ] jjの基本操作（status, log, describe, new）がカバーされている
- [ ] git互換コマンド（fetch, push）がカバーされている
- [ ] co-locationモードでの使用方法が記載されている
- [ ] gitコマンドとの対照表が提供されている
- [ ] Claude Code公式スキル仕様に準拠している（frontmatter形式、500行以下）

## 技術的考慮事項

- 既存の `docs/aidlc/guides/jj-support.md` の内容を活用するが、500行制限のため簡潔化が必要
- gitコマンドとの対照表を含める（jj-support.mdから抽出）
- 既存Skillsの形式（gh/SKILL.md）を踏襲
- frontmatterは以下の形式:
  ```yaml
  ---
  name: jj
  description: 簡潔な説明
  argument-hint: [subcommand] [args]
  allowed-tools: Bash(jj:*)
  ---
  ```
