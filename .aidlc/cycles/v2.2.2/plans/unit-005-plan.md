# Unit 005 計画: PRマージ方法設定化

## 対象Unit

Unit 005: PRマージ方法設定化（#538）

## 目的

config.tomlでPRマージ方法を事前設定可能にし、Operations Phase毎回のマージ方法確認を省略できるようにする。

## 変更対象ファイル

パスはスキルベースディレクトリ（`skills/aidlc/`）からの相対パス。

| ファイル | 変更内容 |
|---------|---------|
| `config/defaults.toml` | `rules.git.merge_method = "ask"` を追加 |
| `steps/operations/operations-release.md` | 7.13 PRマージの分岐ロジック追加 |
| `steps/common/preflight.md` | 設定値取得にmerge_methodを追加 |

**スコープ外**: config.toml.example、config.toml.template、docs/configuration.mdへの追加は本Unitでは行わない（defaults.tomlへの追加のみ。公開面の整備は別途対応）。

## 前提・依存

- `read-config.sh --keys` のバッチ取得出力契約（key:value形式）に依存。スクリプト変更は不要
- `pr-ops.sh merge` のサブコマンド仕様（`--squash`/`--rebase`フラグ）に依存。スクリプト変更は不要

## 設計方針

### defaults.toml

`[rules.git]` セクションに `merge_method = "ask"` を追加。

### preflight.md

- バッチ取得の `--keys` に `rules.git.merge_method` を追加
- コンテキスト変数 `merge_method` として格納
- 有効値: `"merge"` | `"squash"` | `"rebase"` | `"ask"`
- 無効値は `"ask"` にフォールバック（警告表示）

### operations-release.md

7.13 PRマージセクションの既存の「マージ方法はユーザーに確認して実行。」を以下の分岐に置換:

1. **gh_status != available の場合**: merge_methodに関わらず手動マージ案内を優先（既存動作維持）
2. **merge_method == "ask"**: 従来通りAskUserQuestionでユーザーに確認
3. **merge_method == "merge"/"squash"/"rebase"**: 指定方法で自動実行
4. **マージ失敗時**: エラー表示→ユーザーに方法選択を求める

## 完了条件チェックリスト

- [ ] defaults.tomlの`[rules.git]`に `merge_method = "ask"` が追加されている
- [ ] preflight.mdのバッチ取得に `rules.git.merge_method` が含まれている
- [ ] preflight.mdの結果提示に `merge_method: {value}` が含まれている
- [ ] preflight.mdに無効値フォールバック（`⚠ merge_method の値が不正です...`警告+ask）が定義されている
- [ ] operations-release.md 7.13で `gh_status != available` 時に手動マージ案内が優先されている
- [ ] `merge_method=merge` で確認質問なしにマージコマンドが案内される
- [ ] `merge_method=ask` で従来通りAskUserQuestionでユーザー確認される
- [ ] マージ失敗時にユーザーに方法再選択が求められる
