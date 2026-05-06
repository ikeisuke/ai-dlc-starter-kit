# リリース後の運用記録（v2.5.2）

## リリース情報

- **バージョン**: v2.5.2
- **リリース日**: 2026-05-06
- **リリース内容**: v2.5.1 メタ振り返りで顕在化した 4 つの構造的課題を統合解消する patch リリース
  - Unit 001: review-flow 5R 化 + defer 自動 Issue 起票 + Round 4+ 新領域 backlog 化
  - Unit 002: Construction Unit 完了時 CI 構造チェック強化（skill-references / bash-substitution / test-isolation）
  - Unit 003: AIDLC_PROJECT_ROOT 横断リファクタ（producer/consumer 統一、`aidlc-paths.sh` helper 新規）
  - Unit 004: Operations Phase 7.12 PR レビュー反映コミット squash 統合

## 運用状況

### 稼働状況

- **配布形態**: GitHub リポジトリとしての公開（`ai-dlc-starter-kit`）
- **配布対象**: AI-DLC を採用するダウンストリームプロジェクト（プラグイン経由のセットアップ）
- **稼働率 / ダウンタイム / インシデント**: N/A（CLI ツール / Skill プラグインのため）

### パフォーマンス

- **対象外**: スタンドアロンの CLI ツール / プロンプト集合のため、レスポンスタイム / リクエスト数の概念は適用外

## バグ対応

### 修正済みバグ

- #639 Operations Phase で 7.12 PR レビュー反映コミットが squash されずに merge される — Unit 004 で解決
- #631 retrospective-resend.sh spool path AIDLC_PROJECT_ROOT 対応 — Unit 003 で解決
- #632 predecessor-issue.sh fallback path AIDLC_PROJECT_ROOT 対応 — Unit 003 で解決

### 未修正バグ

- バックログ（GitHub Issue `label:backlog state:open`）参照

## 改善点の洗い出し

### 構造的改善（本サイクルで完了）

- review-flow の千日手回避（5R 上限 + 完了条件「最後 2R 連続ゼロ or defer」）
- Construction Unit 完了時の構造的退行検出（CI チェック 3 種を必須化）
- 別リポ運用時の path 不整合の根本解消（producer/consumer 両側を `aidlc-paths.sh` 経由に統一）
- Operations 7.12 PR レビュー反映コミットの履歴汚染防止（squash 統合サブステップ）

## 次期バージョンの計画

### 対象バージョン

未定（次サイクルの Inception で決定）

### 計画候補（オープンバックログから抜粋）

- #645 OUT_OF_SCOPE Issue 自動起票後のユーザー通知タイミング設計
- #644 retrospective-resend.sh の cycle 自動決定を AIDLC_PROJECT_ROOT 対応に
- #643 predecessor-issue.sh の retrospective-issue.sh 横依存解消
- #640 config.toml の重複・deprecated セクション整理
- #629 PR マージ確認前にそのサイクルのまとめサマリを表示
- その他 backlog に登録済みの中優先度 Issue 多数

### スケジュール

- **計画開始**: 次サイクル開始時に決定
- **リリース予定**: 次サイクル完了時

## 備考

- 本サイクルは review-flow 5R 化（Unit 001）を自身に対して自己適用しており、User Stories 9R / Unit 定義 7R で「最後 2R 連続ゼロ」完了条件の妥当性が実証された
- メタ開発プロジェクト（AI-DLC スターターキット自体を AI-DLC で開発）の特性上、運用記録は CLI ツール配布の文脈で記録する
