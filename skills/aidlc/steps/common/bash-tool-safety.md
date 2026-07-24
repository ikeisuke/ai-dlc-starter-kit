# Bash ツール経由 zsh OOM 回避 運用ガイド

AI エージェント（Claude Code / Codex CLI / Gemini CLI 等）が Bash ツール（subprocess 起動）を通じてシェルコマンドを実行する際の **運用ガイド**。本ガイドは規約本文を保持しない（規約 SoT は `CLAUDE.md` の §「AI エージェント Bash ツール経由の安全パターン」）。本ガイドはその規約を AI エージェント運用視点での具体例・禁止パターンサンプル・安全パターン実装スニペットに展開する。

## 規約の所在（SoT）

- **規約本文**: [`CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン](../../../../CLAUDE.md#ai-エージェント-bash-ツール経由の安全パターン)（唯一の Single Source of Truth）
- **AGENTS.md からの最低限の防御**: [`AGENTS.md` § Bash ツール経由の安全パターン](../../../../AGENTS.md#bash-ツール経由の安全パターン)

本ガイドは上記規約の **運用補足** であり、規約本文と齟齬が生じた場合は CLAUDE.md を優先する。

## 禁止パターンサンプル（具体例）

規約上 `CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン により禁止される構成の具体例を以下に示す。本ガイドは規範文を持たず、回避手順のみを提供する。詳細な禁止条件・適用範囲は CLAUDE.md ① セクションを参照すること。

### パターン A: コミットメッセージ内 backtick

```text
# 規約により禁止（実行不可 / 表示用） - メッセージ内の backtick がコマンド置換扱いされる
git commit -m "fix: `function_name` を修正"
```

```bash
# 回避手順 - backtick を含めない
git commit -m "fix: function_name を修正"
```

### パターン B: 長文プロンプトに inline code が混入

```text
# 規約により禁止（実行不可 / 表示用） - プロンプト内の Markdown inline code が展開対象になる
codex exec "..レビュー対象: `script_name.sh` の `option_name` 処理.."
```

```bash
# 回避手順 - 一時ファイル経由で stdin / file-based interface 使用
# 1. Write ツールで /tmp/codex-prompt.md 作成
# 2. 以下のいずれか
codex exec - < /tmp/codex-prompt.md          # stdin 経由
codex exec --json - < /tmp/codex-prompt.md   # stdin + JSON 出力
```

### パターン C: `$(...)` を含む文字列

```text
# 規約により禁止（実行不可 / 表示用） - $(...) は明示的なコマンド置換構文（AI エージェント Bash ツール経由でこの 1 行をそのまま渡してはならない）
git commit -m "release $(cat VERSION)"
```

```bash
# 回避手順 1 - 値を直接書く（最も安全 / 本ガイドの推奨）
git commit -m "release v0.0.0"

# 回避手順 2 - Write ツールで /tmp/aidlc-version.txt 作成後、本文を Read で取得 → 値を直接書く
# Write /tmp/aidlc-version.txt → Read /tmp/aidlc-version.txt → 値 "v0.0.0" を取得 → 上記回避手順 1
```

注: 一部の対話シェル向けドキュメントに掲載されている `VER=$(cat VERSION); git commit -m "release $VER"` のような変数代入パターンは、**AI エージェント Bash ツール呼び出しの 1 行引数文字列に直接含めると CLAUDE.md 規約に反する**ため、AI エージェント経由では使用しない（ローカル対話シェルでユーザーが手動入力する場合とは適用境界が異なる）。

## 安全パターン実装スニペット

### スニペット 1: Write ツール経由の一時ファイル + wrapper

AI エージェントが長文プロンプト・コミットメッセージ・PR 本文を扱う場合の標準的な手順。

1. Write ツールで一時ファイルを作成（`/tmp/aidlc-<purpose>-<timestamp>.md` 等）
2. Bash ツールで対象コマンドを `file-based interface` または stdin redirect で呼び出す
3. 必要なら最後に `rm -f <tempfile>` でクリーンアップ

```bash
# Write ツールで /tmp/aidlc-pr-body.md 作成済とする
gh pr create --title "..." --body-file /tmp/aidlc-pr-body.md
rm -f /tmp/aidlc-pr-body.md
```

### スニペット 2: 外部 CLI レビュー（codex / claude）

```bash
# Write ツールで /tmp/aidlc-review-prompt.md 作成済
codex exec -s read-only -C . --json - < /tmp/aidlc-review-prompt.md
# 反復レビュー時は resume
codex exec resume <session-id> --json - < /tmp/aidlc-review-prompt-r2.md
```

## result-out 関数の local 命名規約（運用補助）

規約本文は [`CLAUDE.md` § printf -v 系 result-out 関数の local 命名規約](../../../../CLAUDE.md#printf--v-系-result-out-関数の-local-命名規約)（Single Source of Truth）。本セクションは規範文を持たず、具体的な before/after スニペットのみを提供する。

**result-out 関数**: 関数引数で結果書き込み先変数名を受け取り `printf -v "$result_var"` で呼出側変数へ書き込む関数。

### NG: 内部 local が caller と同名（dynamic scope shadowing）

```bash
# 規約違反 - 内部 local _resolved が caller の _resolved を dynamic scope で shadowing し、
# printf -v の書き込み先が caller ではなく本関数の内部 local になる（caller 変数は空のまま）
resolve_into() {
  local _result_var="$1"
  local _resolved=""               # caller も _resolved を使うと衝突する
  _resolved="..."
  printf -v "$_result_var" '%s' "$_resolved"
}
caller() {
  local _resolved=""
  resolve_into _resolved "..."     # _resolved は空のまま残る
}
```

### OK: 内部 local を関数固有プレフィックスで namespace 化

```bash
# 規約準拠 - 内部作業用 local を _local_<関数省略名>_<名> 形式で namespace 化
resolve_into() {
  local _result_var="$1"
  local _local_ri_resolved=""      # 関数固有プレフィックスで shadowing を防ぐ
  _local_ri_resolved="..."
  printf -v "$_result_var" '%s' "$_local_ri_resolved"
}
```

`_result_var` / `_input` / `_base` 等の標準パラメータバインディング名は関数間で一貫しており shadowing リスクがないため慣例名のまま許容する。実適用例は `skills/aidlc-migrate/scripts/lib/path-guard.sh` の result-out 関数群を参照。

## 経路別 file-based interface 一覧（CLAUDE.md ① 参考表の運用補足）

CLAUDE.md ① セクション「file-based 経路の参考表」を経路ごとに具体化したもの。

| 用途 | 推奨経路 | 補足 |
|------|---------|------|
| PR 本文（作成） | `gh pr create --body-file <file>` | `--body` は短文用 |
| PR 本文（編集） | `gh pr edit --body-file <file>` | `--body` は短文用 |
| Issue 起票 | `gh issue create --body-file <file>` | `--body` は短文用 |
| 外部 CLI レビュー（codex） | `codex exec - < <file>` または `codex exec --json - < <file>` | stdin 経由（`-` は stdin を意味する codex CLI の慣習） |
| 外部 CLI レビュー（claude） | wrapper script 経由でファイル → 引数展開 | claude CLI の直接 stdin 経路がない場合の代替 |

## トラブルシューティング

### Q: Bash ツール呼び出しが OOM クラッシュした際の復旧手順

1. AI セッションを再起動
2. クラッシュ直前のコマンドを Bash ツール履歴から特定
3. 引数文字列にコマンド置換構文が混入していないか確認
4. 混入していれば本ガイド「安全パターン実装スニペット」の手順で書き直す

### Q: backtick を含むコードレビューコメントを書きたい

Markdown inline code は **コメント本文（PR 本文 / Issue 本文）に書く分には問題ない**。問題は「Bash ツールの引数文字列としてシェルに渡る経路」のみ。file-based interface（`--body-file` 等）でファイル経由にすればシェル解釈を経ないため安全。

### Q: codex exec の `--json -` 表記が分かりにくい

`-` は codex CLI が「stdin から prompt を読み込む」ことを意味する。`codex exec --json -` の後に `< /tmp/foo.md` を続けると、`/tmp/foo.md` の中身が stdin として codex に渡る。これにより、AI エージェントがプロンプトを Bash 引数として渡す経路を完全に回避できる。

## 関連参照

- 規約 SoT: [`CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン](../../../../CLAUDE.md#ai-エージェント-bash-ツール経由の安全パターン)
- 最低限の防御: [`AGENTS.md` § Bash ツール経由の安全パターン](../../../../AGENTS.md#bash-ツール経由の安全パターン)
- 関連 Issue: #697（primary）/ #688（CLOSED / v2.6.1 で `/aidlc v` 経路を個別解決済）
