---
name: poc-caller
description: >
  PoC用 - スキル間呼び出し検証（caller側）。Skillツールでpoc-calleeを呼び出す。
  "poc-caller" で呼び出す。
---

# PoC Caller

このスキルはスキル間呼び出し検証のcaller側です。

## 手順

1. Skillツールを使って `poc-callee` スキルを呼び出してください
2. `poc-callee` からの応答に `[POC-CALLEE-RESPONSE-67890]` が含まれるか確認してください

## 出力

結果を以下のフォーマットで出力してください:

```text
【検証結果: スキル間呼び出し（caller）】
- Skillツール利用: {可能 / 不可}
- poc-callee呼び出し: {成功 / 失敗}
- マーカー検出: {あり / なし}
- callee応答: {受け取った応答}
- 失敗理由: {tool-unavailable / callee-not-found / invocation-denied / なし}
- 備考: {エラーメッセージや制約事項があれば}
```
