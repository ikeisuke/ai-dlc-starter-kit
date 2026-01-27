# Unit 009 計画: バックログ登録時の不明点確認フロー

## 概要

バックログ登録時に不明点を明確にし、後から見ても意味がわかるバックログにするための確認フローを追加する。

## 変更対象ファイル

### 新規作成

- `prompts/package/guides/backlog-registration.md` - バックログ登録ガイド（確認フロー定義）

### 更新

- `prompts/package/guides/backlog-management.md` - 新規ガイドへの参照追加

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: バックログ登録の概念と確認フローの構造を定義
2. **論理設計**: 確認フローの具体的な手順とAskUserQuestion活用パターンを定義
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

4. **コード生成**: `prompts/package/guides/backlog-registration.md` を作成
5. **テスト生成**: 該当なし（ドキュメントのみ）
6. **統合とレビュー**: バックログ管理ガイドへの参照追加、AIレビュー、最終確認

## 完了条件チェックリスト

- [ ] バックログ登録前の確認フロー追加
- [ ] 必須項目テンプレートの提供
- [ ] AskUserQuestionを活用した対話的登録

## 技術的考慮事項

- メタ開発のため、`prompts/package/` 配下を編集（`docs/aidlc/` は直接編集禁止）
- Operations Phase の rsync で `docs/aidlc/` に反映される
- 対象: ユーザー起点のバックログ登録時のみ（AI自動検出は対象外）

## 関連Issue

- #101: バックログ登録時の不明点確認フロー
