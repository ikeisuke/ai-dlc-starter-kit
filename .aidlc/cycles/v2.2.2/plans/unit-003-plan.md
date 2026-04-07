# Unit 003 計画: AGENTS.md活用・ルール移行

## 概要

rules-core.mdから以下3セクションをプラグインルートAGENTS.mdに移行し、初期ロードサイズを削減する。

## 関連Issue

- #533
- #541

## 移行対象セクション

| セクション | rules-core.md行範囲 | 移行先 |
|-----------|-------------------|--------|
| 承認プロセス | L78-83 | AGENTS.md |
| 質問と実行の判断基準 | L30-76 | AGENTS.md |
| AskUserQuestion使用ルール | L85-110 | AGENTS.md |

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/AGENTS.md` | 3セクションを追加 |
| `skills/aidlc/steps/common/rules-core.md` | 移行済み3セクションを削除 |

## 変更しないファイル

| ファイル | 理由 |
|---------|------|
| `skills/aidlc/SKILL.md` | ステップ1でrules-core.md Readの指示はオーケストレーター側で管理。rules-core.mdは残存するため参照は維持 |

## 完了条件チェックリスト

- [ ] 3セクション（承認プロセス、質問と実行の判断基準、AskUserQuestion使用ルール）がAGENTS.mdに移行されていること
- [ ] rules-core.mdから移行済みセクションが削除されていること
- [ ] AGENTS.mdの移行先が自然な構成になっていること
- [ ] rules-core.mdの残りセクションの文脈が整合していること
- [ ] SKILL.mdのステップ1参照に影響がないことを確認
