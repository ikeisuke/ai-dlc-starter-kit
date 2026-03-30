# Unit 003 計画: セッション判別手段

## 概要
Claude Code環境でのセッション判別のため、既存のターミナルエスケープシーケンス方式（`printf '\033]0;...\007'`）をosascript + iTerm2バッジ方式に置換する。

## 変更対象ファイル
- `prompts/package/bin/aidlc-session-title.sh` - 新規作成
- `prompts/package/prompts/inception.md` - ステップ1.5
- `prompts/package/prompts/construction.md` - ステップ2.6
- `prompts/package/prompts/operations.md` - ステップ2.6

## 実装計画

### 方式確定

**実機検証済み**:
- osascript（Apple Events）でiTerm2のタブタイトル変更: 動作確認済み
- 親プロセスTTYデバイスへのiTerm2バッジ用エスケープシーケンス書き込み: 動作確認済み

**採用方式**: osascript（タブタイトル）+ TTY書き込み（バッジ）の併用

| 機能 | 方式 | 対象 |
|------|------|------|
| タブタイトル | osascript（Apple Events） | iTerm2 / Terminal.app |
| 背景バッジ | iTerm2固有エスケープシーケンス（`\033]1337;SetBadgeFormat`）→ 親TTY書き込み | iTerm2のみ |
| フォールバック | TTY直接書き込み（`\033]0;...\007`） | 上記以外のターミナル |
| 最終フォールバック | コンソール出力 | すべて失敗時 |

### スクリプト設計

ファイルパス: `prompts/package/bin/aidlc-session-title.sh`

引数: `<project_name> <phase> <cycle>`

処理フロー:
1. 引数からタイトル文字列を組み立て: `{project_name} / {phase} / {cycle}`
2. `TERM_PROGRAM` を判定
3. iTerm2の場合:
   - osascriptでタブタイトル設定
   - 親プロセスTTYを探索し、バッジ設定
4. Terminal.appの場合:
   - osascriptでタブタイトル設定
5. その他:
   - 親プロセスTTYを探索し、エスケープシーケンスでタイトル設定
6. すべて失敗時: exit 0（エラーでフロー停止しない）

### 各フェーズプロンプトの修正

ステップ1.5/2.6を以下に置換:

**セクション名変更**: 「セッションタイトル設定」→「セッション判別設定」

1. スクリプトパスを決定（存在確認順）:
   - `prompts/package/bin/aidlc-session-title.sh`（ソース環境）
   - `docs/aidlc/bin/aidlc-session-title.sh`（デプロイ後環境）
2. スクリプトが見つかった場合: `bash {script_path} "{project.name}" "{Phase}" "{CYCLE}"` を実行
3. スクリプトが見つからない場合: 従来のprintfコマンドをフォールバックとして実行
4. エラー時はスキップして続行

## 完了条件チェックリスト
- [ ] スクリプト（`prompts/package/bin/aidlc-session-title.sh`）が作成されている
- [ ] iTerm2: タブタイトル変更（osascript）+ 背景バッジが設定される
- [ ] Terminal.app: タブタイトル変更（osascript）が設定される
- [ ] その他ターミナル: TTY直接書き込みでタイトル設定が試行される
- [ ] inception.mdのステップ1.5が更新されている
- [ ] construction.mdのステップ2.6が更新されている
- [ ] operations.mdのステップ2.6が更新されている
- [ ] エラー時にフロー停止しない（常にexit 0）
