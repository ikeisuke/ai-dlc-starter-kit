# Unit 005: Issue管理プロセス改善 - 計画

## 概要

Issueライフサイクル管理を明文化し、PRマージ時の自動クローズとラベル・マイルストーン活用を導入して、Issue管理の可視化と追跡性を向上させる。

## 事前確認【依存Unit】

- [x] Unit 003（label-cycle-issues.shバグ修正）が完了していること
  - ステータス: **完了済み**（2026-02-05）

## 変更対象ファイル

### 新規作成

1. `prompts/package/guides/issue-management.md` - ステータスラベル定義と運用フロードキュメント

### 修正

1. `prompts/package/prompts/inception.md` - Issue管理セクション追加、ラベル付与タイミング明記
2. `prompts/package/prompts/construction.md` - Issue管理セクション追加、ドラフトPRテンプレートに関連Issue記載欄追加
3. `prompts/package/prompts/operations.md` - Issue管理セクション追加、PRマージ時の自動クローズ説明追加
4. `prompts/package/bin/label-cycle-issues.sh` - ステータスラベル付与機能追加（軽微な修正）

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

- Issue管理の概念モデルを定義
- ステータスラベルの種類と状態遷移を設計
- 各フェーズでのIssue操作フローを整理

#### ステップ2: 論理設計

- 各プロンプトへの追加内容を設計
- ステータスラベル定義ドキュメントの構造を設計
- PR作成テンプレートの修正箇所を特定（construction.md:391-405のドラフトPRテンプレート）
- label-cycle-issues.shの修正箇所を特定

#### ステップ3: 設計レビュー

- AIレビュー実施
- ユーザー承認

### Phase 2: 実装

#### ステップ4: コード生成

1. `issue-management.md` ガイドドキュメント作成
   - ステータスラベル定義（in-progress, blocked, waiting-for-review等）
   - 各フェーズでのIssue操作フロー
   - ラベル・マイルストーンの活用方法
   - ラベル付与タイミングの詳細説明

2. `inception.md` 修正
   - Issue管理セクション追加
   - Intent/ユーザーストーリーとIssueの紐付けガイダンス
   - ユーザーストーリー作成時の関連Issue記載ルール
   - **ラベル付与タイミングの明記**（ストーリー6対応）

3. `construction.md` 修正
   - Issue管理セクション追加
   - Unit開始時のIssueステータス更新
   - **ドラフトPRテンプレート（391-405行目）に関連Issue記載欄（Closes #XX）追加**（ストーリー5対応）
   - Unit完了時のIssueステータス更新
   - **ラベル付与タイミングの明記**（ストーリー6対応）

4. `operations.md` 修正
   - Issue管理セクション追加
   - リリース時のIssueクローズ確認
   - **PRマージ時の自動クローズ説明追加**（ストーリー5対応）
   - マイルストーン完了処理
   - **ラベル付与タイミングの明記**（ストーリー6対応）

5. `label-cycle-issues.sh` 修正（軽微な修正）
   - ステータスラベル付与オプション追加（ストーリー6対応）
   - 使用例の追加

#### ステップ5: テスト生成

- プロンプト修正のため、コードテストは不要
- label-cycle-issues.shの動作確認
- ドキュメントの整合性確認

#### ステップ6: 統合とレビュー

- 全ファイルの整合性確認
- AIレビュー実施
- ユーザー承認

## 完了条件チェックリスト

### 責務（Unit定義より）

- [ ] 各フェーズでのIssue取り扱いを明文化
- [ ] PR作成時に「Closes #XX」を含めるガイダンス追加
- [ ] ステータスラベルの定義と運用フロー追加

### ストーリー4: Issueライフサイクル管理の明文化

- [ ] Inception PhaseでのIssue取り扱いが明記されている（対応Issue選択、ラベル付け）
- [ ] Construction PhaseでのIssue取り扱いが明記されている（進捗更新）
- [ ] Operations PhaseでのIssue取り扱いが明記されている（クローズ）
- [ ] 各フェーズのプロンプトにIssue管理セクションが追加されている

### ストーリー5: PRマージ時の自動クローズ

- [ ] PR作成時に「Closes #XX」を含めるガイダンスがある
- [ ] ドラフトPR作成時のテンプレートに関連Issue記載欄がある
- [ ] Operations PhaseのPRマージ手順に自動クローズの説明がある

### ストーリー6: ラベル・マイルストーン活用

- [ ] ステータスラベル（in-progress, blocked等）の定義がある
- [ ] ラベル付与タイミングがプロンプトに明記されている
- [ ] label-cycle-issues.shがステータスラベルにも対応している

### 関連Issue

- [ ] #28の要件を満たす

## 備考

- GitHub Projects連携は対象外（#31で別途検討）
- 既存のcycle-label.sh、label-cycle-issues.shの大幅な改修は対象外（ただしステータスラベル対応は軽微な修正として実施）
