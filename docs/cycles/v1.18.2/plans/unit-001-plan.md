# Unit 001 計画: $()パターン排除とwrite-history.sh --content-file追加

## 概要

プロンプト内のBash実行例から`$()`コマンド置換を排除し、Claude Codeのセミオートモードが許可プロンプトなしで動作するようにする。

## 変更対象ファイル

### Phase A: write-history.sh --content-file実装 & squash-unit.sh --message-file追加
- `prompts/package/bin/write-history.sh` - `--content-file`オプション追加
- `prompts/package/bin/squash-unit.sh` - `--message-file`オプション追加

### Phase B: 主要フロー置換
- `prompts/package/prompts/common/commit-flow.md` - `git commit -m "$(cat ...)"` → Writeツール+`git commit -F`（約14箇所）、`jj describe -m "$(cat ...)"` → Writeツール+`jj describe --stdin`（2箇所）、`SQUASH_MESSAGE="$(cat ...)"` → Writeツール+`--message-file`（5箇所）
- `prompts/package/prompts/common/review-flow.md` - `--content "$(cat ...)"` → Writeツール+`--content-file`（9箇所）、`--body "$(cat ...)"` → `--body-file`（1箇所）
- `prompts/package/prompts/common/rules.md` - write-history.sh呼び出し例の更新（3箇所）。「許可パターン」定義を`--content-file`方式に書き換え、`--content`直接指定パターンも後方互換として併記。**回帰防止ルール追加**: プロンプト`.md`ファイルのBashコードブロック内で`$()`コマンド置換を使用しない旨のルールを新設
- `prompts/package/prompts/inception.md` - `--body "$(cat ...)"` → `--body-file`（1箇所）、`CURRENT_BRANCH=$(...)` → 事前にBashで取得（1箇所）
- `prompts/package/prompts/construction.md` - `--body "$(cat ...)"` → `--body-file`（3箇所）、`RESULT=$(awk ...)`（1箇所）
- `prompts/package/prompts/operations-release.md` - `--body "$(cat ...)"` → `--body-file`（2箇所）
- `prompts/package/prompts/operations.md` - Bashコードブロック内: `gh pr list --head "$(git branch ...)"` → var-pattern（1箇所）。インラインコード/説明文中の`$(ghq root)`（2箇所）は対象外
- `prompts/package/prompts/common/feedback.md` - `--body "$(cat ...)"` → `--body-file`（1箇所）
- `prompts/package/skills/upgrading-aidlc/SKILL.md` - `$(ghq root)` / `$(docs/aidlc/bin/read-config.sh ...)` → var-pattern（2箇所）

### Phase C: 横断クリーンアップ検証
- `prompts/package/`配下全体のgrep検証

## 実装計画

### Phase A: write-history.sh --content-file & squash-unit.sh --message-file実装

1. `write-history.sh`に`--content-file <filepath>`オプションを追加
2. `squash-unit.sh`に`--message-file <filepath>`オプションを追加（`--message`との排他）
3. 仕様:

| 条件 | 動作 | 終了コード |
|------|------|-----------|
| `--content-file`正常 | ファイル内容を`--content`として処理 | 0 |
| `--content`と`--content-file`同時指定 | エラー: `error:--content and --content-file are mutually exclusive` (write-history.sh既存フォーマット準拠) | 1 |
| `--content-file`に存在しないファイル | エラー: `error:file-not-found:<path>` | 1 |
| `--content-file`に空ファイル | エラー: `error:empty-file:<path>` | 1 |
| `--content-file`未指定 & `--content`指定 | 従来動作（後方互換） | 0 |
| `--message-file`正常 | ファイル内容を`--message`として処理 | 0 |
| `--message`と`--message-file`同時指定 | エラー: `Error: --message and --message-file are mutually exclusive` (squash-unit.sh既存フォーマット準拠) | 1 |
| `--message-file`に存在しないファイル | エラー: `Error: file not found: <path>` | 1 |
| `--message-file`に空ファイル | エラー: `Error: file is empty: <path>` | 1 |
| `--message-file`未指定 & `--message`指定 | 従来動作（後方互換） | 0 |
| 文字コード | UTF-8前提（変換なし） | - |

### Phase B: 主要フロー置換

**一時ファイル方針**: プロンプト内の手順では固定パスを使わず、Writeツールで一意のパスに作成し使用後に削除する旨を記述する。例: `/tmp/aidlc-commit-msg-XXXXX.txt`（AIが実行時に一意の名前を生成）

置換パターン一覧:

| 元パターン | 置換先 |
|-----------|--------|
| `git commit -m "$(cat <<'EOF'...)"` | Writeツールで一時ファイル作成 → `git commit -F <tmpfile>` → 一時ファイル削除 |
| `jj describe -m "$(cat <<'EOF'...)"` | Writeツールで一時ファイル作成 → `jj describe --stdin < <tmpfile>` → 一時ファイル削除 |
| `SQUASH_MESSAGE="$(cat <<'EOF'...)"` + `--message "$SQUASH_MESSAGE"` | Writeツールで一時ファイル作成 → `--message-file <tmpfile>` → 一時ファイル削除 |
| `--content "$(cat <<'CONTENT_EOF'...)"` | Writeツールで一時ファイル作成 → `--content-file <tmpfile>` → 一時ファイル削除 |
| `gh pr create/edit --body "$(cat <<'EOF'...)"` | Writeツールで一時ファイル作成 → `--body-file <tmpfile>` → 一時ファイル削除 |
| `CURRENT_BRANCH=$(git branch --show-current)` | 事前にBashで`git branch --show-current`を実行し変数に格納 |
| `RESULT=$(awk ...)` | 事前にBashで`awk`を実行し結果を変数に格納 |

### Phase C: 横断クリーンアップ検証

Unit定義の「対象範囲と判定手順」に従い4段階で検証:

1. 全体調査: `grep -rn '\$(' prompts/package/ --include='*.md' --include='*.sh'` で全体を把握
2. 修正対象抽出: `grep -rn '\$(' prompts/package/prompts/ prompts/package/skills/ --include='*.md'` で修正対象を一覧化
3. 分類判定: 各行がBashコードブロック内の実行例か、説明文中のインラインコード・リテラルかを目視で分類
4. 完了条件: Bashコードブロック内の実行例に含まれる`$()`が0件であること

**正本・コピー整合性**: 編集は`prompts/package/`のみ。`docs/aidlc/`はOperations Phaseのrsyncで自動同期されるため、本Unit内では`docs/aidlc/`を直接編集しない。

## 完了条件チェックリスト

- [x] write-history.shに`--content-file`オプションが追加され、ファイルからコンテンツを読み込めること
- [x] `--content`と`--content-file`の同時指定でエラー（終了コード1）が出ること
- [x] 存在しないファイル指定でエラー（終了コード1）が出ること
- [x] 空ファイル指定でエラー（終了コード1）が出ること
- [x] 既存の`--content`引数が引き続き動作すること（後方互換性）
- [x] squash-unit.shに`--message-file`オプションが追加され、ファイルからメッセージを読み込めること
- [x] squash-unit.shの`--message`と`--message-file`の同時指定でエラーが出ること
- [x] squash-unit.shの存在しないファイル指定でエラーが出ること
- [x] squash-unit.shの空ファイル指定でエラーが出ること
- [x] squash-unit.shの既存`--message`引数が引き続き動作すること（後方互換性）
- [x] commit-flow.mdの`git commit -m "$(cat ...)"` がWriteツール+`git commit -F`方式に変更されていること
- [x] commit-flow.mdの`SQUASH_MESSAGE="$(cat ...)"` が`--message-file`方式に変更されていること
- [x] review-flow.mdのwrite-history.sh呼び出しがWriteツール+`--content-file`方式に変更されていること
- [x] `prompts/package/prompts/common/rules.md`のwrite-history.sh呼び出し例が更新されていること
- [x] inception.md, construction.md, operations-release.mdの`gh pr create/edit --body`が`--body-file`方式に変更されていること
- [x] jj環境の`jj describe -m "$(cat ...)"` が同様に置き換えられていること
- [x] `prompts/package/prompts/common/rules.md`にBashコードブロック内`$()`禁止ルールが追加されていること（回帰防止）
- [x] `prompts/package/skills/upgrading-aidlc/SKILL.md`のBashコードブロック内`$()`がvar-pattern方式に変更されていること
- [x] `prompts/package/prompts/`および`prompts/package/skills/`配下の`.md`ファイルのBashコードブロック内実行例に`$()`が残っていないこと（Phase C検証合格）
