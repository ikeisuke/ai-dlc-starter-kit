# Unit: jj (Jujutsu) Skill追加

## 概要

Jujutsu (jj) の操作をAIスキルとして追加し、AIとの協調作業でバージョン管理操作を効率化する。

## 含まれるユーザーストーリー

- ストーリー5: jj (Jujutsu) Skillの追加 (#124)

## 責務

- `prompts/package/skills/jj/SKILL.md` の作成
- jjの基本操作（status, log, describe, new）のカバー
- git互換コマンド（fetch, push）のカバー
- co-locationモードでの使用方法の記載
- gitコマンドとの対照表の提供

## 境界

- jj CLI自体の機能拡張は行わない
- 高度な操作（rebase、split等）は初回スコープ外

## 依存関係

### 依存する Unit

なし

### 外部依存

- Jujutsu (jj)

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- 既存の `docs/aidlc/guides/jj-support.md` の内容を活用
- gitコマンドとの対照表を含める（jj-support.mdから移植）
- 既存Skillsの形式を踏襲

### スキル仕様準拠（Claude Code公式: https://code.claude.com/docs/ja/skills）

frontmatterは以下の形式で作成すること：

```yaml
---
name: jj
description: 簡潔な説明（何をするか、いつ使うか）。「トリガー:」は不要
argument-hint: [subcommand] [args]
allowed-tools: Bash(jj:*)
---
```

**必須観点**:
- descriptionは「何をするか、いつ使うか」を簡潔に記述（トリガーキーワード列挙は不要）
- argument-hintで予想される引数を示す
- allowed-toolsで使用可能なツールを制限
- SKILL.mdは500行以下に

## 実装優先度

Medium

## 見積もり

中（新規Skillファイル作成、既存ガイド活用可）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
