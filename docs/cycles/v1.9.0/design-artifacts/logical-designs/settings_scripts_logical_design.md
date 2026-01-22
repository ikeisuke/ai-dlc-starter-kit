# 論理設計: 設定確認スクリプト整備

## 概要

プロンプト内の重複bashコードをスクリプト化し、プロンプトからは1行のスクリプト呼び出しで設定確認を行えるようにする。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードはImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

既存の`prompts/package/bin/`配下のユーティリティスクリプト群と同様のパターンを採用。

- 単一責務のスクリプト
- 標準出力への`KEY:VALUE`形式出力
- 引数なしで動作（シンプルなインターフェース）
- ヘルプオプション非対応（単一責務のシンプルなスクリプトのため）

## コンポーネント構成

### ファイル配置

```text
prompts/package/bin/
├── check-gh-status.sh     # 新規作成
├── check-backlog-mode.sh  # 新規作成
├── env-info.sh            # 既存（参考）
└── ...
```

**注**: 配置先は `prompts/package/bin/` だが、rsyncにより `docs/aidlc/bin/` にコピーされるため、プロンプトからの呼び出しは `docs/aidlc/bin/` パスを使用する。

### コンポーネント詳細

#### check-gh-status.sh

- **責務**: GitHub CLIの利用可否を確認し、ステータスを出力
- **依存**: `gh` コマンド
- **公開インターフェース**: 標準出力に `gh:{状態}` を出力

#### check-backlog-mode.sh

- **責務**: バックログモード設定を確認し、モード値を出力
- **依存**: `dasel` コマンド（オプション）、`docs/aidlc.toml`
- **公開インターフェース**: 標準出力に `backlog_mode:{モード値}` を出力

## インターフェース設計

### コマンド

#### check-gh-status.sh

- **パラメータ**: なし
- **戻り値**: 標準出力に1行
  - `gh:available` - 利用可能
  - `gh:not-installed` - 未インストール
  - `gh:not-authenticated` - 未認証
- **副作用**: なし
- **終了コード**: 常に0（エラーも状態として出力）

#### check-backlog-mode.sh

- **パラメータ**: なし
- **戻り値**: 標準出力に1行
  - `backlog_mode:git` - ローカルファイル駆動
  - `backlog_mode:issue` - GitHub Issue駆動
  - `backlog_mode:git-only` - ローカルファイルのみ
  - `backlog_mode:issue-only` - GitHub Issueのみ
  - `backlog_mode:` - dasel未インストール（AIが直接読み取り）
- **副作用**: なし
- **終了コード**: 常に0

## 処理フロー概要

### check-gh-status.sh の処理フロー

**ステップ**:
1. `command -v gh` でインストール確認
2. 未インストールなら `gh:not-installed` を出力して終了
3. `gh auth status` で認証確認
4. 認証済みなら `gh:available`、未認証なら `gh:not-authenticated` を出力

### check-backlog-mode.sh の処理フロー

**ステップ**:
1. `command -v dasel` でインストール確認
2. 未インストールなら `backlog_mode:` を出力して終了（AIに委ねる）
3. `docs/aidlc.toml` から `backlog.mode` を読み取り
4. 読み取り成功なら値を出力、失敗なら `backlog_mode:git`（デフォルト）を出力

**エッジケース対応**:
- dasel未インストール: `backlog_mode:` を出力（AIに読み取りを委ねる既存設計を維持）
- TOMLファイル不在: `backlog_mode:git` を出力（デフォルト値）
- キー欠落/値不正: `backlog_mode:git` を出力（デフォルト値）
- エラーハンドリング: `dasel` 呼び出しは `|| echo "git"` でフォールバック（`set -e` での異常終了を回避）

## プロンプト変更箇所

### inception.md（2箇所 + 4箇所）

| 箇所 | 現状 | 変更後 |
|------|------|--------|
| 6. バックログ確認 | 5行のbashコード | `docs/aidlc/bin/check-backlog-mode.sh` |
| 完了時必須作業 | 12行のbashコード | `docs/aidlc/bin/check-backlog-mode.sh` + `docs/aidlc/bin/check-gh-status.sh` |
| 4. Dependabot PR確認 | 5行のbashコード | `docs/aidlc/bin/check-gh-status.sh` |
| 5. GitHub Issue確認 | 5行のbashコード | `docs/aidlc/bin/check-gh-status.sh` |
| 4. ドラフトPR作成 | 5行のbashコード | `docs/aidlc/bin/check-gh-status.sh` |

### construction.md（1箇所 + 1箇所）

| 箇所 | 現状 | 変更後 |
|------|------|--------|
| 気づき記録フロー | 5行のbashコード | `docs/aidlc/bin/check-backlog-mode.sh` |
| 6. Unitブランチ作成 | 5行のbashコード | `docs/aidlc/bin/check-gh-status.sh` |

### operations.md（2箇所 + 1箇所）

| 箇所 | 現状 | 変更後 |
|------|------|--------|
| 5.1 バックログ整理 | 5行のbashコード | `docs/aidlc/bin/check-backlog-mode.sh` |
| 3. バックログ記録 | 5行のbashコード | `docs/aidlc/bin/check-backlog-mode.sh` |
| 6.5 ドラフトPR Ready化 | 5行のbashコード | `docs/aidlc/bin/check-gh-status.sh` |

### setup.md（1箇所 + 条件付き1箇所）

| 箇所 | 現状 | 変更後 |
|------|------|--------|
| 4. バックログモード確認 | 5行のbashコード | `docs/aidlc/bin/check-backlog-mode.sh` |
| mode=issue時のGH確認 | 8行のbashコード | `docs/aidlc/bin/check-gh-status.sh` |

## 行数削減見積もり

| 項目 | 現状行数 | 変更後行数 | 削減 |
|------|---------|-----------|------|
| バックログモード確認（6箇所） | 約36行 | 約6行 | 約30行 |
| GitHub CLI確認（6箇所） | 約36行 | 約6行 | 約30行 |
| **合計** | 約72行 | 約12行 | **約60行** |

**注**: 約100行削減の目標に対し、約60行の削減見込み。完全達成には追加のリファクタリングが必要な可能性あり。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: スクリプト実行が1秒以内に完了すること
- **対応策**: 軽量なコマンド呼び出しのみ、ネットワークアクセスなし
- **補足**: `gh auth status` はローカル認証情報を参照（ネットワーク不要）

## 技術選定

- **言語**: Bash
- **シェバン**: `#!/usr/bin/env bash`
- **オプション**: `set -euo pipefail`

## 実装上の注意事項

- 出力形式は`env-info.sh`と統一（`KEY:VALUE`形式）
- dasel未インストール時は空値を返し、AIに読み取りを委ねる既存設計を維持
- エラーハンドリングは状態として出力（異常終了しない）

## 不明点と質問（設計中に記録）

特になし（既存パターンからの抽出のため、仕様は明確）
