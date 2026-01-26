# ドメインモデル設計: メタ開発ドキュメント整理

## 概要

prompts/package/ 内のファイルを「ユーザー向け」「開発者向け」に分類し、開発者向けファイルを分離する。

## エンティティ

### 1. 配布パッケージファイル

- **定義**: `prompts/package/` 配下に存在し、rsyncで `docs/aidlc/` に同期されるファイル
- **責務**: AI-DLCを利用するプロジェクトにワークフロー・テンプレート・ガイドを提供
- **分類**: ユーザー向け

### 2. 開発者向けファイル

- **定義**: AI-DLCスターターキット自体の開発・テストに使用するファイル
- **責務**: 機能検証、開発ガイド、テストリソースの提供
- **分類**: 開発者向け

## 分類結果

### 開発者向け（移動対象）

| ファイル | 理由 |
|---------|------|
| `prompts/package/prompts/common/poc-test-level1.md` | 参照方式PoC検証用テストファイル |
| `prompts/package/prompts/common/poc-test-level2.md` | 参照方式PoC検証用テストファイル |
| `prompts/package/prompts/common/poc-test-level3.md` | 参照方式PoC検証用テストファイル |

### ユーザー向け（現状維持）

その他すべてのファイル:
- プロンプト（inception.md, construction.md, operations.md 等）
- テンプレート（unit_definition_template.md 等）
- ガイド（backlog-management.md, deprecation.md 等）
- スクリプト（sync-prompts.sh, write-history.sh 等）

## 分類基準

1. **ユーザー向け**: AI-DLCワークフローの実行に必要なファイル
2. **開発者向け**: AI-DLCスターターキット自体の開発・テスト・検証に使用するファイル

## 質問と回答

（なし - 分類基準は明確）
