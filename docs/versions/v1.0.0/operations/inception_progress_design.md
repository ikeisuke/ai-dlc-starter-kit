# Inception Phase progress.md 設計

## フォーマット案

```markdown
# Inception Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. Intent明確化 | 未着手 | requirements/intent.md | - |
| 2. 既存コード分析 | 未着手 | requirements/existing_analysis.md | - |
| 3. ユーザーストーリー作成 | 未着手 | story-artifacts/user_stories.md | - |
| 4. Unit定義 | 未着手 | story-artifacts/units/*.md | - |
| 5. PRFAQ作成 | 未着手 | requirements/prfaq.md | - |
| 6. Construction用progress.md作成 | 未着手 | construction/progress.md | - |

## 現在のステップ

次回: 1. Intent明確化

## 完了済みステップ

なし

## 次回実行時の指示

Intent明確化から開始してください。

## 最終更新

日時: YYYY-MM-DD HH:MM:SS
```

## 状態遷移

- **未着手**: まだ開始していない
- **進行中**: 作業中（成果物が部分的に作成されている）
- **完了**: 成果物が完成している

## 使い方

### 初回作成（Inception Phase開始時）
- セットアップ完了後、Inception Phaseプロンプト読み込み時に自動作成
- 全ステップが「未着手」

### 更新タイミング
- 各ステップ開始時: 状態を「進行中」に変更
- 各ステップ完了時: 状態を「完了」に変更、完了日を記録

### 再開時
- Inception Phaseプロンプト読み込み時にprogress.mdを読み込み
- 完了済みステップをスキップ
- 「進行中」または最初の「未着手」ステップから再開

## 特殊ケース

### brownfield vs greenfield
- greenfield: ステップ2（既存コード分析）をスキップ
- brownfield: 全ステップ実行

### フェーズに戻る場合（バックトラック）
- Construction PhaseからInception Phaseに戻る場合
- ステップ4（Unit定義）から再開
- 新しいUnit定義を追加
- construction/progress.mdを更新
