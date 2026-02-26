# Unit: squash-unit.sh 事後squash対応

## 概要
squash-unit.sh に `--retroactive` オプションを追加し、GIT_SEQUENCE_EDITOR方式で過去のUnit（HEAD以外）に対する事後squashを実現する。

## 含まれるユーザーストーリー
- ストーリー 2: squash-unit.sh 事後squash対応 (#228)

## 関連Issue
- #228

## 責務
- squash-unit.sh に `--retroactive` オプションを追加
- GIT_SEQUENCE_EDITOR + GIT_EDITOR を使った非対話的rebase方式の実装
- 対象Unitのコミット範囲特定（コミットメッセージのUnit番号から）
- 異常系処理（unit-not-found, dirty-worktree, conflict）
- `--dry-run` との組み合わせ対応
- commit-flow.md のSquash統合フローに事後squash手順を追記

## 境界
- jj環境での事後squash対応はスコープ外（gitのみ）
- 既存の `git reset --soft` 方式（デフォルト動作）は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **互換性**: Linux/macOSの `sed -i` 差異に対応
- **安全性**: rebase衝突時のリカバリ手順（`git rebase --abort`）を提供

## 技術的考慮事項
- `--retroactive` は明示指定時のみ有効（デフォルトは既存の reset --soft 方式）
- squash前後で `git diff <base>..HEAD` が一致することを検証
- エラーコード: `squash:error:unit-not-found`, `squash:error:dirty-worktree`, `squash:error:conflict`
- 成功: `squash:success:{新ハッシュ}`

## 実装優先度
Medium

## 見積もり
大（シェルスクリプト実装 + テスト）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
