# Unitブランチ作成時にPRが作成されない

- **発見日**: 2025-12-28
- **発見フェーズ**: Inception
- **発見サイクル**: v1.5.3
- **優先度**: 高

## 概要

Construction Phase でブランチを分けて処理する際に、PRが自動作成されない問題がある。

## 詳細

**現状の問題**:
- Unit単位でブランチを作成して作業する場合、PRが自動作成されていない
- ユーザーが手動でPRを作成する必要がある

**期待する動作**:
- Unitブランチ作成時にドラフトPRを自動作成
- または、Unit完了時にPRを作成する案内を表示

## 対応案

### Construction Phase のプロンプトに追加

Unit作業開始時のフローを確認し、PR作成ロジックを追加:

1. Unitブランチ作成時:
   - GitHub CLI が利用可能な場合、ドラフトPRを自動作成
   - PR タイトル: `[Unit] {Unit名}`
   - PR 本文: Unit定義から概要を抽出

2. Unit完了時:
   - PRが存在しない場合は作成を案内
   - 既存PRがある場合はReady for Reviewに変更

## 影響範囲

- prompts/package/prompts/construction.md

## 備考

このバックログは v1.5.3 の Inception Phase 中に追加されました。
