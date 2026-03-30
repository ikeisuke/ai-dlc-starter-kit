# Unit 003: サンドボックス環境ガイド補完 - 計画

## 概要

`sandbox-environment.md`に不足している認証方式・サンドボックス種類の説明を追加する。

## 変更対象ファイル

- `prompts/package/guides/sandbox-environment.md`

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 認証方式の分類とサンドボックス保護レベルの構造を定義
2. **論理設計**: ドキュメントに追加するセクション構成を決定
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

4. **コード生成**: ドキュメントに以下のセクションを追加
   - 認証方式比較セクション（API Key vs OAuth）
   - OAuth認証ツールのDocker実行例
   - サンドボックス種類の説明（アプリケーションレベル vs OSレベル）
   - 各ツールの保護範囲一覧

5. **テスト生成**: ドキュメントの整合性確認（Markdownlint）

6. **統合とレビュー**: AIレビュー → 人間レビュー

## 完了条件チェックリスト

- [ ] 各ツールの認証方式（API vs OAuth）の比較表を追加
- [ ] OAuth認証ツールのDocker実行例を追加
- [ ] アプリケーションレベル vs OSレベルのサンドボックスの違いを説明
- [ ] 各ツールの保護範囲を明確化
- [ ] 【追加】サブスクリプション契約（OAuth認証）でのDocker利用手順
  - [ ] Claude Code（claude.ai Pro/Team）のDocker環境構築手順
  - [ ] Codex CLI（ChatGPT Plus等）のDocker環境構築手順
  - [ ] KiroCLI（Amazon Q Developer）のDocker環境構築手順
