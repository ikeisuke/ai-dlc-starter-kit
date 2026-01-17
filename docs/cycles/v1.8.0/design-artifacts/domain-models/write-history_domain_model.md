# ドメインモデル: 履歴記録スクリプト

## 概要

履歴ファイルへの追記を標準化されたフォーマットで行うスクリプトのドメインモデル。
フェーズ別の履歴ファイルに対して統一フォーマットでエントリを追記する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### HistoryEntry（履歴エントリ）

履歴ファイルに記録される1つのエントリを表す。

- **属性**:
  - timestamp: 文字列（"YYYY-MM-DD HH:MM:SS TZ"形式）
  - phase: 文字列（"Inception Phase", "Construction Phase", "Operations Phase"）
  - unit: 文字列（Unit番号と名称、例: "06-write-history（履歴記録スクリプト）"、Construction Phaseの場合のみ）
  - step: 文字列（ステップ名）
  - content: 文字列（実行内容の説明）
  - artifacts: 配列（成果物パスのリスト）
- **不変性**: 一度記録されたエントリは変更されない
- **等価性**: 全属性が一致する場合に等価

### UnitIdentifier（Unit識別子）

Unitを識別する番号、スラッグ、名称の組み合わせ。

- **属性**:
  - number: 整数（1〜99、2桁ゼロ埋めで出力）
  - slug: 文字列（Unitスラッグ、例: "write-history"）
  - name: 文字列（Unit名、例: "履歴記録スクリプト"）
- **表示形式**: `{NN}-{slug}（{name}）`
  - 例: `06-write-history（履歴記録スクリプト）`

### Phase（フェーズ）

有効なフェーズ識別子。

- **許容値**: inception, construction, operations
- **変換**: "inception" → "Inception Phase" （表示用への変換）

### CycleVersion（サイクルバージョン）

サイクルを識別するバージョン文字列。

- **形式**: vX.X.X（例: v1.8.0）
- **バリデーション**: 正規表現 `^v[0-9]+\.[0-9]+\.[0-9]+$` にマッチすること

## ドメインサービス

### HistoryFileResolver（履歴ファイル解決）

フェーズとUnitからファイルパスを解決する。

- **責務**: 出力先ファイルパスの決定
- **操作**:
  - resolve(cycle, phase, unit) → ファイルパス
    - inception → `docs/cycles/{cycle}/history/inception.md`
    - construction → `docs/cycles/{cycle}/history/construction_unit{NN}.md`（2桁ゼロ埋め）
    - operations → `docs/cycles/{cycle}/history/operations.md`

### HistoryFileInitializer（履歴ファイル初期化）

新規履歴ファイルのヘッダーを生成する。

- **責務**: ファイルが存在しない場合のヘッダー生成
- **操作**:
  - initHeader(phase, unit) → ヘッダー文字列
    - inception → `# Inception Phase 履歴`
    - construction → `# Construction Phase 履歴: Unit {NN}`
    - operations → `# Operations Phase 履歴`

### HistoryFormatter（履歴フォーマッタ）

エントリをMarkdown形式に変換する。

- **責務**: 統一フォーマットでの文字列生成
- **操作**:
  - format(entry) → Markdown文字列

### HistoryWriter（履歴ライター）

履歴ファイルへの追記を行う。

- **責務**: ファイル末尾への追記（新規ファイル時はヘッダー付き）
- **操作**:
  - append(filepath, content, header?) → 成功/失敗

## 出力フォーマット仕様

### ファイルヘッダー（新規作成時のみ）

```markdown
# {Phase} Phase 履歴: Unit {NN}
```

### エントリフォーマット

```markdown
## {timestamp}

- **フェーズ**: {phase}
- **Unit**: {unit}（Construction Phaseのみ）
- **ステップ**: {step}
- **実行内容**: {content}
- **成果物**:
  - `{artifact1}`
  - `{artifact2}`
  - ...

---
```

## ユビキタス言語

- **履歴エントリ**: 1回の作業記録。タイムスタンプ、フェーズ、ステップ等を含む
- **履歴ファイル**: フェーズ別の履歴を蓄積するMarkdownファイル
- **フェーズ**: AI-DLCの開発フェーズ（Inception/Construction/Operations）
- **サイクル**: 1つのリリース単位（vX.X.X形式のバージョン）
- **Unit番号**: 2桁ゼロ埋めの整数（01〜99）

## 不明点と質問

[Question] Unit番号の取得方法について
→ Unit番号（001等）を引数で指定するか、Unit名から解決するか？

[Answer] Unit番号を引数 `--unit` で、Unitスラッグを `--unit-slug` で、Unit名を `--unit-name` で指定する方式を採用。
ファイル名は2桁ゼロ埋め（例: `--unit 6` → `construction_unit06.md`）。
出力のUnit行には番号、スラッグ、名称を含める（例: `06-write-history（履歴記録スクリプト）`）。

[Question] 履歴ファイルのヘッダー生成について

[Answer] 履歴ファイルが存在しない場合、ヘッダーを自動生成する。
例: `# Construction Phase 履歴: Unit 06`

[Question] artifacts形式について

[Answer] 既存履歴に合わせて箇条書き形式を採用。
引数では複数パスを指定可能（カンマ区切りまたは複数回指定）。
