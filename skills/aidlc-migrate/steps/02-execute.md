# ステップ2: 移行実行

ステップ1で取得した `manifest_path` を使用する。

## 1. config.toml パス更新

```bash
scripts/migrate-apply-config.sh --manifest <manifest_path>
```

### エラー処理

- **exit 2**: stderr を確認し、`git checkout .` で変更を復元して中断
- **exit 0 + journal に error エントリ**: 問題箇所を確認し、必要に応じて `git checkout .` で復元して中断

## 2. データ移行

```bash
scripts/migrate-apply-data.sh --manifest <manifest_path>
```

### エラー処理

- **exit 2 または journal に error エントリ**: `git checkout .` で変更を復元して中断

## 3. v1痕跡クリーンアップ

```bash
scripts/migrate-cleanup.sh --manifest <manifest_path>
```

### エラー処理

- **exit 2 または journal に error エントリ**: `git checkout .` で変更を復元し、ユーザーに確認

## 3b. Issueテンプレートの確認

manifest の resources に `action: "confirm_delete"` のエントリがある場合、ユーザーに削除するか確認する。

```text
v1で管理していたIssueテンプレートと同名のファイルが見つかりました。
v2では管理対象外のため、不要であれば削除できます。

{ファイル一覧}

削除しますか？
1. はい - 上記ファイルを削除する
2. いいえ - そのまま残す
```

- 「はい」の場合: 各ファイルを `rm` で削除する
- 「いいえ」の場合: 次のステップへ進む
- `confirm_delete` エントリがない場合: このステップをスキップ

## 4. ロールバック手順

問題が発生した場合:

```bash
git checkout .
```

gitブランチ（`aidlc-migrate/v2`）上で作業しているため、上記コマンドで全変更を復元できます。

## 5. 次のステップへ

全フェーズ成功後、ステップ3（03-verify.md）の指示に従う。
