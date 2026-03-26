# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.22.1

## 開発の目的
AI-DLCフレームワークの開発体験改善とPRワークフロー品質向上を図る。具体的には、session-titleスキルの重複解消・外部リポジトリへの移行、スクリプトインフラの堅牢性改善（lib/ディレクトリ欠落修正、承認プロンプト頻発対策、アップグレードチェックスキップ機能）、およびPRマージ前レビューゲートの強化（ローカルレビュー追加とCodexレビュー完了待機ゲート）を実施する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者

## ビジネス価値
- session-titleスキルの重複管理コストを削減し、メンテナンス性を向上させる
- lib/ディレクトリ欠落によるセットアップ失敗を防止し、初回導入体験を改善する
- 承認プロンプト頻発の緩和によりsemi_autoモードの効果を最大化する
- アップグレードチェックスキップによりInception Phase開始の高速化を実現する
- PRマージ前のローカルレビュー追加により、push前に問題を検出し修正サイクルを短縮する

## 成功基準
- session-titleスキルがai-dlc-starter-kit側（prompts/package/skills/session-title/）から削除されていること
- session-titleスキルの参照箇所（CLAUDE.md、inception.md等）がclaude-skillsインストール案内に更新されていること
- docs/aidlc/lib/ディレクトリがaidlc-setup.shのrsync対象に含まれ、新規セットアップ時にlib/が欠落しないこと
- プロンプトファイル内のBashコードブロックに$()を含むコマンドが残存しないこと（grep検証可能）。承認プロンプト頻発の主原因は$()であり、原因除去をもって対策完了とする（発生回数はClaude Code側の挙動に依存するため定量目標は設定しない）
- aidlc.tomlに`rules.upgrade_check.skip = true`を設定するとInception Phase開始時のアップグレードチェックがスキップされること
- Operations Phase PRマージ前に/reviewとcodex review --base mainがプロンプト内の必須ステップとして定義されていること。AI-DLCはプロンプトベースのフローガイドであり、CIによる自動ブロックではなくプロンプト指示による制御とする
- Codex PRレビュー完了待機ゲートがoperations-release.mdに定義され、CHANGES_REQUESTED時は修正→再レビューフローに遷移すること

## 既存ユーザーへの影響と移行
- session-titleスキル削除: 既存ユーザーはaidlc-setupの再実行で自動的にスキル参照が更新される。session-titleはオプション機能であり、未インストールでも全フェーズの動作に影響しない
- lib/ディレクトリ修正: 既存ユーザーはaidlc-setupの再実行で自動的にlib/が配置される。修正前の環境ではread-config.sh等がエラーとなるが、再セットアップで解消する
- アップグレードチェックスキップ: 新規設定項目の追加のみ。デフォルト動作（チェック実行）は変更しない
- PRレビューゲート強化: Operations Phaseに/reviewとcodex review --base mainの必須ステップが追加される。既存のOperations Phase手順に2ステップが加わるが、push前の問題検出により修正往復は減少する見込み。rules.md（プロジェクト固有）とoperations-release.md（パッケージ側）の両方が更新対象

## 期限とマイルストーン
- Intent確定: 2026-03-15
- Unit確定: 2026-03-15
- リリース判定: 2026-03-17

## 制約事項
- session-titleスキルの統合先はclaude-skillsリポジトリ（外部）。このサイクルではai-dlc-starter-kit側の削除と参照変更のみを行う。不具合修正（#328 関係ないタブを書き換える問題）は外部リポジトリ側で対応し、本サイクルの完了条件外とする
- PRレビューゲート関連の変更は、rules.md（プロジェクト固有）とoperations-release.md（パッケージ側）の両方に影響する可能性がある
- `docs/aidlc/` は直接編集せず、必ず `prompts/package/` を編集すること（メタ開発ルール）
- #329の承認プロンプト頻発はClaude Code側の制約に依存する部分もあり、プロンプト側での対策が中心となる

## 不明点と質問（Inception Phase中に記録）

[Question] #333: session-titleスキルの統合方針
[Answer] 外部のclaude-skillsリポジトリに統合し、そこからのインストールを推奨する。ai-dlc-starter-kit側からは削除する。なくても困らないスキル。

[Question] #332と#325の関連性と統合方針
[Answer] まとめて1つのUnitとして扱う。ローカルレビューは/reviewコマンドとcodex review --base mainの2つを実行する。

## 関連Issue
- #330 docs/aidlc/lib/ディレクトリ欠落によるスクリプトエラー
- #333 session-titleスキルの重複解消: claude-skills側に統合
- #328 セッションタイトルスキルが関係ないタブを書き換える
- #331 インセプションでのアップグレードチェックスキップ機能
- #329 複数行コマンド実行時の承認プロンプト頻発
- #332 Operations Phase PRマージ前にローカルレビュー追加
- #325 PRマージ前にCodex PRレビュー完了を待つゲート
