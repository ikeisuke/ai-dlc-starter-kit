# 論理設計: label-cycle-issues.sh

## 概要

Unit定義ファイルから関連Issue番号を抽出し、サイクルラベルを一括付与するシェルスクリプトのコンポーネント構成とインターフェースを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードはPhase 2（コード生成ステップ）で作成します。

## アーキテクチャパターン

**パイプライン処理パターン**を採用。

- 入力検証 → Issue番号抽出 → ラベル付与 → 結果出力
- 各ステージは独立した関数として実装
- 既存スクリプト（issue-ops.sh）を再利用

## コンポーネント構成

### モジュール構成

```text
label-cycle-issues.sh
├── main()                    # エントリーポイント
├── show_help()               # ヘルプ表示
├── check_gh_available()      # gh CLI利用可否チェック
├── extract_issue_numbers()   # Issue番号抽出
└── label_issues()            # ラベル付与（issue-ops.sh呼び出し）
```

### コンポーネント詳細

#### main()

- **責務**: 引数解析、処理フロー制御、エラー出力生成
- **依存**: show_help, check_gh_available, extract_issue_numbers, label_issues
- **公開インターフェース**: スクリプトのエントリーポイント
- **gh利用可否チェック結果のマッピング**:
  - check_gh_available() 戻り値1 → `error:gh-not-available` を出力し終了コード1
  - check_gh_available() 戻り値2 → `error:gh-not-authenticated` を出力し終了コード1
- **ラベル名生成**: `cycle:{CYCLE}` をmain()で生成しlabel_issues()に渡す

#### show_help()

- **責務**: ヘルプメッセージを標準出力に表示
- **依存**: なし
- **公開インターフェース**: `-h`, `--help` オプション時に呼び出し

#### check_gh_available()

- **責務**: gh CLIのインストール状態と認証状態を確認
- **依存**: なし（外部コマンド `gh` のみ）
- **公開インターフェース**: 戻り値 0=利用可能, 1=未インストール, 2=未認証

#### extract_issue_numbers()

- **責務**: Unit定義ファイル群からIssue番号を抽出
- **依存**: なし（awk, grep, sort, uniqコマンド使用）
- **公開インターフェース**: 引数=サイクル名、stdout=Issue番号リスト（改行区切り）
- **抽出方法**: awkで `## 関連Issue` セクションのみを対象とし、`^- #[0-9]+` パターンを抽出
- **エッジケース処理**:
  - サイクルディレクトリ不在: `compgen -G` または `ls` でファイル存在を事前チェックし、なければ空出力で正常終了
  - Unitファイル0件: 同上
  - `set -e` との整合性: ファイル存在チェックを `if` 文で囲み、grepの非0終了（マッチなし）は `|| true` で捕捉

#### label_issues()

- **責務**: 抽出したIssue群にラベルを付与
- **依存**: issue-ops.sh（既存スクリプト）
- **公開インターフェース**: 引数=Issue番号リスト+ラベル名、stdout=処理結果
- **ラベル名生成**: `cycle:{CYCLE}` 形式（main()からラベル名を受け取る）
- **エラー継続処理**: issue-ops.sh呼び出し時は `|| true` で終了コードを捕捉し、一部Issueエラー時も残りを処理継続
- **出力契約**: issue-ops.shの出力仕様に完全準拠（透過）
  - 成功時: `issue:{番号}:labeled:{ラベル名}`
  - エラー時: `issue:{番号}:error:{理由}` （not-found, unknown等）
  - ラベル未作成・権限不足等のエラー分類はissue-ops.shに委譲

## インターフェース設計

### コマンドライン

```text
Usage: label-cycle-issues.sh <CYCLE>
       label-cycle-issues.sh -h | --help

CYCLE - サイクル名（例: v1.8.1）
```

### 出力形式

```text
# 成功時（各Issueごとに1行）
issue:123:labeled:cycle:v1.8.1
issue:456:labeled:cycle:v1.8.1

# エラー時
issue:789:error:not-found
error:gh-not-available
error:gh-not-authenticated
error:missing-cycle
```

## 処理フロー概要

### 一括ラベル付与の処理フロー

**ステップ**:

1. 引数チェック（CYCLE必須）
2. gh CLI利用可否チェック
3. Unit定義ファイルからIssue番号抽出
4. Issue番号が0件の場合は正常終了
5. 各Issueに対してissue-ops.shを呼び出してラベル付与
6. 結果を標準出力に出力

**関与するコンポーネント**: main, check_gh_available, extract_issue_numbers, label_issues

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: N/A（セットアップ時の一回実行）
- **対応策**: 不要

### セキュリティ

- **要件**: N/A
- **対応策**: 不要

### 可用性

- **要件**: N/A
- **対応策**: エラー時は明確なメッセージを出力し、処理を継続可能な範囲で継続

## 技術選定

- **言語**: Bash
- **外部依存**: gh CLI, issue-ops.sh（既存スクリプト）
- **標準コマンド**: grep, sed, sort, uniq

## 実装上の注意事項

- `set -euo pipefail` でエラー検出を厳格化
- Issue番号抽出パターンは `^- #[0-9]+` を使用
- issue-ops.sh のパスは相対パス（`docs/aidlc/bin/issue-ops.sh`）で参照
- 一部Issueでエラーが発生しても残りのIssueは処理継続

## inception.md への統合

### 変更箇所

「完了時の必須作業」セクション内の「関連Issueへのサイクルラベル付与」部分を変更。

### 変更前（現状）

```bash
grep -h "^- #[0-9]" docs/cycles/{{CYCLE}}/story-artifacts/units/*.md 2>/dev/null
# ... 手動でissue-ops.shを呼び出す説明
```

### 変更後（提案）

```bash
docs/aidlc/bin/label-cycle-issues.sh "{{CYCLE}}"
```

## 不明点と質問（設計中に記録）

（なし - Unit定義から要件は明確）
