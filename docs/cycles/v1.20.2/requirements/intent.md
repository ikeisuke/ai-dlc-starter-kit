# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit

## 開発の目的

`prompts/package/guides/` 配下の各種ガイドドキュメント（デプロイ後は `docs/aidlc/guides/` として参照される）を精査し、記述の事実誤記・陳腐化した情報・未使用ツールの記述を修正・削除する。特に `ai-agent-allowlist.md` は使用していないAIエージェント（Codex CLI、Cline、Cursor）の記述が残っているため、Claude Code と Kiro CLI のみに絞った内容に刷新する。

## ターゲットユーザー

AI-DLCスターターキットの利用者（AIエージェントを用いた開発者）

## ビジネス価値

- ガイドドキュメントの信頼性向上により、利用者が正しい設定・運用を行えるようになる
- 不要な情報を削除することで、ドキュメントの可読性と保守性が向上する

## 成功基準

- 全13ガイドファイルについて、事実誤記・陳腐化した記述がないことを確認済み
- `ai-agent-allowlist.md` から Codex CLI、Cline、Cursor の記述が削除され、Claude Code と Kiro CLI のみの内容になっている
- jj 関連の記述は非推奨（v1.19.0）のため、各ガイドから削除されている
- 各ガイドの記述が本サイクル（v1.20.2）時点の仕様と整合している
- Inception Phaseのバージョン決定前に、既存の名前付きサイクルの継続利用を確認するフローが追加されている

## 期限とマイルストーン

特になし

## 制約事項

- 編集対象は `prompts/package/guides/` 配下（メタ開発ルールに従い、`docs/aidlc/guides/` は直接編集しない。Operations Phase の rsync で反映される）
- jj サポートは非推奨（v1.19.0）であり、ガイドから jj 関連記述を削除する

## 既存機能への影響

- Codex CLI、Cline、Cursor の許可リスト設定例が削除されるため、これらのツールでAI-DLCを利用しているユーザーは自身で設定を構築する必要がある
- jj 関連記述の削除により、jj ユーザーへの案内がなくなる（v1.19.0 で非推奨化済みのため影響は限定的）
- 上記の変更は CHANGELOG に記載し、利用者に周知する

## 不明点と質問（Inception Phase中に記録）

[Question] 精査対象のガイドファイルの範囲は？
[Answer] docs/aidlc/guides/ 配下の全13ファイル

[Question] ai-agent-allowlist.md で残すAIエージェントは？
[Answer] Claude Code と Kiro CLI（ターミナル）のみ。Codex CLI、Cline、Cursor は削除

[Question] 今回のサイクルでバックログIssueを対応するか？
[Answer] いいえ、今回は対応しない
