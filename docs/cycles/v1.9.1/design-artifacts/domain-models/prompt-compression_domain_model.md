# ドメインモデル: プロンプトの圧縮・統合

## 概要

AI-DLCのプロンプトファイルとスクリプトの構造を整理し、重複を排除してコンテキスト消費を削減する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はPhase 2（コード生成ステップ）で行います。

## 対象コンポーネント

このUnitでは典型的なDDDのエンティティ・値オブジェクトは存在せず、以下のコンポーネントを扱う。

### スクリプトコンポーネント

#### init-cycle-dir.sh

- **現在の責務**:
  - サイクル用ディレクトリ構造（10個）の作成
  - history/inception.md の初期化
- **拡張する責務**:
  - backlog mode判定（docs/aidlc.tomlから取得）
  - 共通バックログディレクトリの条件付き作成（docs/cycles/backlog/, docs/cycles/backlog-completed/）
- **制約**:
  - サイクル非依存のディレクトリ（共通バックログ）は別処理として追加
  - 既存の出力形式（dir:パス:状態）を維持
  - --dry-run オプション対応
  - **issue-onlyモードの場合**: backlogディレクトリ作成をスキップ

### ドキュメントコンポーネント

#### setup.md

- **現在の責務**:
  - 新規サイクルのセットアップフロー定義
  - ステップ10でbacklogディレクトリを手動作成
- **変更する責務**:
  - backlogディレクトリ作成をinit-cycle-dir.shに委譲
  - AI-DLC手法の要約は維持（単独使用されるため）

## 変更の影響範囲

### 影響を受けるファイル

| ファイル | 変更種別 | 影響 |
|---------|---------|------|
| `prompts/package/bin/init-cycle-dir.sh` | 機能追加 | backlogディレクトリ作成の追加 |
| `prompts/package/prompts/setup.md` | 簡略化 | 手動コマンド削除 |

### 影響を受けないファイル

- `prompts/package/prompts/common/intro.md` - 変更なし
- `prompts/package/prompts/inception.md` - 変更なし
- `prompts/package/prompts/construction.md` - 変更なし
- `prompts/package/prompts/operations.md` - 変更なし

## ユビキタス言語

- **共通バックログ**: サイクルをまたいで管理されるバックログ項目の保存場所（`docs/cycles/backlog/`）
- **サイクル固有ディレクトリ**: 特定サイクルに紐づくディレクトリ（`docs/cycles/{{CYCLE}}/`）
- **プロンプト圧縮**: 重複や冗長な記述を削除してコンテキスト消費を減らすこと

## 不明点と質問（設計中に記録）

[Question] backlog modeがissue-onlyの場合、共通バックログディレクトリを作成してよいですか？
[Answer] mode判定して作成する。issue-onlyの場合はスキップする方針で設計を更新。
