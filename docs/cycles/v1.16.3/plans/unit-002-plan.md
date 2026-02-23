# Unit 002 計画: ブランチ作成方式の設定固定化

## 概要

`[rules.branch].mode` の設定値に応じて、Inception Phase ステップ7のブランチ確認で質問を省略し自動実行する機能を追加する。

## 前提: Issue #223 修正（ブロッカー）

`read-config.sh` が dasel v3 の予約語 `branch` により `rules.branch.mode` を読み取れない問題（Issue #223）を先に修正する。

- **修正対象**: `prompts/package/bin/read-config.sh` の `get_value` 関数
- **修正内容**: dasel に渡すキーの各セグメントをダブルクォートでラップ
  - 例: `rules.branch.mode` → `"rules"."branch"."mode"`

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/bin/read-config.sh` | dasel v3 予約語回避（Issue #223） |
| `prompts/package/prompts/inception.md` | ステップ7の分岐ロジックを変更 |

## 入力値の決定表

| `rules.branch.mode` | `rules.worktree.enabled` | 結果 |
|---------------------|-------------------------|------|
| `"branch"` | 任意 | 自動ブランチ作成（質問なし） |
| `"worktree"` | `true` | 自動worktree作成（質問なし） |
| `"worktree"` | `false` / 未設定 / `true`以外の値 | 警告表示 → 自動ブランチ作成にフォールバック |
| `"ask"` | 任意 | 現行通り質問 |
| 空文字 / 未設定 | 任意 | `"ask"` として扱う |
| その他の無効値 | 任意 | 警告表示 → `"ask"` にフォールバック |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 設定値の分岐ロジック・フォールバック規則・決定表を定義
2. **論理設計**: ステップ7の具体的なフロー変更を設計
3. **設計レビュー**

### Phase 2: 実装

4. **コード生成**:
   - **4a**: read-config.sh の dasel v3 予約語回避修正（Issue #223）
   - **4b**: inception.md ステップ7を修正
     - `rules.branch.mode` の読み取り（read-config.sh使用）
     - 決定表に基づく分岐ロジック
     - 評価順序: (1) mode読み取り → (2) 無効値チェック → (3) worktree有効性チェック → (4) 実行
5. **テスト生成**: read-config.sh の修正テスト + プロンプト変更の手動テストシナリオ
6. **統合とレビュー**

## 完了条件チェックリスト

- [ ] read-config.sh の dasel v3 予約語回避修正（Issue #223）
- [ ] inception.md ステップ7の分岐ロジック変更（`[rules.branch].mode` の値に応じた自動選択）
- [ ] worktree無効時のフォールバック処理（`mode = "worktree"` かつ `rules.worktree.enabled = false` → branch にフォールバック）
- [ ] 無効な mode 値への警告表示と "ask" へのフォールバック
