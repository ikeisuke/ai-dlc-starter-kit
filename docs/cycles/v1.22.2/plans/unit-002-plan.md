# Unit 002 計画: アップグレード用ブランチ名の改善

## 概要

アップグレード用ブランチに `upgrade/vX.X.X` プレフィックスを使用し、サイクル用ブランチ（`cycle/`）との混同を防ぐ。関連するスクリプト・ドキュメントを更新する。

## 問題分析

- `aidlc-setup` SKILL.md は既に `upgrade/vX.X.X` ブランチ名を使用（変更不要）
- `setup-prompt.md` のアップグレードモード案内にブランチ命名の明示なし → 追加必要
- `post-merge-sync.sh` は `cycle/*` パターンのみ対象 → `upgrade/*` も追加必要
- `docs/cycles/rules.md` のブランチ運用フローが `cycle/` のみ → `upgrade/` も記載必要

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `bin/post-merge-sync.sh` | `upgrade/*` ブランチのローカル・リモート削除対応、ヘルプ更新 |
| `prompts/setup-prompt.md` | アップグレードモード案内にブランチ命名(`upgrade/vX.X.X`)の明示追加 |
| `docs/cycles/rules.md` | ブランチ運用フローに `upgrade/` ブランチの削除対応を記載 |

## 実装計画

### 1. post-merge-sync.sh の修正

- ローカルブランチ列挙（line 149）: `cycle/*` に加えて `upgrade/*` も検出
- リモートブランチ列挙（line 181）: `origin/cycle/*` に加えて `origin/upgrade/*` も検出
- ヘルプメッセージ（line 37）: `upgrade/` ブランチの記載追加
- 変数名・メッセージ: `サイクルブランチ` → `マージ済みブランチ`（cycle + upgradeの両方を含むため）

### 2. setup-prompt.md の修正

- ケースC（アップグレード可能）のセクション付近に、aidlc-setupスキルが`upgrade/vX.X.X`ブランチを作成する旨を明記

### 3. docs/cycles/rules.md の修正

- ブランチ運用フロー（line 220付近）に `upgrade/vX.X.X` ブランチの説明を追加
- post-merge-sync.sh の処理内容説明に `upgrade/` ブランチの削除を追加

### 4. 検証

- dry-runモードでの動作確認
- `cycle/*` の既存動作が維持されることの確認

## 完了条件チェックリスト

- [x] post-merge-sync.sh が `upgrade/*` ブランチをローカル削除対象に含むこと
- [x] post-merge-sync.sh が `origin/upgrade/*` ブランチをリモート削除対象に含むこと
- [x] ヘルプメッセージに `upgrade/` ブランチの記載があること
- [x] setup-prompt.md でアップグレード用ブランチが `upgrade/vX.X.X` で案内されること
- [x] docs/cycles/rules.md に `upgrade/` ブランチの運用が記載されていること
- [x] `cycle/*` の既存動作が維持されること（回帰なし）
- [x] `aidlc-setup` SKILL.md で `upgrade/vX.X.X` 案内が維持されていること（変更不要の確認）
- [x] `cycle/*` と `upgrade/*` 以外のブランチ（例: `feature/*`）が削除対象にならないこと
