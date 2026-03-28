# ステップ2: 移行実行

ステップ1で取得した `manifest_path` と `backup_dir` を使用する。

## 1. config.toml パス更新

```bash
skills/aidlc/scripts/migrate-apply-config.sh --manifest <manifest_path> --backup-dir <backup_dir>
```

### エラー処理

- **exit 2**: stderr を確認し、バックアップから config.toml を復元して中断
- **exit 0 + journal に error エントリ**: config journal の成功エントリを復元して中断

## 2. データ移行

```bash
skills/aidlc/scripts/migrate-apply-data.sh --manifest <manifest_path> --backup-dir <backup_dir>
```

### エラー処理

- **exit 2 または journal に error エントリ**: config journal + data journal の成功エントリを累積して復元し中断

## 3. v1痕跡クリーンアップ

```bash
skills/aidlc/scripts/migrate-cleanup.sh --manifest <manifest_path> --backup-dir <backup_dir>
```

### エラー処理

- **exit 2 または journal に error エントリ**: config + data + cleanup journal の成功エントリを累積して復元し、ユーザーに確認

## 4. ロールバック手順

復元が必要な場合:

1. backup result JSON の `files` 一覧を参照
2. 失敗フェーズまでの全 journal の `applied[]` で `status: "success"` のエントリを累積
3. 対応する `files[].backup` → `files[].source` へ `cp` で復元

## 5. 次のステップへ

全フェーズ成功後、ステップ3（03-verify.md）の指示に従う。
