# 実装記録: Unit 001 バックログモード読み込み修正

## 概要

aidlc.tomlの`[backlog].mode`設定を各フェーズプロンプトで正しく読み込み、モードに応じた処理分岐を実現する修正を実施。

## 修正内容

### 1. setup.md

- **追加箇所**: ステップ0.7（バックログモード確認）を新規追加
- **内容**: backlog.mode設定の読み込みとGitHub CLI認証確認

### 2. construction.md

- **修正箇所**: 気づき記録フロー
- **内容**: mode分岐を追加（git→ファイル作成、issue→Issue作成案内）

### 3. inception.md

- **修正箇所**: バックログ確認セクション
- **内容**: mode分岐を追加（git→ls、issue→gh issue list）

### 4. operations.md

- **修正箇所**: バックログ整理（5.1）、バックログ記録（3）
- **内容**: 両セクションにmode分岐を追加

## 技術的決定事項

1. **暫定版パターン使用**: 設定読み込みパターンには既知の問題があり、Unit 004で改善予定
2. **両方確認の維持**: 安全策としてmode設定に関わらず両方（ファイル/Issue）を確認
3. **フォールバック**: mode=issueでもGitHub CLI未認証時はgitにフォールバック

## AIレビュー結果

- Codex MCPによるレビュー実施
- 設定読み込みパターンの問題点を指摘→Unit 004で対応
- 片方のみ確認オプション→バックログに記録

## テスト

- Markdownlint: エラーなし

## 関連ファイル

- 設計: `docs/cycles/v1.7.1/design-artifacts/domain-models/001-backlog-mode-fix_domain_model.md`
- 設計: `docs/cycles/v1.7.1/design-artifacts/logical-designs/001-backlog-mode-fix_logical_design.md`
- 計画: `docs/cycles/v1.7.1/plans/unit-001-backlog-mode-fix.md`

## 完了日

2026-01-11
