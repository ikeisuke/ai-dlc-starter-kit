# ドメインモデル: 設定保存機能

## 概要

対話UIで選択した設定値をconfig.tomlに永続保存する機能のドメインモデル。

## エンティティ

### ConfigFile（設定ファイル）

- **属性**:
  - path: String - ファイルパス
  - scope: ConfigScope - ファイルスコープ
- **振る舞い**:
  - writeKey(key, value): 指定キーに値を書き込む
  - exists(): ファイルが存在するか

## 値オブジェクト

### ConfigScope

| 値 | ファイル | 説明 |
|----|---------|------|
| `project` | `.aidlc/config.toml` | プロジェクト共有設定 |
| `local` | `.aidlc/config.local.toml` | 個人設定（デフォルト保存先） |

### SaveableQuestion（保存可能な質問）

`ask` 設定時にユーザーが値を選択し、その選択を永続保存できる質問。

| 設定キー | ステップファイル | 質問タイミング |
|---------|----------------|--------------|
| `rules.git.merge_method` | `operations/operations-release.md` 7.13 | merge_method=ask時 |
| `rules.git.branch_mode` | `inception/01-setup.md` ステップ9 | branch_mode=ask時 |
| `rules.git.draft_pr` | `inception/05-completion.md` ステップ5 | draft_pr設定の確認時 |

## ドメインサービス

### SaveToConfigFlow（設定保存フロー）

ユーザーが質問に回答した後の2段階保存フロー:

1. **保存確認**: 「この選択を設定に保存しますか？」（はい/いいえ）
2. **保存先選択**（「はい」の場合のみ）: `config.local.toml`（デフォルト）/ `config.toml`
3. **書き込み実行**: `write-config.sh` を呼び出し
4. **結果通知**: 成功/失敗をユーザーに表示

## ユビキタス言語

- **設定保存**: 対話で選択した値をconfig.tomlに永続化すること
- **保存先スコープ**: project（共有）またはlocal（個人）
- **ask設定**: 設定値が `ask` の場合、実行時にユーザーに選択を求める動作

## 不明点と質問

なし
