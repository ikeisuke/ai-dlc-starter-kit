# 論理設計: エラー処理改善

## 概要

`issue-ops.sh`、`cycle-label.sh`、`setup-branch.sh` の3スクリプトに対する具体的な変更箇所とインターフェース仕様を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のシェルスクリプトアーキテクチャを維持。各スクリプトは独立した関数ベースの構造を持ち、変更は既存関数の内部改善に限定する。

## コンポーネント構成

### 変更対象

```text
prompts/package/bin/
├── issue-ops.sh        # 変更: parse_gh_error関数、show_help関数
├── cycle-label.sh      # 変更: create_label関数内コメント
└── setup-branch.sh     # 変更: worktree_exists関数内パス変換ロジック
```

### コンポーネント詳細

#### parse_gh_error (issue-ops.sh)
- **責務**: ghコマンドのstderrエラー出力からエラー理由を判別する
- **依存**: なし（純粋関数）
- **公開インターフェース**: `parse_gh_error <error_output>` → stdout にエラー理由を出力

#### create_label (cycle-label.sh)
- **責務**: GitHubラベルを作成する
- **変更範囲**: 関数内コメントのみ（ロジック変更なし）

#### worktree_exists (setup-branch.sh)
- **責務**: 指定パスがgit worktreeとして登録されているか判定する
- **依存**: `realpath`（オプション）, `git worktree list`
- **変更範囲**: 関数内のパス変換ロジック

## スクリプトインターフェース設計

### issue-ops.sh - parse_gh_error 関数

#### 概要
ghコマンドのエラー出力を受け取り、分類されたエラー理由文字列を返す。

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (error_output) | 必須 | ghコマンドのstderr出力テキスト |

#### 成功時出力（変更後）
```text
not-found       # Issue/リソースが見つからない
auth-error      # 認証・権限エラー（新規追加）
unknown         # 上記以外
```
- 終了コード: `0`

#### エラー分類ルール（処理順序）
1. `not found` / `could not find` / `could not resolve` にマッチ → `not-found`
2. `authentication` / `401` / `403` / `token` / `credential` にマッチ → `auth-error`（大文字小文字不問）
3. いずれにもマッチしない → `unknown`

#### show_help 関数への追記
エラー一覧に以下を追加:
```text
    issue:<number>:error:auth-error
```

### setup-branch.sh - worktree_exists 関数内パス変換

#### 概要
相対パスを絶対パスに変換する内部ロジック。

#### 変換戦略
1. `command -v realpath` で `realpath` の存在を確認
2. 存在する場合: `realpath "$path"` を実行
3. `realpath` が存在しない、または実行失敗した場合: 既存ロジック（`cd + dirname + pwd + basename`）にフォールバック

#### 制約
- `realpath` は未存在パスで失敗する可能性がある → 必ずフォールバックで捕捉
- macOSではデフォルトで `realpath` が存在しない場合がある

### cycle-label.sh - create_label 関数コメント

#### 概要
リダイレクト `2>&1 1>/dev/null` の意図を正確に説明するコメントに改善。

#### 変更内容
既存コメント2行を、以下の趣旨に置換:
- stderrをstdoutへリダイレクト（変数キャプチャ対象へ）
- その後stdoutを/dev/nullへリダイレクト（ghの成功メッセージを破棄）
- 結果: stderrの内容のみが変数に格納される

## 非機能要件（NFR）への対応

### 互換性
- parse_gh_error: 既存の `not-found` / `unknown` パターンの動作を維持
- worktree_exists: 既存パスでの正常動作を維持
- create_label: ロジック変更なし（コメントのみ）

### 可読性
- cycle-label.sh: リダイレクトの意図が明確になる
- setup-branch.sh: `realpath` 優先により意図が明確になる

## 技術選定
- **言語**: Bash
- **依存コマンド**: `realpath`（オプション、フォールバックあり）

## 不明点と質問

なし
