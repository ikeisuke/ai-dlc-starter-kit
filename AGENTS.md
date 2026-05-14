# AGENTS.md

本リポジトリで活動する AI エージェント（Codex CLI / Gemini CLI 等の AGENTS.md 参照 AI、および Claude Code 等の CLAUDE.md 参照 AI）に共通する規約のエントリポイント。

## Bash ツール経由の安全パターン

詳細は [`CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン](./CLAUDE.md#ai-エージェント-bash-ツール経由の安全パターン) を参照。

最低限守るべき 3 項目:

- コマンド置換構文（`$(...)` および backtick `` ` ``）を Bash ツール呼び出しの引数文字列に含めない
- 長文プロンプトは file-based interface（`--content-file` / `--body-file` 等）または Write ツール経由の一時ファイルで渡す
- `codex exec` / `codex exec resume` は非対話 subprocess 環境で `</dev/null` を付与する（stdin 待ちハング回避 / 詳細 SoT は [`skills/reviewing-common/reviewing-common-base.md`](./skills/reviewing-common/reviewing-common-base.md) の「stdin 待ちガードルール」）

違反は zsh `command_not_found_handler` の無限再帰による OOM クラッシュ、または codex の stdin 待ちハングを誘発し、AI セッションを停止・空転させる既知のクラスバグ（Issue #697 / 関連クローズ済 #688 / #703）。

## 関連規約

- [`CLAUDE.md` § 設計原則 § ドッグフーディング特殊処理を本体に埋めない](./CLAUDE.md#ドッグフーディング特殊処理を本体に埋めない)
- [`CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン](./CLAUDE.md#ai-エージェント-bash-ツール経由の安全パターン)（規約 SoT）
- 詳細運用ガイド: [`skills/aidlc/steps/common/bash-tool-safety.md`](./skills/aidlc/steps/common/bash-tool-safety.md)
- codex 非対話実行運用 SoT: [`skills/reviewing-common/reviewing-common-base.md`](./skills/reviewing-common/reviewing-common-base.md) の「stdin 待ちガードルール」
