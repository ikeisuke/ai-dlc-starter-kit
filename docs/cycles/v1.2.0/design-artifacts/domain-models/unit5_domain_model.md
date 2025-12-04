# Unit 5: プロンプト分割・短縮化 ドメインモデル設計

## 概要

セットアップ時にインラインで生成していたファイルを外部ファイル化し、コピーするだけで確実に配置できるようにする。

---

## 課題

### 元の構造の問題

`prompts/setup/inception.md` などにテンプレート内容がインラインで埋め込まれていた：
- 編集が困難（マークダウン内にマークダウン）
- AI生成時にミスの可能性
- 差分管理がしにくい

---

## 解決策

### パッケージディレクトリの導入

コピー元ファイルを `prompts/package/` に配置し、セットアップ時はコピーするだけにする。

---

## 新しい構造

```
prompts/
├── setup-prompt.md          # エントリーポイント
├── setup-init.md            # 初回セットアップ
├── setup-cycle.md           # サイクル開始
├── setup/                   # フロー制御（簡素化）
│   ├── common.md
│   ├── inception.md
│   ├── construction.md
│   └── operations.md
└── package/                 # コピー元（パッケージ）
    ├── prompts/
    │   ├── inception.md
    │   ├── construction.md
    │   └── operations.md
    └── templates/
        ├── intent_template.md
        ├── domain_model_template.md
        └── ... (17ファイル)
```

---

## コピー関係

| ソース | 出力先 |
|--------|--------|
| prompts/package/prompts/* | docs/aidlc/prompts/ |
| prompts/package/templates/* | docs/aidlc/templates/ |

---

## メリット

| 項目 | 改善前 | 改善後 |
|------|--------|--------|
| テンプレート編集 | インラインで困難 | 独立ファイルで容易 |
| セットアップ | AI生成でミスの可能性 | コピーで確実 |
| 差分管理 | 混在して困難 | ファイル単位で明確 |

---

**作成日**: 2025-12-04
**更新日**: 2025-12-04
