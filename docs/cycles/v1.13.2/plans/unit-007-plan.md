# Unit 007 実装計画: progress.md更新タイミング修正

## 概要

Operations Phaseのステップ6完了時にprogress.mdの「完了」更新がPRマージに含まれるよう、更新タイミングを修正する。

## 問題点

現在のoperations.mdでは、ステップ6の最後（6.7 PRマージ後）に「ステップ完了時: progress.mdでステップ6を「完了」に更新」と記載されている。この配置では、progress.mdの更新がPRマージの**後**に行われるため、main ブランチにマージされるPRにprogress.mdの更新が含まれない。

## 変更対象ファイル

- `prompts/package/prompts/operations.md`

## 実装計画

### 修正内容

1. **サブステップ一覧に「6.4.5 progress.md更新」を追加**
   - 6.4 Markdownlint実行と6.5 Gitコミットの間に挿入

2. **新規セクション「#### 6.4.5 progress.md更新」を追加**
   - 6.4 Markdownlint実行セクションの後に追加
   - progress.mdでステップ6を「完了」に更新し、完了日を記録する内容

3. **6.7 PRマージセクションの最後にある「ステップ完了時」記述を削除**
   - 816行付近の記述を削除（6.4.5に移動するため不要）

### 修正箇所の詳細

**サブステップ一覧（569-579行付近）**:
```markdown
**サブステップ一覧**（順番に実行）:
1. 6.0 バージョンファイル更新（AI-DLCスターターキットのみ）
2. 6.1 CHANGELOG更新（`changelog = true` の場合）
3. 6.2 README更新
4. 6.3 履歴記録
5. 6.4 Markdownlint実行
6. 6.4.5 progress.md更新  ← 追加
7. 6.5 Gitコミット
8. 6.6 ドラフトPR Ready化
9. 6.6.5 コミット漏れ確認  ← 既存
10. 6.7 PRマージ
```

**新規セクション（6.4の後に挿入）**:
```markdown
#### 6.4.5 progress.md更新

progress.mdでステップ6を「完了」に更新し、完了日を記録します。

**更新内容**:
- ステップ6の状態: 進行中 → 完了
- 完了日: 現在日付（YYYY-MM-DD形式）

**注意**: この更新をGitコミットに含めることで、PRマージ後のmainブランチでprogress.mdが正確な状態を反映します。
```

**削除対象（816行付近）**:
```markdown
- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録
```

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/operations.md` のステップ6フロー内で、progress.md更新タイミングをPRマージ前（Gitコミット前）に移動
- [ ] サブステップ一覧に「6.4.5 progress.md更新」が追加されている
- [ ] 新規セクション「#### 6.4.5 progress.md更新」が追加されている
- [ ] 元の「ステップ完了時」記述が削除されている

## 影響範囲

- Operations Phaseのステップ6のみ
- 他のフェーズ（inception.md, construction.md）には影響なし
