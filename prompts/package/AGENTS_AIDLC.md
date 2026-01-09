# AI-DLC 共通設定

このファイルはAI-DLC（AI-Driven Development Lifecycle）の共通設定です。
全てのAIツール（Claude Code、Codex、Amazon Q等）で使用されます。

## 開発サイクルの開始

### 初期セットアップ / アップグレード

`prompts/setup-prompt.md` を読み込んでください。

スターターキットの初期セットアップ、バージョンアップ、または移行時に使用します。

### 新規サイクル開始

`docs/aidlc/prompts/setup.md` を読み込んでください。

既存プロジェクトで新しいサイクルを開始する場合に使用します。

### 既存サイクルの継続

以下のプロンプトを読み込んでください：

- Inception Phase: `docs/aidlc/prompts/inception.md`
- Construction Phase: `docs/aidlc/prompts/construction.md`
- Operations Phase: `docs/aidlc/prompts/operations.md`

## 推奨ワークフロー

1. 初回は `prompts/setup-prompt.md` でセットアップ
2. `docs/aidlc/prompts/setup.md` でサイクルを作成
3. Inception Phaseで要件定義とUnit分解
4. Construction Phaseで設計と実装
5. Operations Phaseでデプロイと運用

## ドキュメント

- 設定: `docs/aidlc.toml`
- 追加ルール: `docs/cycles/rules.md`
