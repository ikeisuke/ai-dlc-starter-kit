# Unit 4: フェーズプロンプト改修 - 実装計画

## 概要
変数置換方式を廃止し、フェーズプロンプトが設定ファイル（`project.toml`）を参照する方式へ移行する

## 依存関係
- Unit 2: 設定アーキテクチャ設計（完了済み）- 設定参照方式の定義
- Unit 3: セットアップ分離（完了済み）- 設定ファイルが生成される前提

## 改修対象ファイル

### 1. `prompts/setup/common.md`
- **変更内容**:
  - 「変数置換ルール」セクションを「設定参照ルール」に変更
  - 変数一覧テーブルを削除
  - 代わりに「設定ファイルから情報を取得する」方式の説明を追加
  - `{{VAR}}` 形式の変数は廃止し、固定パスに変更

### 2. `prompts/setup/inception.md`
- **変更内容**:
  - プロンプト冒頭に「最初に読み込むファイル」セクションを追加
  - `{{AIDLC_ROOT}}` → `docs/aidlc`（固定パス）
  - `{{CYCLES_ROOT}}` → `docs/cycles`（固定パス）
  - `{{CYCLE}}` → 「ユーザーから指示されたサイクル」
  - `{{PROJECT_SUMMARY}}` → 「project.tomlから取得」
  - `{{ROLE_INCEPTION}}` → 固定値「プロダクトマネージャー兼ビジネスアナリスト」
  - `{{SETUP_PROMPT_PATH}}` → `prompts/setup-prompt.md`（固定パス）

### 3. `prompts/setup/construction.md`
- **変更内容**:
  - プロンプト冒頭に「最初に読み込むファイル」セクションを追加
  - 同様に変数を固定パスまたは設定ファイル参照に変更
  - `{{ROLE_CONSTRUCTION}}` → 固定値「ソフトウェアアーキテクト兼エンジニア」

### 4. `prompts/setup/operations.md`
- **変更内容**:
  - プロンプト冒頭に「最初に読み込むファイル」セクションを追加
  - 同様に変数を固定パスまたは設定ファイル参照に変更
  - `{{ROLE_OPERATIONS}}` → 固定値「DevOpsエンジニア兼SRE」

## 設定参照の標準パターン

```markdown
## 最初に読み込むファイル【必須】

### 1. プロジェクト設定
`docs/aidlc/project.toml` を読み込む

このファイルから以下の情報を取得:
- プロジェクト名
- プロジェクト概要
- 技術スタック
- コーディング規約
- セキュリティ要件

### 2. サイクル特定
ユーザーから指示されたサイクルバージョン（例: v1.2.0）に基づいて、
サイクルディレクトリ `docs/cycles/{サイクル}` を特定
```

## 実装ステップ

### Phase 1: 設計
1. ドメインモデル設計（設定参照パターンの構造化）
2. 論理設計（各ファイルの改修設計）
3. 設計レビュー

### Phase 2: 実装
4. `prompts/setup/common.md` の改修
5. `prompts/setup/inception.md` の改修
6. `prompts/setup/construction.md` の改修
7. `prompts/setup/operations.md` の改修
8. テスト・レビュー

## テスト方針
- 手動テスト: 各プロンプトファイルがセットアップ時に正しく機能するかを確認
- 既存プロジェクトとの互換性テスト

## 成果物
- `prompts/setup/common.md`（改修版）
- `prompts/setup/inception.md`（改修版）
- `prompts/setup/construction.md`（改修版）
- `prompts/setup/operations.md`（改修版）
- 設計ドキュメント（ドメインモデル、論理設計）
- 実装記録

## 見積もり
2時間

## 作成日
2025-12-04
