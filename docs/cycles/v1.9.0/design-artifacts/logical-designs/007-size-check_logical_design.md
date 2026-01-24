# 論理設計: Operations Phaseサイズチェック

## 概要

プロンプトファイルのサイズを測定し、閾値超過時に警告を出力するシェルスクリプトの設計。

**重要**: この論理設計では**コードは書かず**、インターフェースと処理フローの定義のみを行います。

## アーキテクチャパターン

シングルスクリプトパターン - 単一のシェルスクリプトで完結する設計。
他の既存スクリプト（check-references.sh等）と同様の構造を採用。

## コンポーネント構成

### ファイル構成

```text
prompts/package/bin/
└── check-size.sh          # サイズチェックスクリプト
```

### スクリプト内部構成

- **引数解析部**: コマンドライン引数の処理
- **設定読み込み部**: aidlc.tomlから設定を取得
- **サイズ測定部**: ファイルサイズの測定
- **比較・出力部**: 閾値比較と警告出力

## インターフェース設計

### コマンドラインインターフェース

#### `check-size.sh`

```text
Usage: check-size.sh [target_dir] [options]
```

- **パラメータ**:
  - `target_dir` (optional): チェック対象ディレクトリ（デフォルト: prompts/package/prompts/）
  - **注**: このツールはAI-DLCスターターキット開発専用。配置場所は `bin/check-size.sh`
- **オプション**:
  - `-v, --verbose`: 詳細出力モード（全ファイルの結果を表示）
  - `-h, --help`: ヘルプ表示
  - `--bytes-threshold N`: バイト数閾値の一時上書き
  - `--lines-threshold N`: 行数閾値の一時上書き
- **終了コード**:
  - 0: 閾値超過なし、または enabled=false
  - 1: 閾値超過あり
  - 2: スクリプトエラー

### 設定の優先順位

CLIオプションは設定ファイルより優先される:

1. **最優先**: CLIオプション（--bytes-threshold, --lines-threshold）
2. **次点**: aidlc.tomlの`[rules.size_check]`設定
3. **フォールバック**: デフォルト値

**enabled=falseの動作**:

- CLIオプションが指定された場合: enabled=falseを無視してチェックを実行
- CLIオプションなしの場合: exit 0 で終了（サマリーも含め出力なし）

### 出力形式

#### 通常モード

**警告がある場合**: 各警告ブロック + サマリー

```text
WARNING: File size exceeds threshold
  File: prompts/package/prompts/construction.md
  Size: 180000 bytes (threshold: 150000) [EXCEEDED]
  Lines: 1200 (threshold: 1000) [EXCEEDED]

Size check completed: 1 warning, 15 files checked
```

**部分的閾値超過の場合**: 超過した項目のみ[EXCEEDED]を表示

```text
WARNING: File size exceeds threshold
  File: prompts/package/prompts/construction.md
  Size: 180000 bytes (threshold: 150000) [EXCEEDED]
  Lines: 800 (threshold: 1000)

Size check completed: 1 warning, 15 files checked
```

**警告がない場合**: サマリーのみ

```text
Size check completed: 0 warnings, 15 files checked
```

#### 詳細モード（-v オプション時）

全ファイルの結果 + サマリー:

```text
  [OK] prompts/package/prompts/inception.md (45000 bytes, 350 lines)
  [WARN] prompts/package/prompts/construction.md (180000 bytes, 1200 lines)

Size check completed: 1 warning, 15 files checked
```

## データモデル概要

### 設定ファイル（aidlc.toml）

追加セクション `[rules.size_check]`:

- **フィールド**:
  - `enabled`: Boolean - 機能の有効/無効（デフォルト: true）
  - `max_bytes`: Integer - バイト数閾値（デフォルト: 150000）
  - `max_lines`: Integer - 行数閾値（デフォルト: 1000）
  - `target_pattern`: String - 対象ファイルパターン（デフォルト: "*.md"）

**注**: ドメインモデルでは`SizeCheckConfig.threshold: Threshold`として概念的にグループ化していますが、
TOML設定ではフラットな構造（`max_bytes`, `max_lines`を直接配置）を採用します。
これはaidlc.tomlの既存設定スタイルとの一貫性を保つためです。

## 処理フロー概要

### サイズチェックの処理フロー

**ステップ**:

1. 引数解析（target_dir、オプション）
2. リポジトリルート取得
3. aidlc.tomlから設定を読み込み（存在しない場合はデフォルト使用）
4. enabled=falseかつCLIオプションなしの場合、exit 0
5. 対象ディレクトリ内のパターン一致ファイルを再帰的に列挙（通常ファイルのみ、シンボリックリンク除外）
6. 各ファイルのバイト数と行数を測定
7. 閾値と比較、超過があれば警告を記録
8. 結果を出力（通常モード or 詳細モード）
9. サマリーを出力（enabled=true の場合のみ）
10. 終了コードを設定（警告あり: 1、なし: 0）

**関与するコンポーネント**: check-size.sh（単一スクリプト）

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: スクリプト実行が1秒以内に完了すること
- **対応策**:
  - findとwcコマンドの効率的な使用
  - ファイル数が多い場合でも逐次処理で十分高速
  - 設定読み込みは1回のみ

### セキュリティ

- **要件**: 該当なし
- **対応策**: なし

### スケーラビリティ

- **要件**: 該当なし
- **対応策**: なし

### 可用性

- **要件**: 該当なし
- **対応策**: なし

## 技術選定

- **言語**: Bash
- **依存コマンド**: find, wc, grep, awk（標準的なUnixコマンド）
- **設定読み込み**: dasel（利用可能な場合）またはgrepベースのフォールバック

## 実装上の注意事項

- 既存スクリプト（check-references.sh）と同様のスタイルを踏襲
- set -euo pipefail でエラーハンドリングを厳格に
- 設定ファイルが存在しない場合はデフォルト値を使用
- verboseモードと通常モードの出力を明確に分離
- サブディレクトリも再帰的にチェック（find -type f）
- シンボリックリンクは除外（-type f でファイルのみ）
- 対象パターン"*.md"により、bin/配下の.shファイルは自動的に除外

## Operations Phaseへの組み込み

operations.mdの「完了前チェックリスト」セクションに以下を追加:

- サイズチェック実行手順
- 警告が出た場合の対応ガイダンス

## 不明点と質問

なし（AIレビューの指摘を反映済み）
