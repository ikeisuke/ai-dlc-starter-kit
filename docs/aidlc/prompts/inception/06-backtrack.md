# Inception Phase - バックトラック

---

## このフェーズに戻る場合【バックトラック】

Construction PhaseやOperations Phaseから戻ってきた場合の手順：

### 1. progress.md確認
`.aidlc/cycles/{{CYCLE}}/inception/progress.md` を読み込み、完了済みステップを確認

### 2. 既存成果物読み込み
`.aidlc/cycles/{{CYCLE}}/story-artifacts/user_stories.md` と既存Unit定義を確認

### 3. 差分作業
ステップ3（ユーザーストーリー作成）またはステップ4（Unit定義）から再開し、新しいストーリー・Unit定義を追加

### 4. Unit定義追加
新しいUnitをstory-artifacts/units/に追加

### 5. 履歴記録とコミット
フェーズの変更を記録

**完了後、Construction Phaseに戻る場合**: SKILL.md の引数ルーティングに従い遷移（`/aidlc construction` を実行）

---

## 補足: git worktree の使用

詳細は `{{aidlc_dir}}/guides/worktree-usage.md` を参照してください。
