# AI-DLC Starter Kit v1.0.0 開発開始プロンプト

以下のファイルを読み込んで、AI-DLC Starter Kit v1.0.0 の開発環境をセットアップしてください：

```
/Users/isonokeisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md
```

## 変数設定

以下の変数を使用してください：

```
MODE = setup
PROJECT_NAME = AI-DLC Starter Kit
VERSION = v1.0.0
BRANCH = main
DEVELOPMENT_TYPE = brownfield  # 既存プロジェクトの改善
PROJECT_TYPE = general
DOCS_ROOT = docs
LANGUAGE = 日本語

DEVELOPER_EXPERTISE = ソフトウェア開発
ROLE_INCEPTION = プロダクトマネージャー兼ビジネスアナリスト
ROLE_CONSTRUCTION = ソフトウェアアーキテクト兼エンジニア
ROLE_OPERATIONS = DevOpsエンジニア兼SRE
```

## 開発Intent

このバージョンの開発目的と方針は、以下のファイルに詳しく記載されています：

```
/Users/isonokeisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/docs/v1.0.0-intent.md
```

**必ずこのファイルを読み込んで、開発の背景・目的・新しいディレクトリ構造・実装が必要な項目を理解してから進めてください。**

## 重要な注意事項

1. **brownfield開発**: 既存のv0.1.0の仕組みを改善する開発です
2. **新しいディレクトリ構造**: プロンプトを `docs/aidlc/` に、成果物を `docs/versions/v1.0.0/` に配置する構造に変更します
3. **AI-DLCプロセスに従う**: Inception → Construction → Operations の順で進めます
4. **既存機能の維持**: v0.1.0の機能（進捗管理、一問一答、JIT生成等）はすべて維持します

## 次のステップ

1. setup-prompt.mdを読み込んでセットアップを実行
2. セットアップ完了後、`docs/v1.0.0/prompts/additional-rules.md` をカスタマイズ
3. 新しいセッションでInception Phaseを開始

---

**新しいセッションで、このファイルの内容をClaude Codeに渡してください。**
