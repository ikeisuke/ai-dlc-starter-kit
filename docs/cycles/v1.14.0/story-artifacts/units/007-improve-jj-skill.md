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

## 実装優先度
Medium

## 見積もり
小規模（frontmatter修正 + ファイル分離）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
