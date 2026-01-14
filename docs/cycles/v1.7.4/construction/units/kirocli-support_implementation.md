# 実装記録: KiroCLI対応

## 概要

- **Unit**: 004-kirocli-support
- **関連Issue**: #57
- **実装日**: 2026-01-14

## 実装内容

### 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/AGENTS.md` | KiroCLI対応セクションを追加 |

### 追加セクション

`## KiroCLI対応` セクションを追加し、以下を記載:

1. **制約事項**: `@`参照記法がKiroCLIで機能しない旨
2. **設定手順**: `.kiro/agents/{name}.json` の設定方法
3. **設定例**: 最小限のresources設定（AGENTS.mdのみ）
4. **公式ドキュメントへのリンク**

### 設計判断

- **最小限のresources設定を採用**: 全ファイルをresourcesに含めるとコンテキストが増大するため、エントリーポイント（AGENTS.md）のみを必須とした
- 設定ファイル（aidlc.toml）やフェーズプロンプト等はAI-DLCが必要に応じて読み込む設計

## テスト結果

- Markdownlint: PASS（0 errors）

## 完了状態

- [x] AGENTS.mdにKiroCLI対応セクション追加
- [x] Markdownlint実行
- [x] 実装記録作成
