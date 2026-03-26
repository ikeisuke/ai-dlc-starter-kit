# 論理設計: 履歴記録スクリプト

## 概要

履歴ファイルへの追記を標準化されたフォーマットで行うBashスクリプトのインターフェースと処理フローを定義する。

**重要**: この論理設計では**コードは書かず**、インターフェース定義のみを行います。

## アーキテクチャパターン

シンプルなCLIスクリプトパターン。引数解析 → バリデーション → 処理実行の3段階構成。

## コンポーネント構成

```text
write-history.sh
├── 引数解析（Argument Parser）
├── バリデーション（Validator）
├── ファイルパス解決（Path Resolver）
├── ファイル初期化（File Initializer）
├── フォーマッタ（Formatter）
└── ライター（Writer）
```

### コンポーネント詳細

#### 引数解析（Argument Parser）

- **責務**: コマンドライン引数の解析とオプション抽出
- **依存**: なし
- **公開インターフェース**: parse_args() → 変数設定

#### バリデーション（Validator）

- **責務**: 必須引数の存在確認、形式検証
- **依存**: 引数解析
- **公開インターフェース**: validate() → 成功/失敗

#### ファイルパス解決（Path Resolver）

- **責務**: フェーズとUnitから出力先ファイルパスを決定
- **依存**: バリデーション
- **公開インターフェース**: resolve_path() → ファイルパス

#### ファイル初期化（File Initializer）

- **責務**: 新規ファイル時のヘッダー生成
- **依存**: ファイルパス解決
- **公開インターフェース**: init_file_if_needed() → 成功/失敗

#### フォーマッタ（Formatter）

- **責務**: 履歴エントリのMarkdown文字列生成
- **依存**: ファイル初期化
- **公開インターフェース**: format_entry() → Markdown文字列

#### ライター（Writer）

- **責務**: ファイルへの追記
- **依存**: フォーマッタ
- **公開インターフェース**: append_to_file() → 成功/失敗

## インターフェース設計

### コマンド

#### write-history.sh

```text
Usage: write-history.sh [OPTIONS]

OPTIONS:
  --cycle <VERSION>       サイクルバージョン（必須、例: v1.8.0）
  --phase <PHASE>         フェーズ名（必須、inception/construction/operations）
  --unit <NUMBER>         Unit番号（constructionフェーズの場合必須、例: 6）
  --unit-name <NAME>      Unit名（constructionフェーズの場合必須、例: "履歴記録スクリプト"）
  --unit-slug <SLUG>      Unitスラッグ（constructionフェーズの場合必須、例: "write-history"）
  --step <STEP>           ステップ名（必須）
  --content <CONTENT>     実行内容（必須）
  --artifacts <PATHS>     成果物パス（オプション、複数回指定可能）
  -h, --help              ヘルプを表示
  --dry-run               ファイル追記せず、状態のみ表示
```

**戻り値（終了コード）**:

- 0: 成功
- 1: 引数エラー（必須引数不足、形式エラー等）
- 2: ファイル書き込みエラー

**出力形式（stdout）**:

```text
history:<ファイルパス>:<状態>
```

状態:

- created: 新規ファイル作成＋追記成功
- appended: 既存ファイルへの追記成功
- would-create: 新規作成予定（--dry-runモード）
- would-append: 追記予定（--dry-runモード）
- error: 処理失敗

**エラー出力形式（引数エラー時）**:

```text
error:<理由>
```

### 引数詳細

| 引数 | 必須 | 形式 | 説明 |
|------|------|------|------|
| --cycle | Yes | vX.X.X | サイクルバージョン |
| --phase | Yes | inception/construction/operations | フェーズ識別子 |
| --unit | No* | 整数（1〜99） | Unit番号（*constructionでは必須、2桁ゼロ埋めで出力） |
| --unit-name | No* | 文字列 | Unit名（*constructionでは必須） |
| --unit-slug | No* | 文字列 | Unitスラッグ（*constructionでは必須） |
| --step | Yes | 文字列 | ステップ名 |
| --content | Yes | 文字列 | 実行内容の説明 |
| --artifacts | No | パス | 成果物ファイルパス（複数回指定可能） |

## 処理フロー概要

### 履歴追記の処理フロー

**ステップ**:

1. 引数解析: コマンドライン引数を解析
2. バリデーション: 必須引数の存在確認、形式検証
3. ファイルパス解決: フェーズに応じた出力先決定
4. ファイル存在確認: 新規作成が必要か判定
5. ファイル初期化: 新規の場合ヘッダーを生成
6. 日時取得: `date '+%Y-%m-%d %H:%M:%S %Z'` で現在日時取得
7. フォーマット生成: Markdown形式のエントリ文字列生成
8. ファイル追記: 対象ファイルへ追記
9. 結果出力: 成功/失敗をstdoutへ出力

**関与するコンポーネント**: 全コンポーネント

### ファイルパス解決ロジック

| フェーズ | 出力先ファイル |
|----------|----------------|
| inception | docs/cycles/{cycle}/history/inception.md |
| construction | docs/cycles/{cycle}/history/construction_unit{NN}.md |
| operations | docs/cycles/{cycle}/history/operations.md |

**注意**: Unit番号は2桁でゼロ埋め（例: `--unit 6` → `construction_unit06.md`）

### ファイルヘッダー（新規作成時）

| フェーズ | ヘッダー |
|----------|----------|
| inception | `# Inception Phase 履歴` |
| construction | `# Construction Phase 履歴: Unit {NN}` |
| operations | `# Operations Phase 履歴` |

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 即時完了
- **対応策**: シンプルなファイル追記のみ、外部依存なし

### セキュリティ

- **要件**: N/A
- **対応策**: 入力値のエスケープは不要（Markdown出力のため）

### 可用性

- **要件**: オフライン環境でも動作
- **対応策**: 外部API呼び出しなし、標準コマンドのみ使用

## 技術選定

- **言語**: Bash（POSIX互換）
- **依存コマンド**: date, cat, printf

## 実装上の注意事項

- set -euo pipefail でエラーハンドリングを厳格化
- ヒアドキュメントでの出力フォーマット生成
- ファイル存在確認を行い、新規時はヘッダーを追加
- 既存スクリプト（init-cycle-dir.sh等）と同様のスタイルを維持
- 引数エラー時は `error:<理由>` 形式で出力（issue-ops.shと同様）

## 不明点と質問

（レビュー指摘を反映済み）
