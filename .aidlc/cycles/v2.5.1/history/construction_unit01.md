# Construction Phase 履歴: Unit 01

## 2026-05-05T08:39:21+09:00

- **フェーズ**: Construction Phase
- **Unit**: 01-feedback-mode-config-and-wizard（feedback_mode 5値拡張 + マイグレーション + 初回 wizard）
- **ステップ**: Unit完了
- **実行内容**: # Construction Unit 001 履歴: feedback_mode 5 値拡張 + マイグレーション + 初回 wizard

## 概要

v2.5.0 の 3 値 feedback_mode（silent / mirror / disabled）を v2.5.1 の 5 値（interactive / local-issue-only / mirror-only / local-and-mirror / disabled）に拡張。Operations 04-completion §1.5 から呼び出される初回 wizard 関数 / マイグレーション写像処理 / cap 判定関数 / mode 解決関数を Unit 002 〜 004 が依存する共有契約として提供。

## Phase 1: 設計

- ドメインモデル: FeedbackMode / LegacyFeedbackMode / FeedbackModeMapping / Environment / FeedbackModeResolution / FeedbackModeWizardRequirement / FeedbackCapScope / FeedbackCapDecision / FeedbackModeMigration（集約） / 4 ドメインサービス / 2 リポジトリ
- 論理設計: skills/aidlc/scripts/lib/feedback-mode.sh + feedback-mode-wizard.sh、skills/aidlc-migrate/scripts/migrate-feedback-mode.sh、3 層責務分離（decide / apply / backup-rollback）、互換アダプタ層（retrospective-generate.sh / retrospective-mirror.sh）
- exit code 体系統一（0=成功+警告 / 1=ランタイム異常 / 2=引数エラー）、stderr フォーマット <level>\t<code>\t<detail>
- 計画レビュー: codex 5 件指摘（高 1 / 中 3 / 低 1）→ 全件解消
- 設計レビュー: codex 7 件指摘（高 3 / 中 4）→ 修正後再評価で 2 件追加 → 全件解消

## Phase 2: 実装

- 新規: feedback-mode.sh / feedback-mode-wizard.sh / migrate-feedback-mode.sh
- 変更: defaults.toml（5 値 enum + 既定 interactive）/ retrospective-schema.yml（valid_feedback_modes 拡張）/ migrate-apply-config.sh（feedback_mode_migrate リソース処理 + exit 1 伝播）/ retrospective-generate.sh / retrospective-mirror.sh（互換アダプタ層化）
- AIDLC_FORCE_INTERACTIVE エスケープハッチ（テスト用 tty 検査バイパス）
- コードレビュー: codex 4 件指摘（高 1 / 中 2 / 低 1）→ 全件解消

## テスト

- tests/feedback-mode-wizard.bats: 33 件
- tests/feedback-mode-migration.bats: 14 件
- tests/feedback-cap-by-mode.bats: 14 件
- tests/retrospective/feedback-mode-resolution.bats: 既存 F1-F4 更新 + 新 F5-F7 追加（計 7 件）
- 統合レビュー: codex 3 件指摘（中 2 / 低 1）→ 全件解消（accepted/rejected 対話分岐テスト / wizard 成功経路テスト / dasel 不在フォールバック修正）
- 全テスト 260 件 通過

## 意思決定記録（v2.5.1 サイクル decisions.md に追記）

- DR-009: wizard 対話手段を AskUserQuestion ではなく `read -p` に固定
- DR-010: マイグレーション適用経路を manifest 拡張（resource_type=feedback_mode_migrate）に固定

## 完了条件達成

Unit 責務 6 / Issue #627 受け入れ基準 3 / Intent 成功基準 5 / NFR 3 / 境界・責務 3 = 計 20 項目 すべて達成。

## 関連 Issue

- #627: retrospective 自動生成の起票先選択 wizard 化（feedback_mode 拡張）— Unit 001 範囲完了

---
