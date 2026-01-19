# ドメインモデル: label-cycle-issues.sh

## 概要

Unit定義ファイルから関連Issue番号を抽出し、各Issueにサイクルラベルを一括付与するスクリプトの責務と構造を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はPhase 2（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### CycleName

- **属性**: value: String - サイクル名（例: `v1.8.1`）
- **不変性**: スクリプト実行中に変更されない
- **等価性**: 文字列の完全一致

### IssueNumber

- **属性**: value: Integer - Issue番号（正の整数）
- **不変性**: 抽出後に変更されない
- **等価性**: 数値の一致

### LabelName

- **属性**: value: String - ラベル名（例: `cycle:v1.8.1`）
- **不変性**: サイクル名から導出され不変
- **等価性**: 文字列の完全一致
- **生成ルール**: `cycle:{CycleName.value}`

## ドメインサービス

### IssueNumberExtractor

- **責務**: Unit定義ファイル群からIssue番号を抽出する
- **操作**:
  - extract(cycle_dir) - 指定サイクルのUnit定義ファイルからIssue番号リストを抽出
- **抽出ルール**:
  - 対象パス: `docs/cycles/{CYCLE}/story-artifacts/units/*.md`
  - **セクションスコープ**: `## 関連Issue` 見出しから次の `##` 見出しまでの範囲のみを対象
  - 抽出パターン: `^- #[0-9]+`（上記セクション内の箇条書き）
  - 重複除去: 同一Issue番号は1回のみ処理
- **抽出方法**: awk等で状態機械的にセクションを検出し、対象範囲内のみを処理

### CycleLabelApplier

- **責務**: 抽出したIssue群にサイクルラベルを付与する
- **操作**:
  - apply(issue_numbers, label_name) - 各Issueにラベルを付与
- **依存**: issue-ops.sh（既存スクリプト）を内部で呼び出す

## 処理フロー

```text
[入力: CYCLE名]
    ↓
[Unit定義ファイル群を検索]
    ↓
[Issue番号を抽出・重複除去]
    ↓
[Issue番号が0件の場合] → [正常終了（出力なし）]
    ↓
[各Issueに対してラベル付与]
    ↓
[結果を標準出力に出力]
```

## 入出力仕様

### 入力

| 引数 | 必須 | 説明 |
|------|------|------|
| CYCLE | Yes | サイクル名（例: v1.8.1） |

### 出力（stdout）

**出力契約**: issue-ops.shの出力仕様に完全に準拠する（透過）

| ケース | 出力形式 | 出力元 |
|--------|---------|--------|
| ラベル付与成功 | `issue:{番号}:labeled:cycle:{サイクル}` | issue-ops.sh |
| Issue not found | `issue:{番号}:error:not-found` | issue-ops.sh |
| 権限不足/API失敗 | `issue:{番号}:error:unknown` | issue-ops.sh |
| gh未インストール | `error:gh-not-available` | label-cycle-issues.sh |
| gh未認証 | `error:gh-not-authenticated` | label-cycle-issues.sh |
| Issue番号なし | （出力なし、正常終了） | - |
| 引数不足 | `error:missing-cycle` | label-cycle-issues.sh |

**注**: ラベル付与の成功/失敗判定とエラー分類はissue-ops.shに完全委譲。ラベル未作成時の動作もissue-ops.sh（内部でgh CLI）の仕様に従う。

### 終了コード

| コード | 意味 |
|--------|------|
| 0 | 正常終了（Issue番号なしも含む） |
| 1 | エラー（gh利用不可、引数不足等） |

## エラーハンドリング方針

- **Issue番号が見つからない場合**: 正常終了（エラーにしない）
- **サイクルディレクトリ不在**: 正常終了（エラーにしない、Issue番号なしと同等扱い）
- **Unitファイルが0件**: 正常終了（エラーにしない、Issue番号なしと同等扱い）
- **一部Issueでエラー**: エラー出力を表示し、残りのIssueは処理継続
  - **実装注意**: `set -e` との矛盾を避けるため、issue-ops.sh呼び出し時は `|| true` で終了コードを捕捉
- **gh未インストール/未認証**: 即座にエラー終了（終了コード1）
  - 未インストール時: `error:gh-not-available` を出力
  - 未認証時: `error:gh-not-authenticated` を出力

## ユビキタス言語

- **サイクル**: 開発の1イテレーション単位（例: v1.8.1）
- **サイクルラベル**: `cycle:{サイクル名}` 形式のGitHub Issueラベル
- **Unit定義ファイル**: `docs/cycles/{CYCLE}/story-artifacts/units/` 配下のMarkdownファイル
- **関連Issue**: Unit定義ファイル内の `## 関連Issue` セクションに記載されたIssue番号

## 不明点と質問（設計中に記録）

（なし - Unit定義から要件は明確）
