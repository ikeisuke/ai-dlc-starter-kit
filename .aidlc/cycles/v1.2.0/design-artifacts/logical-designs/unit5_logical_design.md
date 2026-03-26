# Unit 5: プロンプト分割・短縮化 論理設計

## 概要

テンプレートを外部ファイル化し、セットアップ時にコピーする仕組みを設計する。

---

## ディレクトリ構成

### ソース側（prompts/package/）

```
prompts/package/
├── prompts/
│   ├── inception.md
│   ├── construction.md
│   └── operations.md
└── templates/
    ├── intent_template.md
    ├── user_stories_template.md
    ├── unit_definition_template.md
    ├── domain_model_template.md
    ├── logical_design_template.md
    ├── implementation_record_template.md
    └── ... (その他テンプレート)
```

### 出力側（docs/aidlc/）

```
docs/aidlc/
├── prompts/
│   ├── inception.md
│   ├── construction.md
│   └── operations.md
└── templates/
    └── ... (テンプレートファイル)
```

---

## セットアップ時の処理

### setup-init.md セクション 6.2

```bash
# フェーズプロンプトのコピー
cp -r [スターターキットパス]/prompts/package/prompts/* docs/aidlc/prompts/

# ドキュメントテンプレートのコピー
cp -r [スターターキットパス]/prompts/package/templates/* docs/aidlc/templates/
```

---

## フロー制御ファイル

`prompts/setup/*.md` はフロー制御のみに簡素化：
- 「何をコピーするか」の指示
- 「使用方法」の案内

インラインのテンプレート内容は削除済み。

---

## 変数の扱い

テンプレートファイルは**変数を含まない純粋なファイル**として配置。

- コピーするだけで使用可能
- 変数置換の処理が不要
- シンプルで確実

---

**作成日**: 2025-12-04
**更新日**: 2025-12-04
