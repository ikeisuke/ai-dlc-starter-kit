# ドメインモデル: PR本文へのレビュー情報記載

## 概要

Unit PR・サイクルPRの本文テンプレートに、要件・受け入れ基準・レビューサマリを追加する構造を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（PRテンプレート種別）

### Unit PR ドラフトテンプレート

construction.md の「Unitブランチ作成」セクション内で使用されるドラフトPR本文。

- **用途**: Unit作業開始時のドラフトPR作成
- **タイミング**: レビュー未実施（Construction Phase 開始直後）
- **セクション構成**:
  - Unit概要（既存）
  - 要件（新規）: Unit定義の「責務」セクションから抽出
  - 受け入れ基準（新規）: Unit定義の完了条件から抽出
  - 関連Issue（既存）
  - 作業中メッセージ（既存）

### Unit PR Ready化テンプレート

construction.md の「Unit完了時 > Unit PR作成・マージ > ステップ5-2」で使用されるPR本文。

- **用途**: ドラフトPRをReady for Reviewに変更する際のPR本文更新
- **タイミング**: AIレビュー完了後、ユーザーレビュー前
- **セクション構成**:
  - Unit概要（既存）
  - 要件（新規）: Unit定義の「責務」セクションから抽出
  - 受け入れ基準（新規）: Unit定義の完了条件から抽出
  - 変更内容（既存）
  - テスト結果（既存）
  - レビューサマリ（新規・条件付き）: レビューサマリファイルから直接記載

### Unit PR 新規作成テンプレート

construction.md の「Unit完了時 > Unit PR作成・マージ > ステップ5-3」で使用されるPR本文。

- **用途**: ドラフトPRが存在しない場合の新規PR作成
- **セクション構成**: Unit PR Ready化テンプレートと同一

### サイクルPR Ready化テンプレート

operations.md の「ステップ6.6 ドラフトPR Ready化」で使用されるPR本文。

- **用途**: InceptionドラフトPRをReady for Reviewに変更する際のPR本文更新
- **タイミング**: Operations Phase リリース準備時
- **セクション構成**:
  - Summary（既存 → Intent概要に拡張）
  - 受け入れ基準（新規）: 各Unit計画ファイルの完了条件チェックリストから集約
  - 変更概要（新規）: 全Unit変更の概要
  - レビューサマリ（新規・条件付き）: レビューサマリファイルへのリンク一覧
  - Test plan（既存）
  - Closes（既存）

### サイクルPR 新規作成テンプレート

operations.md の「ステップ6.6 ドラフトPRが見つからない場合」で使用されるPR本文。

- **セクション構成**: サイクルPR Ready化テンプレートと同一

## 値オブジェクト

### レビューサマリ参照

- **Construction Phase**: `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md`
  - 単一Unit分のサマリ → PR本文に直接記載（量が限定的）
- **サイクルPR用（Operations Phase）**:
  - Construction: `docs/cycles/{{CYCLE}}/construction/units/*-review-summary.md` 全ファイル
  - Inception: `docs/cycles/{{CYCLE}}/inception/*-review-summary.md` 全ファイル
  - ファイルへのリンク一覧として記載（量が多いため直接記載しない）

### サマリ省略条件

- サマリファイルが存在しない場合: レビューサマリセクション全体を省略
- 存在チェック: `ls` コマンドでファイル有無を確認する指示をテンプレートに記載

## ユビキタス言語

- **Unit PR**: construction.md で管理されるUnit単位のPull Request
- **サイクルPR**: operations.md で管理されるサイクル全体のPull Request（cycle/{{CYCLE}} → main）
- **レビューサマリ**: AIレビューの指摘・対応を記録したファイル（Unit 004 で導入）
- **Ready化**: ドラフトPRをReady for Review状態に変更すること
