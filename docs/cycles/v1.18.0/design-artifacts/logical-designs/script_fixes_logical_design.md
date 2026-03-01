# 論理設計: スクリプトバグ修正

## 概要

issue-ops.sh、squash-unit.sh、resolve-starter-kit-path.sh の3スクリプトの修正・新規作成に関する論理設計。既存スクリプトのインターフェース互換性を維持しつつ、エラーハンドリングとルートコミット対応を追加する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のシェルスクリプトユーティリティ群のパターンを踏襲:
- 各スクリプトは独立したCLIツールとして動作
- 出力フォーマットは `key:value` 形式で機械的に解析可能
- 機械可読契約は stdout の `key:value` 形式のみ。stderr は人間向け補助情報（非契約）
- 既存の正常系動作には一切影響を与えない

## コンポーネント構成

### スクリプト構成

```text
prompts/package/bin/
├── issue-ops.sh          [修正] parse_gh_error() にラベルエラー検出追加
├── squash-unit.sh        [修正] ルートコミット対応追加
└── resolve-starter-kit-path.sh  [新規] スターターキットパス解決
```

### コンポーネント詳細

#### parse_gh_error()（issue-ops.sh 内）

- **責務**: GitHub CLIエラー出力の分類。ラベル固有エラーを汎用エラーより優先して検出
- **依存**: なし（純粋関数）
- **公開インターフェース**: `parse_gh_error(error_output) -> error_reason`
- **変更内容**: パターンマッチ順序に `label-not-found` を `not-found` の前に追加

#### is_root_commit()（squash-unit.sh 内、新規関数）

- **責務**: 指定コミットがルートコミットかどうかを判定
- **依存**: git CLI
- **公開インターフェース**: `is_root_commit(hash) -> 0|1`（shellの真偽値）

#### safe_log_range()（squash-unit.sh 内、新規関数）

- **責務**: ルートコミット対応のgit log用範囲式を構築（`git log` 系コマンド専用）
- **依存**: is_root_commit()
- **公開インターフェース**: `safe_log_range(first_hash, last_hash) -> range_args`
- **ルール**:
  - 通常時: `first^..last` を返す（firstを含む inclusive range）
  - ルートコミット時: `last` を返す（ルートからlastまで全コミットを含む）
  - **重要**: Gitの `A..B` はAを含まない。ルートコミット時に `first..last` を使うとfirstが欠落するため注意
- **使用箇所**: co-author抽出、dry-run表示の2箇所で統一的に使用

#### rebase_base_args()（squash-unit.sh 内、新規関数）

- **責務**: ルートコミット対応のgit rebase起点引数を構築（rebase専用）
- **依存**: is_root_commit()
- **公開インターフェース**: `rebase_base_args(first_hash) -> rebase_args`
- **ルール**:
  - 通常時: `first^` を返す（rebase -i の起点）
  - ルートコミット時: `--root` を返す（git rebase -i --root）
- **使用箇所**: squash_retroactive_git() のrebase起点のみ

#### resolve-starter-kit-path.sh

- **責務**: スクリプトの実行位置からスターターキットのルートパスを解決
- **依存**: 標準のbashコマンドのみ。利用プロジェクトモード時は環境変数 `AIDLC_STARTER_KIT_PATH`（必須）
- **公開インターフェース**: stdout にスターターキットのルートパスを出力

## スクリプトインターフェース設計

### issue-ops.sh（修正箇所のみ）

#### parse_gh_error() の出力値追加

| 出力値 | 条件 | 優先度 |
|--------|------|--------|
| `label-not-found` | エラー出力にラベル関連の "not found" パターンが含まれる | 高（最優先） |
| `not-found` | エラー出力に汎用の "not found" パターンが含まれる | 中 |
| `auth-error` | 認証関連のエラーパターンが含まれる | 中 |
| `unknown` | 上記いずれにも該当しない | 低（フォールバック） |

#### ラベルエラー検出パターン

GitHub CLIが返すラベル未作成時のエラーメッセージ:
- `'label_name' not found`（`gh issue edit --add-label` 時）
- `label ... not found` の類似パターン

**検出順序**:
1. ラベル固有パターン → `label-not-found`
2. 汎用 not-found パターン → `not-found`
3. 認証パターン → `auth-error`
4. フォールバック → `unknown`

### squash-unit.sh（修正箇所のみ）

#### is_root_commit() - 新規関数

##### 概要
指定コミットがリポジトリのルートコミットかどうかを判定する。

##### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (hash) | 必須 | 判定対象のコミットハッシュ |

##### 戻り値
- `0`: ルートコミット
- `1`: ルートコミットではない

##### ロジック
- `git rev-parse "${hash}^" 2>/dev/null` が失敗する場合、ルートコミットと判定
- 代替: `git rev-list --max-parents=0 HEAD` の結果と比較

#### 影響を受ける既存関数

| 関数名 | 修正内容 |
|--------|---------|
| `squash_retroactive_git()` L759 | `rebase_base` 算出時にルートコミットチェック。ルート時は `--root` フラグを使用 |
| `extract_co_authors_for_range()` L434 | `safe_log_range()` を使用してルートコミット対応の範囲式に変更 |
| dry-run表示 L731 | `safe_log_range()` を使用してルートコミット対応の範囲式に変更 |

#### ルートコミット時の代替処理フロー

```text
通常時:
  rebase_base = git rev-parse ${FIRST}^
  git rebase -i $rebase_base
  range = ${FIRST}^..${LAST}

ルートコミット時:
  rebase: rebase_base_args(FIRST) → --root → git rebase -i --root
  co-author/dry-run: safe_log_range(FIRST, LAST) → LAST → git log ${LAST}
  ※ git の A..B はAを含まないため、ルート時は `first..last` ではなく `last` を使用
```

### resolve-starter-kit-path.sh（新規）

#### 概要
スクリプトの実行位置からAI-DLCスターターキットのルートパスを解決する。

#### 引数
なし

#### 成功時出力
```text
/absolute/path/to/starter-kit-root
```
- 終了コード: `0`
- 出力先: stdout（パスのみ、改行付き）

#### エラー時出力
```text
Error: cannot resolve starter kit path from <script_dir>
```
- 終了コード: `1`
- 出力先: stderr

#### 判定ロジック

```text
1. SCRIPT_DIR を取得（symlink解決済み）
2. SCRIPT_DIR のパス構造を確認:
   a. 末尾が "prompts/package/bin" の場合:
      → メタ開発モード
      → SCRIPT_DIR の3階層上がスターターキットルート
   b. 末尾が "docs/aidlc/bin" の場合:
      → 利用プロジェクトモード
      → SCRIPT_DIR の3階層上がプロジェクトルート（スターターキットは外部）
      → スターターキットパスは AIDLC_STARTER_KIT_PATH 環境変数で指定（必須）
      → 未設定時はエラー（終了コード1、stderr: "Error: AIDLC_STARTER_KIT_PATH is not set"）
   c. いずれにも該当しない場合:
      → エラー
```

#### 使用コマンド
```bash
# 基本的な使用方法
STARTER_KIT_ROOT=$(resolve-starter-kit-path.sh)

# sourceで使用
source "$(resolve-starter-kit-path.sh)/prompts/package/bin/some-util.sh"
```

## 処理フロー概要

### ラベルエラー検出フロー

1. `cmd_label()` で `gh issue edit --add-label` を実行
2. 失敗時、`parse_gh_error()` にエラー出力を渡す
3. `parse_gh_error()` がラベル固有パターンを先に検査
4. マッチすれば `label-not-found` を返す
5. 呼び出し元が `format_output()` で標準出力形式に変換

### ルートコミットsquashフロー（retroactive）

1. `find_unit_commit_range_git()` でUnit範囲を特定
2. `UNIT_FIRST_COMMIT` がルートコミットか判定（`is_root_commit()`）
3. ルートコミットの場合:
   a. `extract_co_authors_for_range()` で `^` なし範囲を使用
   b. dry-run表示で `^` なし範囲を使用
   c. `git rebase -i --root` を使用
4. 通常の場合: 既存ロジックのまま

### スターターキットパス解決フロー

1. `SCRIPT_DIR` を取得（`$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)`）
2. symlink解決（`readlink` または `realpath` 使用、bash 3.x互換考慮）
3. パス構造でコンテキスト判定
4. コンテキストに応じたルートパスを算出して出力

## 非機能要件（NFR）への対応

### 可用性
- **要件**: エラー発生時に明確なメッセージを出力
- **対応策**:
  - `label-not-found` エラー時にラベル初期化を促すガイダンスをstderrに出力
  - ルートコミット時の代替処理により、従来エラーで停止していたケースが正常完了可能に
  - パス解決失敗時に具体的なエラーメッセージを出力

### 互換性
- **要件**: `enabled=false` 時の完全互換（Unit 001由来）、既存正常系の維持
- **対応策**:
  - `parse_gh_error()` の既存出力（`not-found`, `auth-error`, `unknown`）はそのまま維持
  - squash-unit.sh の既存正常系（非ルートコミット）は既存ロジックのまま
  - resolve-starter-kit-path.sh は新規スクリプトのため互換性問題なし

## 技術選定

- **言語**: Bash（bash 3.x互換）
- **依存コマンド**: git, gh（GitHub CLI）、標準POSIX系コマンド
- **symlink解決**: macOS互換を考慮し `readlink -f` は避け、`cd ... && pwd` パターンを使用

## 実装上の注意事項

- `parse_gh_error()` のパターン追加時、既存パターンとの順序関係に注意（詳細パターンを先に配置）
- `parse_gh_error()` の新戻り値 `label-not-found` を `show_help()` のエラー一覧に追加すること（後方互換: 呼び出し元はreason値が拡張される前提で設計されている）
- stderrは人間向けの補助情報（非契約）。機械連携は stdout の `issue:<n>:error:<reason>` のみを契約とする
- `git rebase -i --root` はインタラクティブrebaseのため、GIT_SEQUENCE_EDITOR の設定が必要（既存の `build_sequence_editor_script()` で対応）
- `readlink -f` はmacOS標準では使用不可。`cd "$(dirname ...)" && pwd` パターンで代替
- resolve-starter-kit-path.sh は `BASH_SOURCE[0]` を使用してsource時の正確なパスを取得

## 不明点と質問（設計中に記録）

（なし）
