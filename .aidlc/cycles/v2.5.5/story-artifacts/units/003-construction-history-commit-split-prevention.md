# Unit: Construction Unit 完了処理 step5↔step8 分裂の構造的予防

## 概要

`steps/construction/04-completion.md` ステップ 5（履歴記録）と ステップ 8（コミット）の関係を文書整合 + commit-flow チェックリスト + write-history 警告経路の三層化で構造的予防する。v1.15.1 cycle で発生した 5 Unit × 2 commit = 10 commit 分裂 + rebase fixup（破壊的操作）の再発を防ぐ。

## 含まれるユーザーストーリー

- ストーリー 3: Construction Unit 完了処理 step5↔step8 分裂の構造的予防（#654）

## 責務

- `steps/construction/04-completion.md` ステップ 5/8 の関係に「履歴ファイルを必ず Unit 完了 commit に含める」旨の注記を 1 箇所以上追加
- `steps/common/commit-flow.md` のコミット前チェックリストに「履歴ファイル staged 確認」項目を 1 項目以上追加
- **`scripts/write-history.sh` 自身が判定主体（DR-002）**: write-history.sh の `--mode base` 通常パス完了直後に `git diff --cached --name-only -- <history-path>` で履歴ファイルの staged 状態を確認し、unstaged の場合は `warning: history file unstaged` 等の警告を stdout/stderr に出力する経路を追加（exit code 0 維持、`git diff` 失敗時は警告スキップで exit 0 維持）
- bats テスト 1 件以上で write-history 警告経路の動作確認（**テスト対象**: write-history.sh の `--mode base` 通常パス完了直後の staged 確認分岐。fixture: `git init` 済みディレクトリで履歴ファイルが unstaged の状態 → 警告 stdout/stderr 出力検証）
- ドライラン手順を必須記載項目 3 点固定で文書化（write-history 実行参照 / `git status` または `git diff --cached --name-only` 確認 / `git add` 確認）

## 境界

- 提案 D（ステップ 8 への `git add` 明示手順追加）の単独実装は行わない（提案 A の自然な帰結として吸収、OUT_OF_SCOPE）
- `commit-flow.md` の他のチェックリスト項目の再構成は行わない（追加のみ）
- write-history.sh の exit code 体系変更は行わない（exit 0 維持で stdout/stderr 出力のみ）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- 既存の `scripts/write-history.sh` 実装、`steps/construction/04-completion.md` / `steps/common/commit-flow.md` の現行構造

## 非機能要件（NFR）

- **パフォーマンス**: write-history 警告経路は git diff 1 回呼び出し増加。負荷無視可能
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: write-history 警告は exit 0 維持のため後方互換性を完全保持

## 技術的考慮事項

- **判定方式は DR-002 で確定済み**: write-history.sh 自身が `git diff --cached --name-only -- <history-path>` で staged 確認する（外部呼び出しでなく内部判定で単一責任を保つ）
- 提案 A + B + C の 3 層化により、文書を読み飛ばしても commit-flow チェックリストで気付き、checklist を読み飛ばしても write-history 警告で気付く三重防御
- `git diff` 実行失敗時（git リポジトリ外等）は警告スキップで exit 0 維持（後方互換性保護）

## 関連Issue

- #654（[Feedback] Unit 完了処理のステップ 5（履歴記録）と ステップ 8（コミット）の関係が曖昧で commit が分裂しやすい）

## 実装優先度

High

## 見積もり

2〜3 時間（文書修正 2 ファイル + write-history.sh 警告経路追加 + bats テスト 1 件 + ドライラン手順記述）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-08
- **完了日**: 2026-05-08
- **担当**: AI-DLC エージェント
- **エクスプレス適格性**: -
- **適格性理由**: -
