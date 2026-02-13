# Unit 007: jjスキル改善 - 計画

## 概要

jjスキル（`prompts/package/skills/jj/SKILL.md`）をagentskills.ioベストプラクティスに準拠させる。

## 現状分析

agentskills.io仕様・ベストプラクティスと照合した結果:

| 項目 | 現状 | 仕様要件 | 対応要否 |
|------|------|---------|---------|
| frontmatter name | `jj`（小文字英数字のみ） | 小文字英数字+ハイフン、親dir名一致 | 対応不要（準拠済み） |
| frontmatter description | 三人称、whatのみ | what + when to useを含む、三人称 | **要対応**（when to use欠如） |
| Git対照表 | SKILL.md内（172-207行目） | 500行超で分離推奨 | 対応不要（266行で500行以内） |
| SKILL.md行数 | 266行 | 500行以下推奨 | 対応不要（準拠済み） |

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/skills/jj/SKILL.md` | descriptionに "when to use" を追加 |

## 実装計画

### ステップ1: description修正

frontmatter descriptionに "when to use" 情報を追加:

```yaml
# Before
description: Jujutsu (jj) でバージョン管理操作を実行。Git互換の次世代VCSで、自動追跡・安全なundo・bookmarkベースの管理を提供。

# After
description: Jujutsu (jj) でバージョン管理操作を実行。Git互換の次世代VCSで、自動追跡・安全なundo・bookmarkベースの管理を提供。jjが有効化されている環境でgit操作の代わりに使用。
```

### ステップ2: 検証

1. `wc -l < prompts/package/skills/jj/SKILL.md` が500行以下を確認
2. frontmatter name/descriptionの確認

## 完了条件チェックリスト

- [x] SKILL.md frontmatterのnameが小文字英数字+ハイフンのみで構成されている
- [x] SKILL.md frontmatterのdescriptionが三人称で、what + when to useを含む
- [x] `wc -l < prompts/package/skills/jj/SKILL.md` が500以下である

## 設計に関する補足

本Unitはfrontmatter修正のみのため、ドメインモデル・論理設計は省略。
Git対照表のreferences/分離は、266行で500行制限に余裕があるため不要と判断。
Unit定義の「技術的考慮事項」に準じ、nameは `jj` のまま維持する。

## 方針変更の経緯

当初計画ではGit対照表のreferences/分離を含んでいたが、
agentskills.io仕様を精査した結果、500行以下のファイルでは分離の実益がなく
むしろアクセス性が低下するため、description修正のみに絞った。
