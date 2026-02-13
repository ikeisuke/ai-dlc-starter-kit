# Unit 007: jjスキル改善 - 計画

## 概要

jjスキル（`prompts/package/skills/jj/SKILL.md`）をagentskills.ioベストプラクティスに準拠させる。
Git対照表をreferences/に分離してProgressive Disclosureを適用する。

## 現状分析

| 項目 | 現状 | 目標 | 対応要否 |
|------|------|------|---------|
| frontmatter name | `jj`（小文字英数字のみ） | 小文字英数字+ハイフンのみ | 対応不要（準拠済み） |
| frontmatter description | 三人称（主語なし） | "I"/"You"で始まらない | 対応不要（準拠済み） |
| Git対照表 | SKILL.md内（172-207行目） | references/に分離 | **要対応** |
| SKILL.md行数 | 266行 | 500行以下 | 対応不要（準拠済み） |

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/skills/jj/SKILL.md` | Git対照表セクションを参照リンクに置換 |
| `prompts/package/skills/jj/references/git-comparison.md`（新規） | Git対照表を移動 |

## 実装計画

### ステップ1: references/ディレクトリとGit対照表ファイル作成

1. `prompts/package/skills/jj/references/` ディレクトリを作成
2. SKILL.md内のGit対照表セクション（「## Git/jjコマンド対照表」以降、「## 使用例」の前まで）を `references/git-comparison.md` に移動
3. 移動先ファイルにはタイトルとして `# Git/jjコマンド対照表` を付与

### ステップ2: SKILL.md本体の更新

1. Git対照表セクションを参照リンクに置換:
   ```markdown
   ## Git/jjコマンド対照表

   詳細は [references/git-comparison.md](references/git-comparison.md) を参照。
   ```

### ステップ3: 検証

1. `ls prompts/package/skills/jj/references/` でファイル存在確認
2. `wc -l < prompts/package/skills/jj/SKILL.md` が500行以下を確認
3. frontmatter name/descriptionの再確認

## 完了条件チェックリスト

- [ ] SKILL.md frontmatterのnameが小文字英数字+ハイフンのみで構成されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている（"I"や"You"で始まらない）
- [ ] `ls prompts/package/skills/jj/references/` でGit対照表ファイルが存在する
- [ ] `wc -l < prompts/package/skills/jj/SKILL.md` が500以下である

## 設計に関する補足

本Unitはファイル構造変更（テキスト移動）のみのため、ドメインモデル・論理設計は省略可能と判断。
Unit定義の「技術的考慮事項」に準じ、nameは `jj` のまま維持する。
