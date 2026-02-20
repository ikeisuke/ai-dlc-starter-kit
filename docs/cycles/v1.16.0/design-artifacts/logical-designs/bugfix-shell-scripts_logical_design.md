# 論理設計: シェルスクリプトバグ修正

## 概要

既存シェルスクリプト内の2関数のバグ修正。新規コンポーネントの追加はなく、既存関数の条件式修正のみ。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のシェルスクリプトユーティリティパターンを維持。各スクリプトは独立した単機能CLIツールとして動作し、stdout出力のkey:value形式で結果を返す。

## コンポーネント構成

### ファイル構成（変更対象のみ）

```text
prompts/package/bin/
├── aidlc-git-info.sh    # VCS状態取得ユーティリティ
└── suggest-version.sh   # バージョン推測ユーティリティ
```

### コンポーネント詳細

#### aidlc-git-info.sh - detect_vcs()（内部関数）

- **責務**: 現在ディレクトリのVCS種類（jj/git/unknown）を判定
- **依存**: jj CLI（オプション）、git CLI（オプション）
- **内部関数出力**: stdout に "jj", "git", "unknown" のいずれかを出力（呼び出し元の `main()` が `vcs_type:<value>` 形式のスクリプトAPIに変換）

#### suggest-version.sh - get_latest_cycle()（内部関数）

- **責務**: docs/cycles/ 配下の最新サイクルバージョンを特定
- **依存**: ls, grep, sort, tail, basename, sed（標準コマンド、sort -VはGNU拡張）、ファイルシステム（docs/cycles/ ディレクトリ）
- **内部関数出力**: stdout にバージョン文字列（例: "v1.16.0"）または空文字を出力（呼び出し元の `main()` が `latest_cycle:<value>` 形式のスクリプトAPIに変換）

## スクリプトインターフェース設計

### aidlc-git-info.sh

#### 概要

Git/jjの状態を取得し、key:value形式で出力する。

#### 引数

なし

#### 成功時出力（修正対象の `detect_vcs()` 部分のみ）

```text
vcs_type:<git|jj|unknown>
```

- 終了コード: `0`

#### detect_vcs() 判定フロー（修正後）

```text
1. .jj ディレクトリが存在するか？ → YES かつ jj コマンド利用可 → "jj" を返す
2. .git が存在するか（ファイルまたはディレクトリ）？ → YES かつ git コマンド利用可 → "git" を返す
3. いずれにも該当しない → "unknown" を返す
```

**修正箇所**: ステップ2の条件（`-d` → `-e`）および `command -v git` チェック追加

### suggest-version.sh

#### 概要

ブランチ名と既存サイクルからバージョンを推測・提案する。

#### 引数

なし

#### 成功時出力（修正対象の `get_latest_cycle()` 部分のみ）

```text
latest_cycle:<version>
```

- 終了コード: `0`

#### get_latest_cycle() 処理フロー（修正後）

```text
1. docs/cycles/v*/ に一致するディレクトリを列挙
2. SemVerパターン（v{MAJOR}.{MINOR}.{PATCH}）でフィルタ
3. バージョンソート（sort -V）で最新を取得
4. ディレクトリ名からバージョン文字列を抽出
```

**修正箇所**: ステップ2のSemVerフィルタ追加

## 非機能要件（NFR）への対応

### パフォーマンス

- 既存と同等。追加の `grep` フィルタによるオーバーヘッドは無視可能
- `command -v git` の追加も即座に完了する

### セキュリティ

- 該当なし（ローカルファイルシステムとコマンド存在確認のみ）

## 技術選定

- **言語**: Bash
- **外部コマンド**: ls, grep, sort, tail, basename, sed（標準コマンド群（sort -VはGNU拡張））、command（Bashビルトイン、コマンド存在確認用）

## 実装上の注意事項

- 編集対象は `prompts/package/bin/` 配下（メタ開発ルール: `docs/aidlc/bin/` は直接編集しない）
- `grep -E` のSemVerパターンは厳密にマッチさせ、先頭ゼロ付き数値（例: `v01.02.03`）を除外する
- パイプライン全体が空の場合に `|| echo ""` で空文字を返す既存のフォールバックを維持する

## 不明点と質問

なし（修正内容が明確なバグ修正のため）
