# Unit 005: Issue操作スクリプト 実装計画

## 概要

Issueへのラベル付けとCloseを行うスクリプト `issue-ops.sh` を作成する。

## 対象Unit定義

- ファイル: `docs/cycles/v1.8.0/story-artifacts/units/005-issue-ops.md`
- 関連Issue: #34

## 前提条件

- **依存Unit**: Unit 001（環境情報スクリプト）完了済み
- **外部依存**: gh（GitHub CLI）がインストール・認証済みであること
- **境界**: Issue作成（gh issue create）は含まない（label, closeのみ）

## 出力フォーマット仕様

スクリプトは以下の統一フォーマットで結果を標準出力に出力する：

```text
# 成功ケース
issue:123:labeled:cycle:v1.8.0
issue:123:closed
issue:123:closed:not-planned

# エラーケース
issue:123:error:not found
issue:123:error:gh not available
issue:123:error:gh not authenticated
```

## 非機能要件（NFR）

- **パフォーマンス**: 各操作5秒以内に完了すること
- **可用性**: gh認証済み環境で動作

## 実装計画

### Phase 1: 設計（対話形式）

#### ステップ1: ドメインモデル設計

**成果物**: `docs/cycles/v1.8.0/design-artifacts/domain-models/005-issue-ops_domain_model.md`

- Issue操作の概念モデル定義
- コマンドの入出力定義（上記出力フォーマット仕様に準拠）
- エラーケースの整理（gh未インストール、未認証、Issue不存在）

#### ステップ2: 論理設計

**成果物**: `docs/cycles/v1.8.0/design-artifacts/logical-designs/005-issue-ops_logical_design.md`

- スクリプト構成
- サブコマンド設計（label, close）
- 引数パース処理
- 前提条件チェック（gh利用可否、認証状態）
- エラーハンドリングと終了コード

#### ステップ3: 設計レビュー

- ユーザー承認を得る

### Phase 2: 実装

#### ステップ4: コード生成

**成果物**: `prompts/package/bin/issue-ops.sh`

- サブコマンド: label, close
- 使用例（`docs/aidlc/bin/` にrsync後に実行）:
  ```bash
  docs/aidlc/bin/issue-ops.sh label 123 "cycle:v1.8.0"
  docs/aidlc/bin/issue-ops.sh close 123
  docs/aidlc/bin/issue-ops.sh close 123 --not-planned
  ```

#### ステップ5: テスト

- 手動テスト（gh環境で動作確認）
- 出力フォーマットが仕様通りか確認
- エラーケースのテスト（不正なIssue番号、gh未認証時など）
- パフォーマンス確認（5秒以内）

#### ステップ6: 統合とレビュー

**成果物**: `docs/cycles/v1.8.0/construction/units/005-issue-ops_implementation.md`

- プロンプト更新（inception.md, operations.md）
- 実装記録の作成
- ビルド・テスト確認

## 変更対象ファイル

| ファイル | 種別 | 内容 |
|----------|------|------|
| `prompts/package/bin/issue-ops.sh` | 新規 | Issue操作スクリプト |
| `prompts/package/prompts/inception.md` | 更新 | スクリプト呼び出し追加 |
| `prompts/package/prompts/operations.md` | 更新 | スクリプト呼び出し追加 |

## 完了条件

- [ ] issue-ops.sh が正しく動作する
- [ ] label サブコマンドでラベル付けができる（出力: `issue:{N}:labeled:{label}`）
- [ ] close サブコマンドでIssueをCloseできる（出力: `issue:{N}:closed`）
- [ ] --not-planned オプションが機能する（出力: `issue:{N}:closed:not-planned`）
- [ ] gh未インストール/未認証時に適切なエラーメッセージを出力する
- [ ] 存在しないIssue番号でエラーメッセージを出力する
- [ ] 各操作が5秒以内に完了する
- [ ] プロンプトから呼び出し可能

## 見積もり

30分

---

作成日: 2026-01-17
