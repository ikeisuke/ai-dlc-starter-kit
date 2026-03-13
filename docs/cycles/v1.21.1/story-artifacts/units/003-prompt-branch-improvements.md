# Unit: プロンプトブランチ管理改善

## 概要
Inception Phase・Operations Phaseのプロンプトを改善し、main最新化チェックの表示、非正規ブランチ時のサイクルブランチ提案、名前付きサイクル候補表示を実装する。

## 含まれるユーザーストーリー
- ストーリー1b: Inception Phaseでのmain最新化チェック表示（#307）
- ストーリー1c: Operations Phaseでのmain最新化チェック（#307）
- ストーリー3: 非正規ブランチ時のサイクルブランチ提案（#303）
- ストーリー5: Inception時の名前付きサイクル候補表示（#302）

## 関連Issue
- #307, #303, #302

## 責務
- inception.md ステップ7: main最新化チェック結果の表示追加、非正規ブランチ判定の拡張（detached HEAD含む）
- inception.md ステップ5.5: 名前付きサイクル候補表示の追加（既存名の昇順リスト＋新規作成オプション）
- operations-release.md: mainとの差分チェックステップの追加
- ステップ5.6との重複整理

## 境界
- setup-branch.shの判定ロジック自体の修正は含まない（Unit 002で完了済み前提）

## 依存関係

### 依存する Unit
- Unit 002: main最新化チェック判定ロジック（依存理由: setup-branch.shのステータス出力が必要）

### 外部依存
- なし

## 非機能要件（NFR）
- なし（プロンプトファイルの変更のみ）

## 技術的考慮事項
- inception.md ステップ7の変更が最も大きい（非正規ブランチ判定＋main最新化チェック表示）
- ステップ5.5と5.6の統合整理: 候補表示をステップ5.5に統一し、5.6は継続確認のみに絞る
- operations-release.mdへの差分チェック追加は既存のvalidate-git.shの流れに合わせる
- 変更対象は `prompts/package/prompts/` 配下（メタ開発ルール）
- Unit 002完了後に着手（Unit 001とは独立）。Unit 004/005とは並行実装可能

## サブスコープDone条件

### A) Inception Phase ステップ7改善（ストーリー1b, 3）
- [ ] main最新化チェック結果（main_status行）がステップ7で表示される
- [ ] fetch-failed時の情報メッセージが表示される
- [ ] 非正規ブランチ（cycle/vX.X.X以外）でAskUserQuestionが表示される
- [ ] detached HEADでもAskUserQuestionが表示される
- [ ] main/masterブランチでは従来の処理が維持される

### B) Inception Phase ステップ5.5改善（ストーリー5）
- [ ] mode=namedで既存名前付きサイクル名が選択肢に昇順表示される
- [ ] 「新規作成」オプションが最後に含まれる
- [ ] docs/cycles/ 読み取り失敗時は自由入力にフォールバックする

### C) Operations Phase改善（ストーリー1c）
- [ ] operations-release.mdにmainとの差分チェックステップが追加される
- [ ] 差分ありの場合マージ/リベース推奨が表示される
- [ ] fetch-failed時の情報メッセージが表示される

## 実装優先度
High

## 見積もり
中（タスク数: プロンプト3ファイル×サブスコープ3つ = 計5箇所の修正。inception.mdのステップ7が最大の変更点）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-13
- **完了日**: 2026-03-13
- **担当**: @ikeisuke
