# バージョンチェック比較ロジック

このガイドは `steps/inception/01-setup.md` のステップ6（三角モデル）から参照される。バージョン情報の取得（3点）と正規化は 01-setup.md 側で完了している前提。

## ComparisonMode決定

| モード | 条件 | 比較対象 |
|--------|------|---------|
| THREE_WAY | 3点全available | 3点比較 |
| REMOTE_LOCAL | skillのみunavailable | remote vs local（従来フォールバック） |
| SKILL_LOCAL | remoteのみunavailable | skill vs local |
| REMOTE_SKILL | localのみunavailable | remote vs skill |
| SINGLE_OR_NONE | 2点以上unavailable | 比較スキップ（警告のみ表示して続行） |

## 比較実行

### THREE_WAYモード

| パターン | 条件 | アクション |
|---------|------|-----------|
| 全一致 | remote = skill = local | 「最新バージョンです」表示 |
| リモートのみ新しい | remote > skill = local | スキル更新を促す（プラグイン再インストール） |
| スキルのみ古い | remote = local > skill | スキル更新を促す |
| ローカルのみ古い | remote = skill > local | `/aidlc setup`の実行を促す + starter_kit_version確認手順 |
| ローカルのみ進んでいる | local > remote = skill | 警告表示（設定が先行） |
| 複数不一致 | 上記以外 | 各差分を表示、スキル更新→ローカル設定更新の順にアクション提示 |

### REMOTE_LOCALモード（スキル取得失敗時のフォールバック）

| パターン | 条件 | アクション |
|---------|------|-----------|
| 一致 | remote = local | 「取得可能分は一致」+ スキル取得失敗警告 |
| remote > local | - | `/aidlc setup`の実行を促す + starter_kit_version確認手順 |
| local > remote | - | 警告表示（設定が先行） |

### SKILL_LOCALモード（リモート取得失敗時）

| パターン | 条件 | アクション |
|---------|------|-----------|
| 一致 | skill = local | 「取得可能分は一致」+ リモート取得失敗警告 |
| skill > local | - | `/aidlc setup`の実行を促す + リモート取得失敗警告 |
| local > skill | - | スキル更新案内 + リモート取得失敗警告 |

### REMOTE_SKILLモード（ローカル設定取得失敗時）

| パターン | 条件 | アクション |
|---------|------|-----------|
| 一致 | remote = skill | 「取得可能分は一致」+ ローカル設定取得失敗警告 |
| remote > skill | - | スキル更新案内 + ローカル設定取得失敗警告 |
| skill > remote | - | 「スキルが先行している可能性」警告 + ローカル設定取得失敗警告 |

### SINGLE_OR_NONEモード

比較スキップ、unavailableソースの警告のみ表示して続行。

## starter_kit_version確認手順

ローカルのみ古い場合に追加表示:

```text
アップグレード後、以下を確認してください:
1. `/aidlc setup` を実行してアップグレードモードを完了
2. `.aidlc/config.toml` の `starter_kit_version` がスキルバージョンと一致するか確認
```
