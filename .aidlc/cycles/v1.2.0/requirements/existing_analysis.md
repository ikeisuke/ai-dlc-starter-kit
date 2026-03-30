# 既存コード分析

## 分析対象

v1.2.0 の改善項目に関連する既存ファイルを分析

---

## 1. 現在のファイル構成

### セットアップ関連（ツール側）
```
prompts/
├── setup-prompt.md        # メインセットアッププロンプト（330行）
└── setup/
    ├── common.md          # 共通処理（461行）
    ├── inception.md       # Inception Phase生成（448行）
    ├── construction.md    # Construction Phase生成（大）
    └── operations.md      # Operations Phase生成（大）
```

### 生成されるプロンプト（成果物側）
```
docs/aidlc/
├── prompts/
│   ├── inception.md       # 現在は {{CYCLE}} 変数化済み
│   ├── construction.md    # 現在は {{CYCLE}} 変数化済み
│   ├── operations.md      # 現在は {{CYCLE}} 変数化済み
│   ├── additional-rules.md
│   ├── prompt-reference-guide.md
│   └── lite/
│       ├── inception.md
│       ├── construction.md
│       └── operations.md
├── templates/
│   └── *.md
└── version.txt
```

---

## 2. 問題箇所の特定

### 項目2: 変数の具体例を削除（テンプレート側）

**問題ファイル**: `prompts/setup/common.md:22`
```markdown
| `{{CYCLE}}` | サイクル識別子 | v1.0.1 |
```
→ 「例」列に `v1.0.1` があり、AIがこれをデフォルト値と解釈する可能性

**対応済み**: `docs/aidlc/prompts/*.md` は v1.2.0 セットアップ時に `{{CYCLE}}` に変更済み
**未対応**: `prompts/setup/*.md` のテンプレート自体は修正されていない

### 項目7: construction.md のパス参照不整合

**問題**: Unit定義ファイルのパスが異なる
- プロンプト内の想定: `docs/cycles/{version}/units/`
- 実際のパス: `docs/cycles/{version}/story-artifacts/units/`

---

## 3. 新規作成が必要なファイル

### 項目5: マージ後のタグ付け自動化
```
.github/
└── workflows/
    └── auto-tag.yml    # 新規作成
```

---

## 4. 改善項目と影響範囲

| # | 項目 | 影響ファイル | 新規/修正 |
|---|------|-------------|----------|
| 1 | プロンプトの分割・短縮化 | `prompts/setup/*.md`, `docs/aidlc/prompts/*.md` | 修正+新規 |
| 2 | 変数の具体例を削除 | `prompts/setup/common.md` | 修正 |
| 3 | セットアップ処理の分離 | `prompts/setup-prompt.md`, 新規ファイル | 修正+新規 |
| 4 | プロンプト生成方式の改善 | `prompts/setup/*.md` | 修正 |
| 5 | マージ後のタグ付け自動化 | `.github/workflows/auto-tag.yml` | 新規 |
| 6 | バージョン管理 | `prompts/setup/*.md`, `docs/aidlc/**/*.md` | 修正 |
| 7 | パス参照不整合 | `docs/aidlc/prompts/construction.md` | 修正 |

---

## 5. 依存関係の分析

```
項目3（セットアップ分離）
  └─→ 項目4（プロンプト生成方式改善）に影響

項目1（プロンプト分割）
  └─→ 項目6（バージョン管理）と連携が有効

項目5（タグ付け自動化）
  └─→ 独立して実装可能

項目7（パス不整合）
  └─→ 独立して実装可能（優先度低）
```

---

## 6. 推奨実装順序

1. **項目7**: パス参照不整合の修正（簡単、独立）
2. **項目2**: 変数の具体例を削除（簡単、独立）
3. **項目5**: タグ付け自動化（独立、CI/CD）
4. **項目6**: バージョン管理（基盤整備）
5. **項目3+4**: セットアップ分離 + プロンプト生成方式改善（連携）
6. **項目1**: プロンプトの分割・短縮化（最も大きな変更）

---

## 最終更新
2025-12-03
