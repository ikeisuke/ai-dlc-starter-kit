# プロジェクトルール（ai-dlc-starter-kit）

## AI エージェント振る舞いルール

### AI 自発のコンテキストリセット推奨を出さない

AI エージェント（Claude Code / Codex CLI / Gemini CLI 等）は、ユーザーからの明示的な中断・リセット指示が **ない** 場合に「コンテキスト量が長くなったため一度リセット推奨」「品質確保のため `/clear` を推奨」等の自発的な区切り提案を出してはならない。

#### 理由

- AI エージェントは現在 context window の使用量（トークン数）を直接観測する手段を持たない。「長くなった」という判断は会話履歴の見た目や tool 出力量からの推測に過ぎず、観測値に基づく根拠を提示できない
- 観測根拠のない推奨は定型句として挿入されやすく、ユーザーが必要としていない選択肢提示でフローを中断させる
- AI-DLC スキル群（`skills/aidlc/steps/common/context-reset.md`）はコンテキストリセットを **ユーザーからの明示的な中断指示**（「リセットしたい」「長くなってきた」「中断したい」等）が **トリガー** と規定している
- `steps/{construction,operations}/04-completion.md` の「コンテキストリセット提示」は `automation_mode=manual` 時のみ実行、`semi_auto` ではスキップ規定。`semi_auto` 進行中に AI が自発提案するのはこの規定と矛盾する

#### 禁止する具体的振る舞い

- Unit 完了サマリ・Phase 完了サマリの末尾に「コンテキストリセット推奨」を付記する
- 「context が長くなったため」「品質確保のため」を理由に `/clear` を勧める
- 「次のステップに進む前に一度区切りを推奨」のような区切り提案を AskUserQuestion / 平文どちらでも出力する

#### 許可される場合

以下のいずれかに該当する場合のみ提示してよい:

- **ユーザーからの明示的な中断・リセット要請**: 「リセットしたい」「長くなってきた」「コンテキストが溢れそう」「中断したい」「一時停止」「ここで止める」等。この場合は `steps/common/context-reset.md` のフローに従う
- **`automation_mode=manual` での 04-completion ステップ提示**: AI-DLC スキルの `04-completion.md` 内に明示的に規定された提示ステップ。この場合はスキル手順に従う
- **観測可能な不具合の根拠あり**: tool 出力に明確な切り詰め（`... [truncated]`）/ context window エラー / 明示的な制限超過警告等を観測した場合。観測したログ・エラーメッセージを提示根拠として併記する

観測根拠なしの自発推奨は禁止。代わりに進行状況のサマリと次アクションを提示してメッセージを終え、続行可否はユーザーに委ねる（区切り情報のみ提示してメッセージ終了する形は許可される、推奨を伴わない限り）。

#### 関連経緯

- 2026-05-16 v2.6.3 Unit 004 完了サマリで「コンテキストリセット推奨」を AI が semi_auto モードで自発提示し、ユーザーから「観測手段がないのに推奨を出している」「該当プロンプトはどこにもない」と指摘された。本ルールはその是正措置として追記された

## 設計原則

### ドッグフーディング特殊処理を本体に埋めない

本体スクリプト・ライブラリ・ツールの内部に「自リポジトリが starter kit 自身か / consumer プロジェクトか」を判定して挙動を分岐させるロジックを埋め込まない。

#### 背景

ai-dlc-starter-kit は配布物自身で開発（ドッグフーディング）するため、starter kit 自身と consumer プロジェクトの両方で同じスクリプトが実行される。両者で挙動を変えたくなる場面があるが、本体側に「starter kit リポジトリ判定」を埋め込むと以下の問題が生じる:

- 本体スクリプトの責務に「自リポジトリ構造の自己認識」が混入し、責務が肥大化する
- starter kit 側のディレクトリ構造変更が本体スクリプトの動作分岐に直接結合する（高カップリング）
- 「環境による条件分岐」は派生条件を呼び込みやすく、将来的に分岐パターンが増えて複雑度が雪だるま式に増える
- consumer プロジェクト側で偶然同名の構造を持った場合の誤検知リスクが残る

#### 採用すべき代替方針

優先順位の高い順:

1. **opt-in シグナル**: 必要なファイル・スクリプト・設定の存在自体を opt-in シグナルとして扱い、「あれば実行 / なければ skip」の汎用論理で表現する。consumer 側で何も追加しなくても自然に skip される構造を選ぶ
2. **明示的フラグ**: 環境変数 / コマンドラインオプション / 設定ファイルキーで挙動を切り替える（呼び出し側の責務として明示）
3. **wrapper 分離**: starter kit 自身に固有の追加処理が必要な場合は、本体スクリプトには入れず、starter kit 専用の別 wrapper / 別フック / 別 CI ジョブに分離する

#### 適用対象

- `skills/` 配下のスキル本体
- `bin/` 配下の汎用スクリプト
- `scripts/` 配下のヘルパースクリプト
- consumer プロジェクトに配布される全ての実行可能成果物

#### 関連経緯

- 2026-05-10 `skills/aidlc/scripts/squash-unit.sh` の CI 構造チェックで当初「starter kit 判定で fail-closed/fail-open 切替」を採用しかけたが、ドッグフーディング特殊処理に該当するため opt-in シグナル方式（チェックスクリプトの存在で自動分岐）に再設計した

## AI エージェント Bash ツール経由の安全パターン

AI エージェント（Claude Code / Codex CLI / Gemini CLI 等）が Bash ツール（subprocess 起動）を通じてシェルコマンドを実行する経路において、引数文字列内のコマンド置換が zsh `command_not_found_handler` の無限再帰を起こし `fatal error: out of memory` で AI セッションがクラッシュする既知のクラスバグがある（Issue #697 / 関連クローズ済 #688）。本リポジトリで活動する全ての AI エージェントは以下の規約に従う。

### 規約

- **コマンド置換禁止**: Bash ツール呼び出しの引数文字列に、コマンド置換構文（`$(...)` および backtick `` ` ``）を含めてはならない
- **適用範囲**: 全ての Bash ツール呼び出しの引数文字列。コミットメッセージ・PR 本文・履歴記録・外部 CLI レビュープロンプト等を含む長文プロンプトも対象
- **互換**: 個人グローバル `~/.claude/CLAUDE.md` 等でユーザーが独自に類似規約を持つ場合とは独立に、本リポジトリ規約は配布物 baseline として全 consumer プロジェクトに適用される

### 背景

zsh の `command_not_found_handler` フック内でフック自身が呼び出される（典型的には未定義関数名にマッチして自己再帰する）と、スタックフレームが無限増加して OOM クラッシュに至る。bash が引数文字列内の `$(...)` / backtick をコマンド置換として展開する際、内部に未定義コマンド（例: AI が Markdown inline code として書いた識別子）が含まれていると zsh `command_not_found_handler` が呼ばれ、ハンドラ内部で再帰展開が発生する経路が存在する。

### 安全パターン（推奨度順）

| 推奨度 | パターン | 例 |
|--------|---------|---|
| 第一推奨 | Write ツールで一時ファイルに書き出し、wrapper script で読み込んで対象コマンドに渡す | `Write` で `/tmp/foo.md` 作成 → `cmd < /tmp/foo.md` |
| 第二推奨 | `--content-file` / `--body-file` 等の file-based interface を優先使用 | `gh pr edit --body-file <file>` |
| 禁止 | コマンド置換（`$(...)` / backtick）を含む文字列を Bash ツールの引数として直接渡す | `cmd "...`backtick`..."` のような構成 |

### file-based 経路の参考表

| 用途 | file-based 経路 | 直接引数経路（非推奨） |
|------|----------------|------------------------|
| 履歴記録 | `write-history.sh --content-file <file>` | `--content "..."` |
| PR 本文 | `gh pr create / edit --body-file <file>` | `--body "..."` |
| PR Ready 化 | `operations-release.sh pr-ready --body-file <file>`（v2.6.2 Unit 001 整備済） | （該当なし） |
| 外部 CLI レビュー | `codex exec - < <file>`（stdin 経由）/ `claude -p` の wrapper script 経由 | `codex exec "..."` |

### printf -v 系 result-out 関数の local 命名規約

関数引数で結果書き込み先変数名を受け取り `printf -v "$result_var"` で書き込む関数（**result-out 関数**）は、関数内部の作業用 local 宣言を必ず関数固有プレフィックス（`_local_<関数省略名>_<名>` 形式）で namespace 化する。

- **理由**: caller と同名の local を宣言すると、bash の dynamic scope により `printf -v "$result_var"` の書き込み先が caller の変数ではなく **本関数の内部 local** になり、caller の変数が空のまま残る致命的バグを引き起こす（v2.6.2 で CI Migration Tests を停止させた実例。修正コミット da212aea）
- **検出困難性**: shellcheck SC2030 / SC2031 は subshell 由来の scope 問題には反応するが、`printf -v "$caller_var"` パターンの dynamic scope shadowing は捕捉しない。本命名規約が主防御線となる
- **適用対象**: result-out 関数の内部作業用 local、および result-out 関数を呼び出して結果を受け取る caller 側の結果受け取り用 local。`_result_var` / `_input` / `_base` 等の標準パラメータバインディング名は、関数間で一貫しており shadowing リスクがないため慣例名のまま許容する
- **適用例**: `skills/aidlc-migrate/scripts/lib/path-guard.sh` の result-out 関数群（`_aidlc_migrate_path_guard_realpath_m_into` の `_local_m_resolved` 等）

本サブセクションは規約本文の Single Source of Truth である。具体的な before/after スニペット・運用補助は `skills/aidlc/steps/common/bash-tool-safety.md` を参照する。

### codex exec の stdin 待ちガード

`codex exec` / `codex exec resume` は非対話 subprocess 環境（Bash ツール / hooks / CI 等）では、positional 引数で prompt を渡していても stdin が EOF にならない限り `Reading additional input from stdin...` で待ち続けハングする（codex-cli の設計）。非対話環境では **`</dev/null` で stdin を閉じる**（または上の参考表のとおりファイルを stdin にリダイレクトする `codex exec - < <file>`）こと。これを怠ると AI エージェントが「セルフレビューへの無自覚な降格」を起こす。

codex 非対話実行運用の規約 SoT は `skills/reviewing-common/reviewing-common-base.md` の「stdin 待ちガードルール」セクション。本記述はその横断参照である。

### 詳細運用ガイド

具体的な禁止パターンサンプル・安全パターン実装スニペット・経路別の運用例は `skills/aidlc/steps/common/bash-tool-safety.md` を参照する。本セクションは規約本文の Single Source of Truth であり、他ドキュメント（AGENTS.md / SKILL.md / steps/common/* 等）は本セクションを参照する。

### 関連 Issue

- #697（primary / feedback / v2.6.2 で本規約セクション新設）
- #688（CLOSED / v2.6.1 で `/aidlc v` 経路を CLI モード化で個別解決済 / 本規約はその一般化）
- #706（v2.6.3 / printf -v 系 result-out 関数の local 命名規約を追加）
- #703（v2.6.3 / codex exec の stdin 待ちガード横断ルールを追加 / 運用 SoT は reviewing-common-base.md）
