---
name: poc-read-test
description: >
  PoC用 - オンデマンドRead検証。SKILL.md内のRead指示でsteps/ファイルを相対パスで読めるか検証する。
  "poc-read-test" で呼び出す。
allowed-tools: Read
---

# PoC Read Test

このスキルはオンデマンドReadの検証用です。

## 手順

**【次のアクション】** 今すぐ `steps/sample-step.md` を読み込んで、その内容を出力してください。

読み込みが成功した場合、マーカー文字列 `[POC-READ-MARKER-12345]` が含まれているはずです。

## 出力

読み込み結果を以下のフォーマットで出力してください:

```
【検証結果: オンデマンドRead】
- ファイル: steps/sample-step.md
- 読み込み: {成功 / 失敗}
- マーカー検出: {あり / なし}
- マーカー文字列: {読み取った文字列}
- 備考: {エラーメッセージや制約事項があれば}
```
