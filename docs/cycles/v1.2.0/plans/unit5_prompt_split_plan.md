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

## 残作業

### setup/ ディレクトリの整理

`prompts/setup/*.md` と `setup-init.md` で内容が重複している。

**現状**:
```
prompts/
├── setup-prompt.md
├── setup-init.md      # コピー処理を定義
├── setup-cycle.md
├── setup/             # ← 重複、不要？
│   ├── common.md
│   ├── inception.md
│   ├── construction.md
│   └── operations.md
└── package/
```

**対応案**:
- `setup/` ディレクトリを削除
- 必要な情報は `setup-init.md` に集約

---

**作成日**: 2025-12-04
**更新日**: 2025-12-04
**ステータス**: 進行中（setup/ 整理が残）
