# ドメインモデル: 部分対応Issue自動判別

## 概要

PR Closes記載時にUnit定義の「関連Issue」セクションから完全対応/部分対応を判別する。

## 値オブジェクト

### IssueReference（Issue参照）

Unit定義ファイルの「関連Issue」セクション内の1行。

- **属性**:
  - number: Integer - Issue番号
  - coverage: IssueCoverage - 対応種別

### IssueCoverage

| 値 | 記法パターン | PR記載 |
|----|------------|--------|
| `full` | `#NNN`（注記なし） | `Closes #NNN` |
| `partial` | `#NNN（部分対応）` | `Relates to #NNN` |

**デフォルト**: 注記なし = `full`（後方互換）

## ドメインサービス

### IssueClassifier

Unit定義ファイルの「関連Issue」セクションから全IssueReferenceを抽出し、full/partialに分類。

- **入力**: Unit定義ファイル群（`story-artifacts/units/*.md`）
- **出力**: `{ closes: [#NNN, ...], relates: [#NNN, ...] }`
- **分類ルール**: 正規表現 `#(\d+)（部分対応）` → partial、`#(\d+)` のみ → full

## 不明点と質問

なし
