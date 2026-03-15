# 論理設計: アップグレード用ブランチ名の改善

## 概要

`post-merge-sync.sh`のブランチ削除対象パターンを拡張し、関連ドキュメントを更新する論理設計。

**重要**: このドキュメントでは**コードは書かず**、コンポーネント構成とインターフェースのみを定義します。

## アーキテクチャパターン

既存のパターン（`--merged main`フィルタ + `git branch --list`パターンマッチ）を維持。パターンを追加するのみ。

## コンポーネント構成

### 変更対象A: post-merge-sync.sh のブランチ列挙

**現状**:
- ローカル: `git branch --list 'cycle/*' --merged main`
- リモート: `git branch -r --list 'origin/cycle/*' --merged main`

**変更方針**:
- 各コマンドを2回実行し結果を結合: `cycle/*` + `upgrade/*`
- 既存の`--merged main`安全フィルタは維持（非マージブランチは対象外）

### 変更対象B: setup-prompt.md

**変更方針**:
- ケースC（アップグレード可能）のアクション説明に「aidlc-setupスキルが`upgrade/vX.X.X`ブランチを作成する」旨を追記

### 変更対象A-2: post-merge-sync.sh のヘルプ・メッセージ更新

**変更方針**:
- ファイル冒頭コメント（line 6）: `サイクルブランチ` → `マージ済みブランチ（cycle/ + upgrade/）`
- ヘルプ出力（line 37）: `cycle/` に加えて `upgrade/` を記載
- 実行ログ（line 144, 152等）: `サイクルブランチ` → `マージ済みブランチ`

### 変更対象C: docs/cycles/rules.md

**変更方針**:
- ブランチ運用フローの処理内容説明（line 37付近）に`upgrade/`を追加
- post-merge-sync.sh の説明に`upgrade/`ブランチの削除を追記

## インターフェース定義

### post-merge-sync.sh の出力（変更なし）

既存の出力キー（`deleted:local:*`, `deleted:remote:*`, `warn:*-delete-failed:*`）はそのまま維持。`upgrade/*`ブランチの場合も同じキーで出力される。

## 安全性保証

- **マージ先前提**: 削除対象は `main` にマージ済みのブランチのみ（`--merged main` フィルタ）。アップグレードブランチのマージ先は常に`main`（SKILL.mdのPR作成フローで`--base BASE_BRANCH`を指定、通常は`main`またはサイクルブランチの元ブランチ）
- **パターン限定**: `git branch --list` のパターンは明示的な`cycle/*`と`upgrade/*`のみ。他のプレフィックス（`feature/*`等）は対象外
- **未マージ保護**: `--merged main` 条件を満たさないブランチは削除されない
