# プロンプト実行履歴

このファイルには、各フェーズのプロンプト実行履歴を記録します。

---

## 記録ルール

各プロンプト実行時に、以下の情報を追記してください：

- **日時**: `date '+%Y-%m-%d %H:%M:%S'` コマンドで取得
- **フェーズ名**: Inception / Construction / Operations / 準備
- **実行内容**: 何を実行したか（簡潔に）
- **使用プロンプト**: 読み込んだプロンプトファイル、または実行したプロンプトの概要
- **成果物**: 作成・更新されたファイル
- **備考**: 特記事項、問題、決定事項等

---

## 履歴

### 2025-11-07 00:08:54 - 準備: AI-DLC環境セットアップ

**フェーズ名**: 準備

**実行内容**: AI-DLC 開発環境の初期セットアップ

**使用プロンプト**:
```markdown
prompts/setup-prompt.md を読み込んで、AI-DLC 開発環境をセットアップ

変数設定:
- PROJECT_NAME = AI-DLC Starter Kit
- VERSION = v1
- BRANCH = feature/example
- DEVELOPMENT_TYPE = greenfield
- DOCS_ROOT = example
- LANGUAGE = 日本語
- PROJECT_README = /README.md
- OTHER_DOCS = /LICENSE
- DEVELOPER_EXPERTISE = ソフトウェア開発
- ROLE_INCEPTION = プロダクトマネージャー兼ビジネスアナリスト
- ROLE_CONSTRUCTION = ソフトウェアアーキテクト兼エンジニア
- ROLE_OPERATIONS = DevOpsエンジニア兼SRE
- ADDITIONAL_RULES = example/prompts/additional-rules.md
```

**成果物**:

ディレクトリ構成:
```
example/
├── prompts/
├── plans/
├── requirements/
├── story-artifacts/
│   └── units/
├── design-artifacts/
│   ├── domain-models/
│   ├── logical-designs/
│   └── architecture/
├── construction/
│   └── units/
└── operations/
```

プロンプトファイル:
- `example/prompts/common.md` - 全フェーズ共通知識
- `example/prompts/inception.md` - Inception Phase 用プロンプト
- `example/prompts/construction.md` - Construction Phase 用プロンプト
- `example/prompts/operations.md` - Operations Phase 用プロンプト
- `example/prompts/additional-rules.md` - 追加ルール
- `example/prompts/history.md` - このファイル

**備考**:
- AI-DLC の3つのフェーズ（Inception → Construction → Operations）に対応したプロンプトテンプレートを作成
- 各プロンプトには、冪等性保証の仕組み（既存成果物確認 → 差分特定 → 計画作成 → 承認 → 実行）を組み込み
- 各フェーズ開始時に `common.md` と該当フェーズの `.md` を読み込む設計
- コンテキストリセット前提の設計により、各フェーズで必要な情報のみを読み込んで効率化

---

## 次回以降の記録テンプレート

```markdown
### YYYY-MM-DD HH:MM:SS - [フェーズ名]: [実行内容]

**フェーズ名**: [Inception / Construction / Operations]

**実行内容**: [何を実行したか]

**使用プロンプト**:
[読み込んだプロンプトファイルまたは実行したプロンプトの概要]

**成果物**:
- [作成・更新されたファイル1]
- [作成・更新されたファイル2]
- [...]

**備考**:
[特記事項、問題、決定事項等]

---
```

## 履歴の活用

この履歴は以下の目的で活用します：

1. **進捗の追跡**: どのフェーズまで進んでいるか確認
2. **冪等性の保証**: 既に実行済みの内容を確認し、重複を避ける
3. **振り返り**: プロジェクト完了後に開発プロセスを振り返る
4. **トラブルシューティング**: 問題発生時に過去の実行内容を確認
5. **ナレッジ共有**: 他のメンバーやプロジェクトへの参考情報
