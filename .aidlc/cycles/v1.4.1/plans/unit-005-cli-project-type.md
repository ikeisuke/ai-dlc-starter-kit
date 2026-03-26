# Unit 005: CLIプロジェクトタイプ追加 - 計画

## 概要

コマンドラインツール（cli）をプロジェクトタイプとして選択できるようにする。

## 変更対象ファイル

1. `prompts/package/templates/operations_progress_template.md`
2. `prompts/package/prompts/operations.md`

## 変更内容

### 1. operations_progress_template.md

**変更箇所**: 「プロジェクト種別による差異」セクション

**現在**:
```markdown
## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ4（配布）をスキップ
```

**変更後**:
```markdown
## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ4（配布）をスキップ
```

### 2. operations.md

**変更箇所**: ステップ4の説明

**現在（268行目付近）**:
```markdown
### ステップ4: 配布（PROJECT_TYPE=general の場合はスキップ）【対話形式】
```

**変更後**:
```markdown
### ステップ4: 配布（PROJECT_TYPE=web/backend/general の場合はスキップ）【対話形式】
```

**追加変更箇所**: 「最初に必ず実行すること」セクションのステップ3の説明（195行目付近）

**現在**:
```markdown
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（全ステップ「未着手」、PROJECT_TYPEに応じて配布ステップを「スキップ」に設定）
```

この説明は変更不要（既に一般化されている）。

## 設計判断

- cli は desktop に準じる扱いとし、配布ステップを実施
- 配布ステップでは、CLIツールのパッケージング（homebrew、npm、pip等）や配布方法を計画

## 影響範囲

- 新規プロジェクトの Operations Phase で cli を選択した場合に適用
- 既存プロジェクトへの影響なし
