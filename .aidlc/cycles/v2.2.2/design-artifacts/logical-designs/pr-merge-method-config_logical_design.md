# 論理設計: PRマージ方法設定化

## 概要

MergeMethodの設定・読み込み・実行分岐の具体的な変更箇所を定義する。

**重要**: このドキュメントでは**コードは書かず**、インターフェースの定義のみを行います。

## 変更1: config/defaults.toml

`[rules.git]` セクションに追加:

```toml
merge_method = "ask"
```

## 変更2: steps/common/preflight.md

### 手順4: 設定値バッチ取得

`--keys` に `rules.git.merge_method` を追加。

### コンテキスト変数格納テーブル

| 設定キー | コンテキスト変数名 | デフォルト値 |
|---------|-------------------|------------|
| rules.git.merge_method | `merge_method` | ask |

### バリデーション（手順4の取得後に実施）

```text
merge_method の値を確認:
- "merge" / "squash" / "rebase" / "ask" → そのまま使用
- それ以外 → 警告を表示しデフォルト値 "ask" にフォールバック:
  ⚠ merge_method の値が不正です（"{value}"）。デフォルト値 "ask" を使用します。
```

### 手順6: 結果提示

「主要設定値」セクションに `merge_method: {value}` を追加。

## 変更3: steps/operations/operations-release.md

### 7.13 PRマージ（既存の「マージ方法はユーザーに確認して実行。」を置換）

前提: `gh_status != available` の場合は merge_method に関わらず既存の手動マージ案内を優先（既存動作維持）。

依存: `pr-ops.sh merge` のサブコマンド仕様（`--squash`/`--rebase`フラグ）。スクリプト変更は不要。

```text
merge_method分岐（gh_status == available の場合のみ）:

1. merge_method == "ask":
   AskUserQuestionでマージ方法を選択させる:
   - 通常マージ (merge)
   - Squashマージ (squash)
   - Rebaseマージ (rebase)

2. merge_method == "merge" / "squash" / "rebase":
   指定方法で自動実行。実行前に方法を表示:
   「merge_method設定に基づき {method} マージを実行します。」

3. マージ失敗時（いずれの場合も）:
   エラー内容を表示し、AskUserQuestionでマージ方法を再選択:
   「マージに失敗しました。別のマージ方法を選択してください。」
   - 通常マージ (merge)
   - Squashマージ (squash)
   - Rebaseマージ (rebase)
   - 中断する
```
