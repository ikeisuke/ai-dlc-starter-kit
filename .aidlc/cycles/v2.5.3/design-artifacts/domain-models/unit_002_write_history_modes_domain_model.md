# ドメインモデル: Unit 002 write-history skill にモード追加

## 概要

`write-history.sh` の履歴エントリ種別を `mode` 値オブジェクトで分類し、既存 base 処理に対する追加処理（short note / operations round エントリ）を分岐する。

## エンティティ

### HistoryEntry（履歴エントリ）

- **ID**: `(cycle, phase, unit?, step, timestamp)` の組
- **属性**:
  - `mode`: `WriteHistoryMode` 値オブジェクト（`base` | `unit-complete-short-note` | `operations-round`）
  - `cycle` / `phase` / `unit` / `unit_name` / `unit_slug` / `step` / `content` / `artifacts` / `operations_stage`: 既存属性
  - mode 固有属性:
    - `unit-complete-short-note`: `short_note`（3-5 行の自由記述）
    - `operations-round`: `round_number` / `findings_count` / `severity_breakdown` / `disposition_summary`
- **振る舞い**:
  - `validate(mode)`: mode 別必須引数の検証
  - `format()`: mode 別のテンプレ展開（base + 追加セクション）
  - `append_to_history_file()`: 既存 history ファイルへの追記

## 値オブジェクト

### WriteHistoryMode

- **属性**: `value`: `base` | `unit-complete-short-note` | `operations-round`
- **不変性**: 列挙値以外不可
- **等価性**: 文字列一致

### SeverityBreakdown

- **属性**: `critical` / `high` / `medium` / `low`（各非負整数）
- **不変性**: 各値 ≥ 0
- **等価性**: 4 値の組

### DispositionSummary

- **属性**: `resolved_count` / `deferred_count`（各非負整数）

## ドメインサービス

### WriteHistoryDispatcher

- **責務**: mode に応じて base 処理または mode 固有処理を分岐
- **操作**:
  - `dispatch(entry)` - mode を見て追記処理を選択

### PostMergeGuard（既存 / 不変）

- **責務**: Operations Phase post-merge での書き込みを exit 3 でブロック
- **新モードへの適用**: `unit-complete-short-note` / `operations-round` でも引き続き有効（Unit 002 で挙動破壊なし）

## ユビキタス言語

- **mode（ライトヒストリーモード）**: 履歴エントリの種別を示す列挙値（base / unit-complete-short-note / operations-round）
- **base 処理**: `--mode` 未指定時の既存追記処理（後方互換維持の中核）
- **short note**: Unit 完了時に追加する 3-5 行の振り返り短文
- **operations round エントリ**: PR マージ前レビュー round の指摘集計（指摘総数 / 重要度内訳 / 対応判定）
- **post-merge ガード**: 既存（#616）の Operations Phase post-merge 書き込み禁止機能（exit 3）

## 不明点と質問

[Question] mode 指定時に既存 base 処理は実行されるか、それとも mode 固有処理のみか

[Answer] mode 固有処理は base 処理に**追加**する形で動作する。例えば `unit-complete-short-note` モードでは、まず既存 base のエントリ（タイムスタンプ + step + content + artifacts）を追記し、その後ろに「## 補足（short note）」セクション + 自由記述行を追加する。これにより既存 history 構造を維持しつつ、新モード固有の情報を併記できる。`operations-round` モードでは別ファイル（`history/operations.md`）への round エントリ追記が責務（base 処理は通常の history/operations.md 追記、その上に round R 集計テーブルを追加）。
