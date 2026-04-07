# PRFAQ: AI-DLC Starter Kit v2.2.3

## Press Release（プレスリリース）

**見出し**: AI-DLCスターターキット v2.2.3 — コンテキスト圧縮の仕上げと運用品質の強化

**副見出し**: session-state.md廃止・preflight圧縮・条件ロードスキップにより、セッション中盤のcompactionリスクをさらに低減

**発表日**: 2026-04-07

**本文**:

v2.2.0-v2.2.2で進めたコンテキスト圧縮プロジェクト（#519）のTier 1施策を完了するリリースです。不要になったsession-state.mdの廃止、preflight.mdの出力フォーマット簡略化、設定値に応じた条件ロードスキップにより、初回ロードサイズをさらに削減します。

あわせて、SKILL.mdの構造整理、ステップファイル内の不要ルール除去、Operations PhaseへのCIチェック必須化（adminマージ禁止・auto-merge対応）を実施し、AIエージェントの判断精度と品質ゲートを強化します。

## FAQ（よくある質問）

### Q1: session-state.mdを廃止して大丈夫ですか？
A: progress.mdベースの復元が全フェーズで十分に機能しており、session-state.mdは実質的に使用されていませんでした。廃止によりコンテキスト消費を約400tok削減できます。

### Q2: 条件ロードスキップは不変ルールに抵触しませんか？
A: スキップ対象はsteps/common/配下の必要時ロードファイル（review-flow.md等）のみです。フェーズステップファイル（steps/{inception,construction,operations}/）は不変ルール「ステップファイルの読み込みは省略不可」に従い、引き続き全て読み込みます。

### Q3: adminマージ禁止は既存のワークフローに影響しますか？
A: 既存のマージ方法選択（通常/Squash/Rebase）は維持されます。auto-mergeは追加オプションとして提供され、CIチェック未完了時にのみ`gh pr merge --auto`を使用します。
