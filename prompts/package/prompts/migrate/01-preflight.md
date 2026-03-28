# ステップ1: 検出とバックアップ

## 1. v1環境検出

`migrate-detect.sh` を実行し、manifest JSON を取得する。

```bash
skills/aidlc/scripts/migrate-detect.sh
```

### 分岐判定

stdout の JSON を解析し、`status` フィールドで分岐する:

- **`already_v2`**: 以下のメッセージを表示して終了:
  ```text
  v2環境が検出されました。移行は不要です。
  ```

- **`v1_detected`**: 移行対象を表示し、ユーザーに確認:
  ```text
  v1環境が検出されました。以下のリソースが移行対象です:

  | リソース種別 | パス | アクション |
  |-------------|------|-----------|
  | ... | ... | ... |

  移行を開始してよろしいですか？
  ```

## 2. manifest 保存

manifest JSON を一時ファイルに保存する:

```bash
mktemp /tmp/aidlc-manifest.XXXXXX
```

保存したパスを後続ステップで使用する。

## 3. バックアップ作成

ユーザーの承認後、`migrate-backup.sh` を実行:

```bash
skills/aidlc/scripts/migrate-backup.sh --manifest <manifest_path>
```

stdout の `backup_dir` を記録する。後続ステップの `--backup-dir` 引数に渡す。

## 4. 次のステップへ

バックアップ完了後、ステップ2（02-execute.md）の指示に従う。
