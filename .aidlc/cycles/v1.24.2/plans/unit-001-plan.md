# Unit 001: rsync個別許可ルール削除 - 計画

## 概要
`ai-agent-allowlist.md` からrsync個別許可パターン3行を削除し、スクリプト経由実行で許可が代替される旨の説明を追加する。

## 変更対象ファイル
- `prompts/package/guides/ai-agent-allowlist.md` （正本、`docs/aidlc/` は rsync コピーのため直接編集禁止）

## 実装計画
1. `ai-agent-allowlist.md` のallow配列から以下の3行を削除:
   - `"Bash(rsync * docs/aidlc/prompts/)"`
   - `"Bash(rsync * docs/aidlc/templates/)"`
   - `"Bash(rsync * docs/aidlc/guides/)"`
2. rsyncがスクリプト経由でのみ実行される旨の注釈を追加（allowリスト近辺のガイド説明部分）

## 完了条件チェックリスト
- [ ] `ai-agent-allowlist.md` から rsync個別許可3行が削除されている
- [ ] スクリプト経由実行で許可が代替される旨の説明が記載されている
- [ ] 既存のスクリプト許可ルール（aidlc-setup.sh等）で同期機能がカバーされることが確認できる
