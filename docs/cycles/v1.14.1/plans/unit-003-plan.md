# Unit 003 計画: unit_branch.enabledデフォルト値変更

## 概要

`rules.unit_branch.enabled` の未設定時デフォルト値を `true` から `false` に変更する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/construction.md` | 判定ロジック反転（386-387行目） |
| `docs/aidlc.toml` | コメントのデフォルト値記載を更新（87行目） |

**注記**: Unit定義では `prompts/package/templates/aidlc_toml_template.toml` が対象とされていたが、当該ファイルは存在しない。セットアップテンプレート（`prompts/setup/templates/aidlc.toml.template`）には `[rules.unit_branch]` セクションがないため、`docs/aidlc.toml` のコメントを更新する。

## 実装計画

### 1. construction.md の判定ロジック変更

**変更前**:

```text
- `enabled = false`の場合: このセクションをスキップして次へ進む
- `enabled = true`、未設定、または不正値の場合: 以下の「前提条件チェック」から実行
```

**変更後**:

```text
- `enabled = true`の場合: 以下の「前提条件チェック」から実行
- `enabled = false`、未設定、または不正値の場合: このセクションをスキップして次へ進む
```

### 2. docs/aidlc.toml のコメント更新

**変更前**:

```text
# enabled: true | false - Unit開始時にUnitブランチ作成を提案するか（デフォルト: true）
```

**変更後**:

```text
# enabled: true | false - Unit開始時にUnitブランチ作成を提案するか（デフォルト: false）
```

## 完了条件チェックリスト

- [ ] construction.mdの判定ロジック反転（未設定時の動作をスキップに変更）
- [ ] docs/aidlc.tomlのデフォルト値コメント更新（「デフォルト: true」→「デフォルト: false」）
