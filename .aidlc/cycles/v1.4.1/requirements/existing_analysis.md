# 既存コード分析

## サイクル
v1.4.1

## 分析対象
各バックログ項目に関連するファイルの特定

---

## 1. Issue #12: コマンドラインツールのプロジェクトタイプを追加

### 現状
- `aidlc.toml` に `project.type` の設定項目がない
- `operations_progress_template.md` で以下のプロジェクト種別が定義されている:
  - モバイルアプリ（ios/android）: 全ステップ実施
  - Web/バックエンド（web/backend/general）: ステップ4（配布）をスキップ
- コマンドラインツール（cli）は未定義

### 関連ファイル
| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/templates/operations_progress_template.md` | cli プロジェクトタイプを追加 |
| `prompts/package/prompts/operations.md` | cli の配布ステップ処理を追加 |
| `prompts/setup-init.md` | プロジェクトタイプ選択肢に cli を追加（必要な場合） |

---

## 2. chore-workaround-backlog-rule.md: その場しのぎ対応時のバックログ追加ルール

### 現状
- プロンプト内に workaround に関する記述なし
- 気づき記録フローは `construction.md` に存在

### 関連ファイル
| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/construction.md` | workaround 実施時のルールセクションを追加 |
| `prompts/package/prompts/operations.md` | 同上（必要な場合） |
| `docs/cycles/rules.md` | プロジェクト共通ルールに追加 |

---

## 3. feat-follow-readme-links.md: README.md読み込み時にリンクを辿る

### 現状
- `prompts/setup-init.md` で README.md を読み込む処理がある
- リンクを辿る処理は未実装

### 関連ファイル
| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | README.md 読み込み時にリンクを辿るルールを追加 |

---

## 4. feat-unit-file-numbering.md: ユニット定義ファイルに実行順序番号を付与

### 現状
- Unit 定義ファイルは `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md` 形式
- 番号付けは未実装
- 依存関係は Unit 定義ファイル内の「依存する Unit」セクションで記述

### 関連ファイル
| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/inception.md` | Unit 定義ファイル作成時の番号付けルールを追加 |
| `prompts/package/prompts/construction.md` | Unit ファイル読み込み時の番号順処理を追加 |
| `prompts/package/templates/unit_definition_template.md` | ファイル名規則の説明を追加 |

---

## 5. refactor-remove-commit-hash-recording.md: コミットハッシュのファイル記録を廃止

### 現状
- `unit_definition_template.md` の「実装状態」セクションに以下の記述あり:
  ```markdown
  - **コミット**: -

  > **注意**: コミットハッシュは実際にコミットを作成した後に記録してください。短縮形（7文字）を使用します。
  ```

### 関連ファイル
| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/templates/unit_definition_template.md` | コミットフィールドと注意書きを削除 |
| `prompts/package/prompts/construction.md` | コミットハッシュ記録に関する記述があれば削除 |

---

## まとめ

| # | 項目 | 主な変更ファイル |
|---|------|-----------------|
| 1 | コマンドラインツールのプロジェクトタイプ追加 | operations.md, operations_progress_template.md |
| 2 | workaround 時のバックログ追加ルール | construction.md, rules.md |
| 3 | README.md リンク辿り | setup-init.md |
| 4 | Unit ファイル番号付け | inception.md, construction.md, unit_definition_template.md |
| 5 | コミットハッシュ記録廃止 | unit_definition_template.md |
