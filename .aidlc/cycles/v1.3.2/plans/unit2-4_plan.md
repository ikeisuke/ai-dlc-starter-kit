# Unit 2-4 実装計画

## 対象Unit

- Unit 2: コミットハッシュ注意事項の追加
- Unit 3: ブランチ削除手順の明確化
- Unit 4: 最終更新セクションの廃止

---

## Unit 2: コミットハッシュ注意事項の追加

### 対象ファイル
- `prompts/package/templates/unit_definition_template.md` (既存ファイルの修正)

### 変更内容
「実装状態」セクションにコミットハッシュ記録の注意事項を追加：
- コミットハッシュは実際にコミットを作成した後に記録すること
- ハッシュは短縮形（7文字）を使用

### 変更箇所
```markdown
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **コミット**: - （※実際のコミット後に記録）
```

---

## Unit 3: ブランチ削除手順の明確化

### 対象ファイル
- `prompts/package/prompts/operations.md` (既存ファイルの修正)

### 変更内容
「PRマージ後の手順」セクション（ステップ3）を修正：
- 「（任意）」を削除し、標準手順として明記
- リモートブランチの削除も追加

### 変更箇所（348-353行目付近）
```markdown
3. **マージ済みブランチの削除**:
   ```bash
   # ローカルブランチの削除
   git branch -d cycle/vX.X.X
   # リモートブランチの削除（必要に応じて）
   git push origin --delete cycle/vX.X.X
   ```
```

---

## Unit 4: 最終更新セクションの廃止

### 対象ファイル
- `prompts/package/templates/operations_progress_template.md` (既存ファイルの修正)
- `prompts/package/templates/inception_progress_template.md` (既存ファイルの修正)

### 廃止理由
- 日時はgit履歴で追跡可能であり冗長
- 手動更新が必要で運用負荷が高い
- 更新し忘れによる不整合が発生しやすい

### 変更内容
各ファイルから「最終更新」セクションを削除

---

## 実装順序

1. Unit 2 実装
2. Unit 3 実装
3. Unit 4 実装
4. Unit定義ファイルの実装状態更新
5. 履歴記録・コミット
