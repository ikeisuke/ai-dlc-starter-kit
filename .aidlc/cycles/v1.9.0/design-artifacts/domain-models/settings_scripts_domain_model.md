# ドメインモデル: 設定確認スクリプト整備

## 概要

プロンプト内の重複bashコードをスクリプト化し、設定確認処理を共通化する。スクリプトは既存の`env-info.sh`と同様の`KEY:VALUE`出力形式に従う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## スクリプト定義

### check-gh-status.sh

GitHub CLIの利用可否を確認し、ステータスを出力する。

- **責務**: GitHub CLIのインストール状態と認証状態を確認
- **入力**: なし（引数なし）
- **出力形式**: `gh:{状態}`
  - `gh:available` - インストール済み、認証済み
  - `gh:not-installed` - 未インストール
  - `gh:not-authenticated` - インストール済みだが未認証
- **依存**: `gh` コマンド
- **副作用**: なし（読み取りのみ）

### check-backlog-mode.sh

バックログモード設定を確認し、モード値を出力する。

- **責務**: `docs/aidlc.toml`からバックログモード設定を取得
- **入力**: なし（引数なし）
- **出力形式**: `backlog_mode:{モード値}`
  - `backlog_mode:git` - ローカルファイル駆動（デフォルト）
  - `backlog_mode:issue` - GitHub Issue駆動
  - `backlog_mode:git-only` - ローカルファイルのみ
  - `backlog_mode:issue-only` - GitHub Issueのみ
  - `backlog_mode:` - dasel未インストールで読み取り不可（AIが直接読み取り）
- **依存**: `dasel` コマンド（オプション）
- **副作用**: なし（読み取りのみ）
- **エッジケース**:
  - dasel未インストール: `backlog_mode:` を出力（AIに読み取りを委ねる）
  - TOMLファイル不在: `backlog_mode:git` を出力（デフォルト）
  - キー欠落/値不正: `backlog_mode:git` を出力（デフォルト）

## 既存スクリプトとの整合性

### 出力形式

`env-info.sh`と同様の`KEY:VALUE`形式を採用する。

```text
# env-info.sh の出力例
gh:available
dasel:not-installed
jj:available
git:available

# 新スクリプトの出力例
gh:available
backlog_mode:issue-only
```

### スクリプト配置

- 配置先: `prompts/package/bin/`
- 呼び出しパス: `docs/aidlc/bin/`（rsyncでコピーされる）
- 実行権限: 755
- シェバン: `#!/usr/bin/env bash`

### エラーハンドリング

- `set -euo pipefail` を使用
- 依存ツール未インストール時は正常終了（状態を出力）
- 終了コード: 常に0（エラーも状態として出力、`env-info.sh`と同様）
- ヘルプオプション: 対応しない（単一責務のシンプルなスクリプトのため）

### NFR補足

- `gh auth status` はローカル認証情報を参照（ネットワークアクセスなし）

## ユビキタス言語

- **バックログモード**: バックログ項目の保存先を決定する設定値（git/issue/git-only/issue-only）
- **GitHub CLI**: GitHubの操作をCLIから行うためのツール（`gh`コマンド）
- **dasel**: TOML/JSON/YAML等を操作するCLIツール

## 不明点と質問（設計中に記録）

特になし（既存パターンからの抽出のため、仕様は明確）
