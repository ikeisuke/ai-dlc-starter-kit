# Unit 002 計画書: ワークフロー改善（operations/construction）

## 概要

Operations PhaseとConstruction Phaseのワークフローを改善し、以下の問題を解決する：

1. **PRマージ後のcheckout失敗** (Issue #167)
   - 現状: PRマージ後に `git checkout main` するとprogress.mdの未コミット変更でエラー
   - 原因: ステップ6.7でprogress.mdを「完了」に更新後、コミットせずにPRマージ→checkout

2. **Unit完了時のコミット忘れ** (Issue #166)
   - 現状: Unit完了時にGitコミットを忘れることがある
   - 対策: コミット確認チェックリストとステータス表示の強化

## 変更対象ファイル

- `prompts/package/prompts/operations.md` - PRマージ前後の手順修正
- `prompts/package/prompts/construction.md` - Unit完了時のコミット確認強化

## 実装計画

### 1. operations.md の修正

#### 修正箇所1: ステップ6.7 PRマージ【重要】の直前にコミット確認を追加

**目的**: PRマージ前に未コミット変更をブロックし、checkout失敗を事前に防止

**挿入位置**: `#### 6.7 PRマージ【重要】` の直前

**追加する文言**:

```markdown
#### 6.6.5 コミット漏れ確認【必須】

PRマージ前に未コミットの変更がないことを確認します。

**確認コマンド**:
```bash
git status --porcelain
```

**結果に応じた対応**:

- **空（変更なし）**: 次のステップ（6.7 PRマージ）へ進む
- **非空（変更あり）**: 以下を実行

  ```text
  【警告】未コミットの変更があります。PRマージ前にコミットしてください。

  変更されているファイル:
  {git status --porcelain の実行結果をここに貼り付け}

  以下の手順で対応してください：
  1. 変更をコミットする（推奨）
  2. 変更を確認して不要であれば破棄する（※下記注意参照）

  コミット完了後、再度このステップを実行してください。
  ```

**注意**:
- stashは推奨しません。progress.mdやhistoryファイルの変更は履歴として残すべきです。
- **破棄してよいファイル**: 明らかな誤生成ファイル、一時ファイル（`.tmp`等）のみ
- **破棄NG**: progress.md、historyファイル、Unit定義ファイル、設計・実装成果物
```

#### 修正箇所2: セクション「5. PRマージ後の手順」の改善

**目的**: PRマージ後のcheckout時にコミット漏れがあった場合の注意喚起（セーフティネット）

**挿入位置**: `### 5. PRマージ後の手順【重要】` の1番目の手順の前

**追加する文言**:

```markdown
0. **未コミット変更の確認**:
   ```bash
   git status --porcelain
   ```

   **空でない場合**:
   ```text
   【注意】未コミットの変更があります。
   通常、この時点で未コミット変更は存在しないはずです（6.6.5で確認済み）。

   変更されているファイル:
   {git status --porcelain の実行結果をここに貼り付け}

   対応方法を選択してください：
   1. コミットする（推奨）- 変更を履歴として残す
   2. stashする - 一時的に退避してcheckout後に復元
   3. 破棄する - 誤生成/一時ファイルのみ（progress.md, history, Unit定義は破棄NG）
   ```
```

### 2. construction.md の修正

#### 修正箇所: 「4. Gitコミット」セクションの強化

**挿入位置**: `### 4. Gitコミット` セクションの先頭

**追加する文言**:

```markdown
### 4. Gitコミット

**コミット前の確認チェックリスト**:

以下のコマンドで変更ファイルを確認：
```bash
git status
```

**重要ファイルの確認**（以下が含まれているか確認）:
- [ ] Unit定義ファイル: `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`
- [ ] 履歴ファイル: `docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md`
- [ ] 進捗ファイル（Operations Phase）: `docs/cycles/{{CYCLE}}/operations/progress.md`
- [ ] 設計ファイル（作成した場合）: `docs/cycles/{{CYCLE}}/design-artifacts/`
- [ ] 実装ファイル（作成した場合）

**コミット実行後の確認**:
```bash
git status
```

**期待される結果**: `nothing to commit, working tree clean`

**変更が残っている場合**: 追加コミットを実施
```

## 完了条件チェックリスト

- [ ] operations.md: ステップ6.7の直前に「6.6.5 コミット漏れ確認【必須】」セクションが追加されている
- [ ] operations.md: 「5. PRマージ後の手順」に「0. 未コミット変更の確認」が追加されている
- [ ] construction.md: 「4. Gitコミット」セクションにコミット前の確認チェックリストが追加されている
- [ ] construction.md: 重要ファイル（Unit定義、履歴ファイル等）の具体例が記載されている
