# ドメインモデル: パス参照一括更新・aidlc_dir設定廃止

## 概要

テキスト置換が主体のUnit。ドメインモデルは最小限。

## エンティティ

### StepFile（ステップファイル）

- `skills/aidlc/steps/` 配下のMarkdownファイル
- 責務: AIエージェントへの指示を記述
- `{{aidlc_dir}}` テンプレート変数によるガイド参照を含む

### ConfigFile（設定ファイル）

- `.aidlc/config.toml`、`skills/aidlc/config/defaults.toml`
- 責務: プロジェクト設定値の定義
- `paths.aidlc_dir` キーを含む（本Unitでは変更しない）

### PreflightSpec（プリフライト仕様）

- `steps/common/preflight.md`
- 責務: フェーズ開始時のチェック手順定義
- `aidlc_dir` のバッチ取得・表示を含む（除去対象）

## 値オブジェクト

### PathReference（パス参照）

- 形式: `{{aidlc_dir}}/guides/{filename}` または `{{aidlc_dir}}/{filename}`
- 変換ルール:
  - `{{aidlc_dir}}/guides/{filename}` → `guides/{filename}`
  - `{{aidlc_dir}}/bug-response-flow.md` → 参照自体を削除（ファイル未存在）
  - `{{aidlc_dir}}/` 単独参照（project-info.md）→ 更新

## 依存関係

- StepFile → PathReference: ステップファイルがパス参照を含む
- PreflightSpec → ConfigFile: プリフライトが設定キーを参照
- ConfigFile ← bootstrap.sh: スクリプトが設定キーに依存（スコープ外）
