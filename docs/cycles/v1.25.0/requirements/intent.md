# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.25.0

## 開発の目的
AI-DLCの開発者体験（DX）を向上させる。小規模変更をより素早く開始できるエクスプレスモードのインスタント起動、フェーズ開始時の環境品質保証（プリフライトチェック・設定値一括取得）、PRレビュー自動化の改善（Codex絵文字リアクション検出）、およびスキル基盤の整理（.kiro/skills→.agents/skills移行）を実施する。

## ターゲットユーザー
AI-DLCスターターキットを使用してソフトウェア開発を行う開発者（AIエージェント含む）

## ビジネス価値
- エクスプレスモードのインスタント起動により、小規模修正の着手までの時間を短縮
- プリフライトチェックにより、セッション途中での環境起因の中断を防止
- 設定値一括取得により、設定読み飛ばしによるワークフロー不整合を防止
- Codex PRレビューの絵文字リアクション検出により、マージ前ゲートの自動化精度を向上
- .agents/skills への移行により、スキル基盤を将来の拡張に備えて整理

## 成功基準
- 「start express」コマンドで aidlc.toml の `rules.depth_level.level` を事前変更せずにエクスプレスモードが起動し、Inception→Construction が1セッションで完結する。Unit数2以上入力時は通常フローへ遷移し、フォールバック理由メッセージが表示される
- 各フェーズ（Inception/Construction/Operations）開始時にプリフライトチェックが自動実行される。チェック対象: 必須ツール存在（gh, git）、レビューツール認証状態（`rules.reviewing.tools` 設定に基づく）、aidlc.toml設定整合性。失敗時はエラー内容と対処手順をユーザーに提示する
- フェーズ初期化時に `read-config.sh --keys` で主要設定値（`rules.depth_level.level`, `rules.automation.mode`, `rules.reviewing.mode`, `rules.reviewing.tools`, `rules.squash.enabled`, `rules.linting.markdown_lint`, `rules.unit_branch.enabled`）が一括取得・提示される
- PRマージ前ゲートで `@codex review` コメントへの👍リアクションを `gh api` で取得し、レビュー完了と判定できる。👀（レビュー中）の検出もサポートする
- .kiro/skills が .agents/skills に移行され、リポジトリ内の `.kiro/skills` 参照が意図した例外（過去サイクルの履歴ドキュメント等）を除き0件である（`rg ".kiro/skills"` で検証）。破壊的変更としてCHANGELOGに明記し、アップグレード手順を提供する

## 期限とマイルストーン
特になし（通常のサイクル運用）

## 制約事項
- エクスプレスモードのインスタント起動は、aidlc.toml の設定を変更せずセッション内限定のオーバーライドとして実装する
- Unit数1の条件は維持し、Inception中にUnit数が2以上になった場合は通常フローにフォールバック（フォールバック理由をユーザーに表示）
- プリフライトチェック項目は設定で制御可能にする（将来の拡張性）
- .kiro/skills → .agents/skills の移行はディレクトリ移動と参照パス変更のみ（スキル定義形式の変更は含まない）。破壊的変更として扱い、CHANGELOGに明記しアップグレード手順を提供する
- プロンプト・テンプレートの修正は `prompts/package/` を編集する（`docs/aidlc/` は直接編集禁止）

## スコープ外
- depth_level の新レベル追加
- スキル定義形式の変更
- プリフライトチェックの自動修復機能
- 👍以外のリアクション（👎、😕等）によるレビュー判定
- .kiro/skills 互換リンクの維持（破壊的変更として完全移行する）

## 関連Issue
- #364 エクスプレスモードのインスタント起動（start express）
- #350 フェーズ初期化時に設定値を一括取得・提示する
- #347 .kiro/skills廃止と.agents/skills作成
- #336 Codex PRレビューの絵文字リアクション検出によるレビュー完了判定
- #320 セッション開始時プリフライトチェック機構（本Intentでは#320のスコープを「セッション開始時」から「各フェーズ開始時」に拡張して扱う。理由: フェーズ間でツール認証が失効する可能性があるため、フェーズ開始ごとのチェックが実用的。#320と#350は common/preflight.md として統合し、設定値一括取得はプリフライトチェックの一部として実装する）

## 不明点と質問（Inception Phase中に記録）

[Question] #350 と #320 はどちらも「フェーズ開始時」の処理追加だが、共通の仕組み（common/preflight.md）として統合するか、別々に実装するか？
[Answer] Issue #320の記載にある通り、共通化する方向（common/preflight.md）で進める。設定値一括取得はプリフライトチェックの一部として統合する。

[Question] #347 の .agents/skills ディレクトリパスは確定か？
[Answer] はい、.agents/skills で確定。
