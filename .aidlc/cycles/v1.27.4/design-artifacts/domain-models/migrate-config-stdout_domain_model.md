# ドメインモデル: migrate-config警告検出のstdout解析移行

## 概要
aidlc-setup.shのStep 5における警告検出方式の変更。ドメインモデルの対象はシェルスクリプトのフロー制御のみ。

## 変更対象の構造

### migrate-config.shの出力仕様（変更なし）
- stdout: `warn:` プレフィックスの行で警告を出力（例: `warn:override-old-keys:xxx`）
- 終了コード: v1.27.3以降は常に0（終了コード規約に準拠）
- エラー時: 非0の終了コードを返す

### aidlc-setup.shのStep 5 判定フロー（変更対象）

**変更前**:
```
migrate-config.sh 実行
  → exit 0: 正常完了
  → exit 2: warn:migrate-warnings 出力
  → exit 他: error:migrate-failed 出力、スクリプト終了
```

**変更後**:
```
migrate-config.sh 実行（stdout をキャプチャ）
  → exit != 0: error:migrate-failed 出力、スクリプト終了
  → exit == 0:
    → stdout に warn: 行あり: warn:migrate-warnings 出力
    → stdout に warn: 行なし: 何も出力しない
```
