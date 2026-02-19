# 論理設計: シェルスクリプトバグ修正・バリデーション強化

## 概要

`check-open-issues.sh` と `suggest-version.sh` の入力バリデーション・エラー処理改善の具体的な変更箇所とインターフェースを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存スクリプトの構造を維持し、バリデーション・エラー処理の強化のみ行う。新たなアーキテクチャパターンの導入は不要。

## スクリプトインターフェース設計

### check-open-issues.sh

#### 概要
GitHubリポジトリのオープンIssue一覧を取得するCLIユーティリティ。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--limit N` | 任意 | 取得件数（デフォルト: 10）。N は正の整数（1以上） |

#### 成功時出力
```text
# Issue有の場合
<gh issue list の出力>

# Issue無の場合
open_issues:none
```
- 終了コード: `0`

#### エラー時出力
```text
error:<エラー種別>[:<コンテキスト>]
```
- 終了コード: `1`
- エラー種別一覧（エラー種別は固定文字列、コンテキストは付帯情報で一部のエラーにのみ付与）:
  - `unknown-option:<option>` - 未知のオプション（`<option>` は付帯コンテキスト）
  - `missing-limit-value` - `--limit` の値未指定
  - `invalid-limit-value` - `--limit` の値が不正（非数値、0以下等）
  - `gh-not-installed` - gh コマンド未インストール
  - `gh-not-authenticated` - gh 未認証
  - `gh-issue-list-failed` - Issue取得失敗（詳細は stderr）

### suggest-version.sh

#### スクリプトレベルの契約
- **入力**: 引数なし
- **出力**: `key:value` 形式の5行（`branch_version`, `latest_cycle`, `suggested_patch`, `suggested_minor`, `suggested_major`）
- **終了コード**: `0`（正常）、`1`（エラー、`set -e` によるearly exit含む）
- **今回の変更影響**: `calculate_next_version` に不正な type が渡された場合に `return 1` → `set -e` によりスクリプト全体が終了。現在の呼び出し元（`main` 関数）は固定値 "patch"/"minor"/"major" のみ渡すため、実行時の影響はない

### suggest-version.sh > calculate_next_version()

#### 概要
バージョン文字列とタイプから次バージョンを計算する内部関数。

#### 引数

| 引数 | 説明 |
|------|------|
| `$1` (version) | バージョン文字列（例: "v1.2.3"）。空の場合は "v1.0.0" を返す |
| `$2` (type) | バージョン計算タイプ: "patch" / "minor" / "major" |

#### 成功時出力
```text
v<major>.<minor>.<patch>
```
- 戻り値: `0`

#### エラー時出力
- stderr にエラーメッセージ出力
- 戻り値: `1`

## 処理フロー概要

### check-open-issues.sh の引数解析フロー

**ステップ**:
1. `--limit` オプション検出
2. `$#` が 1以下かチェック → 値未指定なら `error:missing-limit-value` で終了
3. `$2` が正規表現 `^[1-9][0-9]*$` にマッチするかチェック → 不一致なら `error:invalid-limit-value` で終了
4. バリデーション通過 → `LIMIT="$2"` に代入、`shift 2`

### check-open-issues.sh の gh issue list エラー処理フロー

**実装パターン**: stdout には固定エラー種別のみ。`gh` の生エラー出力は stderr に分離する。

**ステップ**:
1. `gh issue list` を実行。stderr は別途キャプチャ（`2>` でファイルディスクリプタまたは一時変数に退避）
2. 失敗時: stdout に `error:gh-issue-list-failed` を出力
3. 失敗時: stderr にキャプチャしたエラー詳細を出力
4. `exit 1`

### calculate_next_version の default ケース処理フロー

**ステップ**:
1. `case "$type"` で patch/minor/major にマッチしない
2. `*)` ケースに到達
3. stderr にエラーメッセージ出力
4. `return 1`

## 非機能要件（NFR）への対応

### 互換性
- 正常系（有効な引数での実行）の既存動作は変更しない
- 既存のエラー種別（`unknown-option`、`gh-not-installed`、`gh-not-authenticated`）はそのまま維持
- `gh issue list` のエラー出力のみ `error:${result}` → `error:gh-issue-list-failed` に変更（機械可読性向上）
- **互換性変更（意図的）**: `--limit` に不正値（非数値、0等）を渡した場合、従来は `gh issue list` に直接渡されていたが、新たにバリデーションエラーとして即座に拒否する。これはバグ修正に該当し、呼び出し側が不正値を渡すケースは想定外の使用方法であるため影響は軽微

### セキュリティ
- `--limit` の数値バリデーションによりコマンドインジェクションリスクを排除

## 技術選定
- **言語**: Bash（既存スクリプトと同一）
- **外部コマンド**: gh（GitHub CLI）

## 実装上の注意事項
- `set -u` 環境下で `$2` 参照前に `$#` チェックが必須
- `gh issue list` のstderr出力には改行が含まれる可能性があるため、stdoutへの混入を防ぐ
- 修正は `prompts/package/bin/` 配下で行う（`docs/aidlc/bin/` は直接編集禁止）

## 不明点と質問（設計中に記録）

特になし（要件が明確であるため）
