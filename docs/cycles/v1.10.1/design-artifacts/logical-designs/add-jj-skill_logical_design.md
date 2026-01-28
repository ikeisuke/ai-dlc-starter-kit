# jj Skill 論理設計

## ファイル構成

```text
prompts/package/skills/jj/
└── SKILL.md
```

## SKILL.md 構成設計

### frontmatter（必須）

```yaml
---
name: jj
description: Jujutsu (jj) でバージョン管理操作を実行。Git互換の次世代VCSで、自動追跡・安全なrebase・操作取り消しを提供。
argument-hint: [subcommand] [args]
allowed-tools: Bash(jj:*)
---
```

### セクション構成

| セクション | 内容 | 行数目安 |
|-----------|------|---------|
| 1. タイトル・概要 | スキルの説明 | 10行 |
| 2. 重要な注意事項 | bookmarkの手動移動等 | 20行 |
| 3. 状態確認コマンド | status, log, diff | 30行 |
| 4. コミット操作 | describe, new, split | 40行 |
| 5. ブックマーク操作 | bookmark list/create/set, edit | 40行 |
| 6. リモート操作 | git fetch, git push | 30行 |
| 7. Git/jj対照表 | 主要コマンドの対照 | 50行 |
| 8. co-locationモード | 設定・使用方法 | 30行 |
| 9. 使用例 | 典型的なワークフロー | 40行 |
| 10. 実行手順 | スキル使用の流れ | 10行 |
| **合計** | | **300行程度** |

## インターフェース設計

### スキル呼び出し

```bash
# Claude Codeでの呼び出し
/jj status
/jj describe -m "メッセージ"
/jj new
```

### 依存関係

- jj CLI がインストールされていること
- リポジトリがjjで初期化されていること（co-locationモード推奨）

## 制約

- **500行以下**: Claude Codeスキル仕様に準拠
- **高度な操作は対象外**: rebase、squash、evolog等は初回スコープ外
- **jj-support.mdとの関係**: 詳細ガイドは既存のjj-support.mdを参照

## 差別化ポイント

jj-support.md（559行）との違い：

| 項目 | jj-support.md | jj/SKILL.md |
|------|--------------|-------------|
| 目的 | 包括的なガイド | コマンドリファレンス |
| 対象 | jjを試したい開発者 | AIスキル経由での実行 |
| 行数 | 559行 | 300行程度 |
| 詳細度 | 背景説明・フロー図あり | コマンド中心 |
