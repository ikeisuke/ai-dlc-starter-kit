# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.24.0

## 開発の目的
Inception Phaseのワークフロー最適化と、小規模変更向けエクスプレスモードの追加を行う。エクスプレスモードはDepth Level（minimal）を拡張し、InceptionとConstructionを1セッションで完結する高速パスを提供する。エクスプレスモードの適用条件は「Unitが1つ以下」かつ「アーキテクチャ変更を含まない」変更とし、条件を満たさない場合は通常フローにフォールバックする。併せて、Inception Phaseの初期セットアップ手順の改善（rules.md確認タイミング前倒し、バージョン確認デフォルト無効化）と、メタ開発時のaidlc-setup同期タイミング最適化を実施する。

## ターゲットユーザー
AI-DLCスターターキットの利用者および開発者

## ビジネス価値
- 小規模バグ修正・ドキュメント修正時のオーバーヘッドを大幅に削減（エクスプレスモード）
- Inception Phase開始時の設定ミス早期検出（rules.md前倒し）
- 毎回のバージョンチェックの煩わしさを解消（デフォルト無効化）
- メタ開発時のaidlc-setup同期漏れリスクを低減（タイミング最適化）

## スコープ

### 対応Issue
- #359 エクスプレスモード（小規模インテント用高速パス）の追加
- #357 Inception Phaseのrules.md確認タイミングをPart 1に前倒し
- #354 Inception PhaseのAI-DLCバージョン確認をオプション化
- #352 メタ開発時のaidlc-setup同期タイミングをPR Ready化直前に移動

### In Scope
- エクスプレスモードの設計と実装（Depth Level minimal拡張、Inception+Construction統合フロー）
- inception.mdのステップ順序変更（rules.md確認をPart 1に移動）
- rules.mdのアップグレードチェック設定デフォルト値をtrueからfalseに変更
- rules.mdのカスタムワークフロー（aidlc-setup同期タイミング）をPR Ready化直前に移動

### Out of Scope
- エクスプレスモードのOperations Phase統合（将来対応）
- Depth Level体系の大規模再設計
- 新規スクリプトの追加（既存ファイルの修正のみ）

### エクスプレスモード適用不可ケース（通常フローへフォールバック）
- 複数Unitにまたがる変更
- アーキテクチャ変更を含む場合
- セキュリティ影響がある変更
- Depth Levelがstandard/comprehensiveの場合

## 成功基準
- エクスプレスモード使用時に、Unitが1つ以下の変更がIntent作成→実装完了まで1セッションで完結する
- エクスプレスモード非使用時（standard/comprehensive）の既存フローが変更なしで動作する
- rules.mdがInception Phase Part 1で読み込まれ、以降のステップで反映される
- `rules.upgrade_check.enabled` のデフォルト値が `false` となり、`true` 設定時のみバージョン確認が実行される
- メタ開発時のaidlc-setup同期がPR Ready化直前に実行される

## 制約事項
- 既存のDepth Level体系（minimal/standard/comprehensive）との後方互換性を維持。デフォルト動作（standard）は一切変更しない
- エクスプレスモード切替条件: `rules.depth_level.level = "minimal"` かつ適用不可ケースに該当しないこと
- prompts/package/ 配下を編集（docs/aidlc/ は直接編集禁止）
- エクスプレスモードはsemi_autoモードでの自動承認と整合性を保つ
- バージョン確認設定キー: `rules.upgrade_check.enabled`（Inception Phase ステップ6で評価、rules.mdが定義源）
