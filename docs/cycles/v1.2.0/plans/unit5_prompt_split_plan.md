# Unit 5: プロンプト分割・短縮化 実装計画

## 概要

セットアップ時にインラインで生成していたファイルを外部ファイル化し、コピーするだけで確実に配置できるようにする。

## 課題

`prompts/setup/inception.md` などにテンプレート内容がインラインで埋め込まれていた：
- 編集が困難（マークダウン内にマークダウン）
- AI生成時にミスの可能性
- 差分管理がしにくい

## 解決策

`prompts/package/` ディレクトリを導入し、コピー元ファイルを配置。

## 成果物

```
prompts/package/
├── prompts/
│   ├── inception.md
│   ├── construction.md
│   └── operations.md
└── templates/
    └── ... (17ファイル)
```

## セットアップ時の処理

```
prompts/package/prompts/*   → docs/aidlc/prompts/
prompts/package/templates/* → docs/aidlc/templates/
```

## 変更したファイル

- `prompts/setup-init.md` - コピー処理に変更
- `prompts/setup/common.md` - 簡素化
- `prompts/setup/inception.md` - 簡素化
- `prompts/setup/construction.md` - 簡素化
- `prompts/setup/operations.md` - 簡素化

---

**作成日**: 2025-12-04
**更新日**: 2025-12-04
**ステータス**: 完了
