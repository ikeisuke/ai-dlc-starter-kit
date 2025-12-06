# Unit 3: ファイルコピー判定改善 - 実装計画

## 概要
セットアップ時のファイルコピーをrsyncで効率化する

## 背景・目的
- **現状**: 個別ファイルを `\cp -f` でコピー、存在チェックで分岐
- **問題**: 同一内容でも毎回上書き、git履歴に不要な変更が残る
- **解決**: rsync --checksum で差分のみ更新、--delete で不要ファイル削除

## 依存関係
- Unit 6（ファイル構成整理）完了 ✅

---

## 実装内容

### 1. ディレクトリ構成の整理

```
prompts/
├── package/           # rsync で完全同期
│   ├── prompts/       → docs/aidlc/prompts/
│   └── templates/     → docs/aidlc/templates/
└── setup/
    └── templates/     # 初回のみコピー
        ├── rules_template.md
        └── operations_handover_template.md
```

### 2. rsyncコマンドへの置き換え（setup-init.md）

現在の個別cpコマンドを以下のrsyncコマンドに置き換え：

```bash
# プロンプトの同期（完全同期）
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/prompts/ \
  docs/aidlc/prompts/

# テンプレートの同期（完全同期）
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/templates/ \
  docs/aidlc/templates/
```

### 3. オプション説明
- `--checksum`: ハッシュで比較、同一内容ならスキップ
- `--delete`: コピー元にないファイルを削除
- `-av`: アーカイブモード + 詳細出力

### 4. 初回のみコピーするファイル

```bash
# rules.md が存在しない場合のみコピー
if [ ! -f docs/cycles/rules.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/rules_template.md docs/cycles/rules.md
fi

# operations.md が存在しない場合のみコピー
if [ ! -f docs/cycles/operations.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/operations_handover_template.md docs/cycles/operations.md
fi
```

### 5. 互換性
- macOS/Linux共通: rsyncは両環境でプリインストール済み
- shasum/sha256sumの分岐が不要になる

---

## 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | cpコマンドをrsyncに置き換え |

---

## 出力例
```
sending incremental file list
>fcst....... construction.md   # 内容が異なる → 更新
.f..t....... inception.md      # タイムスタンプのみ → スキップ（--checksumにより）

sent 1,234 bytes  received 56 bytes
```

---

## ビルド・テスト
- このUnitはドキュメント（プロンプト）の修正のみ
- ビルド・テストは不要

---

## 作成日
2025-12-06
