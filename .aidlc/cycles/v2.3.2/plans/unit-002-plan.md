# Unit 002 実装計画: 設定保存機能

## 対象Unit

- Unit 002: 設定保存機能
- 関連Issue: #556

## 目的

対話UIの設定選択をconfig.tomlに永続保存する機能を追加する。`write-config.sh` の新規作成と、対象ステップファイルへの「設定に保存」選択肢追加ロジックの組み込みを行う。

## 変更対象ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `skills/aidlc/scripts/write-config.sh` | 新規作成 | TOML安全書き込みスクリプト |
| `skills/aidlc/steps/operations/operations-release.md` | 修正 | 7.13 merge_method選択時に「設定に保存」追加 |
| `skills/aidlc/steps/inception/01-setup.md` | 修正 | ステップ9 branch_mode選択時に「設定に保存」追加 |
| `skills/aidlc/steps/inception/05-completion.md` | 修正 | ステップ5 draft_pr選択時に「設定に保存」追加 |

## 変更方針

### 1. `write-config.sh` 新規作成

- `read-config.sh` と対となる書き込みスクリプト
- daselを使用してTOML安全書き込み（dasel未インストール時はエラー）
- 書き込み先: `config.toml`（プロジェクト共有）/ `config.local.toml`（個人設定）をユーザーが選択
- ファイル未存在時は新規作成、セクション未存在時は安全に追加
- キー・セクション・他キーの値は維持（daselはTOML構造を保持して書き込むが、コメント保持はdaselの実装依存。保証範囲はキー/値/セクション構造の保持に限定し、コメント保持は best effort とする）
- `config.local.toml` 新規作成時はパーミッション `600` を設定（既存ファイルの権限は変更しない）
- 終了コード: 0=成功、1=書き込み失敗、2=引数エラー/dasel未インストール

### 2. ステップファイル修正（3箇所）

対象質問で `ask` 設定時にユーザーが選択した後、明示的な2段階質問で設定保存を提案:

**1段目**: 「この選択を設定に保存しますか？（はい / いいえ）」
**2段目**（「はい」の場合のみ）: 「保存先を選択してください」
  - `config.local.toml`（個人設定）← **デフォルト**
  - `config.toml`（プロジェクト共有）

### 変更しないもの

- `read-config.sh` の4層読込ロジック
- AskUserQuestionツール自体の拡張
- 対象質問3件以外の質問への設定保存機能追加

## 完了条件チェックリスト

### 機能

- [ ] `write-config.sh` が指定キー・値をconfig.toml/config.local.tomlに安全に書き込める
- [ ] ファイル未存在時に新規作成される
- [ ] セクション未存在時に安全に追加される
- [ ] 既存キー・セクション構造が維持される（コメント保持は best effort）
- [ ] merge_method選択時（ask設定時）に「設定に保存」選択肢が表示される
- [ ] branch_mode選択時（ask設定時）に「設定に保存」選択肢が表示される
- [ ] draft_pr選択時（ask設定時）に「設定に保存」選択肢が表示される
- [ ] 保存先としてconfig.toml / config.local.toml を選択できる
- [ ] デフォルト保存先が `config.local.toml` である

### 品質

- [ ] `read-config.sh` の4層読込ロジックが不変である
- [ ] 保存後、次回実行時に `read-config.sh` が保存済みの値を正しく返す
- [ ] dasel未インストール時に適切なエラーメッセージが表示される
- [ ] 書き込み処理が1秒以内に完了する
- [ ] `config.local.toml` 新規作成時にパーミッション `600` が設定される
