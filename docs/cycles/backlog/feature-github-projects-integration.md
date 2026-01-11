# GitHub Projects連携

- **発見日**: 2026-01-11
- **発見フェーズ**: Construction
- **発見サイクル**: v1.7.0
- **優先度**: 低

## 概要

Issue駆動バックログ管理とGitHub Projectsの連携を検討・実装する。

## 詳細

現在のUnit 005ではシンプルなラベル運用（backlog, type:, priority:, cycle:）で実装するが、将来的にはGitHub Projectsとの連携も考慮すべき。

**検討事項**:
- Projectのカスタムステータス列との連携
- Issueの自動移動（ステータス変更時）
- サイクルとProjectの紐付け

## 対応案

- Unit 005完了後、運用してみて必要性を評価
- 必要であれば将来サイクルで実装
