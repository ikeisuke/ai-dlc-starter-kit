# 論理設計: Unit 001 pr-ready --body-file 空ファイル検証

## 概要

`skills/aidlc/scripts/operations-release.sh` 内に共通検証ヘルパーを導入し、`cmd_pr_ready`（Primary 経路）と `gh_pr_edit_body_with_fallback()`（Fallback 経路）の両方から呼び出すことで、PR 本文ファイルの不在 / 0 バイトを fail-fast で拒否する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

- **レイヤード（責務分離）**: コマンドハンドラ層（`cmd_pr_ready`）と外部 API 呼び出し層（`gh_pr_edit_body_with_fallback`）の間に「入力検証層」を共通ヘルパーとして挿入する
- **Single Source of Truth（検証ロジックの単一化）**: 検証ヘルパー `_pr_ready_validate_body_file` のみが判定を行い、両呼び出し元は戻り値判定だけを担当する（codex 指摘 #1 反映）
- **Fail-Fast**: 外部 API 呼び出し前に検証を完了させ、副作用ゼロで停止する

## コンポーネント構成

### スクリプト内モジュール構成

```text
skills/aidlc/scripts/operations-release.sh
├── _pr_ready_validate_body_file()     [NEW] 共通検証ヘルパー（単一 SoT）
├── cmd_pr_ready()                     [変更] Primary 経路から検証ヘルパー呼び出し
└── gh_pr_edit_body_with_fallback()    [変更] Fallback 経路から検証ヘルパー呼び出し
```

### コンポーネント詳細

#### `_pr_ready_validate_body_file()` [NEW]

- **責務**: PR 本文ファイルパスを受け取り、Missing / Empty / Valid を判定し、エラー時は機械可読メッセージを stderr に出力する。検証ロジックの単一 SoT
- **依存**: **bash 組み込みテストオペレータのみ**（`[[ -f ]]` / `[[ -s ]]`）。外部コマンドは使わない（`wc` 等のサブプロセス起動も不要）
- **公開インターフェース**: 後述「スクリプトインターフェース設計」参照

#### `cmd_pr_ready()` [変更]

- **責務**: `pr-ready` サブコマンドのコマンドハンドラ。引数パース後、`--body-file` 値が指定されていれば検証ヘルパーを呼び出す
- **依存**: `_pr_ready_validate_body_file`, `pr-ops.sh`, `gh_pr_edit_body_with_fallback`, `gh pr create`
- **挿入箇所**: 既存の引数 while ループ完了直後、`cycle` resolution の前後（dry-run / 非 dry-run / find-draft の全分岐より前）

#### `gh_pr_edit_body_with_fallback()` [変更]

- **責務**: `gh pr edit` 実行と REST PATCH fallback の判定。冒頭で検証ヘルパーを再呼び出しし、検証エラーなら `gh pr edit` 自体を呼ばない（二重防御）
- **依存**: `_pr_ready_validate_body_file`, `gh CLI`, `gh api`
- **挿入箇所**: 関数冒頭、`local pr_number / body_file` 宣言後、`gh pr edit` 実行前

## インターフェース設計

### スクリプトインターフェース設計

#### `_pr_ready_validate_body_file()`

##### 概要

PR 本文ファイルが API 送信に適するか（存在し、かつ非空であるか）を検証する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` body_file_path | 必須 | 検証対象のファイルパス |

> 設計判断（設計レビュー指摘 #2 反映）: 当初検討の `phase`（primary/fallback）引数は導入しない。SoT ヘルパーの API 表面を最小化し、将来分岐温床を排除する。

##### 成功時出力

- 終了コード: `0`
- 出力先: なし（stdout / stderr 共に何も出力しない）
- 意味: 引数パスは通常ファイルとして存在し、サイズ ≥ 1 バイト（`[[ -f ]]` true かつ `[[ -s ]]` true）

##### エラー時出力

ファイル不在 / 非 regular file（ディレクトリ・特殊ファイル等を含む）:

```text
error<TAB>pr-ready:body-file-missing<TAB><path>
```

- 終了コード: `1`
- 出力先: stderr
- 判定: `[[ -f "$path" ]]` が false

0 バイトファイル:

```text
error<TAB>pr-ready:body-file-empty<TAB><path>
本文が空です。--body-file の中身を確認してから再実行してください
```

- 終了コード: `1`
- 出力先: stderr（機械可読 1 行 + 人間可読 1 行の計 2 行）
- 判定: `[[ -f "$path" ]]` true かつ `[[ ! -s "$path" ]]`

##### 設計上の注意

- ファイル**内容**は stderr に絶対に出力しない（情報リーク防止）
- 判定は **bash 組み込みテストオペレータ `[[ -f ]]` / `[[ -s ]]` のみで完結**する。`wc -c` / `stat -c %s` 等の外部コマンドは使用しない（コマンド置換 `$(...)` の必要性を構造的に排除し、CLAUDE.md / Intent 制約に整合）
- `Missing` ステートは「不在」だけでなく「ディレクトリ / FIFO / デバイス / ソケット / 通常ファイルでない symlink 先」も包含する（設計レビュー指摘 #1 反映）。ユーザーから見ると「指定パスを通常ファイルとして読めない」という同一カテゴリのため、エラーコードは追加せず `pr-ready:body-file-missing` に統合する

### コマンド

#### `cmd_pr_ready` 改修

- **パラメータ**: 既存の `--cycle` / `--pr` / `--body-file` / `--dry-run` のまま変更なし
- **戻り値**: 既存のまま
- **副作用追加**:
  - `--body-file` 指定時、検証ヘルパー失敗 → 即 `return 1`（dry-run / 非 dry-run 問わず）
  - `--body-file` 未指定時は従来通り（後段の `body-file-required` エラーチェックで判定）

#### `gh_pr_edit_body_with_fallback` 改修

- **パラメータ**: `$1 pr_number, $2 body_file` のまま変更なし
- **戻り値**: 既存のまま
- **副作用追加**:
  - 冒頭で検証ヘルパー失敗 → `gh pr edit` を呼ばずに `return 1`

## データモデル概要

該当なし（永続データなし）。

## 処理フロー概要

### ユースケース 1: `pr-ready --body-file <正常ファイル>` の処理フロー

**ステップ**:

1. `cmd_pr_ready` が `--body-file <path>` をパース
2. `_pr_ready_validate_body_file <path>` 呼び出し → `state=Valid` → exit 0
3. 既存処理: get-related-issues / find-draft / pr-ops.sh ready / `gh_pr_edit_body_with_fallback`
4. `gh_pr_edit_body_with_fallback` 冒頭で `_pr_ready_validate_body_file <path>` 再呼び出し → `state=Valid` → exit 0
5. `gh pr edit --body-file <path>` 実行（成功 or scope-error → REST PATCH fallback）

**関与するコンポーネント**: `cmd_pr_ready`, `_pr_ready_validate_body_file`, `gh_pr_edit_body_with_fallback`, `gh CLI`

### ユースケース 2: `pr-ready --body-file <0 バイトファイル>` の処理フロー

**ステップ**:

1. `cmd_pr_ready` が `--body-file <path>` をパース
2. `_pr_ready_validate_body_file <path>` 呼び出し → `state=Empty`
3. stderr に `error\tpr-ready:body-file-empty\t<path>` + 人間可読案内
4. `cmd_pr_ready` から exit 1（**get-related-issues / find-draft / gh pr edit は呼ばれない**）

**関与するコンポーネント**: `cmd_pr_ready`, `_pr_ready_validate_body_file`

### ユースケース 3: `pr-ready --body-file <不在 or 非 regular パス>` の処理フロー

**ステップ**: ユースケース 2 と同様で、`state=Missing` / `error\tpr-ready:body-file-missing\t<path>` を出力して exit 1。「不在」と「ディレクトリ / 特殊ファイル」は同一エラーコードに統合。

### ユースケース 4: 二重防御テスト（直接 `gh_pr_edit_body_with_fallback` 呼び出し時の防御）

**ステップ**:

1. テストハーネスが `gh_pr_edit_body_with_fallback "123" "<0 バイト or 不在 path>"` を直接呼ぶ
2. 関数冒頭で `_pr_ready_validate_body_file <path>` → `state=Empty` or `Missing`
3. stderr に機械可読エラー出力 → return 1
4. **`gh pr edit` も `gh api PATCH` も呼ばれない**

**関与するコンポーネント**: `gh_pr_edit_body_with_fallback`, `_pr_ready_validate_body_file`

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 検証オーバーヘッド 100ms 未満
- **対応策**: `[[ -f ]]` + `[[ -s ]]` の bash 組み込みテストのみ（外部プロセス起動なし、stat(2) 1〜2 回分）。実測 1ms 以下を見込む

### セキュリティ

- **要件**: ファイル内容を stderr に出力しない
- **対応策**: 検証ヘルパーはサイズ判定のみ行い、`cat` / `head` で内容を読まない

### 可搬性

- **要件**: macOS / Linux 双方の bash で動作
- **対応策**: bash 組み込みテストオペレータ `[[ -f ]]` / `[[ -s ]]` を採用（GNU/BSD の `stat` フラグ差や `wc` の出力フォーマット差を完全に回避）

### 後方互換性

- **要件**: 正常本文ありの `--body-file` 経路は従来通り動作
- **対応策**: `state=Valid` 時は何も出力せず exit 0。既存呼び出し元の挙動を変えない

## 技術選定

- **言語**: bash 4+（既存 operations-release.sh と同じ）
- **外部コマンド**: なし（`[[ ]]` 組み込みのみ）
- **テスト**: bats（既存テスト環境）

## 実装上の注意事項

- **コマンド置換禁止**: `$(...)` / バッククォートを新規導入しない（CLAUDE.md / Intent 制約）。本設計は bash 組み込み `[[ ]]` テストオペレータのみで完結するため、`wc` / `stat` 等の外部コマンドが不要であり、コマンド置換の必要性自体が構造的に排除される
  - 判定ロジック:
    - `[[ ! -f "$path" ]]` → Missing（不在 OR 非 regular file）
    - `[[ ! -s "$path" ]]`（このとき `-f` は true 既知）→ Empty
    - それ以外 → Valid
- **bats fixture 配置**: `tests/fixtures/pr-ready-body-validate/` 配下に 0 バイト / 通常 / 不在系の fixture を新設（不在系は実体ファイルなしのパスを指定）

### テスト設計（要点）

新規テストファイル: `tests/operations-release-pr-ready-body-validate.bats`

| ケース | 入力 | 期待 exit | 期待 stderr | 期待 gh shim 呼び出し回数 |
|--------|------|----------|------------|------------------------|
| C1: 正常ファイル | 1 バイト以上のファイル | 0 (validator 単体) / 0 (cmd_pr_ready は下流の `gh` shim 経由で進行) | なし | （正常経路: 検証ヘルパーは透過、cmd_pr_ready 本体は別ケース扱い） |
| C2: 0 バイトファイル | 0 バイトファイル | 1 | `error\tpr-ready:body-file-empty\t<path>` + 人間可読 | **0**（重要: API 未送信） |
| C3: 不在パス | 存在しないパス | 1 | `error\tpr-ready:body-file-missing\t<path>` | **0** |

既存テストファイル `tests/operations-release-pr-edit-fallback.bats` に追加:

| ケース | 入力 | 期待 exit | 期待 stderr | 期待 gh shim 呼び出し回数 |
|--------|------|----------|------------|------------------------|
| C4: fallback 経路で 0 バイト | `gh_pr_edit_body_with_fallback "123" <0 バイト>` | 1 | `error\tpr-ready:body-file-empty\t<path>` | **0** |
| C5: fallback 経路で不在 | `gh_pr_edit_body_with_fallback "123" <不在>` | 1 | `error\tpr-ready:body-file-missing\t<path>` | **0** |

`gh` shim 呼び出し回数 = 0 のアサート方法: shim 内で `printf '%s\n' "$*" >> "${GH_MOCK_CALL_LOG:-/dev/null}"` を仕込み、テスト側で `[ ! -s "$GH_MOCK_CALL_LOG" ]` を検証する（codex 指摘 #2 反映）。

## 不明点と質問

[Question] なし（責務分離・テスト戦略ともに明確）
