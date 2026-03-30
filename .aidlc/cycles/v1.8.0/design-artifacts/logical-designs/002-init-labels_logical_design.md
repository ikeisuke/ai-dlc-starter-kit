# 論理設計: 共通ラベル一括初期化スクリプト

## 概要

バックログ管理用の共通ラベル11個をGitHub リポジトリに一括作成するシェルスクリプトの構成とインターフェースを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードはImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

シングルファイル・シェルスクリプトパターンを採用（env-info.shと同様）。

**選定理由**:

- 単一責務で完結する処理
- 外部依存が少ない（gh CLIのみ）
- 既存スクリプト（env-info.sh）との一貫性

## コンポーネント構成

### スクリプト構成

```text
prompts/package/bin/init-labels.sh
├── ヘルプ表示機能
├── gh CLI利用可否確認機能
├── ラベル存在確認機能
├── ラベル作成機能
└── メイン処理（一括実行）
```

### コンポーネント詳細

#### show_help()

- **責務**: 使用方法のヘルプメッセージを表示
- **依存**: なし
- **公開インターフェース**: 標準出力へヘルプ表示

#### check_gh_available()

- **責務**: gh CLIが利用可能（インストール済み・認証済み）かを確認
- **依存**: gh CLI（直接確認、env-info.shは使用しない）
- **公開インターフェース**: 利用可能なら0、不可なら1を返す
- **エラー出力**:
  - 未インストール時: `error:gh-not-installed`
  - 未認証時: `error:gh-not-authenticated`

#### label_exists()

- **責務**: 指定されたラベルがリポジトリに存在するかを確認
- **依存**: gh CLI
- **公開インターフェース**: 引数としてラベル名を受け取り、存在すれば0、なければ1を返す

#### create_label()

- **責務**: 指定されたラベルをリポジトリに作成
- **依存**: gh CLI
- **公開インターフェース**: 引数として名前・色・説明を受け取り、作成結果を出力

#### main()

- **責務**: 引数解析、全ラベルの一括初期化を実行
- **依存**: 上記すべての関数
- **公開インターフェース**: スクリプトエントリポイント

## インターフェース設計

### コマンド

#### init-labels.sh

```text
使用方法:
  ./init-labels.sh [OPTIONS]

OPTIONS:
  -h, --help    ヘルプを表示
  --dry-run     実際に作成せず、作成予定のラベルを表示

引数:
  なし（ラベル定義はスクリプト内に埋め込み）
```

### 出力形式

出力は標準出力（stdout）と標準エラー出力（stderr）を分離する。

**標準出力（stdout）** - 機械可読形式、3パート固定:

```text
# 成功時
label:backlog:created
label:type:feature:exists
label:type:bugfix:created
...

# --dry-run モード時
label:backlog:would-create
label:type:feature:exists
label:type:bugfix:would-create
...

# 作成失敗時（状態のみ、詳細はstderrへ）
label:backlog:error
```

**標準エラー出力（stderr）** - 人間可読形式:

```text
# ghが利用不可の場合
error:gh-not-installed
error:gh-not-authenticated

# 作成失敗時の詳細メッセージ
[error] backlog: API rate limit exceeded
```

**パース方法**: stdoutは常に `label:<ラベル名>:<状態>` の3パート。最後のコロンで分割してラベル名と状態を取得。

### 終了コード

| コード | 意味 |
|--------|------|
| 0 | 正常終了（全ラベル作成またはスキップ） |
| 1 | gh CLI利用不可 |
| 2 | 1件以上のラベル作成に失敗 |

## 処理フロー概要

### 一括初期化の処理フロー

**ステップ**:

1. 引数解析（--help, --dry-run）
2. gh CLI利用可否確認
   - 利用不可 → エラー出力（stderr）、終了コード1で終了
3. 既存ラベル一覧を一括取得（`gh label list --json name -q '.[].name'`）
4. ラベル定義配列をループ
   - 各ラベルについて:
     a. 存在確認（取得済み一覧との完全一致照合）
     b. 存在する → "exists" 出力、次へ
     c. 存在しない → ラベル作成（gh label create）
        - 成功 → "created" 出力
        - 失敗 → "error" 出力（stdout）、詳細メッセージ出力（stderr）、エラーカウント増加
5. エラーカウントが0なら終了コード0、それ以外は終了コード2

**関与するコンポーネント**: check_gh_available, label_exists, create_label, main

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 11ラベル作成で30秒以内
- **対応策**:
  - 既存ラベル一覧を1回のAPI呼び出しで一括取得（存在確認の効率化）
  - 各ラベル作成は順次処理（並列化は行わない、API制限回避のため）
  - API呼び出し回数: 1回（一覧取得）+ 最大11回（作成）= 最大12回

### セキュリティ

- **要件**: N/A
- **対応策**: gh CLIの認証を使用、スクリプト内に認証情報を保持しない

### 可用性

- **要件**: gh認証済み環境で動作
- **対応策**:
  - 事前に gh auth status で認証状態を確認
  - ネットワークエラー時は gh CLI のエラーメッセージをそのまま出力

## 技術選定

- **言語**: Bash（bash 4.0+、POSIX非互換の機能を使用）
- **依存**: gh CLI（GitHub CLI）
- **スタイル**: env-info.sh と同様（set -euo pipefail、関数分割）

## 実装上の注意事項

- `set -euo pipefail` で厳格モードを有効化
  - ただしラベル作成の失敗時は継続するため、`if ... then ... else ... fi` でエラーをキャッチ
- ラベル名にコロン(:)が含まれるため、出力パース時に注意
  - 出力形式: `label:<ラベル名>:<状態>` の3パート構成
  - パース時は最後のコロンで分割（最初から2つ目のコロンまでがラベル名）
- gh label list の --search オプションは部分一致のため、完全一致確認が必要
  - `gh label list --json name` で全ラベルを取得し、完全一致でフィルタリング
  - または `gh label list --search "ラベル名" --json name` の結果を完全一致で検証
- gh label create の --force オプションは既存ラベルを上書きするため使用しない

## プロンプト変更箇所

**注意**: スクリプトは `prompts/package/bin/init-labels.sh` に作成され、Operations Phase の rsync で `docs/aidlc/bin/init-labels.sh` にコピーされます。プロンプト内の呼び出しパスは `docs/aidlc/bin/` を使用します。

### setup.md への呼び出し追加

編集対象: `prompts/package/prompts/setup.md`

「共通ラベルの初期化」セクションにスクリプト呼び出しを追加:

```bash
docs/aidlc/bin/init-labels.sh
```

### backlog-management.md への記載追加

編集対象: `prompts/package/guides/backlog-management.md`

「ラベル設定」セクションにスクリプト呼び出しを追加。

## 不明点と質問（設計中に記録）

なし（Unit定義で要件が明確）
