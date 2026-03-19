# 論理設計: rsync個別許可ルール削除

## 変更方針

### 1. allow配列からrsync行を削除
`ai-agent-allowlist.md` のClaude Code設定例（セクション4.1）のallow配列から以下を削除:
- `"Bash(rsync * docs/aidlc/prompts/)"`
- `"Bash(rsync * docs/aidlc/templates/)"`
- `"Bash(rsync * docs/aidlc/guides/)"`

### 2. rsync説明の更新
- L237のrsync設定ポイント説明を、スクリプト経由で実行されるため個別許可不要と更新
- セクション3.4のrsync説明にスクリプト内実行の旨を追記

### 3. オプション追加セクションの更新
- rsyncのオプション追加行（L326）の説明を、スクリプト経由実行が標準であることを反映

## 影響範囲
- `prompts/package/guides/ai-agent-allowlist.md` のみ
- スクリプト本体への変更なし
