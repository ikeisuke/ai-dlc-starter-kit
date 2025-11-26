# バックトラック機構 設計

## 概要

開発中に前のフェーズに戻る必要がある場合の標準的な手順。

## バックトラックのパターン

### パターン1: Construction → Inception（Unit追加・拡張）

**トリガー**:
- Construction中に新しいUnitが必要になった
- 既存Unitの拡張が必要になった
- 要件変更でユーザーストーリーの見直しが必要

**手順**:
1. 現在の作業を一時保存（progress.mdで管理）
2. `docs/aidlc/prompts/inception.md` を読み込み
3. Inception Phaseのprogress.mdを読み込み
4. ステップ3（ユーザーストーリー作成）またはステップ4（Unit定義）から再開
5. 新しいUnit定義を追加
6. construction/progress.mdを更新（新しいUnitを追加）
7. Inception Phaseの履歴を記録してコミット
8. `docs/aidlc/prompts/construction.md` を読み込んで再開

### パターン2: Operations → Construction（バグ修正）

**トリガー**:
- Operations中にバグを発見
- デプロイテストで問題が見つかった

**手順**:
1. 現在の作業を一時保存（progress.mdで管理）
2. `docs/aidlc/prompts/construction.md` を読み込み
3. Construction Phaseのprogress.mdを読み込み
4. 修正対象のUnitを選択（progress.mdで「進行中」に変更）
5. Unit修正（設計→実装→テスト）
6. progress.mdを更新（Unitを「完了」に戻す）
7. Construction Phaseの履歴を記録してコミット
8. `docs/aidlc/prompts/operations.md` を読み込んで再開

### パターン3: Operations → Inception（大規模な要件変更）

**トリガー**:
- Operations中に大規模な要件変更が必要になった
- 新しいEpicの追加が必要

**手順**:
パターン1とパターン2を組み合わせ：
1. Operations → Inception（新しいUnit定義）
2. Inception → Construction（新しいUnit実装）
3. Construction → Operations（デプロイ継続）

## 各フェーズプロンプトへの追加内容

### Inception Phase

```markdown
## このフェーズに戻る場合【バックトラック】

Construction PhaseやOperations Phaseから戻ってきた場合の手順：

### Unit追加・拡張の場合

1. **progress.md確認**: `{{VERSIONS_ROOT}}/{{VERSION}}/inception/progress.md` を読み込み
2. **既存成果物読み込み**:
   - `{{VERSIONS_ROOT}}/{{VERSION}}/story-artifacts/user_stories.md` を読み込み
   - 既存のUnit定義（`{{VERSIONS_ROOT}}/{{VERSION}}/story-artifacts/units/*.md`）を確認
3. **差分作業**:
   - ステップ3（ユーザーストーリー作成）: 新しいストーリーを追加
   - ステップ4（Unit定義）: 新しいUnit定義を作成
4. **progress.md更新**: construction/progress.mdに新しいUnitを追加
5. **履歴記録とコミット**: Inception Phaseの変更を記録

### 完了後の次のステップ

- Construction Phaseに戻る: `{{AIDLC_ROOT}}/prompts/construction.md` を読み込み
```

### Construction Phase

```markdown
## このフェーズに戻る場合【バックトラック】

### Inceptionに戻る必要がある場合

新しいUnitの追加や大規模な変更が必要な場合：

1. 現在のprogress.mdを確認
2. `{{AIDLC_ROOT}}/prompts/inception.md` を読み込み
3. 上記「Inception Phase - このフェーズに戻る場合」の手順に従う

### Operations Phaseからバグ修正で戻ってきた場合

1. **progress.md確認**: `{{VERSIONS_ROOT}}/{{VERSION}}/construction/progress.md` を読み込み
2. **修正対象Unit選択**: バグがあるUnitを「進行中」に変更
3. **Unit修正**: 設計レビュー→実装→テスト
4. **progress.md更新**: Unitを「完了」に戻す
5. **履歴記録とコミット**: Construction Phaseの変更を記録

### 完了後の次のステップ

- Operations Phaseに戻る: `{{AIDLC_ROOT}}/prompts/operations.md` を読み込み
```

### Operations Phase

```markdown
## このフェーズに戻る場合【バックトラック】

### Constructionに戻る必要がある場合

バグ修正や機能修正が必要な場合：

1. 現在のprogress.mdを確認
2. `{{AIDLC_ROOT}}/prompts/construction.md` を読み込み
3. 上記「Construction Phase - Operations Phaseからバグ修正で戻ってきた場合」の手順に従う

### 完了後の次のステップ

- Operations Phaseに戻る: `{{AIDLC_ROOT}}/prompts/operations.md` を読み込み
- progress.mdを読み込んで、未完了ステップから再開
```

## 実装時の注意点

1. **progress.mdの整合性**: フェーズを戻る際も、各フェーズのprogress.mdで状態管理
2. **履歴記録**: バックトラック時も、各フェーズでhistory.mdに記録
3. **Gitコミット**: フェーズ間を移動する前に必ずコミット
4. **冪等性**: 既存成果物を確認し、差分のみ更新

## 将来の拡張

- バックトラック専用のプロンプトファイル（`docs/aidlc/prompts/back_to_*.md`）の追加
- 自動的なフェーズ選択（progress.mdの状態から最適なフェーズを提案）
