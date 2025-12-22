# ドラフトPRベースの並行作業ワークフロー

- **発見日**: 2025-12-22
- **発見フェーズ**: Operations
- **発見サイクル**: v1.5.1
- **優先度**: 中

## 概要

同時進行しやすいように、Inception時にドラフトPRを作成し、各UnitはそのドラフトPRのブランチに対してPRを作成するフローを導入する。

## 詳細

### 現在のフロー
1. サイクルブランチで全Unitを実装
2. Operations Phase完了時にmainへのPRを作成
3. PRマージ

### 提案するフロー
1. Inception Phase完了時にmainへのドラフトPRを作成
2. 各UnitはサイクルブランチからUnit用ブランチを切り、サイクルブランチに対してPRを作成
3. Operations PhaseもサイクルブランチにPRを作成
4. 最終的にドラフトPRをReady for Reviewに変更してマージ

### 期待される効果
- 複数人（または複数セッション）での並行作業が容易になる
- Unit単位でのレビューが可能になる
- 進捗が可視化される

## 対応案

- Inception Phase プロンプトにドラフトPR作成ステップを追加
- Construction Phase プロンプトにUnit完了時のPR作成ステップを追加
- Operations Phase プロンプトの最終PRをドラフトPRのReady化に変更
- ブランチ命名規則を定義（例: `cycle/v1.x.x`、`cycle/v1.x.x/unit-001`）
