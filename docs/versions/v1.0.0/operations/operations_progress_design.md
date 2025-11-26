# Operations Phase progress.md 設計

## フォーマット案

```markdown
# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. デプロイ準備 | 未着手 | operations/deployment_checklist.md | - |
| 2. CI/CD構築 | 未着手 | operations/cicd_setup.md | - |
| 3. 監視・ロギング戦略 | 未着手 | operations/monitoring_strategy.md | - |
| 4. 配布 | 未着手 | operations/distribution_plan.md | - |
| 5. リリース後の運用 | 未着手 | operations/post_release_operations.md | - |

## 現在のステップ

次回: 1. デプロイ準備

## 完了済みステップ

なし

## 次回実行時の指示

デプロイ準備から開始してください。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: ステップ4（配布）を実施
- Web/バックエンド（web/backend/general）: ステップ4（配布）をスキップ

## 最終更新

日時: YYYY-MM-DD HH:MM:SS
```

## 状態遷移

- **未着手**: まだ開始していない
- **進行中**: 作業中（成果物が部分的に作成されている）
- **完了**: 成果物が完成している
- **スキップ**: プロジェクト種別により不要（モバイル以外の配布など）

## 使い方

### 初回作成（Operations Phase開始時）
- Construction Phase完了後、Operations Phaseプロンプト読み込み時に自動作成
- 全ステップが「未着手」
- プロジェクト種別に応じて、配布ステップを「スキップ」に設定

### 更新タイミング
- 各ステップ開始時: 状態を「進行中」に変更
- 各ステップ完了時: 状態を「完了」に変更、完了日を記録

### 再開時
- Operations Phaseプロンプト読み込み時にprogress.mdを読み込み
- 完了済み・スキップステップをスキップ
- 「進行中」または最初の「未着手」ステップから再開

## 特殊ケース

### プロジェクト種別による差異
- `PROJECT_TYPE` が ios/android: 全ステップ実行
- `PROJECT_TYPE` が web/backend/general: ステップ4（配布）をスキップ

### フェーズに戻る場合（バックトラック）
- Operations PhaseからConstruction Phaseに戻る場合
- バグ修正後、Operations Phaseに戻る
- 既存のprogress.mdを読み込んで、未完了ステップから再開

### スターターキット本体の場合
- このプロジェクト（AI-DLC Starter Kit）のように、デプロイ対象がない場合
- 主要な作業はバージョン管理とドキュメント整備
- 各ステップは最小限に調整（operations_plan.mdで定義）
