# ステップ3: 検証と完了

## 1. 移行後検証

```bash
scripts/migrate-verify.sh --manifest <manifest_path>
```

### 分岐判定

stdout の JSON を解析し、`overall` フィールドで分岐する:

- **`ok`**: 全検証項目がパス。完了メッセージへ進む
- **`fail`**: 検証失敗の詳細を表示し、ユーザーに確認:
  ```text
  移行後の検証で不整合が検出されました:

  | 検証項目 | ステータス | 詳細 |
  |---------|-----------|------|
  | ... | ... | ... |

  手動で確認・修正してください。
  ```

## 2. 一時ファイルの削除

manifest 一時ファイルを削除する:

```bash
rm -f <manifest_path>
```

## 3. 完了メッセージ

```text
v1→v2 移行が完了しました。

実施した変更:
- config.toml のパス参照を更新しました
- cycles配下のデータファイルを移行しました
- v1由来の不要ファイルを削除しました

問題が発生した場合は git checkout . で変更を復元できます。
```

## 4. コミットとPR作成

移行結果をコミットし、PRを作成する:

1. 変更差分を確認:
   ```bash
   git diff --stat
   ```

2. 全変更をステージしてコミット:
   ```bash
   git add -A
   git commit -m "chore: v1→v2 マイグレーション"
   ```

3. リモートにプッシュしてPRを作成:
   ```bash
   git push -u origin migrate/v2
   ```
   `gh pr create` でPRを作成する。タイトル例: `chore: v1→v2 マイグレーション`

4. PRマージ後、新しいサイクルを開始するには `/aidlc inception` を実行する旨を案内:

```text
マイグレーションPRを作成しました。

PRをマージ後、新しいサイクルを開始するには:
  /aidlc inception
```
