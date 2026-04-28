# 論理設計: Unit 004 markdownlint PostToolUse hook 追加と Operations §7.5 削除

## 概要

`bin/check-markdownlint.sh`（新規）の I/O 契約 / 処理フロー / 検出戦略、および `.claude/settings.json` の編集差分、`operations-release.md` / `02-deploy.md` / `operations-release.sh` の削除箇所一覧を確定する。**コードは書かず**、コンポーネント構成とインターフェース定義のみを示す。

## アーキテクチャパターン

**Filter Chain + Safe-Skip**: 既存 PostToolUse hook（`bin/check-utf8-corruption.sh`）と同じパターンで、入力 JSON 解析 → 早期 return（拡張子・存在・サイズ・依存）→ 実行 → exit 0 を踏襲する。`.claude/settings.json` の hooks 配列に **別エントリ** として追加し、既存 hook と並列実行（matcher が異なるため起動タイミングは独立）。

**選定理由**:

- 既存 hook と同枠組みのため、Claude Code ランタイム側の hook 仕様を再学習せずに済む
- 並列実行の独立性により、片方の失敗が他方に波及しない（exit 0 維持の不変条件で保証）
- 拡張子による早期 return で `*.md` 以外の編集ではほぼゼロコスト

## コンポーネント構成

### レイヤー / モジュール構成

```text
.claude/
└── settings.json           [編集] PostToolUse hooks 配列に新規エントリ追加
bin/
├── check-utf8-corruption.sh    [変更なし] 既存 hook（参照のみ）
└── check-markdownlint.sh       [新規] Edit|Write の Markdown ファイル lint
skills/aidlc/
├── steps/operations/
│   ├── operations-release.md   [削除] §7.5 関連3箇所（見出し / lint bullet / auto-fix bullet）
│   └── 02-deploy.md            [削除] §7.5 サブステップ列挙削除 + ordinal 詰め
└── scripts/
    ├── operations-release.sh   [削除] lint サブコマンド5箇所
    └── run-markdownlint.sh     [変更なし] 直接呼び出し用スクリプトとして維持
```

### コンポーネント詳細

#### bin/check-markdownlint.sh（新規）

- **責務**: Edit / Write ツールで `.md` ファイル編集後に markdownlint-cli2 を実行し、違反があれば stderr で警告する。常に exit 0 を返す（編集ブロック禁止）
- **依存**: `jq` / `command` / `stat` / `markdownlint-cli2` または `npx --no-install markdownlint-cli2`（フォールバックチェーン、どちらか一方で動作）
- **公開インターフェース**: stdin から JSON 受け取り、stderr に警告出力、stdout は空、exit 0 のみ
- **不変条件**:
  - exit code は **常に 0**
  - **依存ツール不在時の出力契約（既存 `check-utf8-corruption.sh` と統一）**:
    - `jq` 不在 → stderr に `⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。` を出力（hook 機能不全の通知）→ exit 0
    - `markdownlint-cli2` 不在 → 出力なし（任意ツールの未インストールは正常状態）→ exit 0
  - その他のスキップ条件（拡張子・存在・サイズ・tool_name 不一致・file_path 空）は出力なしで exit 0

#### .claude/settings.json（編集）

- **責務**: Claude Code ランタイムに対し新規 hook を登録
- **依存**: 既存の `Write` matcher エントリと並列、独立した別エントリ
- **公開インターフェース**: hooks.PostToolUse 配列（JSON）

## インターフェース設計

### スクリプトインターフェース設計

#### bin/check-markdownlint.sh

##### 概要

PostToolUse hook として Edit / Write ツール実行直後に起動し、対象が `.md` の場合のみ markdownlint-cli2 を実行する。

##### 入力

- **stdin**: PostToolUse hook 仕様の JSON
  ```json
  {
    "tool_name": "Edit" | "Write",
    "tool_input": {
      "file_path": "path/to/file"
    }
  }
  ```

##### 引数

なし（コマンドライン引数は受け取らない）。設定情報はすべて stdin の JSON から取得する。

##### 成功時出力

```text
（stdout/stderr 両方とも空、または markdownlint-cli2 の違反警告が stderr に出力される）
```

- 終了コード: `0`（常に）
- 出力先:
  - 違反なし or スキップ（拡張子・存在・サイズ・tool_name・file_path・markdownlint-cli2 不在）: 出力なし
  - **`jq` 不在のみ**: stderr に `⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。` を出力（既存 `check-utf8-corruption.sh` と同方針）
  - 違反検出: stderr に markdownlint-cli2 の出力をそのまま流す + ヘッダ警告メッセージ

##### エラー時出力

エラー終了は存在しない（warn-only 契約）。依存不在・JSON 解析失敗等はすべて safe-skip（exit 0）。`jq` 不在時のみ stderr 警告を出すのは「hook 自体が機能しない」ことをユーザー / エージェントに通知する目的（既存 hook 踏襲）。`markdownlint-cli2` 不在時に出力しないのは Issue #609「未インストール時はスキップ」「任意ツール扱い」の方針に従う差分。

##### 使用コマンド

```bash
# Claude Code ランタイムが PostToolUse 起動時に呼び出す（手動実行は通常不要）
echo '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}' | bin/check-markdownlint.sh
```

##### 処理フロー（決定論的順序）

1. `command -v jq` 検出 → **不在なら stderr に警告 (`⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。`) を出力して exit 0**（既存 `check-utf8-corruption.sh` 踏襲）
2. stdin から JSON 読み取り → `jq -r '.tool_name // empty'` で `tool_name` 抽出
3. `tool_name` が `"Edit"` / `"Write"` 以外なら exit 0（出力なし）
4. `jq -r '.tool_input.file_path // empty'` で `file_path` 抽出 → 空なら exit 0（出力なし）
5. `[ -f "$file_path" ]` で存在確認 → 不在なら exit 0（出力なし）
6. 拡張子チェック: `case "$file_path" in *.md) ;; *) exit 0 ;; esac`（出力なし）
7. ファイルサイズ取得（macOS: `stat -f%z` / Linux: `stat -c%s`） → 1MB 超なら exit 0（出力なし）
8. **markdownlint-cli2 解決（フォールバックチェーン）**:
   - 8a. `command -v markdownlint-cli2` 検出（直接バイナリ） → 利用可能なら `markdownlint-cli2 "$file_path" >&2` を実行（高速パス）
   - 8b. 直接バイナリ不在時、`command -v npx` 検出 + `npx --no-install markdownlint-cli2 --version` で利用可能性確認 → 利用可能なら `npx --no-install markdownlint-cli2 "$file_path" >&2` を実行（プロジェクト標準: `defaults.toml` の `command = "npx markdownlint-cli2"` と整合）
   - 8c. どちらも利用不可なら出力なしで exit 0（任意ツールのため通知不要）
9. 違反有無・lint コマンド失敗に関わらず exit 0（warn-only 契約）

#### .claude/settings.json 編集差分

```diff
 "PostToolUse": [
   {
     "matcher": "Write",
     "hooks": [
       { "type": "command", "command": "bin/check-utf8-corruption.sh" }
     ]
+  },
+  {
+    "matcher": "Edit|Write",
+    "hooks": [
+      { "type": "command", "command": "bin/check-markdownlint.sh" }
+    ]
   }
 ]
```

**配置位置**: 既存 `Write` matcher エントリの後に追加（PostToolUse 配列の末尾）。

**矛盾しない理由**: matcher が異なるため、Write 編集時は両 hook が並列起動される。両者とも独立プロセスで exit 0 を返すため相互干渉なし。

#### operations-release.md 削除差分

| 行 | 削除内容 | 理由 |
|----|---------|------|
| L23 | `## 7.2〜7.6 CHANGELOG / README / 履歴 / lint / progress` の `lint /` 部分 | §7.5（lint）廃止 |
| L28 | `- operations-release.sh lint --cycle {{CYCLE}}（エラー時修正、markdownlint:skipped は設定スキップ）` 行全体 | §7.5 手順の廃止 |
| L63 | `- markdownlint で修正したその他ファイル（§7.5 で markdownlint:auto-fix が発生した場合のみ）` 行全体 | §7.5 由来のコミット対象記述廃止 |

**サブステップ番号維持方針**: §7.6 〜 §7.13 は番号変更しない。§7.5 は欠番として gap を維持。理由は plan §「リスクと注意点」参照。

#### 02-deploy.md 削除差分

| 行 | 削除内容 | 理由 |
|----|---------|------|
| L183 | `5. 7.5 Markdownlint実行` 行全体 | §7.5 廃止 |
| L179-191（列挙ordinal） | 残った12項目に 1〜12 で再採番（7.X 番号は維持し、ordinal のみ詰める） | 整合性 |

#### operations-release.sh 削除差分

| 行 | 削除内容 | 理由 |
|----|---------|------|
| L10 | `lint             ステップ 7.5 - run-markdownlint.sh 実行` ヘッダコメント行 | サブコマンド削除 |
| L44 | `print_help` 内の `lint` ステップ 7.5 行（`run-markdownlint.sh 実行`） | 同上 |
| L81-L95 | `print_help_lint()` 関数本体（13行） | サブコマンド削除 |
| L314-L348 | `cmd_lint()` 関数本体（35行） | サブコマンド削除 |
| L695-L697 | dispatcher の `lint) cmd_lint "$@" ;;` ケース3行 | サブコマンド削除 |

**`run-markdownlint.sh` 本体は不変**: ラッパー（operations-release.sh の lint サブコマンド）のみ廃止する方針。

## データモデル概要

本 Unit にはデータベーススキーマは存在しない。

### ファイル形式

- **`.claude/settings.json`**: JSON（既存形式維持、`hooks.PostToolUse` 配列に1エントリ追加）
- **stdin JSON 入力（hook 仕様）**: PostToolUse 標準形式（Claude Code ドキュメント準拠）
  ```json
  { "tool_name": string, "tool_input": object, ... }
  ```

## 処理フロー概要

### ユースケース1: ユーザー / エージェントが Markdown ファイルを編集する

**ステップ**:

1. ユーザー / エージェントが Edit または Write ツールで `.md` ファイルを編集
2. Claude Code ランタイムが PostToolUse hook を起動（matcher 一致するエントリすべて並列）
3. `bin/check-markdownlint.sh` が stdin で JSON 受信
4. 拡張子・存在・サイズ・依存ツールチェックで safe-skip 判定
5. 適格なら `markdownlint-cli2 <file>` を実行、stderr に出力
6. exit 0 で終了
7. 既存 `bin/check-utf8-corruption.sh`（matcher: Write）も同時起動するが、独立プロセスのため相互干渉なし

**関与するコンポーネント**: Claude Code ランタイム / `bin/check-markdownlint.sh` / `markdownlint-cli2` / `bin/check-utf8-corruption.sh`（独立並列）

### ユースケース2: Operations Phase 実行時の §7.5 廃止

**ステップ**:

1. AI エージェントが `02-deploy.md` のサブステップ列挙を読み取る
2. §7.5 が削除済みのため、列挙は §7.4（履歴記録）→ §7.6（progress.md 更新）と直結
3. AI エージェントが `operations-release.md` を参照する際も §7.5 関連記述が存在しないため誤呼び出しリスクなし
4. `operations-release.sh lint --cycle X` を誤って呼んだ場合は `operations-release:error:unknown-subcommand:lint` が出力されて exit 1（dispatcher の `*)` ケース）

**関与するコンポーネント**: AI エージェント / `02-deploy.md` / `operations-release.md` / `operations-release.sh`

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: hook 実行は `*.md` 編集時のみで高速（拡張子チェックで早期 return）
- **対応策**: 処理フロー先頭で jq 検出・拡張子・サイズ判定し、対象外なら数 ms 以内で exit 0

### セキュリティ

- **要件**: 既存 hook 枠組み踏襲（影響なし）
- **対応策**: stdin の JSON は jq でパース、シェルインジェクション余地なし。`file_path` を変数展開する際は必ず double-quote で囲む（`"$file_path"`）

### スケーラビリティ

- **要件**: 影響なし
- **対応策**: hook は1編集ごとに起動・破棄される transient プロセスのため、状態管理不要

### 可用性

- **要件**: `markdownlint-cli2` 未インストール環境でも編集動作をブロックしない
- **対応策**: `command -v markdownlint-cli2` で検出、不在なら exit 0。`jq` も同様に safe-skip

## 技術選定

- **言語**: Bash（既存 `bin/check-utf8-corruption.sh` と同じ）
- **依存ツール**: `jq`（必須・safe-skip 対象）, `markdownlint-cli2` または `npx --no-install markdownlint-cli2`（任意・フォールバックチェーン、両方不在で safe-skip）, `stat`（macOS / Linux 両対応）
- **データベース**: なし

## 実装上の注意事項

- **シェル安全性**: `set -euo pipefail` を冒頭で設定（既存 hook と同じ）
- **macOS / Linux 互換**: `stat -f%z`（macOS）/ `stat -c%s`（Linux）の両方を試行（`||` で fallback）
- **既存 hook の破壊禁止**: `.claude/settings.json` 編集時、既存 `Write` matcher エントリの構造を変更しない（追加のみ）
- **JSON 構文チェック**: 編集後に `jq . .claude/settings.json > /dev/null` で構文確認
- **実行権限**: `bin/check-markdownlint.sh` 作成後 `chmod +x` を実行
- **hook 命名規約（design.md 補足）**:
  - **現行規約**: `bin/check-<domain>.sh`（例: `check-utf8-corruption.sh`, `check-markdownlint.sh`）。簡潔で発火点（PostToolUse / PreToolUse）は名前に含めない
  - **将来拡張案**: PostToolUse / PreToolUse 双方の hook が増えた場合、`check-<domain>-posttooluse.sh` のように発火点を含める命名に拡張可能。ただし本 Unit では現行規約を維持し、必要が生じた時点で別 Unit / Issue として議論する
  - **凝集の観点**: PostToolUse 専用とわかる接尾辞は将来の hook 増加時に有効だが、現状（hook 2件）では過剰な命名となるため避ける

### 検証方針（実装後）

#### 検証マトリクス

| 観点 | 検証手順 | 期待結果 |
|------|----------|----------|
| matcher 起動範囲（Edit） | Edit ツールで `*.md` ファイル編集（テスト用） | hook 起動・違反検出時 stderr 警告 |
| matcher 起動範囲（Write） | Write ツールで `*.md` ファイル新規作成 | hook 起動・違反検出時 stderr 警告 |
| 拡張子別動作（非 .md） | Edit で `*.sh` / `*.md.sample` を編集 | hook がスキップ（stderr 出力なし） |
| markdownlint-cli2 未インストール | `PATH=/usr/bin` で hook を直接実行（jq は存在） | stderr 出力なし、exit 0 |
| jq 未インストール | `PATH=/usr/bin` で hook を直接実行（jq 不在） | stderr に `⚠ check-markdownlint: jq が見つかりません。hookが動作不能です。` 出力、exit 0（既存 `check-utf8-corruption.sh` 踏襲） |
| 既存 hook 連鎖 | Write で `*.md` 編集（U+FFFD 含む） | 両 hook が並列実行、相互干渉なし |
| §7.5 削除整合（運用対象） | `grep -rn "§7\.5\|operations-release\.sh lint\|7\.5 Markdownlint" skills/ .claude/` | ヒット 0 件 |
| §7.5 削除整合（履歴保護） | `grep -rn "§7\.5\|operations-release\.sh lint\|7\.5 Markdownlint" .aidlc/cycles/` | ヒットがあった場合、すべて履歴保護対象配下のみ。許容範囲: 過去サイクル `.aidlc/cycles/v*/` 配下の `history/` `plans/` `design-artifacts/` `story-artifacts/` `inception/` `construction/`、および本サイクル `v2.4.3/` 配下の `plans/` `history/` `design-artifacts/` `inception/` `construction/`（運用ファイル `skills/` `.claude/` への混入がないこと） |
| dispatcher 削除確認 | `skills/aidlc/scripts/operations-release.sh lint --cycle test` | `operations-release:error:unknown-subcommand:lint` (exit 1) |

## 不明点と質問（設計中に記録）

[Question] hook の stderr 出力は Claude Code エージェントのコンテキストに自動取り込みされるか？
[Answer] Claude Code は PostToolUse hook の stderr 出力を system-reminder としてエージェントに表示する仕様（公式ドキュメント準拠）。本 Unit はこの仕様に依存せず、ユーザーが目視確認することも前提とする。仕様変更時の影響は別 Unit / Issue で議論。

[Question] `markdownlint-cli2` が `npx --no-install` でしか呼べない環境への対応は？
[Answer] 本 Unit のスコープに **含まれる**（Phase 2 検証で発見し fallback として追加）。本リポジトリは `skills/aidlc/config/defaults.toml` に `command = "npx markdownlint-cli2"` と定義されており、プロジェクト標準は npx 経由インストール。フォールバックチェーン（`direct binary` → `npx --no-install markdownlint-cli2 --version` 検出 → 両方不在で safe-skip）を実装し、論理設計 §処理フロー ステップ8a/8b/8c に明記。両方利用不可時は出力なしで exit 0（Issue #609「未インストール時はスキップ」と整合）。

[Question] 並列起動された複数 hook の出力が混在する可能性は？
[Answer] Claude Code ランタイムが各 hook を独立プロセスで起動する想定。stderr が時間的に交錯する可能性はあるが、両 hook とも先頭にヘッダ的な目印（既存: `⚠ UTF-8文字化け検出` / 新規: `⚠ markdownlint 違反` 等）を出すことで識別可能。実装時に既存 hook のヘッダ形式を踏襲する。
