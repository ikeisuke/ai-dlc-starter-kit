# ドメインモデル: SKILL.md参照混同修正

## 概要

Inceptionセットアップのステップ3-4における「存在確認」と「参照先ポリシー定義」の責務を分離し、メタ開発環境でのSKILL.md参照混同を解消する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### デプロイ済みファイル確認（ステップ3）

- **責務**: `skills/aidlc/SKILL.md` のファイル存在確認のみ
- **属性**:
  - skill_md_exists: boolean - ファイルが存在するか
- **振る舞い**:
  - 存在確認: `ls skills/aidlc/SKILL.md` で判定
  - 未存在時: `/aidlc setup` を案内し続行
- **制約**: 環境依存の判断を行わない（存在するかどうかの事実のみ）

### リポジトリ判定（ステップ4）

- **責務**: プロジェクト種別の判定 + 環境ごとの参照先ポリシー定義
- **属性**:
  - project_type: enum(STARTER_KIT_DEV, USER_PROJECT) - プロジェクト種別
- **振る舞い**:
  - 判定: `[project].name` が `ai-dlc-starter-kit` かどうか
  - ポリシー定義: 判定結果に基づき参照先ポリシーを適用

## 値オブジェクト（Value Object）

### 参照先ポリシー

- **属性**:
  - edit_target: string - スキル内リソースの編集対象パス
  - deploy_check_meaning: string - ステップ3の存在確認が意味すること
  - excluded_paths: list - 編集候補・更新対象・差分比較対象から除外するパス
- **不変性**: 環境判定結果に対して一意に決まる
- **等価性**: project_typeで決定

### STARTER_KIT_DEVポリシー

- edit_target: `skills/aidlc/`（リポジトリ内）
- deploy_check_meaning: プラグインのインストール状態を保証しない（リポジトリ内に常に存在）
- excluded_paths: `~/.claude/plugins/` 配下

### USER_PROJECTポリシー

- edit_target: 該当なし（スキル実行時はスキルベースディレクトリ相対パス）
- deploy_check_meaning: プラグインがデプロイされているかどうかを示す
- excluded_paths: `~/.claude/plugins/` 配下

## 集約（Aggregate）

### Inceptionセットアップフロー

- **集約ルート**: セットアップ手順全体
- **含まれる要素**: ステップ3（存在確認）、ステップ4（リポジトリ判定 + 参照先ポリシー）
- **境界**: ステップ3とステップ4は独立に実行される。ステップ4は `project_type` を独立に判定し、その結果に基づいてステップ3の存在確認結果の意味解釈を与える
- **不変条件**: 環境依存の判断はステップ4以降でのみ行う。依存方向: `project_type` → `reference_policy`、`skill_md_exists` + `reference_policy` → `deploy_check_meaning`

## ユビキタス言語

- **プラグインキャッシュ**: `~/.claude/plugins/` 配下のインストール済みスキルファイル群。読み取り専用で使用
- **リポジトリソース**: プロジェクト内の `skills/aidlc/` 配下のソースファイル。メタ開発時の編集対象
- **参照先ポリシー**: 環境判定結果に基づく、スキルリソースの参照・編集・除外ルールの定義
- **デプロイ済みファイル確認**: `skills/aidlc/SKILL.md` の存在を環境非依存に確認する手順

## 不明点と質問（設計中に記録）

（なし - 要件は明確）
