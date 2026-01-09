# ls -d コマンドの出力でスラッシュが重複する問題

- **発見日**: 2026-01-05
- **発見フェーズ**: セットアップ
- **発見サイクル**: v1.5.4
- **優先度**: 低

## 概要

`ls -d docs/cycles/*/` コマンドの出力で、末尾にスラッシュが2つ表示される（例: `docs/cycles/backlog//`）。

## 詳細

setup.md のステップ2.2で使用している以下のコマンド：
```bash
ls -d docs/cycles/*/ 2>/dev/null | sort -V
```

このコマンドは、グロブパターン `*/` 自体に末尾スラッシュが含まれているため、`ls -d` の出力と合わせて二重スラッシュになる。

出力例：
```
docs/cycles/backlog-completed//
docs/cycles/backlog//
docs/cycles/v1.0.1//
```

## 対応案

以下のいずれかの修正を適用：

1. グロブパターンから末尾スラッシュを削除：
   ```bash
   ls -d docs/cycles/* 2>/dev/null | sort -V
   ```

2. sedで末尾スラッシュを1つに正規化：
   ```bash
   ls -d docs/cycles/*/ 2>/dev/null | sed 's#//$#/#' | sort -V
   ```

3. findコマンドを使用：
   ```bash
   find docs/cycles -maxdepth 1 -type d | sort -V
   ```
