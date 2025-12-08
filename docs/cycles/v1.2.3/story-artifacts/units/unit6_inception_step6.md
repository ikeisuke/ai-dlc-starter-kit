# Unit 6: Inception Phaseステップ6削除

## 概要
inception.mdからステップ6（Construction用進捗管理ファイル作成）を削除し、フェーズの責務を明確化する。

## 対象ストーリー
- US-6: Inception Phaseステップ6の削除

## 依存関係
なし

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `docs/aidlc/prompts/inception.md` | ステップ6セクション削除、完了基準修正 |
| `prompts/package/prompts/inception.md` | 同上（パッケージ版） |

## 修正内容

### ステップ6セクションの削除

削除対象（inception.md:240-250付近）:
```markdown
### ステップ6: Construction用進捗管理ファイル作成【重要】

- **ステップ開始時**: progress.mdでステップ6を「進行中」に更新
- 全Unit定義完了後、`docs/cycles/{{CYCLE}}/construction/progress.md` を作成
- **記載内容**:
  - Unit一覧（名前、依存関係、優先度、見積もり）を表形式で記録
  - 全Unitの初期状態は「未着手」
  - 次回実行可能なUnit候補（依存関係がないまたは依存Unitが完了済みのUnit）
  - 最終更新日時
- Construction Phaseで使用する進捗管理の中心ファイル
- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録
```

### 完了基準の修正

変更前:
```markdown
## 完了基準

- すべての成果物作成
- 技術スタック決定（greenfieldの場合）
- **進捗管理ファイル作成**（construction/progress.md）
```

変更後:
```markdown
## 完了基準

- すべての成果物作成（Intent、ユーザーストーリー、Unit定義）
- 技術スタック決定（greenfieldの場合）
```

### 完了時の必須作業の修正

変更前:
```markdown
各Unitで作成・変更したすべてのファイル（**inception/progress.md、construction/progress.md、history.mdを含む**）をコミット
```

変更後:
```markdown
Inception Phaseで作成・変更したすべてのファイル（**inception/progress.md、history.mdを含む**）をコミット
```

## 受け入れ基準
- [ ] inception.mdからステップ6が削除されている
- [ ] Inception Phaseが5ステップ構成になっている
- [ ] 完了基準から「construction/progress.md作成」が削除されている
- [ ] コミット対象から「construction/progress.md」が削除されている

## 見積もり
小（プロンプト修正のみ）
