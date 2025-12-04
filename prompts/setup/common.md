# 共通セットアップ処理

このファイルは `prompts/setup-prompt.md` から参照されます。

---

## 設定参照ルール【重要】

### 設定ファイル
プロジェクト設定は `docs/aidlc/project.toml` に集約されています。

### パス規約
- 共通プロンプト・テンプレート: `docs/aidlc/`
- サイクル固有成果物: `docs/cycles/{サイクル}/`

---

## パッケージファイルのコピー

### フェーズプロンプト

`prompts/package/prompts/` から `docs/aidlc/prompts/` にコピー:

| ソース | 出力先 |
|--------|--------|
| prompts/package/prompts/inception.md | docs/aidlc/prompts/inception.md |
| prompts/package/prompts/construction.md | docs/aidlc/prompts/construction.md |
| prompts/package/prompts/operations.md | docs/aidlc/prompts/operations.md |

### ドキュメントテンプレート

`prompts/package/templates/` から `docs/aidlc/templates/` にコピー。

詳細は setup-init.md のセクション 6.2 を参照。

---

## ディレクトリ構成

セットアップ時に以下の構造を作成:

```
docs/aidlc/
├── prompts/
│   ├── inception.md
│   ├── construction.md
│   └── operations.md
├── templates/
├── operations/
├── project.toml
└── version.txt

docs/cycles/{サイクル}/
├── plans/
├── requirements/
├── story-artifacts/units/
├── design-artifacts/
├── inception/
├── construction/units/
├── operations/
└── history.md
```

---

## 重要な設計原則

- **フェーズごとに必要な情報のみ**: 各 .md は該当フェーズに必要な情報だけを含める
- **コンテキストリセット前提**: 該当フェーズの .md のみ読み込む設計
- **設定ファイル参照**: プロジェクト情報は project.toml から取得
