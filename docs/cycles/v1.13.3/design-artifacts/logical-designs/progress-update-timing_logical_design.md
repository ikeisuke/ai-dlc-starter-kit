# 論理設計: progress.md更新タイミング修正

## 変更対象

- `prompts/package/prompts/construction.md`

## 変更1: ステップ1の説明拡張（行714-717付近）

### 現在のテキスト

```markdown
### 1. Unit定義ファイルの「実装状態」を更新
完了したUnitの定義ファイル（`docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`）の「実装状態」セクションを更新:
- 状態: 進行中 → 完了
- 完了日: 現在日付（YYYY-MM-DD形式）
```

### 変更後のテキスト

```markdown
### 1. Unit定義ファイルの「実装状態」を更新
完了したUnitの定義ファイル（`docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`）の「実装状態」セクションを更新:
- 状態: 進行中 → 完了（= PR準備完了）
- 完了日: 現在日付（YYYY-MM-DD形式）

**注意**: Unit定義ファイルの「完了」は「PR準備完了」を意味します（Operations Phase ステップ6.4.5と同一の解釈）。この更新をGitコミット（ステップ4）に含めることで、Unit PRに正確な状態が反映されます。ステップ5以降はPR準備完了後のレビュー・マージ作業です。
```

### 変更理由

- 「完了」の意味がUnitブランチ使用時に曖昧だった
- Operations Phase ステップ6.4.5との一貫性を確保

## 変更2: ステップ4のコミットチェックリスト修正（行754-760付近）

### 現在のテキスト

```markdown
- [ ] Unit定義ファイル: `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`
- [ ] 履歴ファイル: `docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md`
- [ ] 進捗ファイル（Operations Phase）: `docs/cycles/{{CYCLE}}/operations/progress.md`
- [ ] 設計ファイル（作成した場合）: `docs/cycles/{{CYCLE}}/design-artifacts/`
- [ ] 実装ファイル（作成した場合）
```

### 変更後のテキスト

```markdown
- [ ] Unit定義ファイル: `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`
- [ ] 履歴ファイル: `docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md`
- [ ] 設計ファイル（作成した場合）: `docs/cycles/{{CYCLE}}/design-artifacts/`
- [ ] 実装ファイル（作成した場合）
```

### 変更理由

- `operations/progress.md` はOperations Phaseで管理されるファイルであり、Construction Phaseのコミットチェックリストに含めるのは不適切
- Construction Phaseの進捗管理はUnit定義ファイルの「実装状態」で行う（v1.9.0で `construction/progress.md` を廃止済み）

## 変更3: ステップ5に注意事項を追加（行800付近、「はい」の場合セクション内）

### 挿入位置

ステップ5の「**「はい」の場合**:」の直後、「1. **既存PRの確認**:」の前に注意事項を挿入する。

### 追加テキスト

```markdown
**注意**: PR作成・Ready化後は、バグ修正や追加要件がない限り**新たな変更**を加えないでください。Unit定義ファイルの「実装状態」は既にステップ1で「完了」（= PR準備完了）として更新済みです。コミット漏れが見つかった場合は、漏れていたファイルのみ追加コミットしてください。
```

### 変更理由

- Operations Phase ステップ6.6の注意事項との一貫性
- PR作成後に追加変更を加えると、Unit定義ファイルの「完了」状態と実際のコード状態が乖離するリスクを防止

## 影響範囲

### 影響あり

- Unitブランチを使用する場合のUnit完了フロー: 「PR準備完了」の解釈が明確になる

### 影響なし

- Unitブランチを使用しない場合: 既存のフローに変更なし（ステップ5自体が「Unitブランチで作業した場合」の条件付き）
- Operations Phase: 変更なし（参照のみ）
- Inception Phase: 変更なし
