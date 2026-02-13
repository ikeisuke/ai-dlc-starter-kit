# Unit: jjスキル改善

## 概要
jjスキルをagentskills.ioベストプラクティスに準拠させる。frontmatterのname/descriptionを整備し、Git対照表をreferences/に分離してProgressive Disclosureを適用する。

## 含まれるユーザーストーリー
- ストーリー 7: jjスキルのベストプラクティス準拠

## 責務
- SKILL.md frontmatterのnameが小文字英数字+ハイフンのみであることを確認・修正
- SKILL.md frontmatterのdescriptionを三人称に変更（"I" や "You" で始まらない）
- Git対照表（約40行）を `references/` ディレクトリ内の別ファイルに分離
- SKILL.md bodyが500行以下であることを確認

## 境界
- jjスキルの機能追加は含まない
- コマンドリファレンスの内容変更は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- agentskills.io仕様（https://agentskills.io/specification）
- agentskills.ioベストプラクティス（https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices）

## 非機能要件（NFR）
- **SKILL.md行数**: 500行以下（agentskills.io推奨）
- **Progressive Disclosure**: Git対照表はreferences/に配置

## 技術的考慮事項
- nameは `jj` のまま維持（ツール名としての例外、gerund formにしない）
- Git対照表はreferencesに分離するが、SKILL.md本体からの参照パスを記載

## 受け入れ基準
- [ ] SKILL.md frontmatterのnameが小文字英数字+ハイフンのみで構成されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている（"I" や "You" で始まらない）
- [ ] `ls prompts/package/skills/jj/references/` でGit対照表ファイルが存在する
- [ ] `wc -l < prompts/package/skills/jj/SKILL.md` が500以下である

## 実装優先度
Medium

## 見積もり
0.5日（frontmatter修正 + Git対照表のreferences分離）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-14
- **完了日**: 2026-02-14
- **担当**: @ikeisuke
